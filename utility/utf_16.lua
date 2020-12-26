local bit_op = require("utility.bit_compat")[1]

local utf_16 = {}

function utf_16.surrogates(cdpts)
	local surrogates = {}

	for _, cp in ipairs(cdpts) do
		if cp < 0x10000 then
			table.insert(surrogates, cp)
		else
			local base = cp - 0x10000
			local low_sur = 0xdc00 + bit_op.band(base, 0x3FF)
			local high_sur = 0xd800 + bit_op.band(bit_op.rshift(base, 10), 0x3FF)
			table.insert(surrogates, high_sur)
			table.insert(surrogates, low_sur)
		end
	end
	return surrogates
end

return utf_16
