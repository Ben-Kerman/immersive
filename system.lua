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
			data_home = string.format([[%s/.local/share]], os.getenv("HOME"))
		end
		return string.format([[%s/Anki2]], data_home)
	elseif system.platform == "win" then
		return string.format([[%s/Anki2]], os.getenv("APPDATA"):gsub("\\", "/"))
	elseif system.platform == "mac" then
		return string.format([[%s/Library/Application Support/Anki2]], os.getenv("HOME"))
	end
end)()

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
	local files = {}
	local cmd

	if system.platform == "lnx" then
		cmd = string.format([[find '%s' -type f -printf '%%P\n']], dir)
	elseif system.platform == "win" then
		cmd = string.format([[powershell -Command "Get-ChildItem -Path ""%s"" -File -Name"]], dir)
	elseif system.platform == "mac" then
		-- TODO
		mp.osd_message("list_files is not implemented on macOS")
		return {}
	end

	local find = io.popen(cmd)
	for file in find:lines() do
		table.insert(files, file)
	end
	find:close()

	return files
end

return system
