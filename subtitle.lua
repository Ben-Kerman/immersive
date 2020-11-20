Subtitle = {}

function Subtitle.__lt(a ,b)
	if a.start == b.start then return a.stop < b.stop
	else return a.start < b.start end
end

function Subtitle:new(text, start, stop)
	local sub = {
		text = text,
		start = start,
		stop = stop
	}
	setmetatable(sub, Subtitle)
	return sub
end
