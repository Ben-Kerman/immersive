local anki = require "anki"
local http = require "http"
local mpu = require "mp.utils"

local ankiconnect = {}

function ankiconnect.request(action, params)
	return http.post_json{
		url = "localhost:8765",
		data = mpu.format_json{
			action = action,
			params = params,
			version = 6
		}
	}
end

function ankiconnect.add_note(fields)
	local tgt = anki.active_target("could not add deck")
	if not tgt then return end

	ankiconnect.request("addNote", {
		note = {
			deckName = tgt.deck,
			modelName = tgt.note_type,
			fields = fields,
			options = {allowDuplicate = true},
			tags = tgt.config.tags
		}
	})
end

return ankiconnect
