local bit_op = require("bit_compat")[1]

local function is_ascii(byte)
	-- byte & 0b1000'0000 == 0
	return bit_op.band(byte, 0x80) == 0
end

local function is_lead(byte)
	-- byte & 0b1100'0000 == 0b1100'0000
	return bit_op.band(byte, 0xc0) == 0xC0
end

local function is_cont(byte)
	-- byte & 0b1100'0000 == 0b1000'0000
	return bit_op.band(byte, 0xc0) == 0x80
end

local function char_byte_count(lead_byte)
	local mask, num = 0x80, 0
	while bit_op.band(lead_byte, mask) ~= 0 do
		mask, num = bit_op.rshift(mask, 1), num + 1
	end
	return num
end

local function decode(str, pos, byte_count, lead_byte)
	if not lead_byte then lead_byte = str:byte(pos) end
	if not byte_count then byte_count = char_byte_count(lead_byte) end
	-- extract leading bits of the code point
	local cp = bit_op.extract(lead_byte, 0, 7 - byte_count)
	for i = pos + 1, pos + byte_count - 1 do
		local byte = str:byte(i)
		-- no more bytes or byte isn't a cont. byte --> invalid UTF-8
		if byte == nil or not is_cont(byte) then return nil end

		-- shift tmp number and or in bits from byte
		cp = bit_op.bor(bit_op.lshift(cp, 6), bit_op.extract(byte, 0, 6))
	end

	return cp, byte_count
end

local function encode(cp)
	-- determine how many bytes it takes to encode cp
	-- if cp is ASCII or too large for UTF-8 return immediately
	local byte_count
	if cp < 0x80 then return {cp}
	elseif cp < 0x800 then byte_count = 2
	elseif cp < 0x10000 then byte_count = 3
	elseif cp < 0x110000 then byte_count = 4
	else return nil end -- code point can't be encoded as UTF-8

	-- construct leading byte
	local bytes = {
		bit_op.replace(bit_op.rshift(cp, (byte_count - 1) * 6), 0xff, 8 - byte_count, byte_count)
	}

	-- construct continuation bytes
	for pos = byte_count - 2, 0, -1 do
		table.insert(bytes, bit_op.bor(0x80, bit_op.extract(cp, pos * 6, 6)))
	end

	return bytes
end

local utf_8 = {}

function utf_8.codepoints(str, from, to)
	if not from then from = 1 end
	if not to then to = #str end

	local cps = {}

	local byte_pos, char_pos = 1, 1
	while true do
		local byte = str:byte(byte_pos)
		if byte == nil then break end

		if is_ascii(byte) then
			-- for ASCII the byte value is the code point
			table.insert(cps, byte)
			byte_pos = byte_pos + 1
		elseif is_lead(byte) then
			local byte_count = char_byte_count(byte)
			local cp, width = decode(str, byte_pos, byte_count, byte)
			if char_pos >= from then table.insert(cps, cp) end
			byte_pos = byte_pos + width
		else return nil end -- shouldn't happen for valid UTF-8
		char_pos = char_pos + 1
		if char_pos > to then break end
	end
	return cps
end

function utf_8.string(cps)
	local bytes = {}
	for _, cp in ipairs(cps) do
		for _, b in ipairs(encode(cp)) do
			table.insert(bytes, b)
		end
	end
	return string.char(table.unpack(bytes))
end

return utf_8
