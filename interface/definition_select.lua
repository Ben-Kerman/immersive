-- Immersive is licensed under the terms of the GNU GPL v3: https://www.gnu.org/licenses/; © 2020 Ben Kerman

local cfg = require "systems.config"
local dicts = require "dict.dicts"
local helper = require "utility.helper"
local LineSelect = require "interface.line_select"
local Menu = require "interface.menu"
local menu_stack = require "interface.menu_stack"
local msg = require "systems.message"
local templater = require "systems.templater"

local DefinitionSelect = {}
DefinitionSelect.__index = DefinitionSelect

function DefinitionSelect:new(word, prefix, data)
	local dict_cfg = dicts.active()
	if not dict_cfg or not dict_cfg.table then
		return nil
	end

	local dict = dict_cfg.table
	local result = (prefix and dict.look_up_start or dict.look_up_exact)(word)

	if not result then
		msg.info("no definitions found")
		return
	end

	local ds

	local bindings = {
		group = "definition_select",
		{
			id = "confirm",
			default = "ENTER",
			desc = "Use selected definition",
			action = function() ds:finish() end
		}
	}

	local function sel_conv(qdef) return dict.format_quick_def(qdef) end
	local function line_conv(qdef) return helper.short_str(sel_conv(qdef), 40, "⏎") end

	ds = setmetatable({
		line_select = LineSelect:new(result, line_conv, sel_conv, nil, 5),
		data = data,
		bindings = bindings,
		menu = Menu:new{bindings = bindings},
		lookup_result = {dict = dict, defs = result}
	}, DefinitionSelect)
	return ds
end

function DefinitionSelect:finish(word)
	if self.data then
		local dict = self.lookup_result.dict
		local def = dict.get_definition(self.line_select:selection().id)
		table.insert(self.data.definitions, def)
	end
	menu_stack.pop()
end

function DefinitionSelect:show()
	self.menu:show()
	self.line_select:show()
end

function DefinitionSelect:hide()
	self.line_select:hide()
	self.menu:hide()
end

function DefinitionSelect:cancel()
	self:hide()
end

return DefinitionSelect
