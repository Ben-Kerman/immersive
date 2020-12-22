local b64 = require "base64"
local BasicOverlay = require "basic_overlay"
local cfg = require "config"
local http = require "http"
local LineSelect = require "line_select"
local Menu = require "menu"
local menu_stack = require "menu_stack"
local player = require "player"
local sys = require "system"
local url = require "url"

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
		name = "Host",
		value = "audio00.forvo.com"
	})
	table.insert(headers, {
		name = "Accept",
		value = "audio/webm,audio/ogg,audio/wav,audio/*;q=0.9,application/ogg;q=0.7,video/*;q=0.6,*/*;q=0.5"
	})
	return headers
end)()

local html_headers = (function()
	local headers = request_headers()
	table.insert(headers, {
		name = "Host",
		value = "forvo.com"
	})
	table.insert(headers, {
		name = "Accept",
		value = "text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8"
	})
	return headers
end)()

local function audio_request(url, target_path, async, callback)
	local headers = request_headers()
	table.insert(headers, audio_accept)
	local http_params = {
		url = url,
		headers = headers,
		target_path = target_path
	}
	local function handle_http_res(res)
		if res then return target_path
		else msg.error("Failed to load Forvo audio") end
	end
	if async then
		http.get_async(http_params, function(res)
			callback(handle_http_res(res))
		end)
	else
		local res = http.get(http_params)
		return handle_http_res(res)
	end
end

local function html_request(url)
	local headers = request_headers()
	table.insert(headers, html_accept)
	return http.get{
		url = url,
		headers = headers
	}
end

local Pronunciation = {}
Pronunciation.__index = Pronunciation

function Pronunciation:new(menu, id, user, mp3_l, ogg_l, mp3_h, ogg_h)
	local pr = {
		menu = menu,
		id = tonumber(id),
		user = user,
		audio_l = {
			mp3 = "https://audio00.forvo.com/mp3/" .. b64.decode(mp3_l),
			ogg = "https://audio00.forvo.com/ogg/" .. b64.decode(ogg_l)
		}
	}
	if mp3_h ~= "" and ogg_h ~= "" then
		pr.audio_h = {
			mp3 = "https://audio00.forvo.com/audios/mp3/" .. b64.decode(mp3_h),
			ogg = "https://audio00.forvo.com/audios/ogg/" .. b64.decode(ogg_h)
		}
	end
	return setmetatable(pr, Pronunciation)
end

function Pronunciation:load_audio(async)
	local function set_audio_file(res)
		if res then
			self.audio_file = {
				word = self.menu.word,
				extension = extension,
				path = res
			}
			self.menu.prn_sel:update()
		end
	end

	if not self.audio_file then
		local extension = cfg.values.forvo_prefer_mp3 and "mp3" or "ogg"
		local src = self.audio_h and self.audio_h or self.audio_l
		local audio_url = src[extension]
		if async then
			audio_request(audio_url, sys.tmp_file_name(), true, set_audio_file)
		else set_audio_file(audio_request(audio_url, sys.tmp_file_name())) end
	end
end

function Pronunciation:play()
	self:load_audio()
	if self.audio_file then
		player.play(self.audio_file.path)
	else msg.error("Failed to download audio file") end
end

local function extract_pronunciations(menu, word, callback)
	local word_url = "https://forvo.com/word/" .. url.encode(word) .. "/"
	local html = html_request(word_url)

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
end

local function line_conv(prn)
	return {
		style = {"word_audio_select", prn.audio_file and "loaded" or "unloaded"},
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
		resume_state = was_paused,
		data = data,
		word = word,
		prns = {},
		loading_overlay = BasicOverlay:new("Loading Forvo data...", nil, "line_select"),
		menu = Menu:new{bindings = bindings}
	}, Forvo)

	extract_pronunciations(fv, word, function(prns)
		fv.prns = prns
		fv.prn_sel = LineSelect:new(prns, line_conv)
		if cfg.values.forvo_preload_audio then
			for _, prn in ipairs(prns) do
				prn:load_audio(true)
			end
		end
	end)
	return fv
end

function Forvo:play_selected()
	if self.prn_sel then
		local prn = self.prn_sel:selection()
		prn:play()
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
	mp.set_property_bool("pause", self.resume_state)
end

return Forvo
