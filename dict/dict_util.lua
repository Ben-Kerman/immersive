local mpu = require "mp.utils"
local sys = require "system"
local utf_8 = require "utf_8"

local dict_util = {}

function dict_util.cache_path(dict_id)
	local config_dir =  mp.find_config_file("."):sub(1, -3)
	local cache_dir = mpu.join_path(config_dir, mp.get_script_name() .. "-dict-cache")
	if not mpu.file_info(cache_dir) then
		sys.create_dir(cache_dir)
	end
	return mpu.join_path(cache_dir, dict_id .. ".json")
end

function dict_util.parse_json_file(path)
	local file = io.open(path)
	local data = file:read("*a")
	file:close()
	return mpu.parse_json(data)
end

function dict_util.write_json_file(path, data)
	local file = io.open(path, "w")
	file:write((mpu.format_json(data)))
	file:close()
end

function dict_util.create_index(entries, search_term_gen)
	local function index_insert(index, key, value)
		if index[key] then table.insert(index[key], value)
		else index[key] = {value} end
	end

	local index, start_index = {}, {}
	for entry_pos, entry in ipairs(entries) do
		-- find all unique readings/spelling variants
		local search_terms = search_term_gen(entry)

		-- build index from search_terms and find first characters
		local initial_chars = {}
		for _, term in ipairs(search_terms) do
			initial_chars[utf_8.string(utf_8.codepoints(term, 1, 1))] = true

			index_insert(index, term, entry_pos)
		end

		-- build first character index
		for initial_char, _ in pairs(initial_chars) do
			index_insert(start_index, initial_char, entry_pos)
		end
	end

	return index, start_index
end

return dict_util
