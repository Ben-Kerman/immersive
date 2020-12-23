local cfg = require "config"

local dicts = {}

local function load_dict(dict_cfg)
	local dict_id, entries = dict_cfg.name, dict_cfg.entries
	if entries.location and entries.type then
		local status, loader = pcall(require, "dict." .. entries.type)
		if status then
			table.insert(dicts, loader.load(dict_id, entries))
		else
			-- TODO handle error
		end
	end
end

for _, dict_cfg in ipairs(cfg.load_subcfg("dictionaries")) do
	load_dict(dict_cfg)
end

return dicts
