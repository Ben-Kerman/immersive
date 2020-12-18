local kbds = require "key_bindings"
local series_id = require "series_id"
local sub_select = require "sub_select"
local sys = require "system"
require "menu"

-- forward declarations
local menu

local autocopy = false

local function display_bool(val)
	if val then return "enabled"
	else return "disabled" end
end

local infos = {
	{name = "Series ID", value = "{\\i1}no file loaded{\\i0}"},
	{name = "Sub auto-copy", value = autocopy, display = display_bool}
}

mp.register_event("file-loaded", function()
	infos[1].value = series_id.get_id()
	menu:redraw()
end)

local function copy_active_line()
	local sub_text = mp.get_property("sub-text")
	if sub_text and sub_text ~= "" then
		sys.clipboard_write(sub_text)
	end
end

local function toggle_autocopy()
	if autocopy then
		mp.osd_message("Subtitle auto-copy disabled")
		mp.unobserve_property(copy_active_line)
	else
		mp.osd_message("Subtitle auto-copy enabled")
		mp.observe_property("sub-text", "none", copy_active_line)
	end
	autocopy = not autocopy
	infos[2].value = autocopy
	menu:redraw()
end

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
		id = "copy_active_line",
		default = "c",
		desc = "Copy current subtitle to clipboard",
		action = copy_active_line,
		global = true
	},
	{
		id = "toggle_autocopy",
		default = "C",
		desc = "Toggle subtitle auto-copy",
		action = toggle_autocopy,
		global = true
	},
	{
		id = "lookup_word",
		default = "k",
		desc = "Select and look up word from active subtitle",
		action = nil,
		global = true
	},
	{
		id = "export_active_line",
		default = "K",
		desc = "Create card from active subtitle, skip line selection",
		action = nil,
		global = true
	},
	{
		id = "export_active_line_instant",
		default = "Ctrl+k",
		desc = "Create card from active subtitle, export immediately",
		action = nil,
		global = true
	},
	{
		id = "close_global_menu",
		default = "ESC",
		desc = "Close the menu",
		action = function() menu:disable() end
	}
}

menu = Menu:new{infos = infos,bindings = bindings}

kbds.add_global_bindings(bindings)
