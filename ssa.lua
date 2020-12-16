local util = require("util")

local base_defaults = (function()
	local p = {
		str = mp.get_property,
		bool = mp.get_property_bool,
		num = mp.get_property_number
	}

	local function convert_mpv_color(str)
		local alpha = 0xff - tonumber(str:sub(2, 3), 16)
		local red = str:sub(4, 5)
		local green = str:sub(6, 7)
		local blue = str:sub(8, 9)
		return string.format("%s%s%s", blue, green, red), string.format("%02X", alpha)
	end

	local text_col, text_alpha = convert_mpv_color(p.str("osd-color"))
	local bord_col, bord_alpha = convert_mpv_color(p.str("osd-border-color"))
	local shad_col, shad_alpha = convert_mpv_color(p.str("osd-shadow-color"))
	local bord_size = p.num("osd-border-size")
	local shad_size = p.num("osd-shadow-offset")

	return {
		bold = p.bool("osd-bold"),
		italic = p.bool("osd-italic"),
		underline = false,
		strikeout = false,
		border = bord_size,
		border_x = bord_size,
		border_y = bord_size,
		shadow = shad_size,
		shadow_x = shad_size,
		shadow_y = shad_size,
		blur = p.num("osd-blur"),
		font_name = p.str("osd-font"),
		font_size = p.num("osd-font-size"),
		letter_spacing = p.num("osd-spacing"),
		primary_color = text_col,
		secondary_color = "808080",
		border_color = bord_col,
		shadow_color = shad_col,
		primary_alpha = text_alpha,
		secondary_alpha = "00",
		border_alpha = bord_alpha,
		shadow_alpha = shad_alpha,
	}
end)()

local basic_tags = {
	{id = "bold", tag = "b"},
	{id = "italic", tag = "i"},
	{id = "underline", tag = "u"},
	{id = "strikeout", tag = "s"},
	{id = "border", tag = "bord"},
	{id = "border_x", tag = "xbord"},
	{id = "border_y", tag = "ybord"},
	{id = "shadow", tag = "shad"},
	{id = "shadow_x", tag = "xshad"},
	{id = "shadow_y", tag = "yshad"},
	{id = "blur", tag = "blur"},
	{id = "font_name", tag = "fn"},
	{id = "font_size", tag = "fs"},
	{id = "letter_spacing", tag = "fsp"},
}

local color_tags = {
	{id = "primary_color", tag = "1c"},
	{id = "secondary_color", tag = "2c"},
	{id = "border_color", tag = "3c"},
	{id = "shadow_color", tag = "4c"}
}

local alpha_tags = {
	{id = "all_alpha", tag = "alpha"},
	{id = "primary_alpha", tag = "1a"},
	{id = "secondary_alpha", tag = "2a"},
	{id = "border_alpha", tag = "3a"},
	{id = "shadow_alpha", tag = "4a"}
}

local function insert_tag(list, tag, value, hex, closing, default)
	table.insert(list, "\\")
	table.insert(list, tag)
	if hex then table.insert(list, "&H") end

	local base_value
	if closing then base_value = default
	else base_value = value end

	local insert_value
	local val_type = type(base_value)
	if val_type == "boolean" then
		insert_value = base_value and "1" or "0"
	elseif val_type == "number" then
		insert_value = tostring(base_value)
	else insert_value = base_value end

	table.insert(list, insert_value)
	if hex then table.insert(list, "&") end
end

local ssa = {}

function ssa.generate_style(values, closing, custom_defaults)
	if not values then values = {} end
	local defaults = util.map_merge(base_defaults, custom_defaults)

	local style_str = {"{"}
	local function insert_tags(tags, hex)
		for _, tag in ipairs(tags) do
			if values[tag.id] ~= nil then
				insert_tag(style_str, tag.tag, values[tag.id], hex, closing, defaults[tag.id])
			elseif defaults[tag.id] ~= nil then
				insert_tag(style_str, tag.tag, defaults[tag.id], hex)
			end
		end
	end

	insert_tags(basic_tags, false)
	insert_tags(color_tags, true)
	insert_tags(alpha_tags, true)

	table.insert(style_str, "}")

	return table.concat(style_str)
end

return ssa
