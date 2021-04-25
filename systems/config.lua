-- Immersive is licensed under the terms of the GNU GPL v3: https://www.gnu.org/licenses/; © 2021 Ben Kerman

local bus = require "systems.bus"
local cfg_util = require "systems.config_util"
local ext = require "utility.extension"
local mpu = require "mp.utils"
local msg = require "systems.message"

local conv = cfg_util.convert
local cfg_def = {
	sections = false,
	entries = {
		items = {
			mpv_executable = {},
			preload_dictionaries = {
				convert = conv.bool,
				default = false
			},
			startup_dict_overlay = {
				convert = conv.bool,
				default = true
			},
			max_targets = {
				convert = conv.num,
				default = 1
			},
			always_show_minutes = {
				convert = conv.bool,
				default = true
			},
			target_select_blackout = {
				convert = conv.bool,
				default = true
			},
			active_sub_blackout = {
				convert = conv.bool,
				default = true
			},
			forvo_language = {
				default = "ja"
			},
			forvo_preload_audio = {
				convert = conv.bool,
				default = false
			},
			forvo_prefer_mp3 = {
				convert = conv.bool,
				default = false
			},
			forvo_prefix = {
				default = "word_audio"
			},
			forvo_reencode = {
				convert = conv.bool,
				default = true
			},
			forvo_extension = {
				default = "mka"
			},
			forvo_format = {
				default = "matroska"
			},
			forvo_codec = {
				default = "libopus"
			},
			forvo_bitrate = {
				default = "64ki"
			},
			ankiconnect_host = {
				default = "localhost"
			},
			ankiconnect_port = {
				convert = conv.num,
				default = 8765
			},
			windows_copy_mode = {
				validate = {
					allowed = {"exact", "quick"}
				},
				default = "exact"
			},
			enable_autocopy = {
				convert = conv.bool,
				default = false
			},
			global_autoselect = {
				convert = conv.bool,
				default = true
			},
			enable_autoselect = {
				convert = conv.bool,
				default = true
			},
			global_help = {
				convert = conv.bool,
				default = true
			},
			enable_help = {
				convert = conv.bool,
				default = false
			},
			take_screenshots = {
				convert = conv.bool,
				default = true
			},
			hide_infos_if_help_active = {
				convert = conv.bool,
				default = false
			}
		}
	}
}

local _msg_fmt = "config: %s; %s:%d"
local function parse_warn(msg_txt, file, line)
	local msg_str
	if file then
		msg_str = string.format(_msg_fmt, msg_txt, file, line)
	else msg_str = "config: " .. msg_txt end

	msg.warn(msg_str)
end

local function vldt_warn(msg_txt, file, key, section, lvl)
	local msg_str = file
	if section then
		msg_str = msg_str .. ", section [" .. section .. "]"
	end
	if key then
		msg_str = msg_str .. ", entry '" .. key .. "'"
	end
	msg_str = msg_str .. ": " .. msg_txt

	msg[lvl and lvl or "warn"](msg_str)
end

local _allow_fmt = "value '%s' not allowed, possible values: '%s'"
local function validate_value(val, vldt_def)
	if vldt_def.allowed then
		local allow = vldt_def.allowed
		if not ext.list_find(allow, val) then
			return false, string.format(_allow_fmt, val, table.concat(allow, "', '"))
		end
	end

	if vldt_def.bounds then
		local min, max = vldt_def.bounds.min, vldt_def.bounds.max
		if max and max < val then
			return false, string.format("value %d too high (max: %d)", val, max)
		elseif min and val < min then
			return false, string.format("value %d too low (min: %d)", val, min)
		end
	end

	if vldt_def.fn then
		local valid, err = vldt_def.fn(val)
		if not valid then
			return false, err
		end
	end

	return true
end

local function validate_entry(key, value, path, def, section_name)
	local new_value = value

	if def.convert then
		local is_fn = type(def.convert) == "function"
		local fn = is_fn and def.convert or def.convert.fn

		local err
		if not is_fn then
			new_value, err = fn(value, table.unpack(def.convert.params))
		else new_value, err = fn(value) end

		if new_value == nil then
			vldt_warn(err, path, key, section_name)
			return nil
		end
	end

	if def.validate then
		local valid, err = validate_value(new_value, def.validate)
		if not valid then
			vldt_warn(err, path, key, section_name)
			return nil
		end
	end

	return new_value
end

local function validate_entries(path, entries, entr_def, section_name)
	local result = {}

	for key, value in pairs(entries) do
		local static = not not entr_def.items[key]
		local dynamic = entr_def.dynamic_fn and entr_def.dynamic_fn(key) or false

		if static then
			result[key] = validate_entry(key, value, path, entr_def.items[key], section_name)
		elseif dynamic then
			result[key] = value
		else vldt_warn("ignoring entry with invalid key", path, key, section_name) end
	end

	local valid = true
	for key, def in pairs(entr_def.items) do
		if def.required and result[key] == nil then
			vldt_warn("required entry missing", path, key, section_name, "error")
			valid = false
		end
	end

	return valid and result or nil
end

local function apply_defaults(entries, entr_def)
	local result = ext.map_merge(entries)
	for key, def in pairs(entr_def.items) do
		if def.default ~= nil and result[key] == nil then
			result[key] = def.default
		end
	end
	return result
end

local function entr_def_for(val, raw_sect)
	if type(val) == "function" then
		return val(raw_sect)
	else return val end
end

local function apply_def(path, raw, def)
	if not def.sections and #raw ~= 0 then
		vldt_warn("ignoring sections", path)
	end

	local global_entries = {}
	if raw.global and (def.entries or def.global_as_base) then
		local entr_def_val = def.global_as_base and def.section_entries or def.entries
		local entr_def = entr_def_for(entr_def_val, raw.global)
		local validated = validate_entries(path, raw.global, entr_def)
		if validated then
			global_entries = validated
		end
	end

	local result = {}
	if def.sections then
		for _, section in ipairs(raw) do
			local entr_def = entr_def_for(def.section_entries, section.entries)
			local validated = validate_entries(path, section.entries, entr_def, section.name)
			if validated then
				if def.global_as_base then
					for key, value in pairs(global_entries) do
						if validated[key] == nil then
							validated[key] = value
						end
					end
				end
				table.insert(result, {
					name = section.name,
					entries = apply_defaults(validated, entr_def)
				})
			end
		end
	end

	if not def.global_as_base and def.entries then
		local entr_def = entr_def_for(def.entries, raw.global)
		result.global = apply_defaults(global_entries, entr_def)
	end

	return result
end

local function check_file(path)
	if not path then return false end
	local stat_res = mpu.file_info(path)
	if not stat_res or not stat_res.is_file then
		return false
	end
	return true
end

local config = {}

config.cfg_dir = (function()
	return (mp.find_config_file("."):sub(1, -3))
end)()

function config.load(path, def)
	if not check_file(path) then
		local path_str = path and ": " .. path or ""
		msg.verbose("config file could not be loaded" .. path_str)
		if def and def.entries then
			local entr_def = entr_def_for(def.entries)
			return {global = apply_defaults({}, entr_def)}
		else return {} end
	end

	local result = {}
	local global_entries
	local section_name, section_entries
	local block_token, block_key, block_value

	local function insert_global()
		if global_entries then
			result.global = global_entries
		end
	end

	local function insert_section()
		local entries
		if global_as_base and result.global then
			entries = ext.map_merge(result.global, section_entries)
		else entries = section_entries end
		table.insert(result, {
			name = section_name,
			entries = entries
		})
	end

	local count = 1
	for line in io.lines(path) do
		if block_token then
			if ext.string_trim(line) == block_token then
				section_entries[block_key] = table.concat(block_value, "\n")
				block_token, block_key, block_value = nil
			else table.insert(block_value, line) end
		else
			local trimmed = ext.string_trim(line, "start")
			if #trimmed ~= 0 and not ext.string_starts(trimmed, "#") then
				if ext.string_starts(trimmed, "[") then
					local new_section_name = line:match("%[([^%]]+)%]")
					if new_section_name then
						if section_name then insert_section()
						elseif global_entries then insert_global() end

						section_name, section_entries = new_section_name, {}
					else parse_warn("invalid section header: '" .. line .. "'", path, count) end
				else
					local entries
					if section_name then entries = section_entries
					else
						if not global_entries then global_entries = {} end
						entries = global_entries
					end

					local key, value = trimmed:match("^([^=]+)=(.*)$")
					if key then
						key = ext.string_trim(key)
						local trim_val = ext.string_trim(value)
						local block_token_match = trim_val:match("^%[([^%[]*)%[$")
						if block_token_match then
							block_token = "]" .. block_token_match .. "]"
							block_key, block_value = key, {}
						else entries[key] = value end
					else parse_warn("invalid line: '" .. line .. "'", path, count) end
				end
			end
		end
		count = count + 1
	end
	if section_name then insert_section()
	else insert_global() end

	if def then
		return apply_def(path, result, def)
	else return result end
end

function config.load_subcfg(name, def)
	local suf = name and "-" .. name or ""
	local rel_path = string.format("script-opts/%s%s.conf", script_name, suf)
	return config.load(mpu.join_path(config.cfg_dir, rel_path), def)
end

local function reload_config()
	config.values = config.load_subcfg(nil, cfg_def).global
	config.enable_help = config.values.enable_help
	config.take_scrot = config.values.take_screenshots
end
reload_config()
bus.listen("reload_config", reload_config)

return config
