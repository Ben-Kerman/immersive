local cfg = require "config"
local mpu = require "mp.utils"
local msg = require "message"
local utf_8 = require "utf_8"
local util = require "util"

local helper = {}

function helper.format_time(time, hide_ms)
	local function int_div(a, b)
		local a_int = math.floor(a)
		local b_int = math.floor(b)
		return math.floor(a_int / b_int), math.floor(a_int % b_int)
	end

	local all_min, s = int_div(time, 60)
	local all_h, min = int_div(all_min, 60)
	local days, h = int_div(all_h, 24)

	local units = {"days", "h", "min"}
	local values = {
		min = (min ~= 0 or cfg.values.always_show_minutes) and min or nil,
		h = h ~= 0 and h or nil,
		days = days ~= 0 and days or nil
	}
	local formats = {
		min = "%02d:",
		h = "%02d:",
		days = "%d:"
	}

	local largest_found = false
	for _, unit in ipairs(units) do
		if values[unit] then largest_found = true
		elseif largest_found then values[unit] = 0 end
	end
	local parts = {}
	for _, unit in ipairs(units) do
		if values[unit] then
			table.insert(parts, string.format(formats[unit], values[unit]))
		end
	end
	table.insert(parts, string.format("%02d", s))
	if not hide_ms then
		table.insert(parts, string.format(".%03d", time * 1000 % 1000))
	end
	return table.concat(parts)
end

function helper.check_active_sub()
	local sub_text = mp.get_property("sub-text")
	if sub_text and sub_text ~= "" then
		return sub_text
	else msg.info("no active subtitle line") end
end

function helper.current_path_abs()
	local working_dir = mp.get_property("working-directory")
	local rel_path = mp.get_property("path")
	if working_dir and rel_path then
		return mpu.join_path(working_dir, rel_path)
	end
end

function helper.default_times(times)
	return util.map_merge({
		scrot = -1,
		start = -1,
		stop = -1
	}, times)
end

function helper.short_str(str, len, lf_sub)
	if lf_sub then
		str = str:gsub("\n", lf_sub)
	end
	local cps = utf_8.codepoints(str)

	if #cps > len then
		return utf_8.string(util.list_range(cps, 1, len - 1)) .. "…"
	else return str end
end

function helper.parse_json_file(path)
	local file = io.open(path)
	local data = file:read("*a")
	file:close()
	return mpu.parse_json(data)
end

function helper.write_json_file(path, data)
	local file = io.open(path, "w")
	file:write((mpu.format_json(data)))
	file:close()
end

function helper.display_bool(val)
	if val then return "enabled"
	else return "disabled" end
end

return helper
