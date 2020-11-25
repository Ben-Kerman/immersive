local cfg = require "config"
local sys = require "system"
local util = require "util"

local active_target_index = 1

local function default_tgt_cfg()
	return {
		audio = {
			extension = "mka",
			format = "matroska",
			codec = "libopus",
			bitrate = "64k",
			pad_start = 0.1,
			pad_end = 0.1
		},
		image = {
			extension = "jpg",
			codec = "mjpeg",
			max_width = -1,
			max_height = -1,
			jpeg = {
				qscale = 5
			},
			webp = {
				lossless = false,
				quality = 90,
				compression = 4
			},
			png = {
				compression = 9
			}
		},
		anki = {
			tags = {"ankisubs"},
			fields = {}
		}
	}
end

local anki = {
	targets = {}
}

-- parse target definitions
for name, profile, deck, note_type
	in cfg.values.anki_targets:gmatch("%[([^:]+):([^;]+);([^;]+);([^%]]+)%]") do
	table.insert(anki.targets, {
		name = name, profile = profile, deck = deck, note_type = note_type, config = default_tgt_cfg()
	})
end

-- parse target config file
local tgt_cfg_path = mp.find_config_file("script-opts/" .. mp.get_script_name() .. "-targets.conf")
local tgt_cfg_file = io.open(tgt_cfg_path)
local iter, lines, line = tgt_cfg_file:lines()
while true do
	line = iter(lines, line)
	if line == nil then break end

	local target_name = line:match("%[([^%]]+)%]")
	if target_name then
		local target = util.list_find(anki.targets, function(target)
			return target.name == target_name
		end)

		if not target then mp.osd_message("Config for unknown target '" .. target_name .. "' found.")
		else
			repeat
				line = iter(lines, line)
				if not line then break end
				local key, value = line:match("([^=]+)=(.*)")
				if key then
					local f_start, f_end = key:find("field:", 1, true)
					if f_start == 1 then
						target.config.anki.fields[key:sub(f_end + 1)] = value
					elseif key == "anki/tags" then
						target.config.anki.tags = util.string_split(value)
					else
						local components = util.string_split(key, "/")
						local entry = target.config
						print(require("luajson.json").encode(components))
						for i, comp in ipairs(components) do
							if not entry[comp] then
								mp.osd_message("Config key '" .. key .. "' doesn't exist")
							elseif i ~= #components then entry = entry[comp] end
						end
						if type(entry[components[#components]]) == "number" then
							entry[components[#components]] = tonumber(value)
						else entry[components[#components]] = value end
					end
				end
				-- TODO else -> error
			until line == ""
		end
	end
end
tgt_cfg_file:close()

function anki.active_target()
	return anki.targets[active_target_index]
end

function anki.media_dir()
	local profile = anki.active_target().profile
	return string.format("%s/%s/collection.media", sys.anki_base_dir, profile)
end

function anki.generate_filename(series_id, extension)
	local files = sys.list_files(anki.media_dir())
	local existing = util.list_filter(files, function(file)
		return file:find(series_id, 1, true) == 1
		       and file:match("%." .. extension .. "$")
	end)
	local next_number
	if #existing == 0 then next_number = 0
	else
		next_number = 1 + util.list_max(util.list_map(existing, function(file)
			local _, id_end = file:find(series_id, 1, true)
			return tonumber((file:match("%-(%d+)", id_end + 1)))
		end))
	end
	return string.format("%s-%04d.%s", series_id, next_number, extension)
end

return anki
