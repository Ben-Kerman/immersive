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
			data_home = string.format([[%s/.local/share]], os.getenv("HOME"))
		end
		return string.format([[%s/Anki2]], data_home)
	elseif system.platform == "win" then
		return string.format([[%s/Anki2]], os.getenv("APPDATA"):gsub("\\", "/"))
	elseif system.platform == "mac" then
		return string.format([[%s/Library/Application Support/Anki2]], os.getenv("HOME"))
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
	if system.platform == "lnx" or system.platform == "mac" then
		os.execute(string.format("mkdir -p '%s'", path))
	elseif system.platform == "win" then
		-- TODO
	end
end

return system
