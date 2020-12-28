-- Immersive is licensed under the terms of the GNU GPL v3: https://www.gnu.org/licenses/; © 2020 Ben Kerman

local bit_conv = require("utility.bit_compat")[2]
local ext = require "utility.extension"

local char_lookup = {
	"A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N", "O", "P",
	"Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z", "a", "b", "c", "d", "e", "f",
	"g", "h", "i", "j", "k", "l", "m", "n", "o", "p", "q", "r", "s", "t", "u", "v",
	"w", "x", "y", "z", "0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "+", "/"
}

local bit_lookup = (function()
	local res = {}
	for i, digit in ipairs(char_lookup) do
		res[digit:byte()] = ext.list_reverse(bit_conv.to_bits(i - 1, 6))
	end
	return res
end)()

local function insert_digit(list, bits)
	local pos = bit_conv.to_num(ext.list_reverse(bits))
	table.insert(list, char_lookup[pos + 1])
end

local base64 = {}

function base64.encode(str)
	local bits = {}
	for i = 1, #str do
		for _, bit in ipairs(ext.list_reverse(bit_conv.to_bits(str:byte(i), 8))) do
			table.insert(bits, bit)
		end
	end

	local b64 = {}
	local rem_bits_start

	local from = 1
	while from <= #bits do
		local to = from + 5
		if to > #bits then
			rem_bits_start = from
			break
		end

		insert_digit(b64, ext.list_range(bits, from, to))
		from = from + 6
	end
	if rem_bits_start then
		local rem_bits = ext.list_range(bits, rem_bits_start)
		for i = 1, 6 - #rem_bits do
			table.insert(rem_bits, false)
		end
		insert_digit(b64, rem_bits)
	end

	local pad_len = 4 - (#b64 % 4)
	if pad_len ~= 4 then
		for i = 1, pad_len do
			table.insert(b64, "=")
		end
	end
	return table.concat(b64)
end

function base64.decode(b64)
	local pad_start = b64:find("=")
	local bits = {}
	for i = 1, pad_start and pad_start - 1 or #b64 do
		for _, bit in ipairs(bit_lookup[b64:byte(i)]) do
			table.insert(bits, bit)
		end
	end

	local str = {}

	local from = 1
	while from <= #bits do
		local to = from + 7
		if to > #bits then break end

		local byte = bit_conv.to_num(ext.list_reverse(ext.list_range(bits, from, to)))
		table.insert(str, string.char(byte))

		from = from + 8
	end
	return table.concat(str)
end

return base64
