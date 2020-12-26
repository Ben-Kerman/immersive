local cfg = require "config"
local mpu = require "mp.utils"
local msg = require "message"
local utf_8 = require "utf_8"
local util = require "util"

local system = {}

system.platform = (function()
	-- taken from mpv's built-in console
	local default = {}
	if mp.get_property_native("options/vo-mmcss-profile", default) ~= default then
		return "win"
	elseif mp.get_property_native("options/macos-force-dedicated-gpu", default) ~= default then
		return "mac"
	end
	return "lnx"
end)()

system.anki_base_dir = (function()
	if system.platform == "lnx" then
		local data_home = os.getenv("XDG_DATA_HOME")
		if not data_home then
			data_home = string.format("%s/.local/share", os.getenv("HOME"))
		end
		return string.format("%s/Anki2", data_home)
	elseif system.platform == "win" then
		return string.format("%s\\Anki2", os.getenv("APPDATA"))
	elseif system.platform == "mac" then
		return string.format("%s/Library/Application Support/Anki2", os.getenv("HOME"))
	end
end)()

function system.tmp_dir()
	if system.platform == "lnx" then
		local tmpdir_env = os.getenv("TMPDIR")
		if tmpdir_env then return tmpdir_env
		else return "/tmp" end
	elseif system.platform == "win" then
		return os.getenv("TEMP")
	elseif system.platform == "mac" then
		-- TODO
	end
end

local function handle_process_result(success, res, err)
	if not res then
		msg.error("failed to run subprocess: '" .. err .. "'; arguments: " .. mpu.format_json(args))
		return
	end
	return res.status, res.stdout, res.error_string, res.killed_by_us
end

function system.subprocess(args)
	local res, err = mp.command_native{
		name = "subprocess",
		playback_only = false,
		capture_stdout = true,
		args = args
	}
	return handle_process_result(res, res, err)
end

function system.background_process(args, callback)
	return mp.command_native_async({
		name = "subprocess",
		playback_only = false,
		capture_stdout = true,
		args = args
	}, function(success, res, err)
		if callback then
			callback(handle_process_result(success, res, err))
		end
	end)
end

function system.list_files(dir)
	return mpu.readdir(dir, "files")
end

function system.create_dir(path)
	local stat_res = mpu.file_info(path)
	if stat_res then
		return stat_res.is_dir
	end

	local args = {"mkdir"}
	if system.platform == "lnx" or system.platform == "mac" then
		table.insert(args, "-p")
	end
	table.insert(args, path)
	return system.subprocess(args) == 0
end

function system.move_file(src_path, tgt_path)
	local cmd
	if system.platform == "lnx" or system.platform == "mac" then
		cmd = "mv"
	elseif system.platform == "win" then
		cmd = "move"
	end
	return system.subprocess{cmd, src_path, tgt_path} == 0
end

local ps_clip_write_fmt = "Set-Clipboard ([Text.Encoding]::UTF8.GetString((%s)))"
local function ps_clip_write(str)
	local bytes = {}
	for i = 1, #str do
		table.insert(bytes, (str:byte(i)))
	end
	return string.format(ps_clip_write_fmt, table.concat(bytes, ","))
end

local ps_clip_read = [[
Add-Type -AssemblyName System.Windows.Forms
$clip = [Windows.Forms.Clipboard]::GetText()
$utf8 = [Text.Encoding]::UTF8.GetBytes($clip)
[Console]::OpenStandardOutput().Write($utf8, 0, $utf8.length)]]

function system.clipboard_read()
	local args
	if system.platform == "lnx" then
		args = {"xclip", "-out", "-selection", "clipboard"}
	elseif system.platform == "win" then
		args = {"powershell", "-NoProfile", "-Command", ps_clip_read}
	elseif system.platform == "mac" then
		args = {}-- TODO
	end

	local status, clip, err_str = system.subprocess(args)
	if status == 0 then return clip
	else return nil, err_str end
end

function system.clipboard_write(str)
	local args
	if system.platform == "lnx" or system.platform == "mac" then
		local cmd
		if system.platform == "lnx" then
			cmd = "xclip -in -selection clipboard"
		elseif system.platform == "mac" then
			cmd = "" -- TODO
		end

		local pipe = io.popen(cmd, "w")
		pipe:write(str)
		pipe:close()
	elseif system.platform == "win" then
		if cfg.values.windows_clip_mode == "exact" then
			msg.debug("exact copy " .. str)
			system.background_process{"powershell", "-NoProfile", "-Command", ps_clip_write(str)}
		else
			msg.debug("quick copy: " .. str)
			mp.commandv("run", "cmd", "/d", "/c", "chcp 65001 & echo " .. str:gsub("[\r\n]+", " ") .. " | clip")
		end
	end
end

return system
