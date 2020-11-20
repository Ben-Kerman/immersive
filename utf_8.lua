local function is_ascii(byte)
	-- byte & 0b1000'0000 == 0
	return bit32.band(byte, 0x80) == 0
end

local function is_lead(byte)
	-- byte & 0b1100'0000 == 0b1100'0000
	return bit32.band(byte, 0xc0) == 0xC0
end

local function is_cont(byte)
	-- byte & 0b1100'0000 == 0b1000'0000
	return bit32.band(byte, 0xc0) == 0x80
end

local function char_byte_num(lead_byte)
	local mask, num = 0x80, 0
	while bit32.band(lead_byte, mask) ~= 0 do
		mask, num = bit32.rshift(mask, 1), num + 1
	end
	return num
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
		bit32.replace(bit32.rshift(cp, (byte_count - 1) * 6), 0xff, 8 - byte_count, byte_count)
	}

	-- construct continuation bytes
	for pos = byte_count - 2, 0, -1 do
		table.insert(bytes, bit32.bor(0x80, bit32.extract(cp, pos * 6, 6)))
	end

	return bytes
end

utf_8 = {}

function utf_8.codepoints(str)
	local cps, bytes = {}, table.pack(str:byte(1, #str))

	local next_cp = 0
	local iter, _, i = ipairs(bytes)
	while true do
		i, b = iter(bytes, i)
		if i == nil then break end

		-- for ASCII the byte value is the code point
		if is_ascii(b) then table.insert(cps, b)
		elseif is_lead(b) then
			local byte_num = char_byte_num(b)
			-- extract leading bits of the code point
			next_cp = bit32.extract(b, 0, 7 - byte_num)
			for k = 1, byte_num - 1 do
				i, cb = iter(bytes, i)
				-- no more bytes or cb isn't a cont. byte --> invalid UTF-8
				if i == nil or not is_cont(cb) then return nil end

				-- shift tmp number and or in bits from cb
				next_cp = bit32.bor(bit32.lshift(next_cp, 6), bit32.extract(cb, 0, 6))
			end
			table.insert(cps, next_cp)
			next_cp = 0
		else return nil end -- shouldn't happen for valid UTF-8
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
