local mputil = require "mp.utils"

local dict_util = {}

function dict_util.parse_json_file(path)
	local file = io.open(path)
	local data = file:read("*a")
	file:close()
	return mputil.parse_json(data)
end

return dict_util
