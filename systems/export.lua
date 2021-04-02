-- Immersive is licensed under the terms of the GNU GPL v3: https://www.gnu.org/licenses/; © 2020 Ben Kerman

local anki = require "systems.anki"
local ankicon = require "systems.ankiconnect"
local BasicOverlay = require "interface.basic_overlay"
local bus = require "systems.bus"
local cfg = require "systems.config"
local encoder = require "systems.encoder"
local ext = require "utility.extension"
local helper = require "utility.helper"
local menu_stack = require "interface.menu_stack"
local mpu = require "mp.utils"
local msg = require "systems.message"
local series_id = require "utility.series_id"
local series_id = require "utility.series_id"
local sys = require "systems.system"
local templater = require "systems.templater"

local function anki_sound_tag(filename)
	return string.format("[sound:%s]", filename)
end

local function anki_image_tag(filename)
	return string.format([[<img src="%s">]], filename)
end

local function apply_substitutions(str, substs)
	local res = str
	for _, subst in ipairs(substs) do
		res = res:gsub(subst.pattern, subst.repl)
	end
	if #res == 0 then return nil end
	return res
end

local function replace_field_vars(field_def, data, tgt, audio_file, image_file, word_audio_filename, start, stop, prev_value)
	local abs_path = helper.current_path_abs()
	local _, filename = mpu.split_path(abs_path)

	local template_data = {
		-- exported files --
		audio_file = {data = audio_file},
		image_file = false,
		audio = {data = anki_sound_tag(audio_file)},
		image = false,
		-- current file --
		path = {data = abs_path},
		filename = {data = filename},
		-- times --
		start = {data = helper.format_time(start, true)},
		["end"] = {data = helper.format_time(stop, true)},
		start_ms = {data = helper.format_time(start)},
		end_ms = {data = helper.format_time(stop)},
		start_seconds = {data = string.format("%.0f", math.floor(start))},
		end_seconds = {data = string.format("%.0f", math.floor(stop))},
		start_seconds_ms = {data = string.format("%.3f", start)},
		end_seconds_ms = {data = string.format("%.3f", stop)},
		-- series --
		series_id = {data = series_id.id()},
		series_title = {data = series_id.title()},
		-- optional values --
		word_audio_file = false,
		word_audio = false,
		sentences = false,
		word = false,
		definitions = false,
		-- previous field value when adding to card --
		prev_content = false
	}
	if image_file then
		template_data.image_file = {data = image_file}
		template_data.image = {data = anki_image_tag(image_file)}
	end
	if word_audio_filename then
		template_data.word_audio_file = {data = word_audio_filename}
		template_data.word_audio = {
			data = anki_sound_tag(word_audio_filename)
		}
	end
	if data.subtitles and #data.subtitles ~= 0 then
		template_data.sentences = {
			data = data.subtitles,
			sep = "<br>",
			transform = function(sub)
				return apply_substitutions(sub.text, tgt.sentence_substitutions)
			end
		}
	end
	if data.definitions and #data.definitions ~= 0 then
		template_data.word = {data = data.definitions[1].word}
		template_data.definitions = {
			data = ext.list_map(data.definitions, function(def) return def.definition end),
			sep = "<br>",
			transform = function(def)
				return apply_substitutions(def, tgt.definition_substitutions)
			end
		}
	end
	if prev_value then
		template_data.prev_content = {data = prev_value}
	end
	return templater.render(field_def, template_data)
end

local function export_word_audio(data)
	local media_dir = anki.media_dir()
	if data.word_audio_file and media_dir then
		local src_path = data.word_audio_file.path
		local base_fn = string.format("%s-%s.", cfg.values.forvo_prefix, data.word_audio_file.word)

		local function check_file(extension, action)
			local full_fn = base_fn .. extension
			local tgt_path = mpu.join_path(media_dir, full_fn)
			if not mpu.file_info(tgt_path) then
				action(tgt_path)
			else msg.info("word audio file " .. full_fn .. " already exists") end
			return full_fn
		end

		if cfg.values.forvo_reencode then
			return check_file(cfg.values.forvo_extension, function(tgt_path)
				encoder.any_audio{
					src_path = src_path,
					tgt_path = tgt_path,
					format = cfg.values.forvo_format,
					codec = cfg.values.forvo_codec,
					bitrate = cfg.values.forvo_bitrate
				}
			end)
		else
			return check_file(data.word_audio_file.extension, function(tgt_path)
				sys.move_file(src_path, tgt_path)
			end)
		end
	end
end

local export = {}

function export.verify_times(data, warn)
	local ts = helper.default_times(data.times)

	local start = ts.start >= 0 and ts.start or nil
	local stop = ts.stop >= 0 and ts.stop or nil

	if not (start or stop) then
		if warn then msg.warn("select subtitles or set times manually") end
		return false
	end

	if not (start and stop) then
		if warn then msg.warn("start or end time missing") end
		return false
	end
	return true
end

function export.verify(data, warn)
	-- subs present → times can be derived
	if #data.subtitles ~= 0 then return true end

	return export.verify_times(data, warn)
end

function export.resolve_times(data)
	local ts = helper.default_times(data.times)

	local start = ts.start < 0 and data.subtitles[1]:real_start() or ts.start
	local stop = ts.stop < 0 and ext.list_max(data.subtitles, function(a, b)
		return a.stop < b.stop
	end):real_stop() or ts.stop
	local scrot = ts.scrot < 0 and mp.get_property_number("time-pos") or ts.scrot

	return start, stop, scrot
end

local function prepare_fields(data, prev_contents)
	local tgt = anki.active_target("could not execute export")
	if not tgt then return end

	local media_dir = anki.media_dir()
	if not media_dir or not ankicon.prepare_target(tgt) then
		return nil
	end

	local tgt_cfg = tgt.config
	local start, stop, scrot = export.resolve_times(data)

	local audio_filename = anki.generate_filename(series_id.id(), tgt_cfg.audio.extension)
	encoder.audio(mpu.join_path(media_dir, audio_filename), start, stop)
	local image_filename
	if cfg.take_scrot then
		image_filename = anki.generate_filename(series_id.id(), tgt_cfg.image.extension)
		encoder.image(mpu.join_path(media_dir, image_filename), scrot)
	end
	local word_audio_filename = export_word_audio(data)

	local fields = {}
	for name, def in pairs(tgt.fields) do
		local prev_value
		if prev_contents and prev_contents[name] then
			prev_value = prev_contents[name]
		end
		fields[name] = replace_field_vars(def, data, tgt, audio_filename, image_filename, word_audio_filename, start, stop, prev_value)
	end

	return fields, tgt
end

local function fill_first_field(fields, tgt, ignore_nil)
	if not fields then return end

	local field_names = ankicon.model_field_names(tgt.note_type)
	local first_field = fields[field_names[1]]
	if (not first_field and not ignore_nil) or (first_field and #first_field == 0) then
		fields[field_names[1]] = "<i>placeholder</i>"
	end
	return fields
end

local function hide_menus(data)
	menu_stack.push(BasicOverlay:new("exporting note", nil, "info_overlay"))
	bus.fire("set_blackouts", false)
end

local function show_menus(data)
	bus.fire("set_blackouts", true)
	menu_stack.pop()
end

local function pop_menus(data)
	local count = 1
	if data.level then
		count = data.level + 1
	end
	menu_stack.pop(count)
end

function export.execute(data)
	hide_menus(data)
	local fields = fill_first_field(prepare_fields(data))
	if fields then
		if ankicon.add_note(fields) then
			pop_menus(data)
			msg.info("note added successfully")
			return
		end
	end
	msg.warn("note couldn't be added")
	show_menus()
end

function export.execute_gui(data)
	hide_menus(data)
	local fields = prepare_fields(data)
	if fields then
		if ankicon.gui_add_cards(fields) then
			pop_menus(data)
			msg.info("'Add' GUI opened")
			return
		end
	end
	msg.warn("'Add' GUI couldn't be opened")
	show_menus()
end

local function combine_fields(prev_fields, fields, tgt)
	local new_fields = {}
	for name, value in pairs(prev_fields) do
		if fields[name] then
			local new_value = fields[name]
			if tgt.add_mode == "append" then
				new_value = value .. fields[name]
			elseif tgt.add_mode == "prepend" then
				new_value = fields[name] .. value
			elseif tgt.add_mode == "overwrite" then
				new_value = fields[name]
			else new_value = value end
			new_fields[name] = new_value
		else new_fields[name] = value end
	end
	return new_fields
end

function export.execute_add(data, note)
	hide_menus(data)
	-- "updated" because the user could have edited the note by now
	local updated_note = ankicon.notes_info({note.noteId})[1]
	if updated_note then
		local prev_fields = ext.map_map(updated_note.fields, function(field_name, content)
			return field_name, content.value
		end)

		local fields, tgt = prepare_fields(data, prev_fields)
		if fields then
			local new_fields = fill_first_field(combine_fields(prev_fields, fields, tgt), tgt, true)

			if ankicon.update_note_fields(updated_note.noteId, new_fields) then
				pop_menus(data)
				msg.info("note updated successfully")
				return
			end
		end
	end
	msg.warn("note couldn't be updated")
	show_menus()
end

return export
