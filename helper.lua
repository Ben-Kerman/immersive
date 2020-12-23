local mpu = require "mp.utils"
local msg = require "message"

local helper = {}

function helper.check_active_sub()
	local sub_text = mp.get_property("sub-text")
	if sub_text and sub_text ~= "" then
		return sub_text
	else msg.info("No active subtitle line") end
end

function helper.current_path_abs()
	local working_dir = mp.get_property("working-directory")
	local rel_path = mp.get_property("path")
	if working_dir and rel_path then
		return mpu.join_path(working_dir, rel_path)
	end
end

return helper
