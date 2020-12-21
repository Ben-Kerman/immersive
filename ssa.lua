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

local function find_tag(str)
	for _, tags in pairs(tags) do
		local find_res = util.list_find(tags, function(tag_def)
			return tag_def.id == str
		end)
		if find_res then return find_res end
	end
end

local config = (function()
	local config = get_defaults()
	local cfg_data = cfg.load_subcfg("style")

	local function insert_values(tbl, entries)
		for key, value in pairs(entries) do
			local tag = find_tag(key)
			if tag then
				local success, res = pcall(cfg.force_type, value, tag.type)
				if success then tbl[key] = res
				else msg.warn("Ignoring invalid style value: " .. value) end
			else msg.warn("Ignoring unknown style property: " .. key) end
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

local function insert_tag(list, tag, value, hex, closing, default)
	if value == nil then return end

	local base_value
	if closing then
		if default == nil then return
		else base_value = default end
	else base_value = value end

	local insert_value
	local val_type = type(base_value)
	if val_type == "boolean" then
		insert_value = base_value and "1" or "0"
	elseif val_type == "number" then
		insert_value = tostring(base_value)
	else insert_value = base_value end

	table.insert(list, "\\")
	table.insert(list, tag)
	if hex then table.insert(list, "&H") end
	table.insert(list, insert_value)
	if hex then table.insert(list, "&") end
end

local ssa = {}

function ssa.get(path)
	if not path then return config_defaults.base end
	return cfg.get_nested(config_defaults, path)
end

function ssa.get_full(...)
	local paths = {...}
	local res = ssa.get()
	for _, path in ipairs(paths) do
		res = util.map_merge(res, ssa.get(path))
	end
	return res
end

function ssa.generate(values_path, default_values_path, full, closing)
	local values
	if values_path[1] then
		values = ssa.get(values_path)
	else values = values_path end
	local partial_defaults
	if default_values_path and default_values_path[1] then
		partial_defaults = ssa.get(default_values_path)
	else partial_defaults = default_values_path end
	local defaults = util.map_merge(config_defaults.base, partial_defaults)

	local style_str = {"{"}
	local function insert_tags(tags, hex)
		for _, tag in ipairs(tags) do
			if values[tag.id] ~= nil then
				insert_tag(style_str, tag.tag, values[tag.id], hex, closing, defaults[tag.id])
			elseif full and not tag.explicit and defaults[tag.id] ~= nil then
				insert_tag(style_str, tag.tag, defaults[tag.id], hex)
			end
		end
	end

	insert_tags(tags.basic, false)
	insert_tags(tags.color, true)
	insert_tags(tags.alpha, true)

	table.insert(style_str, "}")

	return table.concat(style_str)
end

function ssa.format(text, values_path, default_values_path, full)
	local before = ssa.generate(values_path, default_values_path, full, false)
	local after = ssa.generate(values_path, default_values_path, full, true)
	return string.format("%s%s%s", before, text, after)
end

return ssa
