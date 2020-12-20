local anki = require "anki"
local sys = require "system"

local function calc_dimension(cfg_val, prop_name)
	if cfg_val < 0 then return cfg_val end
	local prop = mp.get_property_number(prop_name)
	return cfg_val < prop and cfg_val or prop
end

local encoder = {}

function encoder.any_audio(params)
	local args = {
		"mpv",
		params.src_path,
		"--o=" .. params.tgt_path,
		"--no-ocopy-metadata",
		"--vid=no",
		"--aid=" .. (params.track or "1"),
		"--sid=no",
		"--of=" ..params. format,
		"--oac=" .. params.codec,
		"--oacopts=b=" .. params.bitrate
	}
	if params.start then table.insert(args, "--start=" .. params.start) end
	if params.stop then table.insert(args, "--end=" .. params.stop) end

	sys.subprocess(args)
end

function encoder.audio(path, start, stop)
	local tgt_cfg = anki.active_target().config.audio
	encoder.any_audio{
		src_path = mp.get_property("path"),
		tgt_path = path,
		track = mp.get_property("aid"),
		format = tgt_cfg.format,
		codec = tgt_cfg.codec,
		bitrate = tgt_cfg.bitrate,
		start = start - tgt_cfg.pad_start,
		stop = stop + tgt_cfg.pad_end
	}
end

function encoder.image(path, time)
	local tgt_cfg = anki.active_target().config.image
	local width = calc_dimension(tgt_cfg.max_width, "width")
	local height = calc_dimension(tgt_cfg.max_height, "height")

	local args = {
		"mpv",
		mp.get_property("path"),
		"--o=" .. path,
		"--no-ocopy-metadata",
		"--vid=" .. mp.get_property("vid"),
		"--aid=no",
		"--sid=no",
		"--start=" .. time,
		"--frames=1",
		"--of=image2",
		"--vf-add=scale=" .. width .. ":" .. height
	}

	local codec = tgt_cfg.codec

	if codec == "mjpeg" then
		table.insert(args, "--ovcopts-add=qmin=" .. tgt_cfg.jpeg.qscale)
		table.insert(args, "--ovcopts-add=qmax=" .. tgt_cfg.jpeg.qscale)
	elseif codec == "libwebp" then
		table.insert(args, "--ovcopts-add=lossless=" .. tgt_cfg.webp.lossless)
		table.insert(args, "--ovcopts-add=compression_level=" .. tgt_cfg.webp.compression)
		table.insert(args, "--ovcopts-add=quality=" .. tgt_cfg.webp.quality)
	elseif codec == "png" then
		table.insert(args, "--ovcopts-add=compression_level=" .. tgt_cfg.png.compression)
	end

	sys.subprocess(args)
end

return encoder
