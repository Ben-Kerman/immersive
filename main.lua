local kbds = require "key_bindings"
local sub_select = require "sub_select"
local sys = require "system"
require "menu"

-- forward declarations
local menu

local bindings = {
	{
		id = "begin_sub_select",
		default = "a",
		desc = "Start line selection",
		action = sub_select.begin,
		global = true
	},
	{
		id = "open_global_menu",
		default = "Ctrl+a",
		desc = "Open the global menu",
		action = function() menu:enable() end,
		global = true
	},
	{
		id = "close_global_menu",
		default = "ESC",
		desc = "Close the menu",
		action = function() menu:disable() end
	}
}

menu = Menu:new{bindings = bindings}

kbds.add_global_bindings(bindings)
