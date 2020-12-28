-- Immersive is licensed under the terms of the GNU GPL v3: https://www.gnu.org/licenses/; © 2020 Ben Kerman

local cfg = require "systems.config"
local ssa = require "systems.ssa"

local ScreenBlackout = {}
ScreenBlackout.__index = ScreenBlackout

function ScreenBlackout:new()
	local sb

	local function observer()
		sb:redraw()
	end

	sb = setmetatable({
		observer = observer,
		overlay = mp.create_osd_overlay("ass-events")
	}, ScreenBlackout)

	sb.overlay.z = -1

	return sb
end

function ScreenBlackout:redraw()
	local ol_fmt = [[{\an7\pos(0,0)\bord0\shad0\1c&H]] ..
	               ssa.query{"blackout", "primary_color"} ..
	               [[&\1c&H]] ..
	               ssa.query{"blackout", "primary_alpha"} ..
	               [[&\p1}m 0 0 l 0 720 %s 720 %s 0{\p0}]]

	local _, _,aspect_ratio = mp.get_osd_size()
	local ol_width = 720 * aspect_ratio

	self.overlay.data = string.format(ol_fmt, ol_width, ol_width)
	self.overlay:update()
end

function ScreenBlackout:show()
	self:redraw()
	mp.observe_property("osd-width", "number", self.observer)
	mp.observe_property("osd-height", "number", self.observer)
end

function ScreenBlackout:hide()
	mp.unobserve_property(self.observer)
	self.overlay:remove()
end

function ScreenBlackout:cancel()
	self:hide()
end

return ScreenBlackout
