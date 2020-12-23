script_name = mp.get_script_name()

-- always log verbose messages unless the user overrides msg-level
mp.set_property("msg-level", (function()
	local msg_lvl = mp.get_property("msg-level")
	local new_msg_lvl = script_name .. "=v"
	if msg_lvl and #msg_lvl ~= 0 then
		new_msg_lvl = new_msg_lvl .. "," .. msg_lvl
	end
	return new_msg_lvl
end)())

local ActiveSubLookup = require "active_sub_lookup"
local anki = require "anki"
local dicts = require "dict.dicts"
local export = require "export"
local helper = require "helper"
local kbds = require "key_bindings"
local Menu = require "menu"
local menu_stack = require "menu_stack"
local series_id = require "series_id"
local msg = require "message"
local SubSelect = require "sub_select"
local Subtitle = require "subtitle"
local sys = require "system"
local target_select = require "target_select"

-- forward declaration
local menu

local autocopy = false

local function display_bool(val)
	if val then return "enabled"
	else return "disabled" end
end

local infos = {
	{
		name = "Series ID",
		value = {style = {"menu_info", "unset"}, "no file loaded"}
	},
	{
		name = "Sub auto-copy",
		value = autocopy,
		display = display_bool
	},
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

mp.register_event("file-loaded", function()
	local id, custom = series_id.get_id()
	if custom then infos[1].value = id
	else
		infos[1].value = {
			style = {"menu_info", "unset"},
			id and id or "unknown"
		}
	end
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
		action = function() menu_stack.push(SubSelect:new()) end,
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
		action = function() menu_stack.push(ActiveSubLookup:new()) end,
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
		id = "prev_target",
		default = "Ctrl+UP",
		desc = "Switch to the previous Anki target",
		action = function() anki.switch_target(-1); menu:redraw() end
	},
	{
		id = "next_target",
		default = "Ctrl+DOWN",
		desc = "Switch to the next Anki target",
		action = function() anki.switch_target(1); menu:redraw() end
	},
	{
		id = "prev_dict",
		default = "Alt+UP",
		desc = "Switch to the previous dictionary",
		action = function() dicts.switch(-1); menu:redraw() end
	},
	{
		id = "next_dict",
		default = "Alt+DOWN",
		desc = "Switch to the next dictionary",
		action = function() dicts.switch(1); menu:redraw() end
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

msg.end_startup()
