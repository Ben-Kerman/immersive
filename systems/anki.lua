-- Immersive is licensed under the terms of the GNU GPL v3: https://www.gnu.org/licenses/; © 2021 Ben Kerman

local cfg = require "systems.config"
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

local function default_tgt(raw_tgt)
	return {
		name = raw_tgt.name,
		profile = raw_tgt.entries.profile,
		deck = raw_tgt.entries.deck,
		note_type = raw_tgt.entries.note_type,
		add_mode = "append",
		note_template = "{{type}}: {{id}}",
		media_directory = nil,
		tags = {"immersive"},
		sentence_substitutions = default_sentence_substs(),
		definition_substitutions = {},
		fields = {},
		config = {
			audio = {
				extension = "mka",
				format = "matroska",
				codec = "libopus",
				bitrate = "64ki",
				pad_start = 0.1,
				pad_end = 0.1
			},
			image = {
				extension = "webp",
				codec = "libwebp",
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
			}
		}
	}
end

local function parse_substitution(def)
	local repl, lt_pos = helper.parse_with_escape(def, nil, "<")
	if lt_pos then
		local pattern = helper.parse_with_escape(def, nil, nil, lt_pos + 1)
		if pcall(string.find, "", pattern) then
			return {pattern = pattern, repl = repl}
		end
	end
	msg.warn("ignoring invalid substitution: " .. def)
	return nil
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

	local tgt = default_tgt(raw_tgt)
	for key, value in pairs(raw_tgt.entries) do
		if ext.string_starts(key, "field:") then
			tgt.fields[key:sub(7)] = value
		elseif string.find(key, "/") then
			cfg.insert_nested(tgt.config, ext.string_split(key, "/"), value, true)
		elseif not ext.list_find(required_opts, key) then
			if key == "add_mode" then
				if ext.list_find({"prepend", "append", "overwrite"}, value) then
					tgt.add_mode = value
				else msg.warn("unkown Anki add mode ('" .. value .. "'), using 'append'") end
			elseif key == "tags" then
				tgt.tags = ext.list_unique(ext.string_split(value, " "))
			elseif key == "sentence_substitutions" or key == "definition_substitutions" then
				local defs = ext.string_split(value, "\n")
				local non_empty = ext.list_filter(defs, function(def)
					return #def ~=0
				end)
				tgt[key] = ext.list_map(non_empty, parse_substitution)
			elseif ext.list_find({"media_directory"}, key) then
				tgt[key] = value
			end
		end
	end
	table.insert(anki.targets, tgt)
end

for _, raw_tgt in ipairs(cfg.load_subcfg("targets", true)) do
	load_tgt(raw_tgt)
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
