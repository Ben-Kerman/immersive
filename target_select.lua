local DefinitionSelect = require "definition_select"
local export = require "export"
local forvo = require "forvo"
local LineTextSelect = require "line_text_select"
local Menu = require "menu"

local TargetSelect = {}
TargetSelect.__index = TargetSelect

function TargetSelect:new(data)
	local ts

	local bindings = {
		group = "target_select",
		{
			id = "lookup_exact",
			default = "ENTER",
			desc = "Look up selected word / Select definition",
			action = function() ts:select_target_def() end
		},
		{
			id = "lookup_partial",
			default = "Shift+ENTER",
			desc = "Look up words starting with selection",
			action = function() ts:select_target_def(true) end
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
			id = "cancel",
			default = "ESC",
			desc = "Cancel definition selection or the card creation process",
			action = function() ts:handle_cancel() end
		}
	}

	data.definitions = {}
	ts = setmetatable({
		data = data,
		menu = Menu:new{bindings = bindings}
	}, TargetSelect)
	ts:show()
	ts:start_tgt_sel()
end

local function sel_conv(sub) return sub.text end
local function line_conv(sub) return sub:short() end
function TargetSelect:start_tgt_sel()
	self.tgt_word_sel = LineTextSelect:new(self.data.subtitles, line_conv, sel_conv, 9)
	self.tgt_word_sel:show()
end

function TargetSelect:select_target_def(prefix)
	if self.def_sel then
		table.insert(self.data.definitions, self.def_sel:finish())
		self.def_sel = nil
		self:start_tgt_sel()
	else
		local selection = self.tgt_word_sel:finish(true)
		if not selection then
			mp.osd_message("No word selected")
			return nil
		end

		self.tgt_word_sel = nil
		self.def_sel = DefinitionSelect:new(selection, prefix)
		if not self.def_sel then
			mp.osd_message("No entry found for selected word")
			self:start_tgt_sel()
		end
	end
end

function TargetSelect:delete_line()
	if self.def_sel then
		mp.osd_message("Not available in definition mode")
		return nil
	end

	local _, index = self.tgt_word_sel._line_select:finish()
	self.tgt_word_sel:finish()
	table.remove(self.data.subtitles, index)
	self:start_tgt_sel()
end

function TargetSelect:add_word_audio()
	if #self.data.definitions ~= 0 then
		self.menu:disable()
		if self.tgt_word_sel then self.tgt_word_sel:finish() end
		if self.def_sel then self.def_sel:finish() end
		self.tgt_word_sel, self.def_sel = nil
		forvo.begin(self.data.definitions[#self.data.definitions].word, function(prn)
			self.data.word_audio_file = prn.audio_file
			self.menu:enable()
			self:start_tgt_sel()
		end)
	else
		mp.osd_message("No target word selected")
	end
end

function TargetSelect:handle_cancel()
	if self.def_sel then
		self.def_sel:finish()
		self.def_sel = nil
		self:start_tgt_sel()
	else self:cancel() end
end

function TargetSelect:show()
	if self.tgt_word_sel then
		self.tgt_word_sel:show()
	end
	if self.def_sel then
		self.def_sel:show()
	end
	self.menu:enable()
end

function TargetSelect:hide()
	if self.tgt_word_sel then
		self.tgt_word_sel:hide()
	end
	if self.def_sel then
		self.def_sel:hide()
	end
	self.menu:disable()
end

function TargetSelect:cancel()
	self:hide()
end

function TargetSelect:finish()
	self:hide()
	export.execute(self.data)
end

return TargetSelect
