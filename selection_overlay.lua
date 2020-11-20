SelectionOverlay = {}
SelectionOverlay.__index = SelectionOverlay

function SelectionOverlay:new(selection)
	local so = {
		_overlay = mp.create_osd_overlay("ass-events"),
		selection = selection
	}
	return setmetatable(so, SelectionOverlay)
end

function SelectionOverlay:redraw()
	local lines = {"{\\an3}"}
	for _, sub in ipairs(self.selection) do
		table.insert(lines, sub:short())
	end
	self._overlay.data = table.concat(lines, "\\N")
	self._overlay:update()
end

function SelectionOverlay:remove()
	self._overlay:remove()
end
