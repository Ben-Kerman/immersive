local dicts = require "dict.dicts"
local export = require "export"
require "menu"
require "line_select"
require "line_text_select"
require "text_select"

-- forward declarations
local menu

local tgt_word_sel
local lookup_result, def_sel
local data

local function sel_converter(sub) return sub.text end
local function line_renderer(sub) return sub:short() end
local function start_tgt_sel()
	tgt_word_sel = LineTextSelect:new(data.subtitles, sel_converter, line_renderer, 9)
	tgt_word_sel:start()
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
local function start_def_sel(def)
	def_sel = LineSelect:new(lookup_result.defs, sel_def_renderer, def_renderer, nil, 5)
	def_sel:start()
end

local function select_target_def(prefix)
	if def_sel then
		local def = def_sel:finish()
		table.insert(data.definitions, dicts[lookup_result.dict_index].get_definition(def.id))
		lookup_result, def_sel = nil
		start_tgt_sel()
	else
		local selection = tgt_word_sel:finish(true)
		if not selection then return end

		for i, dict in ipairs(dicts) do
			local lookup_fn = prefix and dict.look_up_start or dict.look_up_exact
			local result = lookup_fn(selection)
			if result then
				lookup_result = {dict_index = i, defs = result}
				break
			end
		end

		if lookup_result then start_def_sel()
		else
			mp.osd_message("No entry found for selected word")
			start_tgt_sel()
		end
	end
end

local function delete_line()
	if def_sel then
		mp.osd_message("Not available in definition mode")
		return nil
	end

	local _, index = tgt_word_sel._line_select:finish()
	tgt_word_sel:finish()
	table.remove(data.subtitles, index)
	start_tgt_sel()
end

local function cancel()
	menu:disable()
	if tgt_word_sel then
		tgt_word_sel:finish()
		tgt_word_sel = nil
	end
	if def_sel then
		def_sel:finish()
		def_sel = nil
	end
	lookup_result = nil
	data = nil
end

local function finish()
	local export_data = data
	cancel()
	export.execute(export_data)
end

local function handle_cancel()
	if def_sel then
		def_sel:finish()
		def_sel = nil
		start_tgt_sel()
	else cancel() end
end

local bindings = {
	{
		id = "target_select-lookup",
		default = "ENTER",
		desc = "Look up selected word / Select definition",
		action = select_target_def
	},
	{
		id = "target_select-lookup_partial",
		default = "Shift+ENTER",
		desc = "Look up words starting with selection",
		action = function() select_target_def(true) end
	},
	{
		id = "target_select-delete_line",
		default = "DEL",
		desc = "Delete selected line",
		action = delete_line
	},
	{
		id = "target_select-export",
		default = "f",
		desc = "Export with selected target words",
		action = finish
	},
	{
		id = "target_select-cancel",
		default = "ESC",
		desc = "Cancel definition selection or the card creation process",
		action = handle_cancel
	}
}

menu = Menu:new{bindings = bindings}

local target_select = {}

function target_select.begin(prev_data)
	target_words = {}
	data = prev_data
	data.definitions = {}
	start_tgt_sel()
	menu:enable()
end

return target_select
