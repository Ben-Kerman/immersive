local util = {}

function util.list_find(list, predicate)
	for _, val in ipairs(list) do
		if predicate(val) then return val end
	end
end

function util.list_slice(list, start, length)
	local slice = {}
	for i = start, start + length do
		table.insert(slice, list[i])
	end
	return slice
end

function util.list_max(list, cmp)
	local max = list[1]
	for i, v in ipairs(list) do
		if cmp(max, v) then max = v end
	end
	return max
end

function util.list_filter(list, predicate)
	local res = {}
	for _, val in ipairs(list) do
		if predicate(val) then
			table.insert(res, val)
		end
	end
	return res
end

function util.list_map(list, mapper)
	local res = {}
	for _, val in ipairs(list) do
		table.insert(res, mapper(val))
	end
	return res
end

function util.string_split(str, pattern, filter_empty)
	if type(str) ~= "string"
	   or type(pattern) ~= "string"
	   or #pattern == 0 then
		return nil
	end
	local res = {}
	local start = 1
	while true do
		local m_start, m_end = str:find(pattern, start)
		if m_start then
			local sub = str:sub(start, m_start - 1)
			if not filter_empty or #sub > 0 then table.insert(res, sub) end
			start = m_end + 1
		else
			local sub = str:sub(start, #str)
			if not filter_empty or #sub > 0  then table.insert(res, sub) end
			break
		end
	end
	return res
end

return util
