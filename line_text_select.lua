local LineSelect = require "line_select"
local ssa = require "ssa"
local TextSelect = require "text_select"

local LineTextSelect = {}
LineTextSelect.__index = LineTextSelect

function LineTextSelect:new(lines, line_conv, sel_conv, limit)
	local lts
	local function _sel_conv() return lts.sel_ssa_def end
	local function update_handler(line)
		if line ~= lts.active_line then
			lts.active_line = line
			if lts._text_select then lts._text_select:finish() end

			lts._text_select = TextSelect:new(sel_conv(line), function(self, visible, has_sel, curs_pos, segments)
				if visible then
					lts.sel_ssa_def = self:default_generator(has_sel, curs_pos, segments)
					lts._line_select:update()
				else lts.sel_ssa_def = {} end
			end, ssa.query{"line_select", "selection", "font_size"}, true)
			lts._text_select:show()
		end
	end
	lts = {
		lines = lines,
		converter = converter,
		limit = limit,
		sel_ssa_def = {}
	}
	lts._line_select = LineSelect:new(lines, line_conv, _sel_conv, update_handler, limit)
	return setmetatable(lts, LineTextSelect)
end

function LineTextSelect:show()
	if self._text_select then
		self._text_select:show()
	end
	self._line_select:show()
end

function LineTextSelect:hide()
	if self._text_select then
		self._text_select:hide()
	end
	self._line_select:hide()
end

function LineTextSelect:selection()
	return self._text_select:finish()
end

function LineTextSelect:finish(force_sel)
	local sel = self:selection()
	if force_sel and not sel then
		-- TODO
		return
	end
	self:hide()
	return sel
end

return LineTextSelect
