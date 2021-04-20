-- Immersive is licensed under the terms of the GNU GPL v3: https://www.gnu.org/licenses/; © 2021 Ben Kerman

local mpo = require "mp.options"
local mpu = require "mp.utils"
local msg = require "systems.message"
local ext = require "utility.extension"

local function check_file(path)
	if not path then return false end
	local stat_res = mpu.file_info(path)
	if not stat_res or not stat_res.is_file then
		return false
	end
	return true
end

local config = {
	values = {
		mpv_executable = "mpv",
		preload_dictionaries = false,
		startup_dict_overlay = true,
		max_targets = 1,
		always_show_minutes = true,
		target_select_blackout = true,
		active_sub_blackout = true,
		forvo_language = "ja",
		forvo_preload_audio = false,
		forvo_prefer_mp3 = false,
		forvo_prefix = "word_audio",
		forvo_reencode = true,
		forvo_extension = "mka",
		forvo_format = "matroska",
		forvo_codec = "libopus",
		forvo_bitrate = "64ki",
		ankiconnect_host = "localhost",
		ankiconnect_port = 8765,
		windows_copy_mode = "exact",
		enable_autocopy = false,
		global_autoselect = true,
		enable_autoselect = true,
		global_help = true,
		enable_help = false,
		take_screenshots = true,
		hide_infos_if_help_active = false
	}
}

mpo.read_options(config.values)
config.take_scrot = config.values.take_screenshots

local msg_fmt = "config: %s; %s:%d"
local function warn_msg(msg_txt, file, line)
	local msg_str
	if file then
		msg_str = string.format(msg_fmt, msg_txt, file, line)
	else msg_str = "config: " .. msg_txt end
	msg.warn(msg_str)
end

function config.load(path, global_as_base)
	if not check_file(path) then
		msg.verbose("config file could not be loaded")
		return {}
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
					else warn_msg("invalid section header ('" .. line .. "')", path, count) end
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
						local block_token_match = value:match("%[([^%[]*)%[")
						if block_token_match then
							block_token = "]" .. block_token_match .. "]"
							block_key, block_value = key, {}
						else entries[key] = value end
					else warn_msg("invalid line ('" .. line .. "')", path, count) end
				end
			end
		end
		count = count + 1
	end
	if section_name then insert_section()
	else insert_global() end

	return result
end

function config.load_subcfg(name, global_as_base)
	local rel_path = string.format("script-opts/%s-%s.conf", script_name, name)
	return config.load(mp.find_config_file(rel_path), global_as_base)
end

return config
