if not table.pack then
	table.pack = function(...)
		return {...}
	end
end

if not table.unpack then
	table.unpack = unpack
end
