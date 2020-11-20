local config = {
	values = {
		anki_profile="",
		anki_deck="",
		anki_note_type="",
		anki_field_text="",
		anki_field_audio="",
		anki_field_image=""
	}
}

local mp_opts = require "mp.options"
mp_opts.read_options(config.values)

return config
