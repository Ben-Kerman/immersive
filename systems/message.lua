local util = require "utility.extension"

local overlay = mp.create_osd_overlay("ass-events")
overlay.z = 127

local levels = {"fatal", "error", "warn", "info", "verbose", "debug", "trace"}
local osd_duration = mp.get_property_number("osd-duration") / 1000
local durations = {
	fatal = 0,
	error = math.max(osd_duration, 10),
	warn = math.max(osd_duration, 5),
	info = osd_duration,
	verbose = osd_duration,
	debug = osd_duration,
	trace = osd_duration
}

local messages = {}

local function update_overlay()
	local ssa = require "systems.ssa"

	local ssa_definition = {
		style = "messages",
		full_style = true
	}
	for _, msg in ipairs(messages) do
		table.insert(ssa_definition, {
			style = {"messages", msg.level},
			newline = true,
			msg.text
		})
	end
	overlay.data = ssa.generate(ssa_definition)
	overlay:update()
end

local function add_msg_timeout(msg)
	if msg.duration ~= 0 then
		mp.add_timeout(msg.duration, function()
			local _, pos = util.list_find(messages, msg)
			table.remove(messages, pos)
			update_overlay()
		end)
	end
end

local function add_msg(level, text, duration)
	mp.msg[level](text)

	local msg = {
		level = level,
		duration = duration and duration or durations[level],
		text = text
	}

	local _, index = util.list_find(levels, msg.level)
	if index and index <= 4 then
		table.insert(messages, msg)
		if started then
			add_msg_timeout(msg)
			update_overlay()
		end
	end
end

local message = {}

for level, _ in pairs(durations) do
	message[level] = function(text, duration)
		add_msg(level, text, duration)
	end
end

function message.end_startup()
	if not started then
		started = true
		if #messages ~= 0 then
			for _, msg in ipairs(messages) do
				add_msg_timeout(msg)
			end
			update_overlay()
		end
	end
end

return message
