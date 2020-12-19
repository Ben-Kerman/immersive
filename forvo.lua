local b64 = require "base64"
local http = require "http"
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

local function audio_request(url, target_path)
	local headers = request_headers()
	table.insert(headers, audio_accept)
	http.get{
		url = url,
		headers = headers,
		target_path = target_path
	}
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

local forvo = {}

function forvo.begin(word)
	local word_url = "https://forvo.com/word/" .. url.encode(word) .. "/"
	local html = html_request(word_url)
end

return forvo
