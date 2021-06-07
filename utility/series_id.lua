-- Immersive is licensed under the terms of the GNU GPL v3: https://www.gnu.org/licenses/; © 2021 Ben Kerman

local bus = require "systems.bus"
local cfg = require "systems.config"
local ext = require "utility.extension"
local helper = require "utility.helper"
local mpu = require "mp.utils"

local cfg_def = {
	sections = true,
	section_entries = {
		items = {
			title = {},
			keywords = {
				required = true,
				convert = function(value)
					return ext.string_split(value:lower(), "%s+", true)
				end
			}
		}
	}
}

local config
local function reload_config()
	config = ext.list_map(cfg.load_subcfg("series", cfg_def), function(section)
		return {
			id = section.name,
			title = section.entries.title,
			keywords = section.entries.keywords
		}
	end)
end
reload_config()
bus.listen("reload_config", reload_config)

local function generate_title(filename)
	return (filename:gsub("%.[^%.]+$", "")        -- file extension
	                :gsub("[_%.]", " ")
	                :gsub("%s*%[[^%]]+%]%s*", "") -- tags in []
	                :gsub("%s*%([^%)]+%)%s*", "") -- tags in ()
	                :gsub("%s+%-?%s*[SsEePpVv%d%.]+$", "")) -- episode number at end
end

local function generate_id(filename)
	local title = generate_title(filename)
	return (title:lower()
	             :gsub("[^%w%s%-\128-\255]", "")  -- all non-alnum ASCII chars
	             :gsub("%s+", "-")                -- replace spaces with dash
	             :gsub("%-+", "-")                -- duplicated dashes
	             :gsub("^%-+", "")                -- leading dashes
	             :gsub("%-+$", ""))               -- trailing dashes
end

local function get_base()
	local abs_path, is_url = helper.current_path_abs()
	if not abs_path then return false end

	if is_url then
		return abs_path
	else
		local _, filename = mpu.split_path(abs_path)
		return filename
	end
end

local function match_keywords(str)
	local str_lc = str:lower()
	for _, values in ipairs(config) do
		local match = true
		for _, kw in ipairs(values.keywords) do
			if not str_lc:find(kw) then
				match = false
				break
			end
		end
		if match then
			return values.id, values
		end
	end
	return false
end

local series_id = {}

function series_id.id()
	local base = get_base()
	if not base then return nil end

	local id = match_keywords(base)
	if id then
		return id, true
	else return generate_id(base), false end
end

function series_id.title()
	local base = get_base()
	if not base then return nil end

	local id, values = match_keywords(base)
	if id and values.title then
		return values.title, true
	else return generate_title(base), false end
end

return series_id
