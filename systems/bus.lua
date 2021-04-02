local ext = require "utility.extension"

local handlers = {}

local bus = {}

function bus.listen(event, handler)
	if not handlers[event] then
		handlers[event] = {handler}
	else
		table.insert(handlers[event], handler)
	end
end

function bus.unlisten(event, handler)
	handlers[event] = ext.list_filter(handlers[event], function(elem)
		return elem ~= handler
	end)
end

function bus.fire(event, ...)
	if handlers[event] then
		for _, handler in ipairs(handlers[event]) do
			handler(...)
		end
	end
end

return bus