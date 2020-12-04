local dicts = require "dict.dicts"
local helper = require "helper"
require "menu"
require "line_select"
require "text_select"

local line_sel, tgt_word_sel
local lookup_result, def_sel
local sub_selection, timestamps
local target_words = {}

local function target_select_update_handler(has_sel, curs_index, segments)
	if has_sel then
		table.insert(segments, 2, "{\\u1}")
		table.insert(segments, 4, "{\\u0}")
	end

	if curs_index < 0 then
		curs_index = #segments + curs_index + 1
	end
	table.insert(segments, curs_index, TextSelect.default_cursor(mp.get_property_number("osd-font-size")))
	table.insert(segments, curs_index + 1, "{\\b1}")
	table.insert(segments, 1, "{\\b1}")
	table.insert(segments, "{\\b0}")

	local ssa_str = table.concat(segments)

	if line_sel then
		line_sel.sel_renderer = function() return ssa_str end
		line_sel:update()
	end
end

local function line_renderer(sub)
	return sub:short()
end

local active_sub
local function update_handler(sub)
	if sub ~= active_sub then
		active_sub = sub
		if tgt_word_sel then tgt_word_sel:finish() end
		tgt_word_sel = TextSelect:new(sub.text, target_select_update_handler)
		tgt_word_sel:start()
	end
end

local function initialize_target_select()
	line_sel = LineSelect:new(sub_selection, nil, line_renderer, update_handler)
	update_handler(sub_selection[1])
	line_sel:start()
end

local function format_def(def)
	local readings = table.concat(def.readings, "・")
	local variants
	if def.variants then
		variants = "【" .. table.concat(def.variants, "・") .. "】"
	else variants = "" end
	local defs = table.concat(def.defs, "; ")
	return string.format("%s%s: %s", readings, variants, defs)
end

local function def_renderer(def)
	return format_def(def)
end

local function sel_def_renderer(def)
	return "{\\b1}" .. format_def(def) .. "{\\b0}"
end

local function select_target_def(prefix)
	if def_sel then
		local def = def_sel:finish()
		def_sel = nil
		table.insert(target_words, dicts[lookup_result.dict_index].get_definition(def.id))
		initialize_target_select()
	else
		local selection = tgt_word_sel:finish(true)
		if not selection then return end

		line_sel:finish()
		line_sel = nil

		for i, dict in ipairs(dicts) do
			local lookup_fn = prefix and dict.look_up_start or dict.look_up_exact
			local result = lookup_fn(selection)
			if result then
				lookup_result = {dict_index = i, defs = result}
				break
			end
		end

		if lookup_result then
			def_sel = LineSelect:new(lookup_result.defs, sel_def_renderer, def_renderer)
			def_sel:start()
		else
			-- TODO handle error
		end
	end
end

local bindings = {
	{key = "ENTER", desc = "Look up selected word / Select definition", action = select_target_def},
	{key = "Shift+ENTER", desc = "Look up words starting with selection", action = function() select_target_def(true) end},
	{key = "f", desc = "Export with selected target words", action = function() end}
}

local menu = Menu:new{bindings = bindings}

local target_select = {}

function target_select.begin(sub_sel, times)
	target_words = {}
	sub_selection, timestamps = sub_sel, times
	initialize_target_select()
	menu:enable()
end

return target_select
