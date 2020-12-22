local DefinitionSelect = require "definition_select"
local helper = require "helper"
local Menu = require "menu"
local menu_stack = require "menu_stack"
local TextSelect = require "text_select"

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
		}
	}

	asl = setmetatable({
		txt_sel = TextSelect:new(sub_text),
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
	self.txt_sel:show()
	self.menu:show()
end

function ActiveSubLookup:hide()
	self.txt_sel:hide()
	self.menu:hide()
end

function ActiveSubLookup:cancel()
	self:hide()
end

return ActiveSubLookup
