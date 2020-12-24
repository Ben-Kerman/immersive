local dict_util = require "dict.dict_util"
local mpu = require "mp.utils"
local msg = require "message"
local sys = require "system"
local util = require "util"

local default_qdef_template = "{{readings:::・}}{{variants:【:】:・}}: {{definitions:::; }}"

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

local function verify(dir)
	if not dir then
		return false, "no directory at specified location"
	end

	local stat_res = mpu.file_info(dir)
	if not stat_res or not stat_res.is_dir then
		return false, "path doesn't exist of is not a directory"
	end

	local files = sys.list_files(dir)
	if not util.list_find(files, "index.json") then
		return false, "no index found"
	end

	local index = dict_util.parse_json_file(mpu.join_path(dir, "index.json"))

	local format = index.format and index.format or index.version
	if format ~= 3 then
		return false, "only v3 Yomichan dictionaries are supported"
	end

	local term_banks = util.list_find(files, function(filename)
		return util.string_starts(filename, "term_bank_")
	end)
	if #term_banks == 0 then
		return false, "no term banks found"
	end

	return true, files
end

local function import(id, dir)
	local verif_res, files_or_error = verify(dir)
	if not verif_res then
		msg.error("failed to load Yomichan dict (" .. id .. "): " .. files_or_error)
		return nil
	end

	local function load_bank(prefix, action)
		for _, bank in ipairs(util.list_filter(files_or_error, function(filename)
			return util.string_starts(filename, prefix)
		end)) do
			local bank_data = dict_util.parse_json_file(mpu.join_path(dir, bank))
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
		if #reading == 0 then
			reading = nil
		end

		table.insert(term_map[id], {
			term = term_entry[1],
			rdng = reading,
			defs = defs,
			clss = term_entry[4],
			scor = term_entry[5],
			dtgs = term_entry[3],
			ttgs = term_entry[8]
		})
	end)

	-- convert terms to usable format
	local entries = {}
	for _, entry in pairs(term_map) do
		-- sort by Yomichan usage score
		table.sort(entry, function(ta, tb) return ta.scor > tb.scor end)

		local init_len = #entry
		for i = 1, init_len do
			local sub_entry = entry[i]
			if sub_entry then
				local readings = {sub_entry.rdng and {
					rdng = sub_entry.rdng,
					vars = {sub_entry.term}
				} or {rdng = sub_entry.term}}

				-- combine entries with the same definitions and group variants by reading
				for k = i + 1, init_len do
					if entry[k] and util.list_compare(sub_entry.defs, entry[k].defs) then
						local other_rdng = entry[k].rdng and entry[k].rdng or entry[k].term
						local other_var = entry[k].rdng and entry[k].term or nil

						local reading = util.list_find(readings, function(reading)
							return other_rdng == reading.rdng
						end)

						if reading then
							if other_var then
								table.insert(reading.vars, other_var)
							end
						else
							table.insert(readings, {
								rdng = other_rdng,
								vars = {other_var}
							})
						end

						entry[k] = nil
					end
				end

				sub_entry.term = nil
				sub_entry.rdng = readings
			end
		end
		util.compact_list(entry, init_len)

		-- having entries as a list makes JSON import/export easier
		table.insert(entries, entry)
	end

	local index, start_index = dict_util.create_index(entries, list_search_terms)
	local data = {
		tags = tag_map,
		entries = entries,
		index = index,
		start_index = start_index
	}
	dict_util.write_json_file(dict_util.cache_path(id), data)
	return data
end

local function generate_dict_table(config, data)
	local function get_quick_def(entry)
		local readings, variants, defs = {}, {}, {}
		for _, sub_entry in ipairs(entry) do
			for _, reading in ipairs(sub_entry.rdng) do
				util.list_insert_cond(readings, reading.rdng)
				if reading.vars then
					for i, var in ipairs(reading.vars) do
						util.list_insert_cond(variants, var)
					end
				end
			end
			for _, def in ipairs(sub_entry.defs) do
				table.insert(defs, def)
			end
		end
		if #variants == 0 then variants = nil end
		return {readings = readings, variants = variants, defs = defs}
	end

	local function export_entries(ids)
		if not ids then return nil end

		local entries = util.list_map(ids, function(id)
			return {id = id, entry = data.entries[id]}
		end)
		table.sort(entries, function(entry_a, entry_b)
			return entry_a.entry[1].scor > entry_b.entry[1].scor
		end)
		return util.list_map(entries, function(entry)
			local quick_def = get_quick_def(entry.entry)
			quick_def.id = entry.id
			return quick_def
		end)
	end

	return {
		quick_def_template = config.quick_def_template and config.quick_def_template or default_qdef_template,
		look_up_exact = function(term)
			return export_entries(data.index[term])
		end,
		look_up_start = function(term)
			return export_entries(dict_util.find_start_matches(term, data, list_search_terms))
		end,
		get_definition = function(id)
			local entry = data.entries[id]
			local word
			if entry[1].rdng[1].vars then
				word = entry[1].rdng[1].vars[1]
			else word = entry[1].rdng[1].rdng end

			local exporter_id = config.exporter and config.exporter or "default"
			local exporter = require("dict.yomichan." .. exporter_id)
			return {word = word, definition = exporter(entry, config, data.tags)}
		end
	}
end

local yomichan = {}

function yomichan.load(dict_id, config)
	local start = mp.get_time()

	local data
	local cache_path = dict_util.cache_path(dict_id)
	if mpu.file_info(cache_path) then
		data = dict_util.parse_json_file(cache_path)
	else data = import(dict_id, config.location) end

	msg.debug(dict_id .. " (Yomichan): " .. mp.get_time() - start)
	return generate_dict_table(config, data)
end

return yomichan
