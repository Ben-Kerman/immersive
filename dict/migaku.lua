local dict_util = require "dict.dict_util"
local helper = require "helper"
local mpu = require "mp.utils"
local msg = require "message"
local templater = require "templater"
local util = require "util"

local default_qdef_template = "{{definitions}}"

local function list_search_terms(entry)
	return util.list_append(entry.trms, entry.alts)
end

local function verify(file)
	if not file then
		return false, "no file at specifier location"
	end

	local stat_res = mpu.file_info(file)
	if not stat_res or not stat_res.is_file then
		return false, "path doesn't exist of is not a regular file"
	end

	return true
end

local function import(dict)
	local verif_res, err_msg = verify(dict.config.location)
	if not verif_res then
		msg.error("failed to load Migaku dict (" .. dict.id .. "): " .. err_msg)
		return nil
	end

	local raw_entries = helper.parse_json_file(dict.config.location)

	local entry_map = {}
	for _, raw_entry in ipairs(raw_entries) do
		local def = raw_entry.definition
		if not entry_map[def] then entry_map[def] = {} end

		table.insert(entry_map[def], {
			term = raw_entry.term,
			alt = #raw_entry.altterm ~= 0 and raw_entry.altterm or nil,
			pron = raw_entry.pronunciation ~= 0 and raw_entry.pronunciation or nil,
			pos = raw_entry.pos ~= 0 and raw_entry.pos or nil,
			exmp = raw_entry.examples ~= 0 and raw_entry.examples or nil
		})
	end

	local entries = {}
	for def, raw_entries in pairs(entry_map) do
		local terms, alts, prns, poss, examples = {}, {}, {}, {}, {}
		for _, raw_entry in ipairs(raw_entries) do
			util.list_insert_cond(terms, raw_entry.term)
			util.list_insert_cond(alts, raw_entry.alt)
			util.list_insert_cond(prns, raw_entry.prn)
			util.list_insert_cond(poss, raw_entry.pos)
			util.list_insert_cond(examples, raw_entry.exmp)
		end
		table.insert(entries, {
			trms = terms,
			alts = #alts ~= 0 and alts or nil,
			def = def,
			prns = #prns ~= 0 and prns or nil,
			poss = #poss ~= 0 and poss or nil,
			exps = #examples ~= 0 and examples or nil
		})
	end

	local index, start_index = dict_util.create_index(entries, list_search_terms)
	local data = {
		entries = entries,
		index = index,
		start_index = start_index
	}
	helper.write_json_file(dict_util.cache_path(dict), data)
	return data
end

local function generate_dict_table(config, data)
	local function export_entries(ids)
		if not ids then return nil end

		return util.list_map(ids, function(id)
			local entry = data.entries[id]
			return {
				id = id,
				terms = entry.trms,
				alts = entry.alts,
				defs = {util.string_trim((entry.def:gsub("<br>", "\n")))}
			}
		end)
	end

	local exporter = dict_util.load_exporter("migaku", config.exporter)
	return {
		format_quick_def = function(qdef)
			local template = config.quick_def_template and config.quick_def_template or default_qdef_template
			return templater.render(template, {
				terms = {data = qdef.terms},
				altterms = qdef.alts and {data = qdef.alts} or false,
				definitions = {data = qdef.defs}
			})
		end,
		look_up_exact = function(term)
			return export_entries(data.index[term])
		end,
		look_up_start = function(term)
			return export_entries(dict_util.find_start_matches(term, data, list_search_terms))
		end,
		get_definition = function(id)
			local entry = data.entries[id]
			local word = entry.trms[1]

			return {word = word, definition = exporter(entry, config)}
		end
	}
end

local migaku = {}

function migaku.load(dict, force_import)
	local start = mp.get_time()
	local data = dict_util.generic_load(dict, import, force_import)
	msg.debug(dict.id .. " (Migaku): " .. mp.get_time() - start)
	return generate_dict_table(dict.config, data)
end

return migaku
