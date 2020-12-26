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

function ActiveSubLookup:new()
	local sub_text = helper.check_active_sub()
	if not sub_text then return end

	local asl

	local bindings = {
		group = "lookup_active",
		{
			id = "exact",
			default = "ENTER",
			desc = "Look up selected word",
			action = function() asl:lookup(false) end
		},
		{
			id = "partial",
			default = "Shift+ENTER",
			desc = "Look up words starting with selection",
			action = function() asl:lookup(true) end
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
		txt_sel = TextSelect:new((sub_text:gsub("\n", "\226\128\139"))),
		blackout = cfg.values.active_sub_blackout and ScreenBlackout:new() or nil,
		menu = Menu:new{bindings = bindings}
	}, ActiveSubLookup)
	return asl
end

function ActiveSubLookup:lookup(prefix)
	local selection = self.txt_sel:selection(true)
	if not selection then return end

	menu_stack.push(DefinitionSelect:new(selection, prefix))
end

function ActiveSubLookup:show()
	self.blackout:show()
	self.menu:show()
	self.txt_sel:show()
end

function ActiveSubLookup:hide()
	self.txt_sel:hide()
	self.menu:hide()
	self.blackout:hide()
end

function ActiveSubLookup:cancel()
	self:hide()
end

return ActiveSubLookup
