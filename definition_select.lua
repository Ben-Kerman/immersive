local cfg = require "config"
local dicts = require "dict.dicts"
local LineSelect = require "line_select"
local Menu = require "menu"
local menu_stack = require "menu_stack"
local msg = require "message"
local templater = require "templater"

local DefinitionSelect = {}
DefinitionSelect.__index = DefinitionSelect

function DefinitionSelect:new(word, prefix, data)
	local dict = dicts.active().table
	local result = (prefix and dict.look_up_start or dict.look_up_exact)(word)

	if not result then
		msg.info("No definitions found")
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

	ds = setmetatable({
		_line_select = LineSelect:new(result, dict.format_quick_def, nil, nil, 5),
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
		local def = dict.get_definition(self._line_select:selection().id)
		table.insert(self.data.definitions, def)
	end
	menu_stack.pop()
end

function DefinitionSelect:show()
	self.menu:show()
	self._line_select:show()
end

function DefinitionSelect:hide()
	self._line_select:hide()
	self.menu:hide()
end

function DefinitionSelect:cancel()
	self:hide()
end

return DefinitionSelect
