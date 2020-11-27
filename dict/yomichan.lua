local dict_util = require "dict.util"
local mputil = require "mp.utils"
local sys = require "system"
local util = require "util"

local yomichan = {}

function yomichan.import(dir)
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
			return filename:find(prefix, 1, true) == 1
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
		table.insert(terms[id], {
			term = term_entry[1],
			rdng = term_entry[2],
			defs = term_entry[6],
			clss = term_entry[4],
			scor = term_entry[5],
			dtgs = term_entry[3],
			ttgs = term_entry[8],
		})
	end)
end

return yomichan
