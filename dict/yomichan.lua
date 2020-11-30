local dict_util = require "dict.dict_util"
local mputil = require "mp.utils"
local sys = require "system"
local utf_8 = require "utf_8"
local util = require "util"

local function create_index(term_list)
	local function index_insert(index, key, value)
		if index[key] then table.insert(index[key], value)
		else index[key] = {value} end
	end

	local index, start_index = {}, {}
	for entry_list_pos, entry_list in ipairs(term_list) do
		local search_terms = {}
		for _, entry in ipairs(entry_list) do
			for _, reading in ipairs(entry.rdng) do
				search_terms[reading.rdng] = true
				if reading.vars then
					for _, var in ipairs(reading.vars) do
						search_terms[var] = true
					end
				end
			end
		end

		local initial_chars = {}
		for term, _ in pairs(search_terms) do
			initial_chars[utf_8.string(utf_8.codepoints(term, 1, 1))] = true

			index_insert(index, term, entry_list_pos)
		end
		for initial_char, _ in pairs(initial_chars) do
			index_insert(start_index, initial_char, entry_list_pos)
		end
	end

	return index, start_index
end

local yomichan = {}

function yomichan.load(dir)
	local files = sys.list_files(dir)
	if not util.list_find(files, "index.json") then
		return nil, "no index file found"
	end

	local index = dict_util.parse_json_file(mputil.join_path(dir, "index.json"))

	local format = index.format and index.format or index.version
	if format ~= 3 then
		return nil, "only v3 Yomichan dictionaries are supported"
	end

	local function load_bank(prefix, action)
		for _, tag_bank in ipairs(util.list_filter(files, function(filename)
			return util.string_starts(filename, prefix)
		end)) do
			local bank_data = dict_util.parse_json_file(mputil.join_path(dir, tag_bank))
			for _, entry in ipairs(bank_data) do
				action(entry)
			end
		end
	end

	local tags = {}
	load_bank("tag_bank_", function(tag_entry)
		tags[tag_entry[1]] = {
			desc = tag_entry[4]
		}
	end)

	local term_map = {}
	load_bank("term_bank_", function(term_entry)
		local id = term_entry[7]
		if not term_map[id] then term_map[id] = {} end

		local defs = term_entry[6]
		for _, def in ipairs(defs) do
			if type(def) ~= "string" then
				-- TODO handle complex def error
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

	local term_list = {}
	for _, entry_list in pairs(term_map) do
		table.sort(entry_list, function(ta, tb) return ta.scor > tb.scor end)

		local init_len = #entry_list
		for i = 1, init_len do
			local entry = entry_list[i]
			if entry then
				for k = i + 1, init_len do
					if entry_list[k] and util.list_compare(entry.defs, entry_list[k].defs) then
						table.insert(entry.alts, {
							term = entry_list[k].term,
							rdng = entry_list[k].rdng
						})
						entry_list[k] = nil
					end
				end

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
		table.insert(term_list, entry_list)
	end

	return {}
end

return yomichan
