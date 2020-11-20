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

return system
