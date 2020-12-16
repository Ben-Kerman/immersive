local mputil = require "mp.utils"
local util = require "util"

local config = {
	values = {
		anki_targets=""
	}
}

local mp_opts = require "mp.options"
mp_opts.read_options(config.values)

function config.load_basic(path)
	local result = {}

	for line in io.lines(path) do
		local trimmed = util.string_trim(line, "start")
		if #trimmed ~= 0 and not util.string_starts(trimmed, "#") then
			local key, value = trimmed:match("^([^=]+)=(.*)$")
			if key then result[key] = value
			else
				-- TODO handle error
			end
		end
	end
	return result
end

function config.load(path)
	local stat_res = mputil.file_info(path)
	if not stat_res or not stat_res.is_file then
		-- TODO handle error
	end

	local result = {}
	local section_name, section_entries
	local block_token, block_key, block_value

	local function insert_section()
		table.insert(result, {
			name = section_name,
			entries = section_entries
		})
	end

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
					if not new_section_name then
						-- TODO handle error
					else
						if section_name then insert_section() end
						section_name, section_entries = new_section_name, {}
					end
				elseif section_name then
					local key, value = trimmed:match("^([^=]+)=(.*)$")
					if key then
						local block_token_match = value:match("%[([^%[]*)%[")
						if block_token_match then
							block_token = "]" .. block_token_match .. "]"
							block_key, block_value = key, {}
						else section_entries[key] = value end
					else
						-- TODO handle error
					end
				else
					-- TODO handle error
				end
			end
		end
	end
	if section_name then insert_section() end
	return result
end

function config.load_subcfg(name, basic)
	local rel_path = string.format("script-opts/%s-%s.conf", mp.get_script_name(), name)
	local loader = basic and config.load_basic or config.load
	return loader(mp.find_config_file(rel_path))
end

function config.convert_bool(str)
	if str == "yes" or str == "true" then
		return true
	elseif str == "no" or str == "false" then
		return false
	else return nil end
end

function config.convert_type(old_val, new_val)
	local old_type = type(old_val)
	if old_type == "number" then
		return tonumber(new_val)
	elseif old_type == "boolean" then
		return config.convert_bool(new_val)
	else return new_val end
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
