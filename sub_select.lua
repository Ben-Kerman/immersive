local export = require "export"
local Menu = require "menu"
local SelectionOverlay = require "selection_overlay"
local Subtitle = require "subtitle"
local target_select = require "target_select"
local util = require "util"

local SubSelect = {}
SubSelect.__index = SubSelect

-- SUB SELECTION --

function SubSelect:select_sub()
	local sub_text = mp.get_property("sub-text")
	local sub_start = mp.get_property_number("sub-start")
	local sub_end = mp.get_property_number("sub-end")
	local sub_delay = mp.get_property_number("sub-delay")
	if sub_text == nil or sub_text == "" then
		mp.osd_message("No active subtitle line, nothing selected")
	else
		local sub = Subtitle:new(sub_text, sub_start, sub_end, sub_delay)

		local subtitles = self.data.subtitles
		-- check for end time, lines with identical start times get combined by mpv
		if not util.list_find(subtitles, function(s) return s.stop == sub.stop end) then
			table.insert(subtitles, sub)
			table.sort(subtitles)
		end
		self.sel_overlay:redraw()
	end
end

function SubSelect:toggle_auto_select()
	if self.autoselect.value then
		self:unobserve_subs()
	else self:observe_subs() end
	self.autoselect.value = not self.autoselect.value
	self.menu:redraw()
end

function SubSelect:observe_subs()
	self.sub_observer = function(_, sub_text)
		if sub_text ~= nil and sub_text ~= "" then
			self:select_sub()
		end
	end
	mp.observe_property("sub-text", "string", self.sub_observer)
end

function SubSelect:unobserve_subs()
	if self.sub_observer then
		mp.unobserve_property(self.sub_observer)
		self.sub_observer = nil
	end
end

-- TIME DISPLAY --

function SubSelect:display_time(var_name)
	local value = self.data.times[var_name]
	if value >= 0 then return tostring(value)
	else return "{\\i1}auto{\\i0}" end
end

local function set_time(self, var_name, value)
	local new_val
	if type(value) == "string" then
		new_val = mp.get_property_number(value)
	else new_val = value end

	if new_val == nil or new_val == self.data.times[var_name] then
		self.data.times[var_name] = -1
	else self.data.times[var_name] = new_val end

	self.menu:redraw()
end
function SubSelect:set_scrot(value)
	set_time(self, "scrot", value)
end
function SubSelect:set_start(value)
	set_time(self, "start", value)
end
function SubSelect:set_stop(value)
	set_time(self, "stop", value)
end

-- INIT/DEINIT  --

local function new_data()
	return {
		subtitles = {},
		times = {
			scrot = -1,
			start = -1,
			stop = -1
		}
	}
end

function SubSelect:reset()
	self.data = new_data()
	self.sel_overlay.selection = self.data.subtitles
	self.sel_overlay:redraw()
	self.menu:redraw()
end

function SubSelect:start_tgt_sel()
	self:hide()
	target_select.begin(self.data)
end
function SubSelect:start_export()
	self:hide()
	export.execute(self.data)
end

function SubSelect:new()
	local ss

	local autoselect = {
		name = "Autoselect",
		value = false,
		display = function(val) return val and "on" or "off" end
	}
	local infos = {
		{
			name = "Screenshot",
			display = function() return ss:display_time("scrot") end
		},
		{
			name = "Start",
			display = function() return ss:display_time("start") end
		},
		{
			name = "End",
			display = function() return ss:display_time("stop") end
		},
		autoselect
	}
	local bindings = {
		group = "sub_select",
		{
			id = "set_start_sub",
			default = "q",
			desc = "Force start to start of active line",
			action = function() ss:set_start("sub-start") end
		},
		{
			id = "set_end_sub",
			default = "e",
			desc = "Force end to end of active line",
			action = function() ss:set_stop("sub-end") end
		},
		{
			id = "set_start_time_pos",
			default = "Q",
			desc = "Force start to current time",
			action = function() ss:set_start("time-pos") end
		},
		{
			id = "set_end_time_pos",
			default = "E",
			desc = "Force end to current time",
			action = function() ss:set_stop("time-pos") end
		},
		{
			id = "set_scrot",
			default = "s",
			desc = "Take screenshot at current time",
			action = function() ss:set_scrot("time-pos") end
		},
		{
			id = "select_line",
			default = "a",
			desc = "Select current line",
			action = function() ss:select_sub() end
		},
		{
			id = "toggle_auto_select",
			default = "A",
			desc = "Toggle automatic selection",
			action = function() ss:toggle_auto_select() end
		},
		{
			id = "reset",
			default = "k",
			desc = "Reset selection",
			action = function() ss:reset() end
		},
		{
			id = "start_target_select",
			default = "d",
			desc = "End line selection and enter target selection",
			action = function() ss:start_tgt_sel() end
		},
		{
			id = "instant_export",
			default = "f",
			desc = "End line selection and export immediately",
			action = function() ss:start_export() end
		},
		{
			id = "cancel",
			default = "ESC",
			desc = "Cancel selection",
			action = function() ss:cancel() end
		}
	}
	local data = new_data()

	ss = setmetatable({
		data = data,
		autoselect = autoselect,
		infos = infos,
		bindings = bindings,
		sel_overlay = SelectionOverlay:new(data.subtitles),
		menu = Menu:new{infos = infos, bindings = bindings}
	}, SubSelect)
	ss:show()
	return ss
end

-- COMMON FUNCTIONS --

function SubSelect:hide()
	if self.autoselect.value then
		self:unobserve_subs()
	end
	self.menu:disable()
	self.sel_overlay:remove()
end

function SubSelect:show()
	if self.autoselect.value then
		self:observe_subs()
	end
	self.menu:enable()
	self.sel_overlay:redraw()
end

function SubSelect:cancel()
	self:unobserve_subs()
	self:hide()
end

return SubSelect
