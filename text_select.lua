local utf_8 = require "utf_8"

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
end

function TextSelect:move_curs_word(change_sel)
end

function TextSelect:enable()
	for i, binding in ipairs(self.bindings) do
		mp.add_forced_key_binding(binding.key, "_ankisubs-text_select_binding-" .. i, binding.action, {repeatable = true})
	end
end

function TextSelect:disable()
	for i, binding in ipairs(self.bindings) do
		mp.remove_key_binding("_ankisubs-text_select_binding-" .. i)
	end
end

function TextSelect:new(text, init_cursor_pos)
	local ts
	ts = {
		cdpts = utf_8.codepoints(text),
		curs_pos = init_cursor_pos and init_cursor_pos or 1,
		sel = {from = 0, to = 0},
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
