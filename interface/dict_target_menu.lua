-- Immersive is licensed under the terms of the GNU GPL v3: https://www.gnu.org/licenses/; © 2020 Ben Kerman

local anki = require "systems.anki"
local dicts = require "dict.dicts"
local Menu = require "interface.menu"
local menu_stack = require "interface.menu_stack"

local DictTargetMenu = {}
DictTargetMenu.__index = DictTargetMenu

local infos = {
	{
		name = "Anki target",
		display = function()
			local tgt = anki.active_target(false)
			if tgt then return tgt.name
			else return {style = {"menu_info", "unset"}, "none"} end
		end
	},
	{
		name = "Dictionary",
		display = function()
			local dict = dicts.active(true)
			if dict then return dict.id
			else return {style = {"menu_info", "unset"}, "none"} end
		end
	}
}

function DictTargetMenu:new()
	local dtm

	local bindings = {
		group = "dict_target_menu",
		{
			id = "prev_target",
			default = "Ctrl+UP",
			desc = "Switch to the previous Anki target",
			action = function() anki.switch_target(-1); dtm.menu:redraw() end
		},
		{
			id = "next_target",
			default = "Ctrl+DOWN",
			desc = "Switch to the next Anki target",
			action = function() anki.switch_target(1); dtm.menu:redraw() end
		},
		{
			id = "prev_dict",
			default = "Alt+UP",
			desc = "Switch to the previous dictionary",
			action = function() dicts.switch(-1); dtm.menu:redraw() end
		},
		{
			id = "next_dict",
			default = "Alt+DOWN",
			desc = "Switch to the next dictionary",
			action = function() dicts.switch(1); dtm.menu:redraw() end
		},
		{
			id = "reimport_dicts",
			default = "r",
			desc = "Reimport all imported dictionaries",
			action = function() dicts.reimport_all() end
		}
	}

	dtm = setmetatable({
		menu = Menu:new{infos = infos, bindings = bindings}
	}, DictTargetMenu)
	return dtm
end

function DictTargetMenu:show()
	self.menu:show()
end

function DictTargetMenu:hide()
	self.menu:hide()
end

function DictTargetMenu:cancel()
	self:hide()
end

return DictTargetMenu
