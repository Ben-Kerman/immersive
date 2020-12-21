local cfg = require "config"
local msg = require "message"
local tags = require "ssa_tags"
local util = require "util"

local function convert_alpha(str)
	return string.format("%02X", 0xff - tonumber(str, 16))
end

local function convert_color(str)
	local red = str:sub(1, 2)
	local green = str:sub(3, 4)
	local blue = str:sub(5, 6)
	return string.format("%s%s%s", blue, green, red):upper()
end

local function convert_mpv_color(str)
	return convert_color(str:sub(4, 9)), convert_alpha(str:sub(2, 3))
end

local function get_defaults()
	local p = {
		str = mp.get_property,
		bool = mp.get_property_bool,
		num = mp.get_property_number
	}

	local text_col, text_alpha = convert_mpv_color(p.str("osd-color"))
	local bord_col, bord_alpha = convert_mpv_color(p.str("osd-border-color"))
	local shad_col, shad_alpha = convert_mpv_color(p.str("osd-shadow-color"))
	local bord_size = p.num("osd-border-size")
	local shad_size = p.num("osd-shadow-offset")

	return {
		base = {
			align = 5,
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
			all_alpha = "FF",
			primary_alpha = text_alpha,
			secondary_alpha = "00",
			border_alpha = bord_alpha,
			shadow_alpha = shad_alpha
		},
		menu_help = {
			base = {align = 7},
			key = {bold = true},
			help = {italic = true}
		},
		menu_info = {
			base = {align = 1},
			key = {bold = true},
			unset = {italic = true}
		},
		line_select = {
			base = {},
			selection = {bold = true}
		},
		text_select = {
			base = {},
			selection = {underline = true}
		}
	}
end

local function verify_convert_value(key, value)
	local tag = util.list_find(tags, function(tag)
		return tag.id == key
	end)
	if tag then
		local res
		local is_color = tag.type == "color"
		if is_color or tag.type == "alpha" then
			local len = is_color and 6 or 2
			local conv = is_color and convert_color or convert_alpha

			if #value == len and value:match("^%x+$") then
				res = conv(value)
			end
		else res = cfg.force_type(value, tag.type) end

		if res then return res
		else msg.warn("Ignoring invalid style value: " .. key .. "=" .. value) end
	else msg.warn("Ignoring unknown style property: " .. key) end
end

local config = (function()
	local config = get_defaults()
	local cfg_data = cfg.load_subcfg("style")

	local function insert_values(tbl, entries)
		for key, value in pairs(entries) do
			local conv_res = verify_convert_value(key, value)
			if conv_res then tbl[key] = conv_res end
		end
	end

	if cfg_data.global then
		insert_values(config.base, cfg_data.global)
	end
	for _, section in ipairs(cfg_data) do
		local path = util.string_split(section.name, "/")
		style_tbl = cfg.get_nested(config, path)
		if style_tbl then
			insert_values(style_tbl, section.entries)
		else msg.warn("Ignoring invalid style path: " .. section.name) end
	end
	return config
end)()

local function inject_tag(list, data, closing, base)
	table.insert(list, "{")
	for _, tag in ipairs(tags) do
		if data[tag.id] ~= nil then
			local value = (closing and base or data)[tag.id]

			table.insert(list, "\\")
			table.insert(list, tag.tag)
			if tag.type == "boolean" then
				table.insert(list, value and "1" or "0")
			elseif tag.type == "number" then
				table.insert(list, tostring(value))
			elseif tag.type == "alpha" or tag.type == "color" then
				table.insert(list, string.format("&H%s&", value))
			else table.insert(list, value) end
		end
	end
	table.insert(list, "}")
end

local function escape(str)
	return str:gsub("\n", "\\N")
end

local err_str = [[{\i1}SSA error{\i0}]]

local ssa = {}

function ssa.generate(definition)
	local secondary_style = definition.base_override
	                        and definition.base_override
	                        or definition.base_style

	if not config[secondary_style] then
		msg.fatal("unknown secondary base style: " .. secondary_style)
		return err_str
	end
	local base_data = util.map_merge(config.base, config[secondary_style].base)

	local string_parts = {}
	if not definition.base_override then
		inject_tag(string_parts, base_data)
	end
	for i, str_def in ipairs(definition) do
		if type(str_def) == "string" then
			table.insert(string_parts, (escape(str_def)))
		elseif type(str_def) == "table" then
			local sub_data
			if str_def.style then
				sub_data = config[definition.base_style][str_def.style]
				if not sub_data then
					msg.fatal("unknown sub style: " .. str_def.style)
				end
			end

			if sub_data then
				inject_tag(string_parts, sub_data)
			end
			table.insert(string_parts, (escape(str_def.text)))
			if sub_data then
				inject_tag(string_parts, sub_data, true, base_data)
			end

			if str_def.newline and i ~= #definition then
				table.insert(string_parts, "\\N")
			end
		else msg.fatal("invalid type in SSA format table: " .. type(str_def)) end
	end
	return table.concat(string_parts)
end

return ssa
