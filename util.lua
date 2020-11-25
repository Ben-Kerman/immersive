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
			table.insert(res, mapper(val))
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

return util
