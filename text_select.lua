local kbds = require "key_bindings"
local ssa = require "ssa"
local utf_8 = require "utf_8"
local util = require "util"

local overlay = mp.create_osd_overlay("ass-events")

local function default_update_handler(self, visible, has_sel, curs_pos, segments)
	if visible then
		overlay.data = ssa.generate(self:default_generator(has_sel, curs_pos, segments))
		overlay:update()
	else overlay:remove() end
end

TextSelect = {}
TextSelect.__index = TextSelect

function TextSelect:default_generator(has_sel, curs_pos, segments)
	local cursor = self:cursor()
	local ssa_definition
	if has_sel then
		ssa_definition = {
			segments[1],
			curs_pos < 0 and cursor or "",
			{
				style = {"text_select", "selection"},
				segments[2]
			},
			curs_pos > 0 and cursor or "",
			segments[3],
		}
	else
		ssa_definition = {
			segments[1],
			cursor,
			segments[2]
		}
	end
	return {
		style = "text_select",
		full_style = self.style_reset,
		ssa_definition
	}
end

function TextSelect:cursor()
	local curs_size = self.font_size * 8
	local pbo = curs_size / 6
	return {
		style = {
			border_x = 0.75,
			border_y = 0,
			shadow_x = 1.5,
			shadow_y = 0,
			primary_color = "FFFFFF",
			border_color = "FFFFFF",
			shadow_color = "000000",
			primary_alpha = "00",
			border_alpha = "00",
			shadow_alpha = "00"
		},
		string.format("{\\p4\\pbo%d}m 0 0 l 1 0 l 1 %d l 0 %d{\\p0}", pbo, curs_size, curs_size)
	}
end

function TextSelect:sel_len()
	return self.sel.to - self.sel.from
end

function TextSelect:reset_sel()
	self.sel.from = 0
	self.sel.to = 0
end

function TextSelect:move_curs(amount, change_sel)
	local new_curs_pos = self.curs_pos + amount
	if new_curs_pos < 1 or #self.cdpts + 1 < new_curs_pos then
		return
	end

	if change_sel then
		if self:sel_len() == 0 then
			self.sel.from = amount > 0 and self.curs_pos or self.curs_pos + amount
			self.sel.to = amount > 0 and self.curs_pos + amount or self.curs_pos
		elseif self.curs_pos == self.sel.to then
			self.sel.to = self.sel.to + amount
		elseif self.curs_pos == self.sel.from then
			self.sel.from = self.sel.from + amount
		end
		if self:sel_len() == 0 then self:reset_sel() end
	else self:reset_sel() end

	self.curs_pos = new_curs_pos

	self:update(true)
end

local whitespace_cps = {
	9, 32, 160, 5760, 8192, 8193, 8194, 8195, 8196, 8197, 8198, 8199, 8200, 8201, 8202, 8239, 8287, 12288
}
local function is_space(cp)
	return not not util.list_find(whitespace_cps, cp)
end

local function classify_cp(cp)
	if not cp then return "nil" end
	if is_space(cp) then return "space" end

	if (0x3041 <= cp and cp <= 0x309f) then return "hiragana" end
	if (0x30a0 <= cp and cp <= 0x30ff) then return "katakana" end
	if (0xff65 <= cp and cp <= 0xff9f) then return "hw-katakana" end

	if (0x0010 <= cp and cp <= 0x0019) or (0x0041 <= cp and cp <= 0x005A) or (0x0061 <= cp and cp <= 0x007A) -- Basic Latin/ASCII
	or (0x00c0 <= cp and cp <= 0x00ff and cp ~= 0x00D7 and cp ~= 0x00F7) -- Latin-1 Supplement
	or (0x0100 <= cp and cp <= 0x017f) -- Latin Extended-A
	or (0x0180 <= cp and cp <= 0x024f) -- Latin Extended-B
	or (0x02b0 <= cp and cp <= 0x02ff) -- Spacing Modifier Letters
	or (0x1e00 <= cp and cp <= 0x1eff) -- Latin Extended Additional
	or (0x2c60 <= cp and cp <= 0x2c7f) -- Latin Extended-C
	or (0xa720 <= cp and cp <= 0xa7ff) -- Latin Extended-D
	or (0xab30 <= cp and cp <= 0xab6f) -- Latin Extended-E
	or (0xFB00 <= cp and cp <= 0xFB06) -- Alphabetic Presentation Forms
	or (0xff10 <= cp and cp <= 0xff19) or (0xff21 <= cp and cp <= 0xff3a) or (0xff41 <= cp and cp <= 0xff5a) -- Halfwidth and Fullwidth Forms
	then return "latin" end

	if  (0x4E00 <= cp and cp <=  0x9FFF) -- CJK Unified Ideographs
	or  (0x3300 <= cp and cp <=  0x33FF) -- CJK Compatibility
	or  (0x3400 <= cp and cp <=  0x4DBF) -- CJK Unified Ideographs Extension A
	or  (0xFE30 <= cp and cp <=  0xFE4F) -- CJK Compatibility Forms
	or  (0xF900 <= cp and cp <=  0xFAFF) -- CJK Compatibility Ideographs
	or (0x20000 <= cp and cp <= 0x2A6DF) -- CJK Unified Ideographs Extension B
	or (0x2A700 <= cp and cp <= 0x2B73F) -- CJK Unified Ideographs Extension C
	or (0x2B740 <= cp and cp <= 0x2B81F) -- CJK Unified Ideographs Extension D
	or (0x2B820 <= cp and cp <= 0x2CEAF) -- CJK Unified Ideographs Extension E
	or (0x2CEB0 <= cp and cp <= 0x2EBEF) -- CJK Unified Ideographs Extension F
	or (0x30000 <= cp and cp <= 0x3134F) -- CJK Unified Ideographs Extension G
	or (0x2F800 <= cp and cp <= 0x2FA1F) -- CJK Compatibility Ideographs Supplement
	then return "ideograph" end

	return "other"
end

function TextSelect:move_curs_word(dir, change_sel)
	local offset = dir < 0 and -1 or 0
	local function get_cp(pos)
		return self.cdpts[pos + offset]
	end

	local bound = dir < 0 and 1 or #self.cdpts + 1

	local new_pos = self.curs_pos
	while is_space(get_cp(new_pos)) and new_pos ~= bound do
		new_pos = new_pos + dir
	end

	local starting_class = classify_cp(get_cp(new_pos))
	for i = new_pos, bound, dir do
		if classify_cp(get_cp(i)) ~= starting_class then
			new_pos = i
			break
		end
	end
	if not new_pos then new_pos = bound end

	self:move_curs(new_pos - self.curs_pos, change_sel)
end

function TextSelect:show()
	kbds.add_bindings(self.bindings)
	self:update(true)
end

function TextSelect:hide()
	kbds.remove_bindings(self.bindings)
	self:update(false)
end

function TextSelect:selection(force)
	if force and self:sel_len() == 0 then
		mp.osd_message("Please select some text")
		return nil
	end
	return utf_8.string(util.list_range(self.cdpts, self.sel.from, self.sel.to - 1))
end

function TextSelect:finish(force)
	local sel = self:selection(force)
	if not sel then return end

	self:hide()
	return sel
end

function TextSelect:new(text, update_handler, font_size, no_style_reset, init_cursor_pos)
	local ts
	ts = {
		cdpts = utf_8.codepoints(text),
		curs_pos = init_cursor_pos and init_cursor_pos or 1,
		sel = {from = 0, to = 0},
		update_handler = update_handler and update_handler or default_update_handler,
		font_size = font_size and font_size or ssa.query{"text_select", "font_size"},
		style_reset = not no_style_reset,
		bindings = {
			group = "text_select",
			{
				id = "prev_char",
				default = "LEFT",
				action = function() ts:move_curs(-1) end,
				repeatable = true
			},
			{
				id = "next_char",
				default = "RIGHT",
				action = function() ts:move_curs(1) end,
				repeatable = true
			},
			{
				id = "prev_word",
				default = "Ctrl+LEFT",
				action = function() ts:move_curs_word(-1) end,
				repeatable = true
			},
			{
				id = "next_word",
				default = "Ctrl+RIGHT",
				action = function() ts:move_curs_word(1) end,
				repeatable = true
			},
			{
				id = "home",
				default = "HOME",
				action = function() ts:move_curs(-ts.curs_pos + 1) end,
				repeatable = true
			},
			{
				id = "end",
				default = "END",
				action = function() ts:move_curs(#ts.cdpts - ts.curs_pos + 1) end,
				repeatable = true
			},
			{
				id = "prev_char_sel",
				default = "Shift+LEFT",
				action = function() ts:move_curs(-1, true) end,
				repeatable = true
			},
			{
				id = "next_char_sel",
				default = "Shift+RIGHT",
				action = function() ts:move_curs(1, true) end,
				repeatable = true
			},
			{
				id = "prev_word_sel",
				default = "Ctrl+Shift+LEFT",
				action = function() ts:move_curs_word(-1, true) end,
				repeatable = true
			},
			{
				id = "next_word_sel",
				default = "Ctrl+Shift+RIGHT",
				action = function() ts:move_curs_word(1, true) end,
				repeatable = true
			},
			{
				id = "home_sel",
				default = "Shift+HOME",
				action = function() ts:move_curs(-ts.curs_pos + 1, true) end,
				repeatable = true
			},
			{
				id = "end_sel",
				default = "Shift+END",
				action = function() ts:move_curs(#ts.cdpts - ts.curs_pos + 1, true) end,
				repeatable = true
			}
		}
	}
	return setmetatable(ts, TextSelect)
end

function TextSelect:update(visible)
	if not visible then
		self:update_handler(false)
		return
	end

	local segments = {}
	local curs_pos
	local has_sel = self:sel_len() ~= 0
	if has_sel then
		table.insert(segments, utf_8.string(util.list_range(self.cdpts, 1, self.sel.from - 1)))
		table.insert(segments, utf_8.string(util.list_range(self.cdpts, self.sel.from, self.sel.to - 1)))
		table.insert(segments, utf_8.string(util.list_range(self.cdpts, self.sel.to, #self.cdpts)))
		curs_pos = self.curs_pos == self.sel.from and -1 or 1
	else
		table.insert(segments, utf_8.string(util.list_range(self.cdpts, 1, self.curs_pos - 1)))
		table.insert(segments, utf_8.string(util.list_range(self.cdpts, self.curs_pos, #self.cdpts)))
		curs_pos = 0
	end
	self:update_handler(true, has_sel, curs_pos, segments)
end

return TextSelect
