local config = require "config"

local dicts = {}

local dict_configs = config.load_subcfg("dictionaries")
for _, dict_config in ipairs(dict_configs) do
	local dict_id, entries = dict_config.name, dict_config.entries
	if entries.location and entries.type then
		local status, loader = pcall(require, "dict." .. entries.type)
		if status then
			table.insert(dicts, loader.load(dict_id, entries))
		else
			-- TODO handle error
		end
	end
end

return dicts
