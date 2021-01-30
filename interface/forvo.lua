-- Immersive is licensed under the terms of the GNU GPL v3: https://www.gnu.org/licenses/; © 2020 Ben Kerman

local b64 = require "utility.base64"
local BasicOverlay = require "interface.basic_overlay"
local cfg = require "systems.config"
local helper = require "utility.helper"
local http = require "systems.http"
local LineSelect = require "interface.line_select"
local Menu = require "interface.menu"
local menu_stack = require "interface.menu_stack"
local mpu = require "mp.utils"
local msg = require "systems.message"
local player = require "systems.player"
local sys = require "systems.system"
local url = require "utility.url"

local html_cache = {}
local cache_dir = mpu.join_path(sys.tmp_dir(), script_name .. "_forvo_cache")
local word_cache_file = mpu.join_path(cache_dir, "words.json")
local audio_host = "https://audio00.forvo.com/"

local function request_headers()
	return {
		{name = "Accept-Language", value = "en-US"},
		{name = "Cache-Control", value = "no-cache"},
		{name = "Connection", value = "keep-alive"},
		{name = "DNT", value = "1"},
		{name = "Pragma", value = "no-cache"},
		{name = "Range", value = "bytes=0-"},
		{name = "Referer", value = "https://forvo.com/"},
		{name = "Upgrade-Insecure-Requests", value = "1"},
		{name = "User-Agent", value = "Mozilla/5.0 (Windows NT 10.0; rv:84.0) Gecko/20100101 Firefox/84.0"}
	}
end
local audio_headers = (function()
	local headers = request_headers()
	table.insert(headers, {
		name = "Accept",
		value = "audio/webm,audio/ogg,audio/wav,audio/*;q=0.9,application/ogg;q=0.7,video/*;q=0.6,*/*;q=0.5"
	})
	return headers
end)()

local html_headers = (function()
	local headers = request_headers()
	table.insert(headers, {
		name = "Accept",
		value = "text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8"
	})
	return headers
end)()

local function get_audio_file(path)
	local target_path = mpu.join_path(cache_dir, path)
	if not sys.create_dir((mpu.split_path(target_path))) then
		msg.warn("could not create directory for Forvo audio")
		return nil
	end

	return not not mpu.file_info(target_path), target_path
end

local function audio_request(path, callback)
	local exists, target_path = get_audio_file(path)
	if exists then
		callback(target_path)
		return nil
	end

	local http_params = {
		url = audio_host .. path,
		headers = audio_headers,
		target_path = target_path
	}
	local function handle_http_res(res)
		if res then return target_path
		else msg.error("failed to load Forvo audio") end
	end
	return http.get_async(http_params, function(res)
		callback(handle_http_res(res))
	end)
end

local function html_request(url, callback)
	if html_cache[url] then
		callback(html_cache[url])
		return nil
	end

	return http.get_async({
		url = url,
		headers = html_headers
	}, function(res)
		if not res then
			msg.error("failed to load Forvo website")
			return
		end
		html_cache[url] = res
		callback(res)
	end)
end

local Pronunciation = {}
Pronunciation.__index = Pronunciation

function Pronunciation:new(menu, id, user, mp3_l, ogg_l, mp3_h, ogg_h)
	local extension = cfg.values.forvo_prefer_mp3 and "mp3" or "ogg"
	local src = mp3_h ~= "" and ogg_h ~= "" and {
		mp3 = "audios/mp3/" .. b64.decode(mp3_h),
		ogg = "audios/ogg/" .. b64.decode(ogg_h)
	} or {
		mp3 = "mp3/" .. b64.decode(mp3_l),
		ogg = "ogg/" .. b64.decode(ogg_l)
	}

	local exists, target_path = get_audio_file(src[extension])
	local audio_file
	if exists then
		audio_file = {
			word = menu.word,
			path = target_path
		}
	end

	return setmetatable({
		menu = menu,
		id = tonumber(id),
		user = user,
		source_path = src[extension],
		audio_file = audio_file,
		loading = false
	}, Pronunciation)
end

function Pronunciation:load_audio(callback)
	if not self.audio_file then
		self.loading = true
		if self.menu.prn_sel then
			self.menu.prn_sel:update()
		end

		local req = audio_request(self.source_path, function(res)
			if res then
				self.loading = false
				self.audio_file = {
					word = self.menu.word,
					path = res
				}
				self.menu.prn_sel:update()
				if callback then callback() end
			end
		end)
		table.insert(self.menu.requests, req)
	elseif callback then callback() end
end

function Pronunciation:play()
	self:load_audio(function()
		if self.audio_file then
			player.play(self.audio_file.path)
		end
	end)
end

local function extract_pronunciations(menu, word, callback)
	local word_url = "https://forvo.com/word/" .. url.encode(word) .. "/"
	return html_request(word_url, function(html)
		local start_pat = [[pronunciation in%s*<a href="https://forvo%.com/languages/]] .. cfg.values.forvo_language .. [[/">]]
		local end_pat = [[<div class="more_actions">]]
		local audio_pat = [[onclick="Play%((%d+),'([^']*)','([^']*)',([^,]*),'([^']*)','([^']*)','(.)'%);return false;"]]
		local user_prefix_pat = "Pronunciation by%s+"
		local user_pat = [[^<span class="ofLink" data%-p1="[^"]+" data%-p2="([^"]+)" >]]
		local user_pat_no_link = "^(%S+)"

		local _, audio_from = html:find(start_pat)
		local audio_to = html:find(end_pat, audio_from)

		local prns = {}
		local next_start = audio_from
		while true do
			local a_start, a_end, a_id, a_mp3_l, a_ogg_l, a_bool, a_mp3_h, a_ogg_h, a_char = html:find(audio_pat, next_start)
			if not a_start or a_start > audio_to then break end

			local _, user_from = html:find(user_prefix_pat, a_end + 1)
			local _, u_end, user = html:find(user_pat, user_from + 1)
			if not user then
				_, u_end, user = html:find(user_pat_no_link, user_from + 1)
			end

			table.insert(prns, Pronunciation:new(menu, a_id, user, a_mp3_l, a_ogg_l, a_mp3_h, a_ogg_h))
			next_start = u_end + 1
		end
		callback(prns)
	end)
end

local function line_conv(prn)
	local style_name
	if prn.audio_file then
		style_name = "loaded"
	elseif prn.loading then
		style_name = "loading"
	else style_name = "unloaded" end

	return {
		style = {"word_audio_select", style_name},
		prn.user
	}
end

local Forvo = {}
Forvo.__index = Forvo

function Forvo:new(data, word)
	local was_paused = mp.get_property_bool("pause")
	mp.set_property_bool("pause", true)

	local fv

	local bindings = {
		group = "forvo",
		{
			id = "play",
			default = "SPACE",
			desc = "Play currently highlighted audio, fetch if not yet loaded",
			action = function() fv:play_selected() end
		},
		{
			id = "select",
			default = "ENTER",
			desc = "Confirm selection",
			action = function() fv:finish() end
		}
	}

	fv = setmetatable({
		requests = {},
		resume_state = was_paused,
		data = data,
		word = word,
		prns = {},
		loading_overlay = BasicOverlay:new("Loading Forvo data...", nil, "info_overlay"),
		menu = Menu:new{bindings = bindings}
	}, Forvo)

	local not_found_cached = false
	local req = extract_pronunciations(fv, word, function(prns)
		if #prns == 0 then
			msg.info("no pronunciations found for '" .. word .."'")
			if menu_stack.top() == fv then
				menu_stack.pop()
			else not_found_cached = true end
		end

		if cfg.values.forvo_preload_audio then
			for _, prn in ipairs(prns) do
				prn:load_audio()
			end
		end
		fv.prns = prns
		fv.prn_sel = LineSelect:new(prns, line_conv)
		fv.loading_overlay:hide()
		fv.prn_sel:show()
	end)
	if not_found_cached then
		return nil
	end
	table.insert(fv.requests, req)
	return fv
end

function Forvo:play_selected()
	if self.prn_sel then
		self.prn_sel:selection():play()
	end
end

function Forvo:finish()
	local sel = self.prn_sel:selection()
	self.data.word_audio_file = sel.audio_file
	menu_stack.pop()
end

function Forvo:show()
	self.menu:show()
	if self.prn_sel then
		self.prn_sel:show()
	else self.loading_overlay:show() end
end

function Forvo:hide()
	self.menu:hide()
	if self.prn_sel then
		self.prn_sel:hide()
	else self.loading_overlay:hide() end
end

function Forvo:cancel()
	self:hide()
	for _, req in ipairs(self.requests) do
		mp.abort_async_command(req)
	end
	mp.set_property_bool("pause", self.resume_state)
end

return Forvo
