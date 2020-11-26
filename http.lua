local sys = require "system"

local http = {}

local data_path = sys.tmp_file_name()

function http.request(method, url, data)
	local data_file = io.open(data_path, "w")
	data_file:write(data)
	data_file:close()
	local status, stdout = sys.subprocess {
			"curl","-s",
			url,
			"-X", method,
			"-H", "Content-Type: application/json; charset=UTF-8",
			"--data-binary", "@" .. data_path
		}
	if status ~= 0 then
		mp.msg.error("HTTP " .. method .. " request for URL '" .. url .. "' failed.")
		return nil
	else return stdout end
end

function http.post(url, data)
	return http.request("POST", url, data)
end

return http
