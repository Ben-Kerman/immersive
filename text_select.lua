local utf_8 = require "utf_8"
local util = require "util"
local mputil = require "mp.utils"

local overlay = mp.create_osd_overlay("ass-events")

local function default_update_handler(has_sel, curs_index, segments)
	if has_sel then
		table.insert(segments, 2, "{\\u1}")
		table.insert(segments, 4, "{\\u0}")
	end

	if curs_index < 0 then
		curs_index = #segments + curs_index + 1
	end
	table.insert(segments, curs_index, TextSelect.default_cursor(mp.get_property_number("osd-font-size")))

	table.insert(segments, 1, "{\\an5}")

	overlay.data = table.concat(segments)
	overlay:update()
end

TextSelect = {}
TextSelect.__index = TextSelect

function TextSelect.default_cursor(font_size)
	local curs_size = font_size * 8
	local pbo = curs_size / 6
	local curs_style =
		[[\r\1a&H00&\3a&H00&\4a&H00&\1c&Hffffff&\3c&Hffffff&\4c&H000000&\xbord0.75\ybord0\xshad1.5\yshad0]]
	return string.format("{%s\\p4\\pbo%d}m 0 0 l 1 0 l 1 %d l 0 %d{\\p0\\r}", curs_style, pbo, curs_size, curs_size)
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

	self:update()
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

function TextSelect:start()
	for i, binding in ipairs(self.bindings) do
		mp.add_forced_key_binding(binding.key, "_ankisubs-text_select_binding-" .. i, binding.action, {repeatable = true})
	end
	self:update()
end

function TextSelect:finish(force_sel)
	if force_sel and self:sel_len() == 0 then
		mp.osd_message("Please select some text")
		return nil
	end
	for i, binding in ipairs(self.bindings) do
		mp.remove_key_binding("_ankisubs-text_select_binding-" .. i)
	end
	overlay:remove()
	return utf_8.string(util.list_range(self.cdpts, self.sel.from, self.sel.to - 1))
end

function TextSelect:new(text, update_handler, init_cursor_pos)
	local ts
	ts = {
		cdpts = utf_8.codepoints(text),
		curs_pos = init_cursor_pos and init_cursor_pos or 1,
		sel = {from = 0, to = 0},
		update_handler = update_handler and update_handler or default_update_handler,
		bindings = {
			{key = "LEFT", action = function() ts:move_curs(-1) end},
			{key = "RIGHT", action = function() ts:move_curs(1) end},
			{key = "Ctrl+LEFT", action = function() ts:move_curs_word(-1) end},
			{key = "Ctrl+RIGHT", action = function() ts:move_curs_word(1) end},
			{key = "Shift+LEFT", action = function() ts:move_curs(-1, true) end},
			{key = "Shift+RIGHT", action = function() ts:move_curs(1, true) end},
			{key = "Ctrl+Shift+LEFT", action = function() ts:move_curs_word(-1, true) end},
			{key = "Ctrl+Shift+RIGHT", action = function() ts:move_curs_word(1, true) end}
		}
	}
	return setmetatable(ts, TextSelect)
end

function TextSelect:update()
	local segments = {}
	local curs_index
	local has_sel = self:sel_len() ~= 0
	if has_sel then
		table.insert(segments, utf_8.string(util.list_range(self.cdpts, 1, self.sel.from - 1)))
		table.insert(segments, utf_8.string(util.list_range(self.cdpts, self.sel.from, self.sel.to - 1)))
		table.insert(segments, utf_8.string(util.list_range(self.cdpts, self.sel.to, #self.cdpts)))
		curs_index = self.curs_pos == self.sel.from and 2 or -1
	else
		table.insert(segments, utf_8.string(util.list_range(self.cdpts, 1, self.curs_pos - 1)))
		table.insert(segments, utf_8.string(util.list_range(self.cdpts, self.curs_pos, #self.cdpts)))
		curs_index = 2
	end
	self.update_handler(has_sel, curs_index, segments)
end
