local util = require "util"

local function convert_to_bits(num)
	num = math.floor(num)
	local bits = {}
	while num > 0 and #bits < 32 do
		table.insert(bits, num % 2 == 1)
		num = math.floor(num / 2)
	end
	for i = #bits + 1, 32 do
		table.insert(bits, false)
	end
	return bits
end

local function convert_to_num(bits)
	if #bits == 0 then return 0 end
	if #bits == 1 then return bits[1] and 1 or 0 end
	local num = 0
	for i = #bits, 2, -1 do
		num = (num + (bits[i] and 1 or 0)) * 2
	end
	num = num + (bits[1] and 1 or 0)
	return num
end

local function bitwise_combine(op, init, nums)
	local numbers = util.list_map(nums, convert_to_bits)
	local res = {}
	for bit_pos = 1, 32 do
		local bit_res = init
		for _, num in ipairs(numbers) do
			bit_res = op(bit_res, num[bit_pos])
		end
		table.insert(res, bit_res)
	end
	return convert_to_num(res)
end

local bit_compat = {}

function bit_compat.band(...)
	return bitwise_combine(function(a, b) return a and b end, true, {...})
end

function bit_compat.bor(...)
	return bitwise_combine(function(a, b) return a or b end, false, {...})
end

function bit_compat.lshift(x, disp)
	local res = convert_to_bits(x)
	for i = 1, disp do
		table.remove(res)
		table.insert(res, 1, false)
	end
	return convert_to_num(res)
end

function bit_compat.rshift(x, disp)
	local res = convert_to_bits(x)
	for i = 1, disp do
		table.remove(res, 1)
		table.insert(res, false)
	end
	return convert_to_num(res)
end

function bit_compat.extract(n, field, width)
	if width == nil then width = 1 end
	local bits, res = convert_to_bits(n), {}
	for i = 1, width do
		res[i] = bits[field + i]
	end
	return convert_to_num(res)
end

function bit_compat.replace(n, v, field, width)
	if width == nil then width = 1 end
	local res, v_bits = convert_to_bits(n), convert_to_bits(v)
	for i = 1, width do
		res[field + i] = v_bits[i]
	end
	return convert_to_num(res)
end

return bit32 and bit32 or bit_compat
