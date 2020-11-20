local util = {}

function util.list_find(list, predicate)
	for i, val in ipairs(list) do
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

return util
