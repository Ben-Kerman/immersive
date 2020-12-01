local dict_util = require "dict.dict_util"
local mputil = require "mp.utils"
local sys = require "system"
local utf_8 = require "utf_8"
local util = require "util"

local function list_search_terms(entry)
	local search_term_map = {}
	for _, sub_entry in ipairs(entry) do
		for _, reading in ipairs(sub_entry.rdng) do
			search_term_map[reading.rdng] = true
			if reading.vars then
				for _, var in ipairs(reading.vars) do
					search_term_map[var] = true
				end
			end
		end
	end
	local search_terms = {}
	for search_term, _ in pairs(search_term_map) do
		table.insert(search_terms, search_term)
	end
	return search_terms
end

local function create_index(term_list)
	local function index_insert(index, key, value)
		if index[key] then table.insert(index[key], value)
		else index[key] = {value} end
	end

	local index, start_index = {}, {}
	for entry_list_pos, entry_list in ipairs(term_list) do
		-- find all unique readings/spelling variants
		local search_terms = list_search_terms(entry_list)

		-- build index from search_terms and find first characters
		local initial_chars = {}
		for _, term in ipairs(search_terms) do
			initial_chars[utf_8.string(utf_8.codepoints(term, 1, 1))] = true

			index_insert(index, term, entry_list_pos)
		end

		-- build first character index
		for initial_char, _ in pairs(initial_chars) do
			index_insert(start_index, initial_char, entry_list_pos)
		end
	end

	return index, start_index
end

local function verify(dir)
	local stat_res = mputil.file_info(dir)
	if not stat_res or not stat_res.is_dir then
		return nil, "path doesn't exist of is not a directory"
	end

	local files = sys.list_files(dir)
	if not util.list_find(files, "index.json") then
		return nil, "no index found"
	end

	local index = dict_util.parse_json_file(mputil.join_path(dir, "index.json"))

	local format = index.format and index.format or index.version
	if format ~= 3 then
		return nil, "only v3 Yomichan dictionaries are supported"
	end

	local term_banks = util.list_find(files, function(filename)
		return util.string_starts(filename, "term_bank_")
	end)
	if #term_banks == 0 then
		return nil, "no term banks found"
	end

	return true, files
end

local function import(id, dir)
	local verif_res, files_or_error = verify(dir)
	if not verif_res then return nil, files_or_error end

	local function load_bank(prefix, action)
		for _, tag_bank in ipairs(util.list_filter(files_or_error, function(filename)
			return util.string_starts(filename, prefix)
		end)) do
			local bank_data = dict_util.parse_json_file(mputil.join_path(dir, tag_bank))
			for _, entry in ipairs(bank_data) do
				action(entry)
			end
		end
	end

	-- import tags
	local tag_map = {}
	load_bank("tag_bank_", function(tag_entry)
		tag_map[tag_entry[1]] = {
			desc = tag_entry[4]
		}
	end)

	-- import terms
	local term_map = {}
	load_bank("term_bank_", function(term_entry)
		local id = term_entry[7]
		if not term_map[id] then term_map[id] = {} end

		-- check for complex definitions
		local defs = term_entry[6]
		for _, def in ipairs(defs) do
			if type(def) ~= "string" then
				return nil, "complex definition are not supported (ID: " .. id .. ")"
			end
		end

		local reading = term_entry[2]
		if reading == "" then
			reading = nil
		end

		table.insert(term_map[id], {
			term = term_entry[1],
			alts = {},
			rdng = reading,
			defs = defs,
			clss = term_entry[4],
			scor = term_entry[5],
			dtgs = term_entry[3],
			ttgs = term_entry[8]
		})
	end)

	-- convert terms to usable format
	local term_list = {}
	for _, entry_list in pairs(term_map) do
		-- sort by Yomichan usage score
		table.sort(entry_list, function(ta, tb) return ta.scor > tb.scor end)

		local init_len = #entry_list
		for i = 1, init_len do
			local entry = entry_list[i]
			if entry then
				-- combine entries with the same definitions
				for k = i + 1, init_len do
					if entry_list[k] and util.list_compare(entry.defs, entry_list[k].defs) then
						table.insert(entry.alts, {
							term = entry_list[k].term,
							rdng = entry_list[k].rdng
						})
						entry_list[k] = nil
					end
				end

				-- group spellings by reading
				local readings = entry.rdng and {{
					rdng = entry.rdng,
					vars = {entry.term}
				}} or {{rdng = entry.term}}
				if #entry.alts ~= 0 then
					for _, alt in ipairs(entry.alts) do
						local reading = util.list_find(readings, function(reading)
							return alt.rdng == reading.rdng
						end)

						if reading then table.insert(reading.vars, alt.term)
						else table.insert(readings, alt.rdng and {
								rdng = alt.rdng,
								vars = {alt.term}
							} or {rdng = alt.term }) end
					end
				end
				entry.term = nil
				entry.alts = nil
				entry.rdng = readings
			end
		end
		util.compact_list(entry_list, init_len)

		-- having entries as a list makes JSON import/export easier
		table.insert(term_list, entry_list)
	end

	dict_util.write_json_file(dict_util.cache_path(id), {
		terms = term_list,
		tags = tag_map
	})

	return term_list, tag_map
end

local yomichan = {}

function yomichan.load(dict_id, config)
	local terms, tag_map = (function()
		local cache_path = dict_util.cache_path(dict_id)
		if mputil.file_info(cache_path) then
			local data = dict_util.parse_json_file(cache_path)
			return data.terms, data.tags
		else return import(dict_id, config.location) end
	end)()

	return true
end

return yomichan
