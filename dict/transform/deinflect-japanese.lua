-- Immersive is licensed under the terms of the GNU GPL v3: https://www.gnu.org/licenses/; © 2021 Ben Kerman

local ext = require "utility.extension"
local utf_8 = require "utility.utf_8"

local special_cases = {
	-- する
	["為"] = "する",
	["さ"] = "する",
	["し"] = "する",
	["せ"] = "する",
	["為よ"] = "する",
	["せよ"] = "する",
	["為ろ"] = "する",
	["しろ"] = "する",
	-- 来る
	["来"] = "来る",
	["來"] = "来る",
	["こ"] = "来る",
	["き"] = "来る",
	["来い"] = "来る",
	["來い"] = "来る",
	-- 行く
	["いっ"] = "行く",
	["行っ"] = "行く",
	["逝っ"] = "逝く",
	["往っ"] = "往く",
	-- イ音便
	["いらっしゃい"] = "いらっしゃる",
	["おっしゃい"] = "おっしゃる",
	["仰っしゃい"] = "おっしゃる",
	["仰しゃい"] = "おっしゃる",
	["仰い"] = "おっしゃる",
	["仰有い"] = "おっしゃる",
	["ください"] = "くださる",
	["下ださい"] = "くださる",
	["下さい"] = "くださる",
	["ござい"] = "ござる",
	["御座い"] = "ござる",
	["ご座い"] = "ござる",
	["なさい"] = "なさる",
	["為さい"] = "為さる"
}
local special_suru = {
	[{"さ", "し", "す", "せ", "そ", "すれ", "そ", "しろ", "しよ", "せよ"}] = "する",
	[{"じ", "ぜ", "ずれ", "じろ", "じよ", "ぜよ"}] = "ずる"
}

local ichidan = {
	"い", "き", "ぎ", "し", "じ", "ち", "ぢ", "に", "ひ", "び", "ぴ", "み", "り",
	"え", "け", "げ", "せ", "ぜ", "て", "で", "ね", "へ", "べ", "ぺ", "め", "れ"
}

local basic_godan = {
	-- 未然形
	["わ"] = "う",
	["か"] = "く",
	["が"] = "ぐ",
	["さ"] = "す",
	["た"] = "つ",
	["な"] = "ぬ",
	["ば"] = "ぶ",
	["ま"] = "む",
	["ら"] = "る",
	-- 未然形（音便）
	["お"] = "う",
	["こ"] = "く",
	["ご"] = "ぐ",
	["そ"] = "す",
	["と"] = "つ",
	["の"] = "ぬ",
	["ぼ"] = "ぶ",
	["も"] = "む",
	["ろ"] = "る",
	-- 連用形
	["い"] = "う",
	["き"] = "く",
	["ぎ"] = "ぐ",
	["し"] = "す",
	["ち"] = "つ",
	["に"] = "ぬ",
	["び"] = "ぶ",
	["み"] = "む",
	["り"] = "る",
	-- 仮定形・命令形
	["え"] = "う",
	["け"] = "く",
	["げ"] = "ぐ",
	["せ"] = "す",
	["て"] = "つ",
	["ね"] = "ぬ",
	["べ"] = "ぶ",
	["め"] = "む",
	["れ"] = "る"
}

local onbin_godan = {
	["い"] = {"く", "ぐ"},
	["っ"] = {"う", "つ", "る"},
	["ん"] = {"ぬ", "ぶ", "む"}
}

local keiyoushi = {
	"かっ", "かれ", "かろ", "く", "けれ", "き", "さ", "そう"
}

local function is_hiragana(cp)
	return 0x3041 <= cp and cp <= 0x3096
end

local function deinflect(tgt, word, infl, base)
	local function insert(sub_end, suf)
		table.insert(tgt, word:sub(1, sub_end) .. suf)
	end

	local first_pos, last_pos = word:find(infl .. "$")
	if first_pos and first_pos > 1 then
		local sub_end = first_pos - 1
		if type(base) == "table" then
			for _, suf in ipairs(base) do
				insert(sub_end, suf)
			end
		else insert(sub_end, base) end
	end
end

return function()
	return function(word)
		local base_forms = {}

		local cdpts = utf_8.codepoints(word)
		if not is_hiragana(cdpts[#cdpts]) then
			table.insert(base_forms, word .. "る")
		end
		for _, stem in ipairs(ichidan) do
			if word:find(stem .. "$") then
				table.insert(base_forms, word .. "る")
			end
		end

		for infl, base in pairs(basic_godan) do
			deinflect(base_forms, word, infl, base)
		end
		for infl, bases in pairs(onbin_godan) do
			deinflect(base_forms, word, infl, bases)
		end

		for _, infl in ipairs(keiyoushi) do
			deinflect(base_forms, word, infl, "い")
		end

		for infl, base in pairs(special_cases) do
			if word == infl then
				table.insert(base_forms, base)
			end
		end
		for infls, base in pairs(special_suru) do
			for _, infl in ipairs(infls) do
				deinflect(base_forms, word, infl, base)
			end
		end

		return base_forms
	end
end
