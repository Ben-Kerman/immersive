local cfg = require "config"
local sys = require "system"

local active_target_index = 1

local anki = {
	targets = {}
}

for name, profile, deck, note_type
	in cfg.values.anki_targets:gmatch("%[([^:]+):([^;]+);([^;]+);([^%]]+)%]") do
	table.insert(anki.targets, {
		name = name, profile = profile, deck = deck, note_type = note_type
	})
end

function anki.active_target()
	return anki.targets[active_target_index]
end

function anki.media_dir()
	local profile = anki.active_target().profile
	return string.format("%s/%s/collection.media", sys.anki_base_dir, profile)
end

return anki
