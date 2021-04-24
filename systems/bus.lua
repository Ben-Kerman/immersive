-- Immersive is licensed under the terms of the GNU GPL v3: https://www.gnu.org/licenses/; © 2021 Ben Kerman

local ext = require "utility.extension"

local handlers = {}

local bus = {}

function bus.listen(event, handler)
	if not handlers[event] then
		handlers[event] = {}
	end

	local ref = {}
	handlers[event][ref] = handler
	return ref
end

function bus.unlisten(event, ref)
	handlers[event][ref] = nil
end

function bus.fire(event, ...)
	if handlers[event] then
		for _, handler in pairs(handlers[event]) do
			handler(...)
		end
	end
end

return bus
