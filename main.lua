local export = require "export"
local helper = require "helper"
local kbds = require "key_bindings"
local lookup_active = require "lookup_active"
local Menu = require "menu"
local menu_stack = require "menu_stack"
local series_id = require "series_id"
local SubSelect = require "sub_select"
local Subtitle = require "subtitle"
local sys = require "system"
local target_select = require "target_select"

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

local function export_active_line(skip_target_select)
	local sub_text = helper.check_active_sub()
	if sub_text then
		local fn = skip_target_select and export.execute or target_select.begin
		fn{
			subtitles = {
				Subtitle:new(sub_text,
				             mp.get_property_number("sub-start"),
				             mp.get_property_number("sub-end"))
			}
		}
	end
end

local bindings = {
	group = "global_menu",
	{
		id = "begin_sub_select",
		default = "a",
		desc = "Start line selection",
		action = SubSelect.new,
		global = true
	},
	{
		id = "open_global_menu",
		default = "Ctrl+a",
		desc = "Open the global menu",
		action = function() menu_stack.push(menu) end,
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
		action = lookup_active.begin,
		global = true
	},
	{
		id = "export_active_line",
		default = "K",
		desc = "Create card from active subtitle, skip line selection",
		action = export_active_line,
		global = true
	},
	{
		id = "export_active_line_instant",
		default = "Ctrl+k",
		desc = "Create card from active subtitle, export immediately",
		action = function() export_active_line(true) end,
		global = true
	},
	{
		id = "close_menu",
		default = "ESC",
		desc = "Go back to previous menu",
		action = menu_stack.pop,
		global = true
	},
	{
		id = "clear_menus",
		default = "Shift+ESC",
		desc = "Close all active menus",
		action = menu_stack.clear,
		global = true
	}
}

menu = Menu:new{infos = infos,bindings = bindings}

kbds.add_global_bindings(bindings)
