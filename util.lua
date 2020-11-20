function list_find(list, predicate)
	for i, val in ipairs(list) do
		if predicate(val) then return val end
	end
end

function list_slice(list, start, length)
	local slice = {}
	for i = start, start + length do
		table.insert(slice, list[i])
	end
	return slice
end
