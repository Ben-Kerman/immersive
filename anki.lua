local cfg = require "config"
local sys = require "system"

local active_target_index = 1

local anki = {
	targets = {},
	target_configs = {}
}

-- parse target definitions
for name, profile, deck, note_type
	in cfg.values.anki_targets:gmatch("%[([^:]+):([^;]+);([^;]+);([^%]]+)%]") do
	table.insert(anki.targets, {
		name = name, profile = profile, deck = deck, note_type = note_type
	})
end

-- parse target config file
local tgt_cfg_path = mp.find_config_file("script-opts/" .. mp.get_script_name() .. "-targets.conf")
local tgt_cfg_file = io.open(tgt_cfg_path)
local iter, lines, line = tgt_cfg_file:lines()
while true do
	line = iter(lines, line)
	if line == nil then break end

	local target = line:match("%[([^%]]+)%]")
	if target then
		anki.target_configs[target] = {}
		repeat
			line = iter(lines, line)
			if not line then break end
			local field, content = line:match("([^=]+)=(.+)")
			if field then
				anki.target_configs[target][field] = content
			end
		until line == ""
	end
end
tgt_cfg_file:close()

function anki.active_target()
	return anki.targets[active_target_index]
end

function anki.media_dir()
	local profile = anki.active_target().profile
	return string.format("%s/%s/collection.media", sys.anki_base_dir, profile)
end

return anki
