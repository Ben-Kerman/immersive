local cfg = require "config"
local ssa = require "ssa"

local ScreenBlackout = {}
ScreenBlackout.__index = ScreenBlackout

function ScreenBlackout:new()
	local sb

	local function observer()
		local ol_fmt = [[{\an7\pos(0,0)\bord0\shad0\1c&H]] ..
		               ssa.query{"blackout", "primary_color"} ..
		               [[&\1c&H]] ..
		               ssa.query{"blackout", "primary_alpha"} ..
		               [[&\p1}m 0 0 l 0 720 %s 720 %s 0{\p0}]]

		local _, _,aspect_ratio = mp.get_osd_size()
		local ol_width = 720 * aspect_ratio

		sb.overlay.data = string.format(ol_fmt, ol_width, ol_width)
		sb.overlay:update()
	end

	mp.observe_property("osd-width", "number", observer)
	mp.observe_property("osd-height", "number", observer)

	sb = setmetatable({
		observer = observer,
		overlay = mp.create_osd_overlay("ass-events")
	}, ScreenBlackout)

	sb.overlay.z = -1

	return sb
end

function ScreenBlackout:show()
end

function ScreenBlackout:hide()
end

function ScreenBlackout:cancel()
	mp.unobserve_property(self.observer)
	self.overlay:remove()
end

return ScreenBlackout
