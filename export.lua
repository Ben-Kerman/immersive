anki = require "anki"
encoder = require "encoder"
series_id = require "series_id"

local export = {}

function export.execute(selection, times)
	local tgt_cfg = anki.active_target().config

	local text = table.concat(selection, "\n")
	local audio_filename = anki.generate_filename(series_id.get_id(), tgt_cfg.audio.extension)
	local image_filename = anki.generate_filename(series_id.get_id(), tgt_cfg.image.extension)
	encoder.audio(anki.media_dir() .. "/" .. audio_filename, times.start, times.stop)
	encoder.image(anki.media_dir() .. "/" .. image_filename, times.scrot)
end

return export
