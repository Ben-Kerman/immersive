-- Immersive is licensed under the terms of the GNU GPL v3: https://www.gnu.org/licenses/; © 2021 Ben Kerman

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

local function replace_field_vars(p)
	local abs_path = helper.current_path_abs()
	local _, filename = mpu.split_path(abs_path)

	local template_data = {
		-- exported files --
		audio_file = {data = p.audio_file},
		image_file = false,
		audio = {data = anki_sound_tag(p.audio_file)},
		image = false,
		-- current file --
		path = {data = abs_path},
		filename = {data = filename},
		-- times --
		start = {data = helper.format_time(p.start, true)},
		["end"] = {data = helper.format_time(p.stop, true)},
		start_ms = {data = helper.format_time(p.start)},
		end_ms = {data = helper.format_time(p.stop)},
		start_seconds = {data = string.format("%.0f", math.floor(p.start))},
		end_seconds = {data = string.format("%.0f", math.floor(p.stop))},
		start_seconds_ms = {data = string.format("%.3f", p.start)},
		end_seconds_ms = {data = string.format("%.3f", p.stop)},
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
	if p.image_file then
		template_data.image_file = {data = p.image_file}
		template_data.image = {data = anki_image_tag(p.image_file)}
	end
	if p.word_audio_file then
		template_data.word_audio_file = {data = p.word_audio_file}
		template_data.word_audio = {
			data = anki_sound_tag(p.word_audio_file)
		}
	end
	if p.data.subtitles and #p.data.subtitles ~= 0 then
		template_data.sentences = {
			data = p.data.subtitles,
			sep = "<br>",
			transform = function(sub)
				return sub.text
			end
		}
	end
	if p.data.definitions and #p.data.definitions ~= 0 then
		template_data.word = {data = p.data.definitions[1].word}
		template_data.definitions = {
			data = ext.list_map(p.data.definitions, function(def) return def.definition end),
			sep = "<br>",
			transform = function(def)
				return helper.apply_substitutions(def, p.tgt.definition_substitutions)
			end
		}
	end
	if p.prev_value then
		template_data.prev_content = {data = p.prev_value}
	end
	return templater.render(p.field_def, template_data)
end

local function export_word_audio(encode_state, data)
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
				encode_state.encodes.word_audio = true
				encoder.any_audio{
					src_path = src_path,
					tgt_path = tgt_path,
					format = cfg.values.forvo_format,
					codec = cfg.values.forvo_codec,
					bitrate = cfg.values.forvo_bitrate,
					state = encode_state,
					desc = "word_audio"
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
	local params = {
		data = data
	}

	local start, stop, scrot = export.resolve_times(data)
	params.start, params.stop = start, stop

	params.tgt = anki.active_target("could not execute export")
	if not params.tgt then return end

	local media_dir = anki.media_dir()
	if not media_dir or not ankicon.prepare_target(params.tgt) then
		return nil
	end

	local tgt_cfg = params.tgt.config

	local encode_state = {encodes = {}}

	params.audio_file = anki.generate_filename(series_id.id(), tgt_cfg.audio.extension)
	encode_state.encodes.audio = true
	encoder.audio(encode_state, mpu.join_path(media_dir, params.audio_file), start, stop)

	if cfg.take_scrot then
		params.image_file = anki.generate_filename(series_id.id(), tgt_cfg.image.extension)
		encode_state.encodes.image = true
		encoder.image(encode_state, mpu.join_path(media_dir, params.image_file), scrot)
	end
	params.word_audio_file = export_word_audio(encode_state, data)

	local fields = {}
	for name, def in pairs(params.tgt.fields) do
		local field_params = ext.map_merge(params)
		field_params.field_def = def

		if prev_contents and prev_contents[name] then
			field_params.prev_value = prev_contents[name]
		end
		fields[name] = replace_field_vars(field_params)
	end

	local tags = {}
	for _, tag in ipairs(params.tgt.tags) do
		local tag_params = ext.map_merge(params)
		tag_params.field_def = tag

		local rendered = replace_field_vars(tag_params)
		local no_space = rendered:gsub(" ", "_"):gsub("　", "＿")
		table.insert(tags, no_space)
	end

	return fields, tags, params.tgt
end

local function fill_first_field(fields, tags, tgt, ignore_nil)
	if not fields then return end

	local field_names = ankicon.model_field_names(tgt.note_type)
	local first_field = fields[field_names[1]]
	if (not first_field and not ignore_nil) or (first_field and #first_field == 0) then
		fields[field_names[1]] = "<i>placeholder</i>"
	end
	return fields, tags
end

local function save_menus(data)
	if data.level then
		bus.fire("set_blackouts", false)
		return {
			msg = msg.info("exporting note", 0),
			menus = menu_stack.save(data.level)
		}
	else return nil end
end

local function restore_menus(state)
	if state then
		msg.remove(state.msg)
		menu_stack.restore(state.menus)
		bus.fire("set_blackouts", true)
	end
end

local function drop_menus(state)
	if state then
		msg.remove(state.msg)
		menu_stack.drop(state.menus)
	end
end

function export.execute(data)
	local state = save_menus(data)
	local fields, tags = fill_first_field(prepare_fields(data))
	if fields then
		if ankicon.add_note(fields, tags) then
			drop_menus(state)
			msg.info("note added successfully")
			return
		end
	end
	restore_menus(state)
	msg.warn("note couldn't be added")
end

function export.execute_gui(data)
	local state = save_menus(data)
	local fields, tags = prepare_fields(data)
	if fields then
		if ankicon.gui_add_cards(fields, tags) then
			drop_menus(state)
			msg.info("'Add' GUI opened")
			return
		end
	end
	restore_menus(state)
	msg.warn("'Add' GUI couldn't be opened")
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
	local state = save_menus(data)
	-- "updated" because the user could have edited the note by now
	local updated_note = ankicon.notes_info({note.noteId})[1]
	if updated_note then
		local prev_fields = ext.map_map(updated_note.fields, function(field_name, content)
			return field_name, content.value
		end)

		local fields, _, tgt = prepare_fields(data, prev_fields)
		if fields then
			local new_fields = fill_first_field(combine_fields(prev_fields, fields, tgt), nil, tgt, true)

			if ankicon.update_note_fields(updated_note.noteId, new_fields) then
				drop_menus(state)
				msg.info("note updated successfully")
				return
			end
		end
	end
	restore_menus(state)
	msg.warn("note couldn't be updated")
end

return export
