local anki = require "anki"
local http = require "http"
local mpu = require "mp.utils"
local msg = require "message"

local function request(action, params)
	local res = http.post_json{
		url = "localhost:8765",
		data = mpu.format_json{
			action = action,
			params = params,
			version = 6
		}
	}

	if res.error then
		local msg_str = res.error
		if action then
			msg_str = msg_str .. "; action: " .. action
		end
		msg.error("AnkiConnect error: " .. msg_str)
		if params then
			msg.debug("params: " .. mpu.format_json(params))
		end
		return nil
	else return res.result end
end

local ankiconnect = {}

function ankiconnect.get_profiles()
	return request("getProfiles")
end

function ankiconnect.deck_names()
	return request("deckNames")
end

function ankiconnect.model_names()
	return request("modelNames")
end

function ankiconnect.model_field_names(model_name)
	return request("modelFieldNames", {
		modelName = model_name
	})
end

local function make_note(fields, options)
	local tgt = anki.active_target("could not make note")
	if not tgt then return end

	return {
		deckName = tgt.deck,
		modelName = tgt.note_type,
		fields = fields,
		options = options,
		tags = tgt.config.tags
	}
end

function ankiconnect.can_add_note(fields)
	local tgt = anki.active_target("could not check note")
	if not tgt then return end

	return request("canAddNotes", {
		notes = {make_note(fields, {allowDuplicate = true})}
	})
end

local function add_note_generic(fields, action, options, err_msg)
	local tgt = anki.active_target("could not " .. err_msg)
	if not tgt then return end

	return request(action, {
		note = make_note(fields, options)
	})
end

function ankiconnect.add_note(fields)
	return add_note_generic(fields, "addNote", {allowDuplicate = true}, "add note")
end

function ankiconnect.gui_add_cards(fields)
	return add_note_generic(fields, "guiAddCards", --[[{closeAfterAdding = true}]]nil, "open card GUI")
end

return ankiconnect
