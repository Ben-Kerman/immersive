local anki = require "anki"
local export = require "export"
local LineSelect = require "line_select"
local Menu = require "menu"
local templater = require "templater"
local util = require "util"

local NotePicker = {}
NotePicker.__index = NotePicker

function NotePicker:new(data, notes)
	local np

	local bindings = {
		group = "note_select",
		{
			id = "confirm",
			default = "ENTER",
			desc = "Confirm selection and export",
			action = function()
				export.execute_add(np.data, (np.note_select:selection()))
			end
		}
	}

	local tgt = anki.active_target("could not get note template")
	if not tgt then return nil end
	local function note_conv(note)
		local data = util.map_map(note.fields, function(name, content)
			return "field_" .. name, {data = content.value}
		end)
		data.type = {data = tostring(note.modelName)}
		data.id = {data = tostring(note.noteId)}
		data.tags = {data = note.tags}

		return templater.render(tgt.note_template, data)
	end

	np = setmetatable({
		data = data,
		notes = notes,
		note_select = LineSelect:new(notes, note_conv, nil, nil, 9),
		menu = Menu:new{bindings = bindings}
	}, NotePicker)
	return np
end

function NotePicker:show()
	self.menu:show()
	self.note_select:show()
end

function NotePicker:hide()
	self.note_select:hide()
	self.menu:hide()
end

function NotePicker:cancel()
	self:hide()
end

return NotePicker
