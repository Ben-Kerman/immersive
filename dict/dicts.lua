local cfg = require "config"
local msg = require "message"

local loaded = false
local dict_list = {}

local function load_dict(dict_cfg)
	local dict_id, entries = dict_cfg.name, dict_cfg.entries

	if cfg.check_required(entries, {"location", "type"}) then
		local status, loader = pcall(require, "dict." .. entries.type)
		if status then
			table.insert(dict_list, loader.load(dict_id, entries))
		else msg.error("unknown dict type: " .. entries.type) end
	end
end

local function load_dicts()
	msg.debug("loading dictionaries")
	for _, dict_cfg in ipairs(cfg.load_subcfg("dictionaries")) do
		load_dict(dict_cfg)
	end
	loaded = true
end

if not cfg.values.lazy_load_dicts then
	mp.register_event("start-file", function()
		load_dicts()
	end)
end

local dicts = {}

function dicts.get()
	if not loaded then
		load_dicts()
	end
	return dicts
end

return dicts
