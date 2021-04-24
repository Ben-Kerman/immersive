-- Immersive is licensed under the terms of the GNU GPL v3: https://www.gnu.org/licenses/; © 2021 Ben Kerman

local cfg = require "systems.config"
local ext = require "utility.extension"
local mpu = require "mp.utils"
local helper = require "utility.helper"

local default_dir = mpu.join_path(cfg.cfg_dir, script_name .. "-data/inflection-tables")

local loaded_tables = {}
local function load_table(path)
	local abs_path = mpu.join_path(default_dir, path)
	if not loaded_tables[abs_path] then
		loaded_tables[abs_path] = helper.parse_json_file(abs_path)
	end
	return loaded_tables[abs_path]
end

return function(path)
	if not path then
		return nil, "argument missing"
	end

	local inflections = load_table(path)
	if not inflections then
		return nil, "inflection table could not be loaded: " .. path
	end

	return function(word)
		local base_forms = {}

		for _, inf in ipairs(inflections) do
			if ext.string_ends(word, inf.inflected) then
				for _, base in ipairs(inf.dict) do
					local no_suf = word:gsub(inf.inflected .. "$", base)
					if inf.prefix then
						local no_pref = word:gsub("^" .. no_suf, "")
						ext.list_insert_cond(base_forms, no_pref)
					end
					ext.list_insert_cond(base_forms, no_suf)
				end
			end
		end

		return base_forms
	end
end
