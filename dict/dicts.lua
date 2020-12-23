local cfg = require "config"
local msg = require "message"
local util = require "util"

local loaded = false
local dict_list = util.list_map(cfg.load_subcfg("dictionaries"), function(dict_cfg)
	return {id = dict_cfg.name, config = dict_cfg.entries, table = nil}
end)
local active_dict_index = 1

local function load_dict(index)
	local dict = dict_list[index]
	if dict.table then return dict end

	msg.debug("loading dictionary '" .. dict.id .. "'")
	if cfg.check_required(dict.config, {"location", "type"}) then
		local status, loader = pcall(require, "dict." .. dict.config.type)
		if status then
			dict.table = loader.load(dict.id, dict.config)
		else msg.error("unknown dictionary type: " .. dict.config.type) end
	end
	return dict
end

if not cfg.values.lazy_load_dicts then
	mp.register_event("start-file", function()
		for i = 1, #dict_list do
			load_dict(i)
		end
		loaded = true
	end)
end

local dicts = {}

function dicts.active()
	local dict = dict_list[active_dict_index]
	if not dict then
		msg.warn("no dictionaries found")
		return nil
	end
	return load_dict(active_dict_index)
end

function dicts.switch(dir)
	active_dict_index = util.num_limit(active_dict_index + dir, 1, #dict_list)
end

return dicts
