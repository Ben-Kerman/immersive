local msg = require "message"
local util = require "util"

local function char(str, pos)
	return str:sub(pos, pos)
end

local msg_fmt = "template error: %s; position: %d; template: %s"
local function err_msg(msg_txt, pos, str)
	local msg_str
	if pos then
		msg_str = string.format(msg_fmt, msg_txt, pos, str)
	else msg_str = "template error: " .. msg_txt end
	msg.error(msg_str)
end

local function number_conv(str)
	local res = tonumber(str)
	if not res then
		err_msg("invalid number ('" .. str .. "'')")
	end
	return res
end

local function parse_indexing(str, init_pos, subst)
	local _, end_pos, index_str = str:find("^%[([^%]%}]*)%]", init_pos)
	if index_str then
		local from_str, to_str = index_str:match("^([^:]*):([^%]]*)$")
		if from_str then
			if from_str then
				if from_str == "" then subst.from = 1
				else subst.from = number_conv(from_str) end

				if to_str == "" then subst.to = -1
				else subst.to = number_conv(to_str) end
			end
		else
			local index = number_conv(index_str)
			subst.from = index
			subst.to = index
		end
		return end_pos
	else
		err_msg("error parsing index", init_pos, str)
		return nil
	end
end

local function parse_affixes(str, init_pos, subst)
	local affix_num = 1
	local affix_names = {"prefix", "suffix", "sep"}

	local affix_tbl = {}
	local function insert()
		subst[affix_names[affix_num]] = table.concat(affix_tbl)
		affix_tbl = {}
		affix_num = affix_num + 1
	end

	local pos = init_pos
	while pos <= #str do
		if char(str, pos) == ":" then
			insert()
		elseif char(str, pos) == "}" and char(str, pos + 1) == "}" then
			insert()
			return true, pos
		else
			if char(str, pos) == "\\" then pos = pos + 1 end
			table.insert(affix_tbl, char(str, pos))
		end
		pos = pos + 1
	end
	return false, pos
end

local function parse_substitution(str, init_pos)
	local subst = {}
	local id_tbl = {}

	local affix_mode, end_reached = false, false
	local pos = init_pos
	while pos <= #str and not (affix_mode or end_reached) do
		if char(str, pos) == "[" then
			local new_pos = parse_indexing(str, pos, subst)
			if new_pos then pos = new_pos
			else return nil, pos end
			affix_mode = true
		elseif char(str, pos) == ":" then
			affix_mode = true
		elseif char(str, pos) == "}" and char(str, pos + 1) == "}" then
			end_reached = true
		else
			if char(str, pos) == "\\" then pos = pos + 1 end
			table.insert(id_tbl, char(str, pos))
		end
		pos = pos + 1
	end
	subst.id = table.concat(id_tbl)

	if not end_reached and affix_mode then
		end_reached, pos = parse_affixes(str, pos, subst)
	end

	if not end_reached then
		err_msg("unexpected characters", pos, str)
		return nil, pos
	end
	return subst, pos + 1
end

local function segment_str(str)
	local segments = {}
	local current_segment = {}
	local function insert_segment()
		if #current_segment ~= 0 then
			table.insert(segments, table.concat(current_segment))
			current_segment = {}
		end
	end

	local pos = 1
	while pos <= #str do
		if char(str, pos) == "{" and char(str, pos + 1) == "{" then
			insert_segment()
			local subst, err
			subst, pos = parse_substitution(str, pos + 2)

			if subst then table.insert(segments, subst)
			else
				table.insert(segments, "|template error|")
			end
		else
			if char(str, pos) == "\\" then pos = pos + 1 end
			table.insert(current_segment, char(str, pos))
		end
		pos = pos + 1
	end
	insert_segment()

	return segments
end

local function transform_data(data, transform)
	return transform and transform(data) or data
end

local templater = {}

function templater.render(template, values)
	local segments = segment_str(template)

	local strings = {}
	for _, segment in ipairs(segments) do
		local seg_type = type(segment)
		if seg_type == "string" then
			table.insert(strings, segment)
		else
			local value = values[segment.id]
			if not value then
				err_msg("substitution '" .. segment.id .. "' missing")
				return nil
			end

			local data_type = type(value.data)
			local is_map = data_type == "table"
			               and value.data[1] == nil
			               and next(value.data) ~= nil

			if data_type ~= "table" or is_map then
				table.insert(strings, transform_data(value.data, value.transform))
			elseif data_type == "table" then
				local include = true

				local list = value.data
				if segment.from then
					list = util.list_range(list, segment.from, segment.to)
				end

				if #list == 0 then
					include = false
				elseif value.transform then
					list = util.list_map(list, value.transform)
				end

				if include then
					if segment.prefix then
						table.insert(strings, segment.prefix)
					end

					local sep = segment.sep and segment.sep or value.sep
					table.insert(strings, table.concat(list, sep))

					if segment.suffix then
						table.insert(strings, segment.suffix)
					end
				end
			end
		end
	end
	return table.concat(strings)
end

return templater
