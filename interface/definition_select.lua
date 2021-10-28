-- Immersive is licensed under the terms of the GNU GPL v3: https://www.gnu.org/licenses/; © 2021 Ben Kerman

local BasicOverlay = require "interface.basic_overlay"
local bus = require "systems.bus"
local cfg = require "systems.config"
local dicts = require "dict.dicts"
local helper = require "utility.helper"
local LineSelect = require "interface.line_select"
local Menu = require "interface.menu"
local menu_stack = require "interface.menu_stack"
local msg = require "systems.message"
local templater = require "systems.templater"

local no_result = {
	ls = BasicOverlay:new("no results")
}

local ltypes = {
	exact = {},
	prefix = {},
	transform = {}
}

local DefinitionSelect = {ltypes = ltypes}
DefinitionSelect.__index = DefinitionSelect

local function lookup_fn(dict, ltype)
	return ({
		[ltypes.exact] = dict.look_up_exact,
		[ltypes.prefix] = dict.look_up_start,
		[ltypes.transform] = dict.look_up_transform
	})[ltype]
end

function DefinitionSelect:new(term, ltype, data)
	local ds

	local bindings = {
		group = "definition_select",
		{
			id = "prev_dict",
			default = "LEFT",
			desc = "Switch to previous dictionary",
			action = function() ds:switch_dict(-1) end
		},
		{
			id = "next_dict",
			default = "RIGHT",
			desc = "Switch to next dictionary",
			action = function() ds:switch_dict(1) end
		},
		{
			id = "add_def",
			default = "Ctrl+ENTER",
			desc = "Add selected definition",
			action = function() ds:add_definition() end
		},
		{
			id = "confirm",
			default = "ENTER",
			desc = "Add selected definition and return",
			action = function() ds:finish() end
		}
	}

	local infos = {
		{
			name = "Dictionary",
			display = function() return dicts.at(ds.dict_index, true).id end
		}
	}

	ds = setmetatable({
		visible = false,
		term = term,
		ltype = ltype,
		dict_index = 1,
		lookups = {},
		active_lu = nil,
		data = data,
		menu = Menu:new{bindings = bindings, infos = infos},
		bus_ref = bus.listen("dict_group_change", function()
			ds.dict_index = 1
			ds.lookups = {}
			ds.active_lu = nil
			ds:look_up()
			if ds.visible then
				ds.menu:redraw()
			end
		end)
	}, DefinitionSelect)

	if not ds:look_up() and dicts.count() == 1 then
		msg.info("no results")
		return nil
	end

	return ds
end

function DefinitionSelect:switch_dict(step)
	local new_index = self.dict_index + step
	if new_index < 1 or dicts.count() < new_index then
		msg.info("no more dictionaries")
	else
		self.dict_index = new_index
		if self.visible then
			self.menu:redraw()
		end
		self:look_up()
	end
end

function DefinitionSelect:look_up()
	local function switch_lu(new_lu)
		if self.active_lu and self.visible then
			self.active_lu.ls:hide()
		end
		self.active_lu = new_lu
		if self.visible then
			self.active_lu.ls:show()
		end
	end

	local existing_lu = self.lookups[self.dict_index]
	if existing_lu then
		switch_lu(existing_lu)
		return true
	end

	local dict_cfg = dicts.at(self.dict_index)
	if not dict_cfg or not dict_cfg.table then
		return false
	end

	local dict = dict_cfg.table
	local result = lookup_fn(dict, self.ltype)(self.term)

	if not result or #result == 0 then
		switch_lu(no_result)
		return false
	end

	local function sel_conv(qdef) return dict.format_quick_def(qdef) end
	local function line_conv(qdef) return helper.short_str(sel_conv(qdef), 40, "⏎") end

	self.lookups[self.dict_index] = {
		res = result,
		ls = LineSelect:new(result, line_conv, sel_conv, nil, 5)
	}
	switch_lu(self.lookups[self.dict_index])

	return true
end

function DefinitionSelect:add_definition()
	if self.data and self.active_lu ~= no_result then
		local dict = dicts.at(self.dict_index).table
		local def = dict.get_definition(self.active_lu.ls:selection().id)
		table.insert(self.data.definitions, def)
	end
end

function DefinitionSelect:finish()
	self:add_definition()
	menu_stack.pop()
end

function DefinitionSelect:show()
	self.menu:show()
	if self.active_lu then
		self.active_lu.ls:show()
	end
	self.visible = true
end

function DefinitionSelect:hide()
	if self.active_lu then
		self.active_lu.ls:hide()
	end
	self.menu:hide()
	self.visible = false
end

function DefinitionSelect:cancel()
	bus.unlisten("dict_group_change", self.bus_ref)
	self:hide()
end

return DefinitionSelect
