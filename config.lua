local mpo = require "mp.options"
local mpu = require "mp.utils"
local smsg = require "startup_msg"
local util = require "util"

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
		anki_targets = "",
		quick_def_template = "{{readings:::・}}{{variants:【:】:・}}: {{definitions:::; }}",
		forvo_language = "ja",
		forvo_preload_audio = false,
		forvo_prefer_mp3 = false,
		forvo_prefix = "word_audio",
		forvo_reencode = true,
		forvo_extension = "mka",
		forvo_format = "matroska",
		forvo_codec = "libopus",
		forvo_bitrate = "64ki"
	}
}

mpo.read_options(config.values)

local msg_fmt = "config: %s; %s:%d"
local function warn_msg(msg_txt, file, line)
	local msg_str
	if file then
		msg_str = string.format(msg_fmt, msg_txt, file, line)
	else msg_str = "config: " .. msg_txt end
	smsg.warn(msg_str)
end

function config.load(path)
	if not check_file(path) then
		smsg.verbose("config file could not be loaded")
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
		table.insert(result, {
			name = section_name,
			entries = section_entries
		})
	end

	local count = 1
	for line in io.lines(path) do
		if block_token then
			if util.string_trim(line) == block_token then
				section_entries[block_key] = table.concat(block_value, "\n")
				block_token, block_key, block_value = nil
			else table.insert(block_value, line) end
		else
			local trimmed = util.string_trim(line, "start")
			if #trimmed ~= 0 and not util.string_starts(trimmed, "#") then
				if util.string_starts(trimmed, "[") then
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

function config.load_subcfg(name)
	local rel_path = string.format("script-opts/%s-%s.conf", mp.get_script_name(), name)
	return config.load(mp.find_config_file(rel_path))
end

function config.convert_bool(str)
	if str == "yes" or str == "true" then
		return true
	elseif str == "no" or str == "false" then
		return false
	else smsg.warn("invalid boolean ('" .. str .. "'), must be 'yes', 'true', 'no' or 'false'") end
end

function config.force_type(val, type_name)
	if type_name == "boolean" then
		return config.convert_bool(val)
	elseif type_name == "number" then
		return tonumber(val)
	elseif type_name == "string" then
		return tostring(val)
	else smsg.fatal("invalid type name: " .. type_name) end
end

function config.convert_type(old_val, new_val)
	return config.force_type(new_val, type(old_val))
end

function config.insert_nested(target, path, value, strict)
	for i, comp in ipairs(path) do
		if target[comp] == nil then
			if strict then
				-- TODO handle error
			else target[comp] = {} end
		elseif type(target[comp]) ~= "table" then
			-- TODO handle error
		end
		if i ~= #path then target = target[comp] end
	end
	target[path[#path]] = config.convert_type(target[path[#path]], value)
end

function config.get_nested(target, path)
	for i, comp in ipairs(path) do
		if target[comp] == nil then return nil
		else target = target[comp] end
	end
	return target
end

return config
