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
		altterms = {data = entry.alts},
		definition = {data = entry.def},
		pronunciations = {data = entry.pronunciations},
		positions = {data = poss},
		examples = {data = exps}
	})
end
