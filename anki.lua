local cfg = require "config"
local sys = require "system"
local util = require "util"

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

function anki.generate_filename(series_id, extension)
	local files = sys.list_files(anki.media_dir())
	local existing = util.list_filter(files, function(file)
		return file:find(series_id, 1, true) == 1
		       and file:match("%." .. extension .. "$")
	end)
	local max_number = util.list_max(util.list_map(existing, function(file)
		local _, id_end = file:find(series_id, 1, true)
		return tonumber((file:match("%-(%d+)", id_end + 1)))
	end))
	return string.format("%s-%04d.%s", series_id, max_number + 1, extension)
end

return anki
