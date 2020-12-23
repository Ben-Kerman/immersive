

local config = require "config"
local templater = require "templater"
local utf_8 = require "utf_8"
local util = require "util"

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
