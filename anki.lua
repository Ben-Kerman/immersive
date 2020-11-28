local cfg = require "config"
local sys = require "system"
local util = require "util"

local active_target_index = 1

local function default_tgt_cfg()
	return {
		audio = {
			extension = "mka",
			format = "matroska",
			codec = "libopus",
			bitrate = "64k",
			pad_start = 0.1,
			pad_end = 0.1
		},
		image = {
			extension = "jpg",
			codec = "mjpeg",
			max_width = -1,
			max_height = -1,
			jpeg = {
				qscale = 5
			},
			webp = {
				lossless = false,
				quality = 90,
				compression = 4
			},
			png = {
				compression = 9
			}
		},
		anki = {
			tags = {"ankisubs"},
			fields = {}
		}
	}
end

local anki = {
	targets = {}
}

-- parse target definitions
for name, profile, deck, note_type
	in cfg.values.anki_targets:gmatch("%[([^:]+):([^;]+);([^;]+);([^%]]+)%]") do
	table.insert(anki.targets, {
		name = name, profile = profile, deck = deck, note_type = note_type, config = default_tgt_cfg()
	})
end

-- parse target config file
local raw_tgt_cfgs = cfg.load_subcfg("targets")
for _, raw_tgt_cfg in ipairs(raw_tgt_cfgs) do
	local tgt_cfg = util.list_find(anki.targets, function(tgt)
		return tgt.name == raw_tgt_cfg.name
	end).config

	for key, value in pairs(raw_tgt_cfg.entries) do
		if util.string_starts(key, "field:") then
			tgt_cfg.anki.fields[key:sub(7)] = value
		elseif key == "anki/tags" then
			tgt_cfg.anki.tags = util.string_split(value)
		else
			local components = util.string_split(key, "/")
			local entry = tgt_cfg
			for i, comp in ipairs(components) do
				if not entry[comp] then
					-- TODO handle error
				elseif i ~= #components then entry = entry[comp] end
			end

			local old_val = entry[components[#components]]
			local new_val = type(old_val) == "number" and tonumber(value) or value
			entry[components[#components]] = new_val
		end
	end
end

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
		return util.string_starts(file, series_id) and file:match("%." .. extension .. "$")
	end)
	local next_number
	if #existing == 0 then next_number = 0
	else
		next_number = 1 + util.list_max(util.list_map(existing, function(file)
			local _, id_end = file:find(series_id, 1, true)
			return tonumber((file:match("%-(%d+)", id_end + 1)))
		end))
	end
	return string.format("%s-%04d.%s", series_id, next_number, extension)
end

return anki
