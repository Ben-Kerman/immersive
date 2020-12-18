local export = require "export"
require "menu"
require "selection_overlay"
require "subtitle"
local util = require "util"
local target_select = require "target_select"

-- forward declarations
local pack_data
local menu, sel_overlay
local reset
local set_scrot, set_start, set_stop

local selection = {}

local function select_sub()
	local sub_text = mp.get_property("sub-text")
	if sub_text == nil or sub_text == "" then
		mp.osd_message("No active subtitle line, nothing selected")
	else
		local sub = Subtitle:new(
			sub_text,
			mp.get_property_number("sub-start"),
			mp.get_property_number("sub-end"))

		-- check for end time, lines with identical start times get combined by mpv
		if not util.list_find(selection, function(s) return s.stop == sub.stop end) then
			table.insert(selection, sub)
			table.sort(selection)
		end
		sel_overlay:redraw()
	end
end

local function handle_sub_text(_, sub_text)
	if sub_text ~= nil and sub_text ~= "" then select_sub() end
end

local auto_select_active = false
local function toggle_auto_select()
	if auto_select_active then mp.unobserve_property(handle_sub_text)
	else mp.observe_property("sub-text", "string", handle_sub_text) end
	auto_select_active = not auto_select_active
end

local function cancel()
	mp.unobserve_property(handle_sub_text)
	reset()
	sel_overlay:remove()
	menu:disable()
end

reset = function()
	selection = {}
	sel_overlay.selection = selection
	sel_overlay:redraw()
	set_scrot()
	set_start()
	set_stop()
end

local function finish()
	local data = pack_data()
	cancel()
	return data
end
local function finish_tgt_sel()
	target_select.begin(finish())
end
local function finish_export()
	export.execute(finish())
end

local bindings = {
	{
		id = "sub_select-set_start_sub",
		default = "q",
		desc = "Force start to start of active line",
		action = function() set_start("sub-start") end
	},
	{
		id = "sub_select-set_end_sub",
		default = "e",
		desc = "Force end to end of active line",
		action = function() set_stop("sub-end") end
	},
	{
		id = "sub_select-set_start_time_pos",
		default = "Q",
		desc = "Force start to current time",
		action = function() set_start("time-pos") end
	},
	{
		id = "sub_select-set_end_time_pos",
		default = "E",
		desc = "Force end to current time",
		action = function() set_stop("time-pos") end
	},
	{
		id = "sub_select-set_scrot",
		default = "s",
		desc = "Take screenshot at current time",
		action = function() set_scrot("time-pos") end
	},
	{
		id = "sub_select-select_line",
		default = "a",
		desc = "Select current line",
		action = select_sub
	},
	{
		id = "sub_select-toggle_auto_select",
		default = "A",
		desc = "Toggle automatic selection",
		action = toggle_auto_select
	},
	{
		id = "sub_select-reset",
		default = "k",
		desc = "Reset selection",
		action = reset
	},
	{
		id = "sub_select-start_target_select",
		default = "d",
		desc = "End line selection and enter target selection",
		action = finish_tgt_sel
	},
	{
		id = "sub_select-instant_export",
		default = "f",
		desc = "End line selection and export immediately",
		action = finish_export
	},
	{
		id = "sub_select-cancel",
		default = "ESC",
		desc = "Cancel selection",
		action = cancel
	}
}

local function display_time(value)
	if value >= 0 then return tostring(value)
	else return "{\\i1}auto{\\i0}" end
end
local scrot = {name = "Screenshot", value = -1, display = display_time}
local start = {name = "Start", value = -1, display = display_time}
local stop = {name = "End", value = -1, display = display_time}
local infos = {start, stop, scrot}

local function set_time(time, value)
	local new_val
	if type(value) == "string" then
		new_val = mp.get_property_number(value)
	else new_val = value end

	if new_val == nil then time.value = -1
	elseif new_val == time.value then time.value = -1
	else time.value = new_val end

	menu:redraw()
end
set_scrot = function(value) set_time(scrot, value) end
set_start = function(value) set_time(start, value) end
set_stop = function(value) set_time(stop, value) end

pack_data = function()
	return {
		subtitles = selection,
		times = {
			scrot = scrot.value,
			start = start.value,
			stop = stop.value
		}
	}
end

menu = Menu:new{infos = infos, bindings = bindings}
sel_overlay = SelectionOverlay:new(selection)

local sub_select = {}

function sub_select.begin()
	reset()
	menu:enable()
end

return sub_select
