local utf_8 = require "utf_8"
local util = require "util"

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

function Subtitle:short()
	local one_line = self.text:gsub("\n", "⏎")
	local cps = utf_8.codepoints(one_line)

	if #cps > 16 then return utf_8.string(util.list_range(cps, 1, 16)) .. "…"
	else return one_line end
end

return Subtitle
