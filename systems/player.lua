-- Immersive is licensed under the terms of the GNU GPL v3: https://www.gnu.org/licenses/; © 2020 Ben Kerman

local mpu = require "mp.utils"
local sys = require "systems.system"

local socket_name = (function()
	local filename = script_name .. "_socket"
	if sys.platform == "lnx" then
		return "/tmp/" .. filename
	elseif sys.platform == "win" then
		return [[\\.\pipe\]] .. filename
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

function player.play(path, start, stop)
	local cmd = {"loadfile", path, "replace"}
	if start or stop then
		table.insert(cmd, {
			start = start and tostring(start),
			["end"] = stop and tostring(stop)
		})
	end
	player_command(mpu.format_json({command = cmd}) .. "\n")
end

return player
