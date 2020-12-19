local b64 = require "base64"
local cfg = require "config"
local http = require "http"
local player = require "player"
local url = require "url"
local sys = require "system"
require "menu"
require "line_select"

-- forward declarations
local menu

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

local function audio_request(url, target_path)
	local headers = request_headers()
	table.insert(headers, audio_accept)
	if http.get{
		url = url,
		headers = headers,
		target_path = target_path
	} then return target_path
	else return nil end
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

function Pronunciation:new(id, user, mp3_l, ogg_l, mp3_h, ogg_h)
	local pr = {
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

function Pronunciation:load_audio()
	if not self.audio_file then
		local src = self.audio_h and self.audio_h or self.audio_l
		local audio_url = cfg.forvo_prefer_mp3 and src.mp3 or src.ogg
		self.audio_file = audio_request(audio_url, sys.tmp_file_name())
	end
end

function Pronunciation:play()
	self:load_audio()
	if self.audio_file then
		player.play(self.audio_file)
	else
		mp.osd_message("Failed to download audio file")
	end
end

local function extract_pronunciations(word)
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

		table.insert(prns, Pronunciation:new(a_id, user, a_mp3_l, a_ogg_l, a_mp3_h, a_ogg_h))
		next_start = u_end + 1
	end
	return prns
end

local function line_renderer(prn)
	return prn.user
end

local function sel_renderer(prn)
	return "{\\b1}" .. line_renderer(prn) .. "{\\b0}"
end

local prns
local prn_sel

local function play_highlighted()
	if prn_sel then
		local prn = prn_sel:active_line()
		prn:play()
	end
end

local bindings = {
	{
		id = "forvo-play",
		default = "SPACE",
		desc = "Play currently highlighted audio if available",
		action = play_highlighted
	},
	{
		id = "forvo-select",
		default = "ENTER",
		desc = "Confirm selection",
		action = nil
	},
	{
		id = "forvo-cancel",
		default = "ESC",
		desc = "Cancel audio selection",
		action = nil
	}
}

menu = Menu:new{bindings = bindings}

local forvo = {}

function forvo.begin(word)
	prns = extract_pronunciations(word)
	prn_sel = LineSelect:new(prns, sel_renderer, line_renderer)
	prn_sel:start()
	menu:enable()
end

return forvo
