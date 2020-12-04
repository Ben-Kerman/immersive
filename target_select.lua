require "line_select"
require "text_select"

local line_sel, tgt_word_sel, tgt_word_sel_ssa
local sub_selection, timestamps

local function target_select_update_handler(has_sel, curs_index, segments)
	if has_sel then
		table.insert(segments, 2, "{\\u1}")
	end

	if curs_index < 0 then
		curs_index = #segments + curs_index + 1
	end
	table.insert(segments, curs_index, TextSelect.default_cursor(mp.get_property_number("osd-font-size")))
	table.insert(segments, curs_index + 1, "{\\b1}")
	table.insert(segments, 1, "{\\b1}")
	table.insert(segments, "{\\b0}")

	tgt_word_sel_ssa = table.concat(segments)
	if line_sel then line_sel:update() end
end

local function sel_renderer()
	return tgt_word_sel_ssa
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
	update_handler(sub_selection[1])
	line_sel = LineSelect:new(sub_selection, sel_renderer, line_renderer, update_handler)
	line_sel:start()
end

local bindings = {
	{key = "ENTER", desc = "Look up selected word", action = function() end},
	{key = "Shift+ENTER", desc = "Look up words starting with selection", action = function() end},
	{key = "f", desc = "Export with selected target words", action = function() end}
}

local target_select = {}

function target_select.begin(sub_sel, times)
	target_words = {}
	sub_selection, timestamps = sub_sel, times
	initialize_target_select()
end

return target_select
