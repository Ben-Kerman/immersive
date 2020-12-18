local anki = require "anki"
local ankicon = require "ankiconnect"
local encoder = require "encoder"
local mputil = require "mp.utils"
local series_id = require "series_id"
local templater = require "templater"
local util = require "util"

local function replace_field_vars(field_def, data, audio_file, image_file)
	local template_data = {
		audio = {data = string.format("[sound:%s]", audio_file)},
		image = {data = string.format([[<img src="%s">]], image_file)}
	}
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

local function resolve_times(data)
	if not data.times then
		data.times = {scrot = -1, start = -1, stop = -1}
	end
	local ts = data.times
	ts.scrot = ts.scrot < 0 and mp.get_property_number("time-pos") or ts.scrot
	ts.start = ts.start < 0 and data.subtitles[1].start or ts.start
	ts.stop = ts.stop < 0 and util.list_max(data.subtitles, function(a, b)
		return a.stop < b.stop
	end).stop or ts.stop
end

local export = {}

function export.execute(data)
	local tgt_cfg = anki.active_target().config
	resolve_times(data)

	local audio_filename = anki.generate_filename(series_id.get_id(), tgt_cfg.audio.extension)
	local image_filename = anki.generate_filename(series_id.get_id(), tgt_cfg.image.extension)
	encoder.audio(mputil.join_path(anki.media_dir(), audio_filename), data.times.start, data.times.stop)
	encoder.image(mputil.join_path(anki.media_dir(), image_filename), data.times.scrot)

	local fields = {}
	for name, def in pairs(tgt_cfg.anki.fields) do
		fields[name] = replace_field_vars(def, data, audio_filename, image_filename)
	end

	ankicon.add_note(fields)
end

return export
