local cfg = require "config"
local mpu = require "mp.utils"
local sys = require "system"
local util = require "util"

local function default_tgt_cfg()
	return {
		audio = {
			extension = "mka",
			format = "matroska",
			codec = "libopus",
			bitrate = "64ki",
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

local anki = {targets = {}}

local required_opts = {"profile", "deck", "note_type"}
local function load_tgt(raw_tgt)
	local valid, missing = cfg.check_required(raw_tgt.entries, required_opts)
	if not valid then
		local fmt = "target '%s' is missing these required options: %s"
		msg.warn(string.format(fmt, raw_tgt.name, table.concat(missing, ", ")))
		return
	end

	local tgt_cfg = default_tgt_cfg()
	local tgt = {
		name = raw_tgt.name,
		profile = raw_tgt.entries.profile,
		deck = raw_tgt.entries.deck,
		note_type = raw_tgt.entries.note_type,
		config = tgt_cfg
	}

	for key, value in pairs(raw_tgt.entries) do
		if util.string_starts(key, "field:") then
			tgt_cfg.anki.fields[key:sub(7)] = value
		elseif key == "anki/tags" then
			tgt_cfg.anki.tags = util.string_split(value)
		elseif not util.list_find(required_opts, key) then
			cfg.insert_nested(tgt_cfg, util.string_split(key, "/"), value, true)
		end
	end
	table.insert(anki.targets, tgt)
end

for _, raw_tgt in ipairs(cfg.load_subcfg("targets")) do
	load_tgt(raw_tgt)
end

local active_tgt_index = 1
function anki.active_target(err_msg)
	local tgt = anki.targets[active_tgt_index]
	if not tgt then
		local err_str = "no Anki targets found"
		if err_msg then
			err_str = err_str .. ": " .. err_msg
		end
		msg.warn(err_str)
		return
	end
	return tgt
end

function anki.switch_target(dir)
	active_tgt_index = util.num_limit(active_tgt_index, 1, #anki.targets)
end

function anki.media_dir()
	local tgt = anki.active_target("could not determine media dir")
	if not tgt then return end

	local profile = tgt.profile
	local profile_dir = mpu.join_path(sys.anki_base_dir, profile)
	return mpu.join_path(profile_dir, "collection.media")
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
