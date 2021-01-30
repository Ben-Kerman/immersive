-- Immersive is licensed under the terms of the GNU GPL v3: https://www.gnu.org/licenses/; © 2020 Ben Kerman

local ext = require "utility.extension"
local msg = require "systems.message"
local utf_8 = require "utility.utf_8"

local Subtitle = {}
Subtitle.__index = Subtitle

function Subtitle.__lt(a ,b)
	if a.start == b.start then return a.stop < b.stop
	else return a.start < b.start end
end

function Subtitle:new(text, start, stop, delay)
	if not start or not stop then
		msg.error("Export will fail: Subtitle start or end time is nil.\nThis is probably an issue with the subtitle file.")
	end

	return setmetatable({
		text = text,
		start = start,
		stop = stop,
		delay = delay
	}, Subtitle)
end

function Subtitle:real_start()
	if self.delay then
		return self.start + self.delay
	else return self.start end
end

function Subtitle:real_stop()
	if self.delay then
		return self.stop + self.delay
	else return self.stop end
end

return Subtitle
