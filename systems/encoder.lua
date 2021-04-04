-- Immersive is licensed under the terms of the GNU GPL v3: https://www.gnu.org/licenses/; © 2020 Ben Kerman

local anki = require "systems.anki"
local helper = require "utility.helper"
local mpu = require "mp.utils"
local msg = require "systems.message"
local sys = require "systems.system"

local function calc_dimension(cfg_val, prop_name)
	if cfg_val < 0 then return -2 end
	local prop = mp.get_property_number(prop_name)
	return cfg_val < prop and cfg_val or prop
end

local encoder = {}

function encoder.any_audio(params)
	local args = {
		sys.mpv_executable(),
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

	local start_time = mp.get_time()
	sys.subprocess(args)
	msg.debug("encoded audio in " .. mp.get_time() - start_time
	          .. " (" .. params.tgt_path .. ")")
end

function encoder.audio(path, start, stop)
	local tgt = anki.active_target("could not encode audio")
	if not tgt then return end

	local tgt_cfg = tgt.config.audio
	encoder.any_audio{
		src_path = helper.current_path_abs(),
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
	local tgt = anki.active_target("could not extract screenshot")
	if not tgt then return end

	local tgt_cfg = tgt.config.image
	local width = calc_dimension(tgt_cfg.max_width, "width")
	local height = calc_dimension(tgt_cfg.max_height, "height")

	local args = {
		sys.mpv_executable(),
		helper.current_path_abs(),
		"--o=" .. path,
		"--no-ocopy-metadata",
		"--vid=" .. mp.get_property("vid"),
		"--aid=no",
		"--sid=no",
		"--start=" .. time,
		"--frames=1",
		"--of=image2",
		"--ovc=" .. tgt_cfg.codec,
		"--vf-add=scale=" .. width .. ":" .. height
	}

	if tgt_cfg.codec == "mjpeg" then
		table.insert(args, "--ovcopts-add=qmin=" .. tgt_cfg.jpeg.qscale)
		table.insert(args, "--ovcopts-add=qmax=" .. tgt_cfg.jpeg.qscale)
	elseif tgt_cfg.codec == "libwebp" then
		table.insert(args, "--ovcopts-add=lossless=" .. (tgt_cfg.webp.lossless and 1 or 0))
		table.insert(args, "--ovcopts-add=compression_level=" .. tgt_cfg.webp.compression)
		table.insert(args, "--ovcopts-add=quality=" .. tgt_cfg.webp.quality)
	elseif tgt_cfg.codec == "png" then
		table.insert(args, "--ovcopts-add=compression_level=" .. tgt_cfg.png.compression)
	end

	local start_time = mp.get_time()
	sys.subprocess(args)
	msg.debug("encoded image in " .. mp.get_time() - start_time
	          .. " (" .. path .. ")")
end

return encoder
