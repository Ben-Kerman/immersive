-- Immersive is licensed under the terms of the GNU GPL v3: https://www.gnu.org/licenses/; © 2021 Ben Kerman

local config = require "systems.config"
local templater = require "systems.templater"
local utf_8 = require "utility.utf_8"
local ext = require "utility.extension"

local default_template = [[{{terms[1]}}{{terms[2:] (:):, }}:<br>
{{altterms::<br>:, }}{{pronunciations::<br>:, }}{{positions::<br>:, }}
{{definition}}
{{examples:::, }}]]
return function(entry, config)
	local template = default_template
	if config["export:template"] then
		template = config["export:template"]
	end

	return templater.render(template, {
		terms = {data = entry.trms},
		altterms = entry.alts and {data = entry.alts} or false,
		definition = {data = entry.def},
		pronunciations = entry.prns and {data = entry.prns} or false,
		positions = entry.poss and {data = entry.poss} or false,
		examples = entry.exps and {data = entry.exps} or false
	})
end
