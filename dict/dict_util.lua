local mputil = require "mp.utils"
local sys = require "system"

local dict_util = {}

function dict_util.cache_path(dict_id)
	local config_dir =  mp.find_config_file("."):sub(1, -3)
	local cache_dir = mputil.join_path(config_dir, mp.get_script_name() .. "-dict-cache")
	if not mputil.file_info(cache_dir) then
		sys.create_dir(cache_dir)
	end
	return mputil.join_path(cache_dir, dict_id .. ".json")
end

function dict_util.parse_json_file(path)
	local file = io.open(path)
	local data = file:read("*a")
	file:close()
	return mputil.parse_json(data)
end

function dict_util.write_json_file(path, data)
	local file = io.open(path, "w")
	file:write((mputil.format_json(data)))
	file:close()
end

return dict_util
