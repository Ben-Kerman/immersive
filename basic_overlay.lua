local ssa = require "ssa"

local SelectionOverlay = {}
SelectionOverlay.__index = SelectionOverlay

function SelectionOverlay:new(selection)
	local so = {
		_overlay = mp.create_osd_overlay("ass-events"),
		selection = selection
	}
	return setmetatable(so, SelectionOverlay)
end

function SelectionOverlay:redraw()
	local ssa_definition = {
		style = "selection_overlay",
		full_style = true
	}
	for _, sub in ipairs(self.selection) do
		table.insert(ssa_definition, {
			newline = true,
			sub:short()
		})
	end
	self._overlay.data = ssa.generate(ssa_definition)
	self._overlay:update()
end

function SelectionOverlay:remove()
	self._overlay:remove()
end

return SelectionOverlay
