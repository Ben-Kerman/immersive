local anki = require "anki"
local ankicon = require "ankiconnect"
local encoder = require "encoder"
local mputil = require "mp.utils"
local series_id = require "series_id"
local templater = require "templater"

local function replace_field_vars(field_def, data, audio_file, image_file)
	return templater.render(field_def, {
		sentences = {
			data = data.subtitles,
			sep = "<br>"
		},
		audio = {data = string.format("[sound:%s]", audio_file)},
		image = {data = string.format([[<img src="%s">]], image_file)}
	})
end

local function resolve_times(data)
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

	local audio_filename = anki.generate_filename(series_id.get_id(), tgt_cfg.audio.extension)
	local image_filename = anki.generate_filename(series_id.get_id(), tgt_cfg.image.extension)
	encoder.audio(mputil.join_path(anki.media_dir(), audio_filename), times.start, times.stop)
	encoder.image(mputil.join_path(anki.media_dir(), image_filename), times.scrot)

	local fields = {}
	for name, def in pairs(tgt_cfg.anki.fields) do
		fields[name] = replace_field_vars(def, data, audio_filename, image_filename)
	end

	ankicon.add_note(fields)
end

return export
