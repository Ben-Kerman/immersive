-- Immersive is licensed under the terms of the GNU GPL v3: https://www.gnu.org/licenses/; © 2020 Ben Kerman

local bus = require "systems.bus"
local cfg = require "systems.config"
local cfg_util = require "systems.config_util"
local msg = require "systems.message"
local tags = require "systems.ssa_tags"
local ext = require "utility.extension"

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
	local back_col, back_alpha = convert_mpv_color(p.str("background"))

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
			font_size = 30,
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
		messages = {
			base = {align = 9},
			fatal = {
				bold = true,
				primary_color = "5791F9"
			},
			error = {primary_color = "7A77F2"},
			warn = {primary_color = "66CCFF"},
			info = {},
			verbose = {primary_color = "99CC99"},
			debug = {primary_color = "A09F93"},
			trace = {}
		},
		menu_help = {
			base = {align = 7},
			key = {bold = true},
			hint = {italic = true}
		},
		menu_info = {
			base = {align = 1},
			key = {bold = true},
			unset = {italic = true}
		},
		line_select = {
			base = {},
			selection = {
				bold = true,
				primary_color = "FFD0D0"
			}
		},
		text_select = {
			base = {},
			selection = {primary_color = "FF8080"}
		},
		word_audio_select = {
			base = {},
			unloaded = {primary_color = "808080"},
			loading = {primary_color = "8080FF"},
			loaded = {}
		},
		selection_overlay = {
			base = {align = 3}
		},
		info_overlay = {
			base = {align = 1}
		},
		blackout = {
			base = {
				primary_color = back_col,
				primary_alpha = back_alpha
			}
		}
	}
end

local function verify_convert_value(key, value)
	local tag = ext.list_find(tags, function(tag)
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
		else res = cfg_util.force_type(value, tag.type) end

		if res then return res
		else msg.warn("invalid style value ignored: " .. key .. "=" .. value) end
	else msg.warn("unknown style property ignored: " .. key) end
end

local config
local function reload_config()
	config = get_defaults()
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
		local path = ext.string_split(section.name, "/")
		style_tbl = cfg_util.get_nested(config, path)
		if style_tbl then
			insert_values(style_tbl, section.entries)
		else msg.warn("invalid style path ignored: " .. section.name) end
	end
end
reload_config()
bus.listen("reload_config", reload_config)

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
	return (str:gsub("\n", "\\N")
	           :gsub("\226\128\139", "\\n")) -- zero width space
end

local ssa = {}

function ssa.custom(data)
	local tag_parts = {}
	inject_tag(tag_parts, data)
	return table.concat(tag_parts)
end

function ssa.query(path)
	local tag_id = path[#path]
	local value = config.base[tag_id]

	if #path > 1 then
		local secondary_value = config[path[1]].base[tag_id]
		if secondary_value then value = secondary_value end
	end
	if #path > 2 then
		local tertiary_value = config[path[1]][path[2]][tag_id]
		if tertiary_value then value = tertiary_value end
	end
	return value
end

local function find_style(style_def)
	if style_def then
		if type(style_def) == "string" then
			return config[style_def].base
		elseif type(style_def) == "table" then
			if #style_def ~= 0 then
				return cfg_util.get_nested(config, style_def)
			else return style_def end
		else msg.fatal("invalid style type: " .. type(style_def)) end
	end
end

local function generate_rec(string_parts, definition, base_data)
	if type(definition) == "string" then
		table.insert(string_parts, escape(definition))
	elseif type(definition) == "table" then
		local style_data = find_style(definition.style)
		if not base_data then
			base_data = ext.map_merge(config.base, style_data)
		end
		local next_base_data = ext.map_merge(base_data, style_data)
		local inj_data = definition.full_style and next_base_data or style_data

		if inj_data then
			inject_tag(string_parts, inj_data)
		end

		for _, sub_def in ipairs(definition) do
			generate_rec(string_parts, sub_def, next_base_data)
		end

		if inj_data then
			inject_tag(string_parts, inj_data, true, base_data)
		end

		if definition.newline then
			table.insert(string_parts, "\\N")
		end
	else msg.fatal("invalid type in SSA format table: " .. type(definition)) end
end

function ssa.generate(definition)
	local string_parts = {}
	generate_rec(string_parts, definition)
	return table.concat(string_parts)
end

return ssa
