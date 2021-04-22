-- Immersive is licensed under the terms of the GNU GPL v3: https://www.gnu.org/licenses/; © 2021 Ben Kerman

local mpu = require "mp.utils"
local msg = require "systems.message"
local sys = require "systems.system"

local socket_name = (function()
	local filename = script_name .. "." .. mpu.getpid() .. ".socket"
	if sys.platform == "lnx" or sys.platform == "mac" then
		return mpu.join_path(sys.tmp_dir, filename)
	elseif sys.platform == "win" then
		return [[\\.\pipe\]] .. filename
	end
end)()

local mpv_process = sys.background_process{
	sys.mpv_executable(),
	"--no-config",
	"--vo=null",
	"--sid=no",
	"--idle",
	"--input-ipc-server=" .. socket_name
}

local function player_command(cmd)
	local fd
	if sys.platform == "lnx" then
		fd = io.popen("socat - " .. socket_name, "w")
	elseif sys.platform == "win" then
		fd = io.open(socket_name, "w")
	elseif sys.platform == "mac" then
		fd = io.popen("nc -w 0 -U \"" .. socket_name .. "\"", "w")
	end
	if fd then
		fd:write(mpu.format_json{command = cmd} .. "\n")
		fd:close()
	else msg.error("could not connect to background player") end
end

mp.register_event("shutdown", function()
	player_command{"quit"}
	os.remove(socket_name)
end)

local player = {}

function player.play(path, start, stop, aid)
	local cmd = {"loadfile", path, "replace"}
	if start or stop or aid then
		table.insert(cmd, {
			aid = aid and tostring(aid),
			start = start and tostring(start),
			["end"] = stop and tostring(stop)
		})
	end
	player_command(cmd)
end

return player
