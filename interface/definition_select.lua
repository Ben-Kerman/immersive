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

	local function inTable(tbl, item)
	    for key, value in pairs(tbl) do
	        if value == item then return true end
            if key == item then return true end
	    end
	    return false
	end
	
    local function starts_with(str, start)
       return str:sub(1, #start) == start
    end

	local function ends_with(str, ending)
	   return ending == "" or str:sub(-#ending) == ending
	end

    local function deconjugate(term, conjugations)
	    local deconjugations = {term}
        if conjugations == "" then 
            return deconjugations 
        else
            local conjugations = helper.parse_json_file(conjugations)
            for k,v in pairs(conjugations) do
                if ends_with(term, v['inflected'])
                then
                    for x,y in pairs(v['dict']) do
                        local deinflected = term:gsub(v['inflected'],y)
                        -- prefix function not tested
                        if inTable(v,'prefix') then
                            local prefix = v['prefix']
                            if starts_with(deinflected, prefix) == true then
                                deprefixedDeinflected=string.sub(deinflected, string.len(v['prefix'])+1)
                                if inTable(deconjugations, deprefixedDeinflected) == false then
                                    table.insert(deconjugations, deprefixedDeinflected)
                                end
                            end
                        end
                        if inTable(deconjugations, deinflected) == false then
                            table.insert(deconjugations, deinflected)
                        end
                    end
                end
            end
	        return deconjugations
        end
	end 

    local function lookup_deconjugated(deconjugations)
        local result = {}
        for num,deconjugatedword in pairs(deconjugations) do
            curresult = (prefix and dict.look_up_start or dict.look_up_exact)(deconjugatedword)
            if curresult then
                for k,v in pairs(curresult) do
                    table.insert(result,v)
                end
            end
        end
        return result
    end

    local result = lookup_deconjugated(deconjugate(word,cfg.values.conjugation_dict))

	if next(result) == nil then
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
