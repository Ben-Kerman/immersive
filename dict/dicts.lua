-- Immersive is licensed under the terms of the GNU GPL v3: https://www.gnu.org/licenses/; © 2021 Ben Kerman

local BasicOverlay = require "interface.basic_overlay"
local cfg = require "systems.config"
local cfg_util = require "systems.config_util"
local ext = require "utility.extension"
local helper = require "utility.helper"
local util = require "dict.util"
local kbds = require "systems.key_bindings"
local menu_stack = require "interface.menu_stack"
local msg = require "systems.message"

local conv = cfg_util.convert

local common_entr_def = {
	type = {
		required = true
	},
	location = {
		required = true
	},
	exporter = {
		default = "default"
	},
	preload = {
		convert = conv.bool
	},
	transformations = {
		convert = function(raw)
			local result = {}

			local next_start = 1
			while next_start <= #raw do
				local id, id_end, next_ch = helper.parse(raw, nil, "(,", next_start, {})
				if id_end then
					local transform = {id = id}
					if next_ch == "(" then
						local args = {}
						local next_arg = id_end + 1
						while true do
							local arg, arg_end, next_ch = helper.parse(raw, nil, ",)", next_arg, {[0x2c] = 0x2c})
							if arg_end then
								table.insert(args, arg)
								next_arg = arg_end + 1

								if next_ch == ")" then
									if arg_end + 1 <= #raw and raw:byte(arg_end + 1) ~= 0x2c then
										return nil, "',' expected after ')'"
									else
										next_start = arg_end + 2
										break
									end
								end
							else return nil, "',' or ')' expected" end
						end
						transform.args = args
					else
						next_start = id_end + 1
					end
					table.insert(result, transform)
				else
					if #id > 0 then
						table.insert(result, {id = id})
					end
					break
				end
			end
			return result
		end
	},
	quick_def_template = {}
}

local entr_defs = {
	yomichan = {
		insert_cjk_breaks = {
			convert = conv.bool
		},
		["export:digits"] = {},
		["export:reading_template"] = {},
		["export:definition_template"] = {},
		["export:template"] = {},
		["export:use_single_template"] = {},
		["export:single_template"] = {}
	},
	migaku = {
		["export:template"] = {}
	}
}

local cfg_entr_def = {
	sections = true,
	section_entries = function(raw_sect)
		local res
		if raw_sect.type then
			return {
				items = ext.map_merge(common_entr_def, entr_defs[raw_sect.type])
			}
		else
			return {
				dynamic_fn = function() return true end,
				items = common_entr_def
			}
		end
	end
}

local dict_list = ext.list_map(cfg.load_subcfg("dictionaries", cfg_entr_def), function(dict_cfg)
	return {id = dict_cfg.name, config = dict_cfg.entries, table = nil}
end)
local active_dict_index = 1

local function loading_overlay(id)
	return BasicOverlay:new("initializing dictionary (" .. id .. ")...", nil, "info_overlay")
end

local function load_dict(dict, show_overlay, force_import)
	if not force_import and dict.table then return dict end

	kbds.disable_global()
	if show_overlay then
		menu_stack.push(loading_overlay(dict.id))
	end
	msg.debug("loading dictionary '" .. dict.id .. "'")
	if cfg_util.check_required(dict.config, {"location", "type"}) then
		local status, loader = pcall(require, "dict." .. dict.config.type)
		if status then
			dict.table = loader.load(dict, force_import)
		else msg.error("unknown dictionary type: " .. dict.config.type) end
	end
	if show_overlay then
		menu_stack.pop()
	end
	-- kind of hacky, a custom event handler
	-- could be a better solution
	mp.add_timeout(0.2, function()
		kbds.enable_global()
	end)
	return dict
end

mp.register_event("start-file", function()
	for _, dict in ipairs(dict_list) do
		local pos_override, neg_override
		if dict.config.preload then
			local cfg_preload = cfg_util.convert.bool(dict.config.preload)
			pos_override = cfg_preload == true
			neg_override = cfg_preload == false
		end

		if not neg_override and (cfg.values.preload_dictionaries or pos_override) then
			load_dict(dict, cfg.values.startup_dict_overlay)
		end
	end
end)

local dicts = {}

function dicts.count()
	return #dict_list
end

function dicts.at(index, block_loading)
	local dict = dict_list[index]
	if not dict then return nil end

	if block_loading then return dict
	else return load_dict(dict, true) end
end

function dicts.active(block_loading)
	local dict = dicts.at(active_dict_index, block_loading)
	if not dict then
		msg.warn("no dictionaries found")
	else return dict end
end

function dicts.switch(dir)
	active_dict_index = ext.num_limit(active_dict_index + dir, 1, #dict_list)
end

function dicts.reimport_all()
	for _, dict in ipairs(dict_list) do
		if util.is_imported(dict) then
			load_dict(dict, true, true)
		end
	end
end

return dicts
