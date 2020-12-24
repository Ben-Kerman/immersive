local anki = require "anki"
local http = require "http"
local mpu = require "mp.utils"
local msg = require "message"
local util = require "util"

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

function ankiconnect.check()
	local res = request("version")
	if res and res >= 6 then
		return true
	elseif res and res < 6 then
		msg.error("wrong AnkiConnect API version")
	else msg.error("AnkiConnect not available") end
	return false
end

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

function ankiconnect.load_profile(profile)
	return request("loadProfile", {
		name = profile
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

	local res = request("canAddNotes", {
		notes = {make_note(fields, {allowDuplicate = true})}
	})
	if not res then return false
	else return res[1] end
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
	-- if closeAfterAdding == true, the note type isn't set correctly
	return add_note_generic(fields, "guiAddCards", --[[{closeAfterAdding = true}]]nil, "open card GUI")
end

function ankiconnect.prepare_target(tgt)
	if not ankiconnect.check() then return false end

	local profiles = ankiconnect.get_profiles()
	if not profiles or not util.list_find(profiles, tgt.profile) then
		msg.error("Anki profile '" .. tgt.profile .. "' not found")
		return false
	end

	if not ankiconnect.load_profile(tgt.profile) then
		msg.error("failed to load Anki profile '" .. tgt.profile .. "'")
		return false
	end

	local decks = ankiconnect.deck_names()
	if not decks or not util.list_find(decks, tgt.deck) then
		msg.error("deck '" .. tgt.deck .. "' not found")
		return false
	end

	local note_types = ankiconnect.model_names()
	if not note_types or not util.list_find(note_types, tgt.note_type) then
		msg.error("note type '" .. tgt.note_type .. "' not found")
		return false
	end

	return true
end

return ankiconnect
