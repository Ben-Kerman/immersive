local anki = require "anki"
local ankicon = require "ankiconnect"
local encoder = require "encoder"
local series_id = require "series_id"
local templater = require "templater"

local function replace_field_vars(field_def, text, audio_file, image_file)
	return templater.render(field_def, {
		text = text:gsub("\n", "<br>"),
		audio = string.format("[sound:%s]", audio_file),
		image = string.format([[<img src="%s">]], image_file)
	})
end

local export = {}

function export.execute(selection, times)
	local tgt_cfg = anki.active_target().config

	local text = table.concat(selection, "\n")
	local audio_filename = anki.generate_filename(series_id.get_id(), tgt_cfg.audio.extension)
	local image_filename = anki.generate_filename(series_id.get_id(), tgt_cfg.image.extension)
	encoder.audio(anki.media_dir() .. "/" .. audio_filename, times.start, times.stop)
	encoder.image(anki.media_dir() .. "/" .. image_filename, times.scrot)

	local fields = {}
	for name, def in pairs(tgt_cfg.anki.fields) do
		fields[name] = replace_field_vars(def, text, audio_filename, image_filename)
	end

	ankicon.add_note(fields)
end

return export
