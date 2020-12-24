local anki = require "anki"
local ankicon = require "ankiconnect"
local cfg = require "config"
local encoder = require "encoder"
local mpu = require "mp.utils"
local msg = require "message"
local series_id = require "series_id"
local sys = require "system"
local templater = require "templater"
local util = require "util"

local function anki_sound_tag(filename)
	return string.format("[sound:%s]", filename)
end

local function anki_image_tag(filename)
	return string.format([[<img src="%s">]], filename)
end

local function replace_field_vars(field_def, data, audio_file, image_file, word_audio_filename)
	local template_data = {
		audio = {data = anki_sound_tag(audio_file)},
		image = {data = anki_image_tag(image_file)}
	}
	if word_audio_filename then
		template_data.word_audio = {
			data = anki_sound_tag(word_audio_filename)
		}
	else template_data.word_audio = {data = ""} end
	if data.subtitles and #data.subtitles ~= 0 then
		template_data.sentences = {
			data = util.list_map(data.subtitles, function(sub) return sub.text end),
			sep = "<br>"
		}
	else template_data.sentences = {data = "<i>placeholder</i>"} end
	if data.definitions and #data.definitions ~= 0 then
		template_data.word = data.definitions[1].word
		template_data.definitions = {
			data = util.list_map(data.definitions, function(def) return def.definition end),
			sep = "<br>"
		}
	else
		template_data.word = {data = ""}
		template_data.definitions = {data = ""}
	end
	return templater.render(field_def, template_data)
end

local function export_word_audio(data)
	if data.word_audio_file then
		local src_path = data.word_audio_file.path
		local base_fn = string.format("%s-%s.", cfg.values.forvo_prefix, data.word_audio_file.word)

		local function check_file(extension, action)
			local full_fn = base_fn .. extension
			local tgt_path = mpu.join_path(anki.media_dir(), full_fn)
			if not mpu.file_info(tgt_path) then
				action(tgt_path)
			else msg.info("Word audio file " .. full_fn .. " already exists") end
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
	local start = data.times.start and data.times.start >= 0
	local stop = data.times.stop and data.times.stop >= 0

	if not data.times or not (start or stop) then
		if warn then msg.warn("Select subtitles or set times manually") end
		return false
	end

	if not (start and stop) then
		if warn then msg.warn("Start or end time missing") end
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
	local ts = util.map_merge({
		scrot = -1,
		start = -1,
		stop = -1
	}, data.times)

	local start = ts.start < 0 and data.subtitles[1]:real_start() or ts.start
	local stop = ts.stop < 0 and util.list_max(data.subtitles, function(a, b)
		return a.stop < b.stop
	end):real_stop() or ts.stop
	local scrot = ts.scrot < 0 and mp.get_property_number("time-pos") or ts.scrot

	return start, stop, scrot
end

function export.execute(data)
	local tgt = anki.active_target("could not execute export")
	if not tgt then return end

	local tgt_cfg = tgt.config
	local start, stop, scrot = export.resolve_times(data)

	local audio_filename = anki.generate_filename(series_id.id(), tgt_cfg.audio.extension)
	local image_filename = anki.generate_filename(series_id.id(), tgt_cfg.image.extension)
	encoder.audio(mpu.join_path(anki.media_dir(), audio_filename), start, stop)
	encoder.image(mpu.join_path(anki.media_dir(), image_filename), scrot)
	local word_audio_filename = export_word_audio(data)

	local fields = {}
	for name, def in pairs(tgt_cfg.anki.fields) do
		fields[name] = replace_field_vars(def, data, audio_filename, image_filename, word_audio_filename)
	end

	ankicon.add_note(fields)
end

return export
