local sys = require "system"

local http = {}

function http.request(method, url, data)
	local status, stdout = sys.subprocess {
			"curl",-- "-s",
			url,
			"-X", method,
			"-d", data
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
