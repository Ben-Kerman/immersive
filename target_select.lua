local BasicOverlay = require "basic_overlay"
local cfg = require "config"
local DefinitionSelect = require "definition_select"
local export = require "export"
local ExportMenu = require "export_menu"
local Forvo = require "forvo"
local LineTextSelect = require "line_text_select"
local Menu = require "menu"
local menu_stack = require "menu_stack"
local msg = require "message"
local sys = require "system"

local TargetSelect = {}
TargetSelect.__index = TargetSelect

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
			id = "delete_line",
			default = "DEL",
			desc = "Delete selected line",
			action = function() ts:delete_line() end
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
		word_overlay = BasicOverlay:new(data.definitions, function(defs, ssa_def)
			for _, def in ipairs(defs) do
				table.insert(ssa_def, {
					newline = true,
					def.word
				})
			end
		end, "selection_overlay"),
		menu = Menu:new{bindings = bindings}
	}, TargetSelect)
	ts:start_tgt_sel()
	return ts
end

local function sel_conv(sub) return sub.text:gsub("\n", "⏎") end
local function line_conv(sub) return sub:short() end
function TargetSelect:start_tgt_sel(init_line)
	self.tgt_word_sel = LineTextSelect:new(self.data.subtitles, line_conv, sel_conv, 9, init_line)
	self.tgt_word_sel:show()
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
		msg.error("Failed to get clipboard content")
		return
	end

	lookup(word, false, self.data)
end

function TargetSelect:delete_line()
	if #self.data.subtitles == 1 and not export.verify_times(self.data) then
		msg.warn("Can't delete last sub if times aren't set")
	else self.tgt_word_sel:delete_sel() end
end

function TargetSelect:add_word_audio()
	if #self.data.definitions ~= 0 then
		local word = self.data.definitions[#self.data.definitions].word
		menu_stack.push(Forvo:new(self.data, word))
	else msg.info("No target word selected") end
end

function TargetSelect:show()
	if self.tgt_word_sel then
		self.tgt_word_sel:show()
	end
	self.word_overlay:show()
	self.menu:show()
end

function TargetSelect:hide()
	if self.tgt_word_sel then
		self.tgt_word_sel:hide()
	end
	self.word_overlay:hide()
	self.menu:hide()
end

function TargetSelect:cancel()
	self:hide()
end

function TargetSelect:finish()
	export.execute(self.data)
end

return TargetSelect
