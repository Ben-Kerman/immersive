require "subtitle"

local subs = {}

local function insert_sub(sub)
	table.insert(subs, sub)
	table.sort(subs)
end

local function handle_sub_text(_, sub_text)
	if sub_text ~= nil and sub_text ~= "" then
		insert_sub(create_subtitle(sub_text, mp.get_property_number("sub-start"), mp.get_property_number("sub-end")))
	end
end

sub_selection = {}

local auto_select_active = false
function sub_selection.toggle_auto_select()
	if auto_select_active then mp.unobserve_property(handle_sub_text)
	else mp.observe_property("sub-text", "string", handle_sub_text) end
	auto_select_active = not auto_select_active
end
