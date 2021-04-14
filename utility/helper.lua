-- Immersive is licensed under the terms of the GNU GPL v3: https://www.gnu.org/licenses/; © 2020 Ben Kerman

local cfg = require "systems.config"
local mpu = require "mp.utils"
local msg = require "systems.message"
local player = require "systems.player"
local utf_8 = require "utility.utf_8"
local ext = require "utility.extension"

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
	return ext.map_merge({
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
		return utf_8.string(ext.list_range(cps, 1, len - 1)) .. "…"
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

local default_escape_table = {
	[0x61] = 0x07, -- \a
	[0x62] = 0x08, -- \b
	[0x65] = 0x1B, -- \e
	[0x66] = 0x0C, -- \f
	[0x6e] = 0x0A, -- \n
	[0x72] = 0x0D, -- \r
	[0x74] = 0x09, -- \t
	[0x76] = 0x0B  -- \v
}
function helper.parse_with_escape(str, escape_char, search, init, escape_table)
	if not escape_char then escape_char = "\\" end
	if not escape_table then escape_table = default_escape_table end

	local escape_byte = escape_char:byte()
	local search_bytes
	if search then
		search_bytes = table.pack(search:byte(1, #search))
	end

	local res = {}
	local found_pos
	local i = init and init or 1
	while i <= #str do
		local byte = str:byte(i)
		if search_bytes and ext.list_find(search_bytes, byte) then
			found_pos = i
			break
		elseif byte == escape_byte then
			local next_byte = str:byte(i + 1)
			if escape_byte == next_byte then
				table.insert(res, escape_byte)
			elseif escape_table[next_byte] then
				table.insert(res, escape_table[next_byte])
			else table.insert(res, next_byte) end
			i = i + 2
		else
			table.insert(res, str:byte(i))
			i = i + 1
		end
	end
	local escaped_str = string.char(table.unpack(res))
	return escaped_str, found_pos and found_pos, found_pos and string.char(str:byte(found_pos))
end

function helper.preview_audio(data)
	-- prevents circular require
	local export = require "systems.export"

	if export.verify(data, true) then
		local was_paused = mp.get_property_bool("pause")
		mp.set_property_bool("pause", true)

		local start, stop = export.resolve_times(data)
		player.play(helper.current_path_abs(), start, stop, mp.get_property_number("aid"))

		mp.add_timeout(stop - start + 0.15, function()
			mp.set_property_bool("pause", was_paused)
		end)
	end
end

local whitespace_cps = {
	0x9, 0x20, 0xa0, 0x1680, 0x2000, 0x2001, 0x2002, 0x2003, 0x2004, 0x2005,
	0x2006, 0x2007, 0x2008, 0x2009, 0x200a, 0x200b, 0x202f, 0x205f, 0x3000
}
function helper.is_space(cp)
	return not not ext.list_find(whitespace_cps, cp)
end

local linebreak_cps = {0xa, 0xb, 0xc, 0xd, 0x85, 0x2028, 0x2029}
function helper.is_break(cp)
	return not not ext.list_find(linebreak_cps, cp)
end

function helper.is_space_or_break(cp)
	return helper.is_space(cp) or helper.is_break(cp)
end

return helper
