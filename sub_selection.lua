require "menu"
require "subtitle"

local menu
local reset
local set_start
local set_stop

local subs = {}

local function select_sub()
	local sub = Subtitle:new(
		mp.get_property("sub-text"),
		mp.get_property_number("sub-start"),
		mp.get_property_number("sub-end"))
	table.insert(subs, sub)
	table.sort(subs)
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

local bindings = {
	{key = "q", desc = "Force start to start of active line", action = function() set_start("sub-start") end},
	{key = "e", desc = "Force end to end of active line", action = function() set_stop("sub-end") end},
	{key = "Q", desc = "Force start to current time", action = function() set_start("time-pos") end},
	{key = "E", desc = "Force end to current time", action = function() set_stop("time-pos") end},
	{key = "a", desc = "Select current line", action = select_sub},
	{key = "A", desc = "Toggle automatic selection", action = toggle_auto_select},
	{key = "k", desc = "Reset selection", action = reset},
	{key = "d", desc = "End selection and enter edit mode", action = function() end},
	{key = "f", desc = "End selection and export immediately", action = function() end},
	{key = "ESC", desc = "Cancel selection", action = cancel},
}

local function display_time(value)
	if value >= 0 then return tostring(value)
	else return "{\\i1}not set{\\i0}" end
end
local start = {name = "Start", value = -1, display = display_time}
local stop = {name = "End", value = -1, display = display_time}
local infos = {start, stop}

local function set_time(time, value)
	local new_val
	if type(value) == "string" then
		new_val = mp.get_property_number(value)
	else new_val = value end

	if new_val == nil then time.value = -1
	else time.value = new_val end

	menu:redraw()
end
set_start = function(value) set_time(start, value) end
set_stop = function(value) set_time(stop, value) end

menu = Menu:new{infos = infos, bindings = bindings}

reset = function()
	subs = {}
	set_start()
	set_stop()
end

function begin_sub_selection()
	reset()
	menu:enable()
end

