local export = require "export"
local Menu = require "menu"
local SelectionOverlay = require "selection_overlay"
local Subtitle = require "subtitle"
local util = require "util"
local target_select = require "target_select"

local SubSelect = {}
SubSelect.__index = SubSelect

function SubSelect:select_sub()
	local sub_text = mp.get_property("sub-text")
	local sub_start = mp.get_property_number("sub-start")
	local sub_en = mp.get_property_number("sub-end")
	if sub_text == nil or sub_text == "" then
		mp.osd_message("No active subtitle line, nothing selected")
	else
		local sub = Subtitle:new(sub_text, sub_start, sub_en)

		local subtitles = self.data.subtitles
		-- check for end time, lines with identical start times get combined by mpv
		if not util.list_find(subtitles, function(s) return s.stop == sub.stop end) then
			table.insert(subtitles, sub)
			table.sort(subtitles)
		end
		self.sel_overlay:redraw()
	end
end

local auto_select_active = false
function SubSelect:toggle_auto_select()
	if auto_select_active then
		mp.unobserve_property(self.sub_observer)
		self.sub_observer = nil
	else
		self.sub_observer = function(_, sub_text)
			if sub_text ~= nil and sub_text ~= "" then
				self:select_sub()
			end
		end
		mp.observe_property("sub-text", "string", self.sub_observer)
	end
	auto_select_active = not auto_select_active
end

local function display_time(value)
	if value >= 0 then return tostring(value)
	else return "{\\i1}auto{\\i0}" end
end
local function new_infos()
	return {
		{name = "Screenshot", value = -1, display = display_time},
		{name = "Start", value = -1, display = display_time},
		{name = "End", value = -1, display = display_time}
	}
end

local function set_time(self, time, value)
	local new_val
	if type(value) == "string" then
		new_val = mp.get_property_number(value)
	else new_val = value end

	if new_val == nil then time.value = -1
	elseif new_val == time.value then time.value = -1
	else time.value = new_val end

	self.menu:redraw()
end
function SubSelect:set_scrot(value)
	set_time(self, self.infos[1], value)
end
function SubSelect:set_start(value)
	set_time(self, self.infos[2], value)
end
function SubSelect:set_stop(value)
	set_time(self, self.infos[3], value)
end

function SubSelect:reset()
	self.data = {subtitles = {}}
	self.sel_overlay.selection = self.data.subtitles
	self.sel_overlay:redraw()
	self:set_scrot()
	self:set_start()
	self:set_stop()
end

function SubSelect:finalize_data()
	self.data.times = {
		scrot = self.infos[1].value,
		start = self.infos[2].value,
		stop = self.infos[3].value
	}
	return self.data
end

function SubSelect:start_tgt_sel()
	self:hide()
	target_select.begin(self:finalize_data())
end
function SubSelect:start_export()
	self:hide()
	export.execute(self:finalize_data())
end

function SubSelect:new()
	local ss
	ss = {
		data = {subtitles = {}},
		infos = new_infos(),
	}
	ss.bindings = {
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
	ss.sel_overlay = SelectionOverlay:new(ss.data.subtitles)
	ss.menu = Menu:new{infos = ss.infos, bindings = ss.bindings}
	setmetatable(ss, SubSelect)
	ss:show()
	return ss
end

function SubSelect:hide()
	self.menu:disable()
	self.sel_overlay:remove()
end

function SubSelect:show()
	self.menu:enable()
	self.sel_overlay:redraw()
end

function SubSelect:cancel()
	mp.unobserve_property(self.sub_observer)
	self:hide()
end

return SubSelect
