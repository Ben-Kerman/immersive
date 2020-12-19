local sys = require "system"

local socket_name = (function()
	if sys.platform == "lnx" then
		return "/tmp/ankisubs_socket"
	elseif sys.platform == "win" then
		return [[\\.\socket\ankisubs_socket]]
	elseif sys.platform == "mac" then
		return "" -- TODO
	end
end)()

local mpv_process = sys.background_process{
	"mpv",
	"--no-config",
	"--vid=no",
	"--sid=no",
	"--idle",
	"--input-ipc-server=" .. socket_name
}

local function player_command(cmd)
	if sys.platform == "lnx" then
		local pipe = io.popen("socat - " .. socket_name, "w")
		pipe:write(cmd)
		pipe:close()
	elseif sys.platform == "win" then
		local fd = io.open(socket_name, "w")
		fd:write(cmd)
		fd:close()
	elseif sys.platform == "mac" then
		return "" -- TODO
	end
end

mp.register_event("shutdown", function() player_command('{"command":["quit"]}\n') end)

local player = {}

function player.play(path)
	local cmd = string.format('{"command":["loadfile","%s"]}\n', path:gsub("\"", [[\"]]))
	player_command(cmd)
end

return player