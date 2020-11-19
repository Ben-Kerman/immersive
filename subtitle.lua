subtitle_mt = {}

function subtitle_mt.__lt(a ,b)
	if a.start == b.start then return a.stop < b.stop
	else return a.start < b.start end
end

function create_subtitle(text, start, stop)
	local sub = {
		text = text,
		start = start,
		stop = stop
	}
	setmetatable(sub, subtitle_mt)
	return sub
end
