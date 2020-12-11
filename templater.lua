local util = require "util"

local function parse_substitution(subs_str)
	local ident = subs_str:match("^([^%[]+)")
	local index = subs_str:match("%[(%d+)%]$")
	local from, to, sep = subs_str:match("%[(%d*):(%d*)%]:?(.*)$")

	if sep == "" then sep = nil end

	if index then
		local index_num = tonumber(index)
		return ident, index_num, index_num
	end

	if from then
		if from == "" then from = 1
		else from = tonumber(from) end
		if to == "" then to = -1
		else to = tonumber(to) end
	end

	return {
		ident = ident,
		from = from and from or 1,
		to = to and to or -1, sep
	}
end

local function segment_str(str)
	local segments = {}

	local next_from = 1
	while true do
		local from, to, val = str:find("%{%{([^%}]+)%}%}", next_from)
		if not from then break end

		if from > next_from then
			table.insert(segments, str:sub(next_from, from - 1))
		end
		table.insert(segments, parse_substitution(val))

		next_from = to + 1
		if next_from >= #str then break end
	end

	if next_from <= #str then
		table.insert(segments, str:sub(next_from))
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
		else
			local value = values[segment.ident]
			if not value then return nil end --TODO error msg

			local data_type = type(value.data)
			local is_map = data_type == "table"
			               and value.data[1] == nil
			               and next(value.data) ~= nil
			if data_type ~= "table" or is_map then
				table.insert(strings, transform_data(value.data, value.transform))
			elseif data_type == "table" then
				local list = value.data
				if segment.from then
					list = util.list_range(list, segment.from, segment.to)
				end

				if value.transform then
					list = util.list_map(list, value.transform)
				end

				local sep = segment.sep and segment.sep or value.sep
				table.insert(strings, table.concat(list, sep))
			end
		end
	end
	return table.concat(strings)
end

return templater
