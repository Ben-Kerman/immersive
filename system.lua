local system = {}

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
