local passthrough = false
local messages = {}

local startup_msg = {}

local levels = {"fatal", "error", "warn", "info", "verbose", "debug", "trace"}
	for _, level in ipairs(levels) do
		startup_msg[level] = function(text)
		if passthrough then
			require("message")[level](text)
		else table.insert(messages, {level = level, text = text}) end
	end
end

function startup_msg.display()
	passthrough = true
	local msg = require "message"
	for _, message in ipairs(messages) do
		msg[message.level](message.text)
	end
end

return startup_msg
