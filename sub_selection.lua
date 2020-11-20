require "menu"
require "subtitle"

local bindings = {
	{key = "q", desc = "Set start to start of active line", action = function() end},
	{key = "e", desc = "Set end to end of active line", action = function() end},
	{key = "a", desc = "Select current line", action = function() end},
	{key = "A", desc = "Toggle automatic selection", action = function() end},
	{key = "k", desc = "Reset selection", action = function() end},
	{key = "d", desc = "End selection and enter edit mode", action = function() end},
	{key = "f", desc = "End selection and export immediately", action = function() end},
	{key = "ESC", desc = "Cancel selection", action = function() end},
}

local function display_time(value)
	if value >= 0 then return tostring(value)
	else return "{\\i1}not set{\\i0}" end
end
local start = {name = "Start", value = -1, display = display_time}
local stop = {name = "Stop", value = -1, display = display_time}
local infos = {start, stop}

local menu = Menu:new{infos = infos, bindings = bindings}

local subs = {}

local function insert_sub(sub)
	table.insert(subs, sub)
	table.sort(subs)
end

local function handle_sub_text(_, sub_text)
	if sub_text ~= nil and sub_text ~= "" then
		insert_sub(create_subtitle(sub_text, mp.get_property_number("sub-start"), mp.get_property_number("sub-end")))
	end
end

sub_selection = {}

local auto_select_active = false
function sub_selection.toggle_auto_select()
	if auto_select_active then mp.unobserve_property(handle_sub_text)
	else mp.observe_property("sub-text", "string", handle_sub_text) end
	auto_select_active = not auto_select_active
end
