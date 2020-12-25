local cfg = require "config"
local mpu = require "mp.utils"
local msg = require "message"

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
		callback(handle_process_result(success, res, err))
	end)
end

function system.list_files(dir)
	return mpu.readdir(dir, "files")
end

function system.create_dir(path)
	local args = {"mkdir"}
	if system.platform == "lnx" or system.platform == "mac" then
		table.insert(args, "-p")
	end
	table.insert(args, path)
	system.subprocess(args)
end

function system.move_file(src_path, tgt_path)
	local cmd
	if system.platform == "lnx" or system.platform == "mac" then
		cmd = "mv"
	elseif system.platform == "win" then
		cmd = "move"
	end
	system.subprocess{cmd, src_path, tgt_path}
end

local ps_clip_write_semi_exact = [[
Add-Type -AssemblyName System.IO
Add-Type -AssemblyName System.Windows.Forms
$bytes = [IO.File]::ReadAllBytes("%s")
$utf16_str = [Text.Encoding]::UTF8.GetString($bytes)
[Windows.Forms.Clipboard]::SetText($utf16_str)]]

local ps_clip_write_exact = require("base64").encode("\065\000\100\000\100\000\045\000\084\000\121\000\112\000\101\000\032\000\045\000\065\000\115\000\115\000\101\000\109\000\098\000\108\000\121\000\078\000\097\000\109\000\101\000\032\000\083\000\121\000\115\000\116\000\101\000\109\000\046\000\087\000\105\000\110\000\100\000\111\000\119\000\115\000\046\000\070\000\111\000\114\000\109\000\115\000\010\000\036\000\109\000\115\000\116\000\114\000\109\000\032\000\061\000\032\000\091\000\083\000\121\000\115\000\116\000\101\000\109\000\046\000\073\000\079\000\046\000\077\000\101\000\109\000\111\000\114\000\121\000\083\000\116\000\114\000\101\000\097\000\109\000\093\000\058\000\058\000\110\000\101\000\119\000\040\000\041\000\010\000\091\000\083\000\121\000\115\000\116\000\101\000\109\000\046\000\067\000\111\000\110\000\115\000\111\000\108\000\101\000\093\000\058\000\058\000\079\000\112\000\101\000\110\000\083\000\116\000\097\000\110\000\100\000\097\000\114\000\100\000\073\000\110\000\112\000\117\000\116\000\040\000\041\000\046\000\067\000\111\000\112\000\121\000\084\000\111\000\040\000\036\000\109\000\115\000\116\000\114\000\109\000\041\000\010\000\036\000\098\000\121\000\116\000\101\000\115\000\032\000\061\000\032\000\036\000\109\000\115\000\116\000\114\000\109\000\046\000\084\000\111\000\065\000\114\000\114\000\097\000\121\000\040\000\041\000\010\000\036\000\117\000\116\000\102\000\049\000\054\000\095\000\115\000\116\000\114\000\032\000\061\000\032\000\091\000\084\000\101\000\120\000\116\000\046\000\069\000\110\000\099\000\111\000\100\000\105\000\110\000\103\000\093\000\058\000\058\000\085\000\084\000\070\000\056\000\046\000\071\000\101\000\116\000\083\000\116\000\114\000\105\000\110\000\103\000\040\000\036\000\098\000\121\000\116\000\101\000\115\000\041\000\010\000\091\000\087\000\105\000\110\000\100\000\111\000\119\000\115\000\046\000\070\000\111\000\114\000\109\000\115\000\046\000\067\000\108\000\105\000\112\000\098\000\111\000\097\000\114\000\100\000\093\000\058\000\058\000\083\000\101\000\116\000\084\000\101\000\120\000\116\000\040\000\036\000\117\000\116\000\102\000\049\000\054\000\095\000\115\000\116\000\114\000\041\000")
--[[ unencoded:
Add-Type -AssemblyName System.Windows.Forms
$mstrm = [System.IO.MemoryStream]::new()
[System.Console]::OpenStandardInput().CopyTo($mstrm)
$bytes = $mstrm.ToArray()
$utf16_str = [Text.Encoding]::UTF8.GetString($bytes)
[Windows.Forms.Clipboard]::SetText($utf16_str)
]]

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
		if cfg.windows_clip_mode == "exact" then
			msg.debug("exact copy:", str)
			local pipe = io.popen("powershell -NoProfile -EncodedCommand " .. ps_clip_write_exact, "w")
			pipe:write(str)
			pipe:close()
		elseif cfg.windows_clip_mode == "semi-exact" then
			msg.debug("semi-exact copy", str)
			local tmp_file = system.tmp_file_name()
			local fd = io.open(tmp_file, "w")
			fd:write(str)
			fd:close()

			local ps_script = string.format(ps_clip_write_semi_exact, tmp_file)
			system.subprocess{"powershell", "-NoProfile", "-Command", ps_script}
			os.remove(tmp_file)
		else
			msg.debug("quick copy", str)
			mp.commandv("run", "cmd", "/d", "/c", "@echo off & chcp 65001 & echo " .. str:gsub("[\r\n]+", " ") .. " | clip")
		end
	end
end

return system
