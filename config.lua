local config = {
	values = {
		anki_targets=""
	}
}

local mp_opts = require "mp.options"
mp_opts.read_options(config.values)

return config
