-- Immersive is licensed under the terms of the GNU GPL v3: https://www.gnu.org/licenses/; © 2021 Ben Kerman

local helper = require "utility.helper"
local msg = require "systems.message"
local ext = require "utility.extension"

local function char(str, pos)
	return str:sub(pos, pos)
end

local msg_fmt = "template: %s; position: %d; template: %s"
local function err_msg(msg_txt, pos, str)
	local msg_str
	if pos then
		msg_str = string.format(msg_fmt, msg_txt, pos, str)
	else msg_str = "template: " .. msg_txt end
	msg.error(msg_str)
end

local function number_conv(str)
	local res = tonumber(str)
	if not res then
		err_msg("invalid number ('" .. str .. "')")
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
		return end_pos + 1
	else
		err_msg("error parsing index", init_pos, str)
		return nil
	end
end

local function parse_affixes(str, init_pos, subst)
	local affix_num = 1
	local affix_names = {"prefix", "suffix", "sep"}

	local pos = init_pos
	local affix

	local function insert()
		if affix_num > #affix_names then
			err_msg("too many affix definitions (" .. affix_num .. ")", pos, str)
		elseif #affix ~= 0 then
			subst[affix_names[affix_num]] = affix
		end
		affix_num = affix_num + 1
	end

	while true do
		local mpos, match
		affix, mpos, match = helper.parse_with_escape(str, nil, ":}", pos)
		if mpos then pos = mpos
		else break end

		if match == ":" then
			insert()
			pos = pos + 1
		elseif match == "}" then
			if char(str, pos + 1) == "}" then
				insert()
				return pos + 2
			end
		else break end
	end
	err_msg("string ended while parsing substitution", pos, str)
	return pos
end

local function parse_substitution(str, init_pos)
	local subst = {}
	local id_tbl = {}

	local pos = init_pos
	local id_parts = {}
	local affixes_left = false
	while true do
		local id_part, mpos, match = helper.parse_with_escape(str, nil, "[:}", pos)
		if #id_part ~= 0 then
			table.insert(id_parts, id_part)
		end

		if match == "[" then
			local new_pos = parse_indexing(str, mpos, subst)
			if new_pos then pos = new_pos
			else return nil, mpos end
			affixes_left = true
			break
		elseif match == ":" then
			pos = mpos + 1
			affixes_left = true
			break
		elseif match == "}" then
			if char(str, mpos + 1) == "}" then
				pos = mpos + 2
				break
			else
				table.insert(id_parts, "}")
				pos = mpos + 1
			end
		else
			err_msg("template ended while parsing substitution", pos, str)
			break
		end
	end
	subst.id = table.concat(id_parts)

	if affixes_left then
		pos = parse_affixes(str, pos, subst)
	end

	if not subst.from then
		subst.from = 1
	end
	if not subst.to then
		subst.to = -1
	end

	return subst, pos
end

local function segment_str(str)
	local segments = {}

	local pos = 1
	while pos do
		local escaped, match
		escaped, pos, match = helper.parse_with_escape(str, nil, "{", pos)
		if #escaped ~= 0 then
			table.insert(segments, escaped)
		end
		if pos and match == "{"then
			if char(str, pos + 1) == "{" then
				local subst
				subst, pos = parse_substitution(str, pos + 2)

				if subst then
					table.insert(segments, subst)
				else table.insert(segments, "|template error|") end
			else
				table.insert(segments, "{")
				pos = pos + 1
			end
		end
	end

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
		elseif seg_type == "table" then
			local value = values[segment.id]
			if value == nil then
				err_msg("substitution '" .. segment.id .. "' missing")
				table.insert(strings, "|missing substitution|")
			elseif value then
				if value.data == nil then
					msg.fatal("value.data is nil")
					return "template error"
				end

				local data_type = type(value.data)
				local is_map = data_type == "table"
				               and value.data[1] == nil
				               and next(value.data) ~= nil

				local insert_str
				if data_type ~= "table" or is_map then
					local transformed = transform_data(value.data, value.transform)
					if transformed then
						insert_str = transformed:sub(segment.from, segment.to)
					end
				elseif data_type == "table" then
					local list = value.data
					if segment.from ~= 1 or segment.to ~= -1 then
						list = ext.list_range(list, segment.from, segment.to)
					end

					if #list ~= 0 then
						if value.transform then
							list = ext.list_map(list, value.transform)
						end
						local sep = segment.sep and segment.sep or value.sep
						insert_str = table.concat(list, sep)
					end
				end

				if insert_str then
					if segment.prefix then
						table.insert(strings, segment.prefix)
					end
					table.insert(strings, insert_str)
					if segment.suffix then
						table.insert(strings, segment.suffix)
					end
				end
			else msg.verbose("empty optional var: " .. segment.id) end
		else msg.fatal("invalid segment type: " .. seg_type) end
	end
	return table.concat(strings)
end

return templater
