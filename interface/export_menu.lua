-- Immersive is licensed under the terms of the GNU GPL v3: https://www.gnu.org/licenses/; © 2020 Ben Kerman

local anki = require "systems.anki"
local export = require "systems.export"
local Menu = require "interface.menu"
local menu_stack = require "interface.menu_stack"
local NoteSelect = require "interface.note_select"

local ExportMenu = {}
ExportMenu.__index = ExportMenu

function ExportMenu:new(data)
	local em

	local bindings = {
		group = "export_menu",
		{
			id = "export",
			default = "f",
			desc = "Export",
			action = function() export.execute(em.data) end
		},
		{
			id = "export_gui",
			default = "g",
			desc = "Export using the 'Add' GUI",
			action = function() export.execute_gui(em.data) end
		}
	}
	local candidates = anki.add_candidates()
	if #candidates ~= 0 then
		table.insert(bindings, {
			id = "export_add",
			default = "a",
			desc = "Export to existing note, choose which",
			action = function()
				menu_stack.push(NoteSelect:new(em.data, candidates))
			end
		})
		table.insert(bindings, {
			id = "export_add_to_last",
			default = "s",
			desc = "Export to existing note, use last added",
			action = function() export.execute_add(em.data, candidates[1]) end
		})
	end

	data.level = data.level and (data.level + 1) or 1
	em = setmetatable({
		data = data,
		menu = Menu:new{bindings = bindings}
	}, ExportMenu)
	return em
end

function ExportMenu:show()
	self.menu:show()
end

function ExportMenu:hide()
	self.menu:hide()
end

function ExportMenu:cancel()
	self:hide()
end

return ExportMenu
