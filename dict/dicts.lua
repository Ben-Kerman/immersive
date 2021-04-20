-- Immersive is licensed under the terms of the GNU GPL v3: https://www.gnu.org/licenses/; © 2020 Ben Kerman

local BasicOverlay = require "interface.basic_overlay"
local cfg = require "systems.config"
local cfg_util = require "systems.config_util"
local util = require "dict.util"
local kbds = require "systems.key_bindings"
local menu_stack = require "interface.menu_stack"
local msg = require "systems.message"
local ext = require "utility.extension"

local dict_list = ext.list_map(cfg.load_subcfg("dictionaries"), function(dict_cfg)
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
			local cfg_preload = cfg_util.convert_bool(dict.config.preload)
			pos_override = cfg_preload == true
			neg_override = cfg_preload == false
		end

		if not neg_override and (cfg.values.preload_dictionaries or pos_override) then
			load_dict(dict, cfg.values.startup_dict_overlay)
		end
	end
end)

local dicts = {}

function dicts.active(block_loading)
	local dict = dict_list[active_dict_index]
	if not dict then
		msg.warn("no dictionaries found")
		return nil
	end

	if block_loading then return dict
	else return load_dict(dict, true) end
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
