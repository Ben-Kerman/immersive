-- Immersive is licensed under the terms of the GNU GPL v3: https://www.gnu.org/licenses/; © 2020 Ben Kerman

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

local ActiveSubLookup = require "interface.active_sub_lookup"
local anki = require "systems.anki"
local cfg = require "systems.config"
local dicts = require "dict.dicts"
local DictTargetMenu = require "interface.dict_target_menu"
local export = require "systems.export"
local helper = require "utility.helper"
local kbds = require "systems.key_bindings"
local Menu = require "interface.menu"
local menu_stack = require "interface.menu_stack"
local series_id = require "utility.series_id"
local msg = require "systems.message"
local SubSelect = require "interface.sub_select"
local Subtitle = require "systems.subtitle"
local sys = require "systems.system"
local TargetSelect = require "interface.target_select"

-- forward declaration
local menu

local autocopy = false

local function get_id_title(fn_name)
	local value, custom = series_id[fn_name]()
	if custom then return value
	else
		return {
			style = {"menu_info", "unset"},
			value and value or "unknown"
		}
	end
end

local infos = {
	{
		name = "Series ID",
		display = function() return get_id_title("id") end
	},
	{
		name = "Title",
		display = function() return get_id_title("title") end
	},
	{
		name = "Sub auto-copy",
		display = function() return helper.display_bool(autocopy) end
	},
	{
		name = "Screenshots",
		display = function() return helper.display_bool(cfg.take_scrot) end
	}
}

mp.register_event("file-loaded", function()
	menu:redraw()
end)

local function copy_active_line(_, sub_text)
	if not sub_text then sub_text = mp.get_property("sub-text") end
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
		mp.observe_property("sub-text", "string", copy_active_line)
	end
	autocopy = not autocopy
	menu:redraw()
end

local function export_active_line(skip_target_select)
	local sub_text = helper.check_active_sub()
	if sub_text then
		local fn = skip_target_select and export.execute or function(data)
			menu_stack.push(TargetSelect:new(data))
		end
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
		id = "show_dict_target",
		default = "Ctrl+A",
		desc = "Show dictionary/target menu",
		action = function() menu_stack.push(DictTargetMenu:new()) end,
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
		id = "toggle_scrot",
		default = "s",
		desc = "Toggle screenshots on/off",
		action = function() cfg.take_scrot = not cfg.take_scrot; menu:redraw() end
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

menu = Menu:new{infos = infos, bindings = bindings}

kbds.create_global(bindings)

msg.end_startup()
