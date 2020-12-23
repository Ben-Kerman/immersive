local msg = require "message"
local sys = require "system"

local data_path = sys.tmp_file_name()

local function request(params, async, callback)
	local args = {
		"curl","-s",
		params.url,
		"-X", params.method
	}

	if params.data then
		table.insert(args, "--data-binary")
		table.insert(args, "@" .. data_path)
		table.insert(args, "-H")
		table.insert(args, "Content-Type: " .. params.data_type)

		local data_file = io.open(data_path, "w")
		data_file:write(params.data)
		data_file:close()
	end

	if params.headers then
		for _, header in ipairs(params.headers) do
			table.insert(args, "-H")
			table.insert(args, string.format("%s: %s", header.name, header.value))
		end
	end

	if params.target_path then
		table.insert(args, "-o")
		table.insert(args, params.target_path)
	end

	local function handle_result(status, stdout)
		if status ~= 0 then
			msg.verbose("HTTP " .. params.method .. " request for URL '" .. params.url .. "' failed.")
		else return stdout end
	end

	if async then
		local internal_callback = callback and function(status, stdout, error_string)
			callback(handle_result(status, stdout))
		end
		return sys.background_process(args, internal_callback)
	else
		local status, stdout = sys.subprocess(args)
		return handle_result(status, stdout)
	end
end

local http = {}

function http.request(params)
	return request(params)
end

function http.post(params)
	params.method = "POST"
	return http.request(params)
end

function http.post_json(params)
	params.data_type = "application/json; charset=UTF-8"
	return http.post(params)
end

function http.get(params)
	params.method = "GET"
	return http.request(params)
end

function http.request_async(params, callback)
	return request(params, true, callback)
end

function http.get_async(params, callback)
	params.method = "GET"
	return http.request_async(params, callback)
end

return http
