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
	local curs_size = mp.get_property_number("osd-font-size") * 8
	local pbo = curs_size / 6
	local curs_style =
		[[\r\1a&H00&\3a&H00&\4a&H00&\1c&Hffffff&\3c&Hffffff&\4c&H000000&\xbord0.75\ybord0\xshad1.5\yshad0]]
	local curs_cmd = string.format("{%s\\p4\\pbo%d}m 0 0 l 1 0 l 1 %d l 0 %d{\\p0\\r}", curs_style, pbo, curs_size, curs_size)
	table.insert(segments, curs_index, curs_cmd)

	table.insert(segments, 1, "{\\an5}")

	overlay.data = table.concat(segments)
	overlay:update()
end

TextSelect = {}
TextSelect.__index = TextSelect

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

function TextSelect:move_curs_word(change_sel)
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
