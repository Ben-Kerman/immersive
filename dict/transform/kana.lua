local utf_8 = require "utility.utf_8"

local base_hira = 0x3040
local base_kata = 0x30a0

local function conv_cp(f, t, cp)
	local is_kana = cp > f and f + 0x57 > cp
	local is_itmrk = cp == f + 0x5d or cp == f + 0x5e
	if is_kana or is_itmrk then
		return cp + t - f
	else return cp end
end

return function(word)
	local cdpts = utf_8.codepoints(word)

	local hira, kata = {}, {}
	for _, cp in ipairs(cdpts) do
		table.insert(hira, conv_cp(base_kata, base_hira, cp))
		table.insert(kata, conv_cp(base_hira, base_kata, cp))
	end

	return {utf_8.string(hira), utf_8.string(kata)}
end
