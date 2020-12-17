local mputil = require "mp.utils"

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

function system.tmp_file_name()
	local path
	if system.platform == "lnx" then
		local mktemp = io.popen("mktemp")
		path = mktemp:read()
		mktemp:close()
	elseif system.platform == "win" then
		path = os.getenv("TEMP") .. os.tmpname()
	elseif system.platform == "mac" then
		-- TODO
	end
	mp.register_event("shutdown", function() os.remove(path) end)
	return path
end

function system.subprocess(args)
	local res = mp.command_native{
		name = "subprocess",
		playback_only = false,
		capture_stdout = true,
		args = args
	}
	return res.status, res.stdout, res.error_string
end

function system.list_files(dir)
	return mputil.readdir(dir, "files")
end

function system.create_dir(path)
	local args = {"mkdir"}
	if system.platform == "lnx" or system.platform == "mac" then
		table.insert(args, "-p")
	end
	table.insert(args, path)
	system.subprocess(args)
end

local ps_clip_write = [[
Add-Type -AssemblyName System.IO
Add-Type -AssemblyName System.Windows.Forms
$bytes = [IO.File]::ReadAllBytes("%s")
$utf16_str = [Text.Encoding]::UTF8.GetString($bytes)
[Windows.Forms.Clipboard]::SetText($utf16_str)]]

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
		local tmp_file = system.tmp_file_name()
		local fd = io.open(tmp_file, "w")
		fd:write(str)
		fd:close()

		local ps_script = string.format(ps_clip_write, tmp_file)
		system.subprocess{"powershell", "-NoProfile", "-Command", ps_script}
		os.remove(tmp_file)
	end
end

return system
