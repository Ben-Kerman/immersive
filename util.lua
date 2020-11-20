function list_find(list, predicate)
	for i, val in ipairs(list) do
		if predicate(val) then return val end
	end
end