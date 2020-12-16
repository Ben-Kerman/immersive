local helper = require "helper"
local ssa = require "ssa"

local function default_sel_renderer(line)
	return ssa.enclose_text(ssa.get_defaults{"line_select", "selection"}, line, ssa.get_defaults{"line_select", "base"})
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

function LineSelect:new(lines, sel_renderer, renderer, update_handler, limit)
	local ls
	ls = {
		_overlay = mp.create_osd_overlay("ass-events"),
		lines = lines,
		renderer = renderer and renderer or default_renderer,
		update_handler = update_handler,
		sel_renderer = sel_renderer and sel_renderer or default_sel_renderer,
		limit = limit,
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
	
	local first, last
	if not self.limit or self.limit >= #self.lines then
		first, last = 1, #self.lines
	else
		first = math.ceil(self.active - self.limit / 2)
		if first < 1 then first = 1 end

		last = math.floor(self.active + self.limit / 2) - (self.limit + 1) % 2
		if last > #self.lines then last = #self.lines end

		if first == 1 then
			last = self.limit
		elseif last == #self.lines then
			first = #self.lines - self.limit + 1
		end
	end

	local rendered_lines = {ssa.load_style{"line_select", "base"}}
	if first ~= 1 then table.insert(rendered_lines, "...") end

	for i, line in ipairs(self.lines) do
		if first <= i and i <= last then
			local renderer = i == self.active and self.sel_renderer or self.renderer
			table.insert(rendered_lines, renderer(line))
		end
		if i == last then break end
	end

	if last ~= #self.lines then table.insert(rendered_lines, "...") end

	self._overlay.data = table.concat(rendered_lines, "\\N")
	self._overlay:update()
end
