local util = require "util"

local overlay = mp.create_osd_overlay("ass-events")
overlay.z = 127

local osd_duration = mp.get_property_number("osd-duration") / 1000
local levels = {
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
	local ssa = require "ssa"
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

local function add_msg(level, text, timeout)
	mp.msg[level](text)

	local msg = {
		level = level,
		text = text
	}
	table.insert(messages, msg)

	if not timeout then timeout = levels[level] end
	if timeout ~= 0 then
		mp.add_timeout(timeout, function()
			local _, pos = util.list_find(messages, msg)
			table.remove(messages, pos)
			update_overlay()
		end)
	end

	local _, index = util.list_find(levels, level)
	if index and index <= 4 then
		update_overlay()
	end
end

local message = {}

for level, _ in pairs(levels) do
	message[level] = function(text, timeout)
		add_msg(level, text, timeout)
	end
end

return message
