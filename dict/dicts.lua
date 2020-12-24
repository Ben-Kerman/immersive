local BasicOverlay = require "basic_overlay"
local cfg = require "config"
local kbds = require "key_bindings"
local menu_stack = require "menu_stack"
local msg = require "message"
local util = require "util"

local loaded = false
local dict_list = util.list_map(cfg.load_subcfg("dictionaries"), function(dict_cfg)
	return {id = dict_cfg.name, config = dict_cfg.entries, table = nil}
end)
local active_dict_index = 1

local function loading_overlay(id)
	return BasicOverlay:new("initializing dictionary (" .. id .. ")...", nil, "info_overlay")
end

local function load_dict(index, show_overlay)
	local dict = dict_list[index]
	if dict.table then return dict end

	kbds.disable_global()
	if show_overlay then
		menu_stack.push(loading_overlay(dict.id))
	end
	msg.debug("loading dictionary '" .. dict.id .. "'")
	if cfg.check_required(dict.config, {"location", "type"}) then
		local status, loader = pcall(require, "dict." .. dict.config.type)
		if status then
			dict.table = loader.load(dict)
		else msg.error("unknown dictionary type: " .. dict.config.type) end
	end
	if show_overlay then
		menu_stack.pop()
	end
	kbds.enable_global()
	return dict
end

if not cfg.values.lazy_load_dicts then
	mp.register_event("start-file", function()
		for i = 1, #dict_list do
			load_dict(i, cfg.values.startup_dict_overlay)
		end
		loaded = true
	end)
end

local dicts = {}

function dicts.active(block_loading)
	local dict = dict_list[active_dict_index]
	if not dict then
		msg.warn("no dictionaries found")
		return nil
	end

	if block_loading then return dict
	else return load_dict(active_dict_index, true) end
end

function dicts.switch(dir)
	active_dict_index = util.num_limit(active_dict_index + dir, 1, #dict_list)
end

return dicts
