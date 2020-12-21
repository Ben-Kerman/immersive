local ssa = require "ssa"
require "line_select"
require "text_select"

LineTextSelect = {}
LineTextSelect.__index = LineTextSelect

function LineTextSelect:new(lines, line_conv, sel_conv, limit)
	local lts
	local function _sel_conv() return lts.sel_ssa end
	local function update_handler(line)
		if line ~= lts.active_line then
			lts.active_line = line
			if lts._text_select then lts._text_select:finish() end

			local fs = ssa.query{"line_select", "selection", "font_size"}
			lts._text_select = TextSelect:new(sel_conv(line), fs, function(self, has_sel, curs_pos, segments)
				lts.sel_ssa = self:default_generator(has_sel, curs_pos, segments)
				lts._line_select:update()
			end, "line_select")
			lts._text_select:start()
		end
	end
	lts = {
		lines = lines,
		converter = converter,
		limit = limit,
		sel_ssa = ""
	}
	lts._line_select = LineSelect:new(lines, line_conv, _sel_conv, update_handler, limit)
	return setmetatable(lts, LineTextSelect)
end

function LineTextSelect:start()
	self._line_select:start()
end

function LineTextSelect:finish(force_sel)
	local sel = self._text_select:finish(force_sel)
	if not sel then return end

	self._line_select:finish()
	return sel
end
