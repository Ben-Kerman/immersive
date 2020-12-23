local cfg = require "config"
local dicts = require "dict.dicts"
local LineSelect = require "line_select"
local Menu = require "menu"
local menu_stack = require "menu_stack"
local msg = require "message"
local templater = require "templater"

local function def_conv(def)
	return templater.render(cfg.values.quick_def_template, {
		readings = {data = def.readings},
		variants = {data = def.variants},
		definitions = {data = def.defs}
	})
end

local DefinitionSelect = {}
DefinitionSelect.__index = DefinitionSelect

function DefinitionSelect:new(word, prefix, data)
	local result, dict_index
	for i, dict in ipairs(dicts.get()) do
		local lookup_fn = prefix and dict.look_up_start or dict.look_up_exact
		result = lookup_fn(word)
		if result then
			dict_index = i
			break
		end
	end

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
		_line_select = LineSelect:new(result, def_conv, nil, nil, 5),
		data = data,
		bindings = bindings,
		menu = Menu:new{bindings = bindings},
		lookup_result = {dict_index = dict_index, defs = result}
	}, DefinitionSelect)
	return ds
end

function DefinitionSelect:finish(word)
	if self.data then
		local dict = dicts.get()[self.lookup_result.dict_index]
		local def = dict.get_definition(self._line_select:finish().id)
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
