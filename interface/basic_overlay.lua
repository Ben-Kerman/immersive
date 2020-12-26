local ssa = require "systems.ssa"

local BasicOverlay = {}
BasicOverlay.__index = BasicOverlay

function BasicOverlay:new(data, converter, style)
	return setmetatable({
		overlay = mp.create_osd_overlay("ass-events"),
		active = false,
		data = data,
		converter = converter,
		style = style
	}, BasicOverlay)
end

function BasicOverlay:redraw()
	if self.active then
		local ssa_definition = {
			style = self.style,
			full_style = true
		}
		if self.converter then
			self.converter(self.data, ssa_definition)
		else
			table.insert(ssa_definition, self.data)
		end
		self.overlay.data = ssa.generate(ssa_definition)
		self.overlay:update()
	end
end

function BasicOverlay:show()
	self.active = true
	self:redraw()
end

function BasicOverlay:hide()
	self.active = false
	self.overlay:remove()
end

function BasicOverlay:cancel()
	self:hide()
end

return BasicOverlay
