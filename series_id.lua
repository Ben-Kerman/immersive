local util = require "util"

local id_conf = {}

local id_cfg_path = mp.find_config_file("script-opts/" .. mp.get_script_name() .. "-ids.conf")
if id_cfg_path then
	local id_cfg_file = io.open(id_cfg_path, "r")
	for line in id_cfg_file:lines() do
		local id, value = line:match("([^=]+)=(.+)")
		if id then
			local keywords = util.string_split(value:lower(), " ", true)
			if keywords then
				id_conf[id] = keywords
			end
		end
	end
	id_cfg_file:close()
end

local function generate_id(filename)
	return (filename:gsub("%.[^%.]+$", "")        -- file extension
	                :gsub("[_%.]", " ")
	                :gsub("%s*%[[^%]]+%]%s*", "") -- tags in []
	                :gsub("%s*%([^%)]+%)%s*", "") -- tags in ()
	                :lower()
	                :gsub("%s+%-?%s*[sepv%d%.]+$", "") -- episode number at end
	                :gsub("[^%w%s%-\128-\255]", "") -- all non-alnum ASCII chars
	                :gsub("%s+", "-")             -- replace spaces with dash
	                :gsub("%-+", "-")             -- duplicated dashes
	                :gsub("^%-+", "")             -- leading dashes
	                :gsub("%-+$", ""))            -- trailing dashes
end

local series_id = {}

function series_id.get_id()
	local filename = mp.get_property("filename"):lower()
	local matched_id
	for id, keywords in pairs(id_conf) do
		local match = true
		for _, kw in ipairs(keywords) do
			if not filename:find(kw) then
				match = false
				break
			end
		end
		if match then
			matched_id = id
			break
		end
	end
	if matched_id then return matched_id, true
	else return generate_id(filename), false end
end

return series_id
