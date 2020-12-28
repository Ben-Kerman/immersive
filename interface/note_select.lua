-- Immersive is licensed under the terms of the GNU GPL v3: https://www.gnu.org/licenses/; © 2020 Ben Kerman

local anki = require "systems.anki"
local export = require "systems.export"
local LineSelect = require "interface.line_select"
local Menu = require "interface.menu"
local templater = require "systems.templater"
local ext = require "utility.extension"

local NoteSelect = {}
NoteSelect.__index = NoteSelect

function NoteSelect:new(data, notes)
	local ns

	data.level = data.level and (data.level + 1) or 1
	local bindings = {
		group = "note_select",
		{
			id = "confirm",
			default = "ENTER",
			desc = "Confirm selection and export",
			action = function()
				export.execute_add(ns.data, (ns.note_select:selection()))
			end
		}
	}

	local tgt = anki.active_target("could not get note template")
	if not tgt then return nil end
	local function note_conv(note)
		local data = ext.map_map(note.fields, function(name, content)
			return "field_" .. name, {data = content.value}
		end)
		data.type = {data = tostring(note.modelName)}
		data.id = {data = tostring(note.noteId)}
		data.tags = {data = note.tags}

		return templater.render(tgt.note_template, data)
	end

	ns = setmetatable({
		data = data,
		notes = notes,
		note_select = LineSelect:new(notes, note_conv, nil, nil, 9),
		menu = Menu:new{bindings = bindings}
	}, NoteSelect)
	return ns
end

function NoteSelect:show()
	self.menu:show()
	self.note_select:show()
end

function NoteSelect:hide()
	self.note_select:hide()
	self.menu:hide()
end

function NoteSelect:cancel()
	self:hide()
end

return NoteSelect
