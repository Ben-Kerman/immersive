-- Immersive is licensed under the terms of the GNU GPL v3: https://www.gnu.org/licenses/; © 2021 Ben Kerman

local cfg = require "systems.config"
local cfg_util = require "systems.config_util"
local helper = require "utility.helper"
local mpu = require "mp.utils"
local msg = require "systems.message"
local sys = require "systems.system"
local ext = require "utility.extension"

local function default_sentence_substs()
	return {
		{
			pattern = "（.-）",
			repl = ""
		},
		{
			pattern = "%(.-%)",
			repl = ""
		}
	}
end

local function parse_substitutions(cfg_value)
	local defs = ext.string_split(cfg_value, "\n", true)
	return ext.list_map(defs, function(def)
		local repl, lt_pos = helper.parse_with_escape(def, nil, "<")
		if lt_pos then
			local pattern = helper.parse_with_escape(def, nil, nil, lt_pos + 1)
			-- pcall to verify that the pattern is valid
			if pcall(string.find, "", pattern) then
				return {pattern = pattern, repl = repl}
			end
		end
		return nil, "invalid substitution: " .. def
	end)
end

local conv = cfg_util.convert
local cfg_def = {
	sections = true,
	global_as_default = true,
	section_entries = {
		dynamic_fn = function(key)
			return ext.string_starts(key, "field:")
		end,
		items = {
			profile = {
				required = true
			},
			deck = {
				required = true
			},
			note_type = {
				required = true
			},
			add_mode = {
				validate = {
					allowed = {"append", "prepend", "overwrite"}
				},
				default = "append"
			},
			note_template = {
				default = "{{type}}: {{id}}"
			},
			media_directory = {},
			tags = {
				convert = {
					fn = conv.list,
					params = {"%s+"}
				},
				default = {"immersive"}
			},
			sentence_substitutions = {
				convert = parse_substitutions,
				default = default_sentence_substs()
			},
			definition_substitutions = {
				convert = parse_substitutions,
				default = {}
			},
			["audio/extension"] = {
				default = "mka"
			},
			["audio/format"] = {
				default = "matroska"
			},
			["audio/codec"] = {
				default = "libopus"
			},
			["audio/bitrate"] = {
				default = "48ki"
			},
			["audio/pad_start"] = {
				convert = {
					fn = conv.num,
					params = {true}
				},
				default = 0.1
			},
			["audio/pad_end"] = {
				convert = {
					fn = conv.num,
					params = {true}
				},
				default = 0.1
			},
			["image/extension"] = {
				default = "webp"
			},
			["image/codec"] = {
				default = "libwebp"
			},
			["image/max_width"] = {
				convert = conv.num,
				default = -1
			},
			["image/max_height"] = {
				convert = conv.num,
				default = -1
			},
			["image/jpeg/qscale"] = {
				convert = conv.num,
				validate = {
					bounds = {min = 1, max = 69}
				},
				default = 5
			},
			["image/webp/lossless"] = {
				convert = conv.bool,
				default = false
			},
			["image/webp/quality"] = {
				convert = conv.num,
				validate = {
					bounds = {min = 0, max = 100}
				},
				default = 90
			},
			["image/webp/compression"] = {
				convert = conv.num,
				validate = {
					bounds = {min = 0, max = 6}
				},
				default = 4
			},
			["image/png/compression"] = {
				convert = conv.num,
				validate = {
					bounds = {min = 0, max = 9}
				},
				default = 9
			}
		}
	}
}

local anki = {targets = {}}

local function load_tgt(section)
	local tgt = {
		name = section.name,
		profile = section.entries.profile,
		deck = section.entries.deck,
		note_type = section.entries.note_type,
		fields = {},
		config = {}
	}

	for key, value in pairs(section.entries) do
		if ext.string_starts(key, "field:") then
			tgt.fields[key:sub(7)] = value
		elseif string.find(key, "/") then
			cfg_util.insert_nested(tgt.config, ext.string_split(key, "/"), value)
		else
			tgt[key] = value
		end
	end
	return tgt
end

for _, raw_tgt in ipairs(cfg.load_subcfg("targets", cfg_def)) do
	table.insert(anki.targets, load_tgt(raw_tgt))
end

local active_tgt_index = 1
function anki.active_target(err_msg)
	local tgt = anki.targets[active_tgt_index]
	if not tgt and err_msg ~= false then
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
	active_tgt_index = ext.num_limit(active_tgt_index + dir, 1, #anki.targets)
end

function anki.media_dir()
	local tgt = anki.active_target("could not determine media dir")
	if not tgt then return nil end

	local media_dir
	if tgt.media_directory then
		media_dir = tgt.media_directory
	else
		local profile = tgt.profile
		local profile_dir = mpu.join_path(sys.anki_base_dir, profile)
		media_dir = mpu.join_path(profile_dir, "collection.media")
	end

	if media_dir then
		local stat_res = mpu.file_info(media_dir)
		if stat_res and stat_res.is_dir then
			return media_dir
		end
	end
	msg.error("media dir doesn't exist or is not a directory")
	return nil
end

function anki.generate_filename(series_id, extension)
	local media_dir = anki.media_dir()
	if not media_dir then return nil end

	local files = sys.list_files(media_dir)
	local existing = ext.list_filter(files, function(file)
		return ext.string_starts(file, series_id) and file:match("%-%d+%." .. extension .. "$")
	end)
	local next_number
	if #existing == 0 then next_number = 0
	else
		next_number = 1 + ext.list_max(ext.list_map(existing, function(file)
			local _, id_end = file:find(series_id, 1, true)
			return tonumber((file:match("%-(%d+)%..+$", id_end + 1)))
		end))
	end
	return string.format("%s-%04d.%s", series_id, next_number, extension)
end

function anki.add_candidates()
	local ankicon = require "systems.ankiconnect"

	local tgt = anki.active_target("could not get notes to add to")
	if not tgt then return nil end

	if not ankicon.prepare_target(tgt) then return nil end

	local query = string.format([["deck:%s" "note:%s" is:new]], tgt.deck, tgt.note_type)
	local card_ids = ankicon.find_cards(query)
	if not card_ids then return nil end
	local cards = ankicon.cards_info(card_ids)
	if not cards then return nil end

	table.sort(cards, function(card_a, card_b)
		return card_a.due > card_b.due
	end)

	local note_ids = ext.list_unique(ext.list_map(cards, function(card)
		return card.note
	end))
	local notes = ankicon.notes_info(note_ids)
	if not notes then return nil end

	return notes
end

function anki.sentence_substitutions()
	local tgt = anki.active_target()
	if tgt then return tgt.sentence_substitutions
	else return default_sentence_substs() end
end

return anki
