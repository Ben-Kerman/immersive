local BasicOverlay = require "basic_overlay"
local cfg = require "config"
local export = require "export"
local helper = require "helper"
local Menu = require "menu"
local menu_stack = require "menu_stack"
local msg = require "message"
local player = require "player"
local Subtitle = require "subtitle"
local TargetSelect = require "target_select"
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
		msg.info("no active subtitle line, nothing selected")
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

local autosel_active = cfg.values.enable_autoselect
function SubSelect:get_autosel()
	if cfg.values.global_autoselect then
		return autosel_active
	else return self.autosel_active end
end

function SubSelect:set_autosel(val)
	if cfg.values.global_autoselect then
		autosel_active = val
	else self.autosel_active = val end
end

function SubSelect:toggle_autosel()
	if self:get_autosel() then
		self:unobserve_subs()
	else self:observe_subs() end
	self:set_autosel(not self:get_autosel())
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

function SubSelect:display_time(var_name, default)
	local value = self.data.times[var_name]
	if value >= 0 then
		return helper.format_time(value)
	else
		return {
			style = {"menu_info", "unset"},
			default
		}
	end
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

-- AUDIO PREVIEW --

function SubSelect:preview_audio()
	if export.verify(self.data, true) then
		local was_paused = mp.get_property_bool("pause")
		mp.set_property_bool("pause", true)

		local start, stop = export.resolve_times(self.data)
		player.play(helper.current_path_abs(), start, stop)

		mp.add_timeout(stop - start + 0.15, function()
			mp.set_property_bool("pause", was_paused)
		end)
	end
end

-- INIT/DEINIT  --

local function new_data()
	return {
		level = 1,
		subtitles = {},
		times = helper.default_times()
	}
end

function SubSelect:reset()
	self.data = new_data()
	self.sel_overlay.data = self.data.subtitles
	self.sel_overlay:redraw()
	self.menu:redraw()
end

function SubSelect:start_tgt_sel()
	if export.verify(self.data, true) then
		menu_stack.push(TargetSelect:new(self.data, 2))
	end
end
function SubSelect:start_export()
	if export.verify(self.data, true) then
		export.execute(self.data)
	end
end

function SubSelect:new()
	local ss

	local infos = {
		{
			name = "Screenshot",
			display = function() return ss:display_time("scrot", "current frame") end
		},
		{
			name = "Start",
			display = function() return ss:display_time("start", "selection start") end
		},
		{
			name = "End",
			display = function() return ss:display_time("stop", "selection end") end
		},
		{
			name = "Autoselect",
			display = function() return helper.display_bool(ss:get_autosel()) end
		}
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
			id = "toggle_autoselect",
			default = "A",
			desc = "Toggle automatic selection",
			action = function() ss:toggle_autosel() end
		},
		{
			id = "preview_audio",
			default = "p",
			desc = "Preview selection audio",
			action = function() ss:preview_audio() end
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
		}
	}
	local data = new_data()

	local sel_overlay = BasicOverlay:new(data.subtitles, function(data, ssa_definition)
		for _, sub in ipairs(data) do
			table.insert(ssa_definition, {
				newline = true,
				helper.short_str(sub.text, 16, "⏎")
			})
		end
	end, "selection_overlay")

	ss = setmetatable({
		data = data,
		autosel = cfg.values.enable_autoselect,
		infos = infos,
		bindings = bindings,
		sel_overlay = sel_overlay,
		menu = Menu:new{infos = infos, bindings = bindings}
	}, SubSelect)
	return ss
end

-- COMMON FUNCTIONS --

function SubSelect:show()
	if self:get_autosel() then
		self:observe_subs()
	end
	self.menu:show()
	self.sel_overlay:show()
end

function SubSelect:hide()
	if self:get_autosel() then
		self:unobserve_subs()
	end
	self.menu:hide()
	self.sel_overlay:hide()
end

function SubSelect:cancel()
	self:unobserve_subs()
	self:hide()
end

return SubSelect
