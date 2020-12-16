require "line_select"
require "text_select"

LineTextSelect = {}
LineTextSelect.__index = LineTextSelect

function LineTextSelect:new(lines, sel_converter, renderer, limit)
	local lts
	local function sel_renderer() return lts.sel_ssa end
	local function update_handler(line)
		if line ~= lts.active_line then
			lts.active_line = line
			if lts._text_select then lts._text_select:finish() end
			lts._text_select = TextSelect:new(sel_converter(line), function(has_sel, curs_index, segments)
				lts.sel_ssa = TextSelect.base_update_handler(has_sel, curs_index, segments)
				lts._line_select:update()
			end)
			lts._text_select:start()
		end
	end
	lts = {
		lines = lines,
		converter = converter,
		limit = limit,
		sel_ssa = ""
	}
	lts._line_select = LineSelect:new(lines, sel_renderer, renderer, update_handler, limit)
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
