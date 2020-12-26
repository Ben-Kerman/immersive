local utf_8 = require "utility.utf_8"
local util = require "utility.extension"

local Subtitle = {}
Subtitle.__index = Subtitle

function Subtitle.__lt(a ,b)
	if a.start == b.start then return a.stop < b.stop
	else return a.start < b.start end
end

function Subtitle:new(text, start, stop, delay)
	local sub = {
		text = text,
		start = start,
		stop = stop,
		delay = delay
	}
	return setmetatable(sub, Subtitle)
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
