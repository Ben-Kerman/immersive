local dicts = require "dict.dicts"
local export = require "export"
require "menu"
require "definition_select"
require "line_select"
require "line_text_select"
require "text_select"

-- forward declarations
local menu

local tgt_word_sel
local def_sel
local data

local function sel_converter(sub) return sub.text end
local function line_renderer(sub) return sub:short() end
local function start_tgt_sel()
	tgt_word_sel = LineTextSelect:new(data.subtitles, sel_converter, line_renderer, 9)
	tgt_word_sel:start()
end

local function select_target_def(prefix)
	if def_sel then
		table.insert(data.definitions, def_sel:finish())
		def_sel = nil
		start_tgt_sel()
	else
		local selection = tgt_word_sel:finish(true)
		if not selection then return end

		tgt_word_sel = nil
		def_sel = DefinitionSelect:new(selection, prefix)
		if not def_sel then
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
		id = "target_select-lookup_exact",
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
