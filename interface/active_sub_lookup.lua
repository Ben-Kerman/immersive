-- Immersive is licensed under the terms of the GNU GPL v3: https://www.gnu.org/licenses/; © 2021 Ben Kerman

local anki = require "systems.anki"
local cfg = require "systems.config"
local DefinitionSelect = require "interface.definition_select"
local helper = require "utility.helper"
local Menu = require "interface.menu"
local menu_stack = require "interface.menu_stack"
local ScreenBlackout = require "interface.screen_blackout"
local sys = require "systems.system"
local TextSelect = require "interface.text_select"

local ActiveSubLookup = {}
ActiveSubLookup.__index = ActiveSubLookup

function create_text_select(txt, raw)
	if not raw then
		txt = helper.apply_substitutions(txt, anki.sentence_substitutions(), true)
	end
	return TextSelect:new((txt:gsub("\n", "\226\128\139")))
end

function ActiveSubLookup:new()
	local sub_text = helper.check_active_sub()
	if not sub_text then return end

	local asl

	local ltypes = DefinitionSelect.ltypes
	local bindings = {
		group = "lookup_active",
		{
			id = "toggle_raw",
			default = "r",
			desc = "Toggle sentence substitutions",
			action = function() asl:toggle_raw() end
		},
		{
			id = "exact",
			default = "ENTER",
			desc = "Look up selected word",
			action = function() asl:lookup(ltypes.exact) end
		},
		{
			id = "partial",
			default = "Shift+ENTER",
			desc = "Look up words starting with selection",
			action = function() asl:lookup(ltypes.prefix) end
		},
		{
			id = "copy",
			default = "c",
			desc = "Copy selection to clipboard",
			action = function()
				local selection = asl.txt_sel:selection(true)
				if not selection then return end

				sys.clipboard_write(selection)
			end
		}
	}

	asl = setmetatable({
		line = sub_text,
		raw = false,
		txt_sel = create_text_select(sub_text, false),
		blackout = cfg.values.active_sub_blackout and ScreenBlackout:new() or nil,
		menu = Menu:new{bindings = bindings}
	}, ActiveSubLookup)
	if asl.blackout then asl.blackout:show() end
	return asl
end

function ActiveSubLookup:lookup(ltype)
	local selection = self.txt_sel:selection(true)
	if not selection then return end

	menu_stack.push(DefinitionSelect:new(selection, ltype))
end

function ActiveSubLookup:toggle_raw()
	self.raw = not self.raw
	self.txt_sel:hide()
	self.txt_sel = create_text_select(self.line, self.raw)
	self.txt_sel:show()
end

function ActiveSubLookup:show()
	self.menu:show()
	self.txt_sel:show()
end

function ActiveSubLookup:hide()
	self.txt_sel:hide()
	self.menu:hide()
end

function ActiveSubLookup:cancel()
	if self.blackout then self.blackout:cancel() end
	self:hide()
end

return ActiveSubLookup
