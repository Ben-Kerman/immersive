local util = require "util"

local overlay = mp.create_osd_overlay("ass-events")
overlay.z = 127

local messages = {}

local function update_overlay()
	local ol_data = {}
	for _, msg in ipairs(messages) do
		table.insert(ol_data, msg.text)
	end
	overlay.data = "{\\an9}" .. table.concat(ol_data, "\\N")
	overlay:update()
end

local function add_msg(level, text, timeout)
	mp.msg[level](text)

	local msg = {
		level = level,
		text = text
	}
	table.insert(messages, msg)

	if not timeout then timeout = 10 end
	if timeout ~= 0 then
		mp.add_timeout(timeout, function()
			local _, pos = util.list_find(messages, msg)
			table.remove(messages, pos)
			update_overlay()
		end)
	end

	update_overlay()
end

local message = {}

local levels = {"fatal", "error", "warn", "info", "verbose", "debug", "trace"}
for _, level in ipairs(levels) do
	message[level] = function(text, timeout)
		add_msg(level, text, timeout)
	end
end

return message
