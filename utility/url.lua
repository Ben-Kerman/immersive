local ext = require "utility.extension"

local unreserved = ext.list_map({
	"A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M",
	"N", "O", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z",
	"a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m",
	"n", "o", "p", "q", "r", "s", "t", "u", "v", "w", "x", "y", "z",
	"0", "1", "2", "3", "4", "5", "6", "7", "8", "9",
	"-", "_", ".", "~"
}, function(char) return char:byte() end)

local url = {}

function url.encode(str)
	local encoded = {}
	for i = 1, #str do
		local byte = str:byte(i)
		local code
		if ext.list_find(unreserved, byte) then
			code = string.char(byte)
		else code = string.format("%%%02X", byte) end
		table.insert(encoded, code)
	end
	return table.concat(encoded)
end

return url
