local anki = require "anki"
local http = require "http"
local mputil = require "mp.utils"

local ankiconnect = {}

function ankiconnect.request(action, params)
	local data = {
		action = action,
		params = params,
		version = 6
	}
	return http.post("localhost:8765", mputil.format_json(data))
end

function ankiconnect.add_note(fields)
	local tgt = anki.active_target()
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
