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

	local terms = {}
	load_bank("term_bank_", function(term_entry)
		local id = term_entry[7]
		if not terms[id] then terms[id] = {} end

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

		table.insert(terms[id], {
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

	local original_ids = {}
	for original_id, term_list in pairs(terms) do
		table.insert(original_ids, original_id)
		table.sort(term_list, function(ta, tb) return ta.scor > tb.scor end)

		local init_len = #term_list
		for i = 1, init_len do
			local entry = term_list[i]
			if entry then
				for k = i + 1, init_len do
					if term_list[k] and util.list_compare(entry.defs, term_list[k].defs) then
						table.insert(entry.alts, {
							term = term_list[k].term,
							rdng = term_list[k].rdng
						})
						term_list[k] = nil
					end
				end
			end
		end
		util.compact_list(term_list, init_len)
	end

	return {}
end

return yomichan
