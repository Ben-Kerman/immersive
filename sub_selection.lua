require "menu"
require "subtitle"
require "util"

local menu
local reset
local set_scrot, set_start, set_stop

local subs = {}

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
		if not list_find(subs, function(s) return s.stop == sub.stop end) then
			table.insert(subs, sub)
			table.sort(subs)
		end
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
	menu:disable()
end

reset = function()
	subs = {}
	set_scrot(nil)
	set_start()
	set_stop()
end

local bindings = {
	{key = "q", desc = "Force start to start of active line", action = function() set_start("sub-start") end},
	{key = "e", desc = "Force end to end of active line", action = function() set_stop("sub-end") end},
	{key = "Q", desc = "Force start to current time", action = function() set_start("time-pos") end},
	{key = "E", desc = "Force end to current time", action = function() set_stop("time-pos") end},
	{key = "s", desc = "Take screenshot at current time", action = function() set_scrot("time-pos") end},
	{key = "a", desc = "Select current line", action = select_sub},
	{key = "A", desc = "Toggle automatic selection", action = toggle_auto_select},
	{key = "k", desc = "Reset selection", action = reset},
	{key = "d", desc = "End selection and enter edit mode", action = function() end},
	{key = "f", desc = "End selection and export immediately", action = function() end},
	{key = "ESC", desc = "Cancel selection", action = cancel},
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
	else time.value = new_val end

	menu:redraw()
end
set_scrot = function(value) set_time(scrot, value) end
set_start = function(value) set_time(start, value) end
set_stop = function(value) set_time(stop, value) end

menu = Menu:new{infos = infos, bindings = bindings}

function begin_sub_selection()
	reset()
	menu:enable()
end

