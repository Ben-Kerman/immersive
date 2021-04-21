-- Immersive is licensed under the terms of the GNU GPL v3: https://www.gnu.org/licenses/; © 2021 Ben Kerman

local ext = require "utility.extension"
local msg = require "systems.message"

local config_util = {}
config_util.convert = {}

function config_util.convert.bool(str)
	if str == "yes" or str == "true" then
		return true
	elseif str == "no" or str == "false" then
		return false
	else
		return nil, "invalid boolean ('" .. str .. "'), must be 'yes', 'true', 'no' or 'false'"
	end
end

function config_util.convert.num(str, allow_decimal)
	local res = tonumber(str)
	if res then
		if not allow_decimal and math.floor(res) ~= res then
			return nil, "value must be an integer"
		else return res end
	else return nil, "not a valid number" end
end

function config_util.convert.list(str, sep_pat)
	return ext.string_split(str, sep_pat, true)
end

function config_util.check_required(cfg, opt_names)
	local valid = true
	local missing = {}
	for _, opt in ipairs(opt_names) do
		if not cfg[opt] then
			table.insert(missing, opt)
			valid = false
		end
	end
	return valid, missing
end

function config_util.force_type(val, type_name)
	if type_name == "boolean" then
		return config_util.convert_bool(val)
	elseif type_name == "number" then
		return tonumber(val)
	elseif type_name == "string" then
		return tostring(val)
	else msg.fatal("invalid type name: " .. type_name) end
end

function config_util.convert_type(old_val, new_val)
	return config_util.force_type(new_val, type(old_val))
end

function config_util.insert_nested(target, path, value, strict)
	for i, comp in ipairs(path) do
		if i == #path then break end

		if target[comp] == nil then
			if strict then
				msg.warn("invalid config path: " .. table.concat(path, "/"))
				return
			else target[comp] = {} end
		end
		if i ~= #path then
			target = target[comp]
		elseif type(target[comp]) == "table" then
			msg.warn("config path ends too soon: " .. table.concat(path, "/"))
			return
		end
	end
	target[path[#path]] = value
end

function config_util.get_nested(target, path)
	for i, comp in ipairs(path) do
		if target[comp] == nil then return nil
		else target = target[comp] end
	end
	return target
end

return config_util
