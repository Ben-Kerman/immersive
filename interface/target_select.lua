-- Immersive is licensed under the terms of the GNU GPL v3: https://www.gnu.org/licenses/; © 2020 Ben Kerman

local BasicOverlay = require "interface.basic_overlay"
local cfg = require "systems.config"
local DefinitionSelect = require "interface.definition_select"
local export = require "systems.export"
local ExportMenu = require "interface.export_menu"
local Forvo = require "interface.forvo"
local helper = require "utility.helper"
local LineTextSelect = require "interface.line_text_select"
local Menu = require "interface.menu"
local menu_stack = require "interface.menu_stack"
local msg = require "systems.message"
local ScreenBlackout = require "interface.screen_blackout"
local sys = require "systems.system"

local TargetSelect = {}
TargetSelect.__index = TargetSelect

local function sel_conv(sub) return (sub.text:gsub("\n", "\226\128\139")) end
local function line_conv(sub) return helper.short_str(sub.text, 24, "\226\128\139") end

function TargetSelect:new(data, menu_lvl)
	local ts

	local bindings = {
		group = "target_select",
		{
			id = "lookup_exact",
			default = "ENTER",
			desc = "Look up selected word",
			action = function() ts:select_target_def(false) end
		},
		{
			id = "lookup_partial",
			default = "Shift+ENTER",
			desc = "Look up words starting with selection",
			action = function() ts:select_target_def(true) end
		},
		{
			id = "lookup_clipboard",
			default = "v",
			desc = "Look up word from clipboard",
			action = function() ts:clipboard_lookup() end
		},
		{
			id = "add_word_audio",
			default = "a",
			desc = "Add Forvo audio for target word",
			action = function() ts:add_word_audio() end
		},
		{
			id = "add_word_audio_direct",
			default = "A",
			desc = "Add Forvo audio from current selection",
			action = function() ts:add_word_audio_direct() end
		},
		{
			id = "delete_line",
			default = "DEL",
			desc = "Delete selected line",
			action = function() ts:delete_line() end
		},
		{
			id = "preview_audio",
			default = "p",
			desc = "Preview selection audio",
			action = function() helper.preview_audio(ts.data) end
		},
		{
			id = "undo_selection",
			default = "BS",
			desc = "Delete last target word",
			action = function()
				table.remove(ts.data.definitions)
				ts.word_overlay:redraw()
			end
		},
		{
			id = "export",
			default = "f",
			desc = "Export with selected target words",
			action = function() ts:finish() end
		},
		{
			id = "export_menu",
			default = "F",
			desc = "Export with selected target words using menu",
			action = function() menu_stack.push(ExportMenu:new(ts.data)) end
		}
	}

	if not data.definitions then
		data.definitions = {}
	end
	data.level = data.level and (data.level + 1) or 1
	ts = setmetatable({
		data = data,
		menu_lvl = menu_lvl and menu_lvl or 1,
		tgt_word_sel = LineTextSelect:new(data.subtitles, line_conv, sel_conv, 9, init_line),
		word_overlay = BasicOverlay:new(data.definitions, function(defs, ssa_def)
			for _, def in ipairs(defs) do
				table.insert(ssa_def, {
					newline = true,
					def.word
				})
			end
		end, "selection_overlay"),
		blackout = cfg.values.target_select_blackout and ScreenBlackout:new() or nil,
		menu = Menu:new{bindings = bindings}
	}, TargetSelect)
	if ts.blackout then ts.blackout:show() end
	return ts
end

local function lookup(word, prefix, data)
	menu_stack.push(DefinitionSelect:new(word, prefix, data))
end

function TargetSelect:select_target_def(prefix)
	if cfg.values.max_targets ~= 0 and #self.data.definitions >= cfg.values.max_targets then
		msg.info("configured target word limit (" .. cfg.values.max_targets .. ") reached")
		return
	end

	local selection = self.tgt_word_sel:selection(true)
	if not selection then return end

	lookup(selection, prefix, self.data)
end

function TargetSelect:clipboard_lookup()
	local word = sys.clipboard_read()
	if not word then
		msg.error("failed to get clipboard content")
		return
	end

	lookup(word, false, self.data)
end

function TargetSelect:delete_line()
	if #self.data.subtitles == 1 and not export.verify_times(self.data) then
		msg.warn("can't delete last sub if times aren't set")
	else self.tgt_word_sel:delete_sel() end
end

function TargetSelect:add_word_audio()
	if #self.data.definitions ~= 0 then
		local word = self.data.definitions[#self.data.definitions].word
		menu_stack.push(Forvo:new(self.data, word))
	else msg.info("no target word selected") end
end

function TargetSelect:add_word_audio_direct()
	local word = self.tgt_word_sel:selection(true)
	if word then
		menu_stack.push(Forvo:new(self.data, word))
	end
end

function TargetSelect:show()
	self.tgt_word_sel:show()
	self.word_overlay:show()
	self.menu:show()
end

function TargetSelect:hide()
	self.tgt_word_sel:hide()
	self.word_overlay:hide()
	self.menu:hide()
end

function TargetSelect:cancel()
	if self.blackout then self.blackout:cancel() end
	self:hide()
end

function TargetSelect:finish()
	export.execute(self.data)
end

return TargetSelect
