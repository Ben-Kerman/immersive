local helper = require "helper"

local function default_sel_renderer(line)
	return "{\\b1}" .. line .. "{\\b0}"
end

local function default_renderer(line)
	return line
end

LineSelect = {}
LineSelect.__index = LineSelect

function LineSelect:move_sel(dir)
	local new_pos = self.active + dir
	if new_pos < 1 or #self.lines < new_pos then return end
	self.active = new_pos
	self:update()
end

function LineSelect:new(lines, sel_renderer, renderer, update_handler)
	local ls
	ls = {
		_overlay = mp.create_osd_overlay("ass-events"),
		lines = lines,
		renderer = renderer and renderer or default_renderer,
		update_handler = update_handler,
		sel_renderer = sel_renderer and sel_renderer or default_sel_renderer,
		active = 1,
		bindings = {
			{key = "UP", action = function() ls:move_sel(-1) end, repeatable = true},
			{key = "DOWN", action = function() ls:move_sel(1) end, repeatable = true},
		}
	}
	return setmetatable(ls, LineSelect)
end

function LineSelect:start()
	helper.add_bindings(self.bindings, "_ankisubs-line_select_binding-")
	self:update()
end

function LineSelect:finish()
	helper.remove_bindings(self.bindings, "_ankisubs-line_select_binding-")
	self._overlay:remove()
	return self.lines[self.active]
end

function LineSelect:update()
	if self.update_handler then self.update_handler(self.lines[self.active]) end
	local rendered_lines = {"{\\an5}"}
	for i, line in ipairs(self.lines) do
		local renderer = i == self.active and self.sel_renderer or self.renderer
		table.insert(rendered_lines, renderer(line))
	end
	self._overlay.data = table.concat(rendered_lines, "\\N")
	self._overlay:update()
end
