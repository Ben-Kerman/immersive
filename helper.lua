local mpu = require "mp.utils"
local msg = require "message"

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
		min = min ~= 0 and min or nil,
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
	else msg.info("No active subtitle line") end
end

function helper.current_path_abs()
	local working_dir = mp.get_property("working-directory")
	local rel_path = mp.get_property("path")
	if working_dir and rel_path then
		return mpu.join_path(working_dir, rel_path)
	end
end

return helper
