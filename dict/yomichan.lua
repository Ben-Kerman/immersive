local dict_util = require "dict.dict_util"
local mputil = require "mp.utils"
local sys = require "system"
local util = require "util"

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

				local readings = {{
					rdng = entry.rdng,
					vars = {entry.term}
				}}
				if #entry.alts ~= 0 then
					for _, alt in ipairs(entry.alts) do
						local reading = util.list_find(readings, function(reading)
							return alt.rdng == reading.rdng
						end)

						if reading then
							table.insert(reading.vars, alt.term)
						else table.insert(readings, {
							rdng = alt.rdng,
							vars = {alt.term}
						}) end
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
