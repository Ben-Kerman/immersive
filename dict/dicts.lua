local config = require "config"

local dicts = {}

local dict_configs = config.load_subcfg("dictionaries")
for _, dict_config in ipairs(dict_configs) do
	local dict, entries = dict_config.dict, dict_config.entries
	if entries.location and entries.type then
		local status, loader = pcall(require, "dict." .. entries.type)
		if status then
			table.insert(dicts, loader.load(entries.location))
		else
			-- TODO handle error
		end
	end
end

return dicts
