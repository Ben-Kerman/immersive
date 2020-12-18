local helper = {}

function helper.check_active_sub()
	local sub_text = mp.get_property("sub-text")
	if sub_text and sub_text ~= "" then
		return sub_text
	else mp.osd_message("No active subtitle line") end
end

return helper
