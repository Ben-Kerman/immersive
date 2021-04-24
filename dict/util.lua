-- Immersive is licensed under the terms of the GNU GPL v3: https://www.gnu.org/licenses/; © 2021 Ben Kerman

local cfg = require "systems.config"
local helper = require "utility.helper"
local mpu = require "mp.utils"
local msg = require "systems.message"
local sys = require "systems.system"
local utf_8 = require "utility.utf_8"
local ext = require "utility.extension"

local util = {}

function util.cache_path(dict)
	local cache_dir = mpu.join_path(cfg.cfg_dir, script_name .. "-data/dict-cache")
	if not sys.create_dir(cache_dir) then
		msg.error("failed to create dictionary cache directory")
		return
	end
	return mpu.join_path(cache_dir, dict.id .. ".json")
end

function util.is_imported(dict)
	local cache_path = util.cache_path(dict)
	if cache_path then
		return not not mpu.file_info(cache_path)
	end
end

function util.generic_load(dict, import_fn, force_import)
	if not force_import and util.is_imported(dict) then
		return helper.parse_json_file(util.cache_path(dict))
	end
	return import_fn(dict)
end

function util.create_index(entries, search_term_gen)
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

function util.load_exporter(dict_type, exporter)
	local exporter_id = exporter and exporter or "default"
	local success, exporter = pcall(require, "dict." .. dict_type .. "." .. exporter_id)
	if not success then
		local err_msg = "could not load exporter '" ..
		                exporter_id ..
		                "' for dictionary type '" ..
		                dict_type ..
		                "', falling back to default"
		msg.error(err_msg)
		return require("dict." .. dict_type .. ".default")
	else return exporter end
end

function util.find_start_matches(term, data, search_term_fn)
	local first_char = utf_8.string(utf_8.codepoints(term, 1, 1))
	local start_matches = data.start_index[first_char]
	if not start_matches then
		return nil
	end

	local filtered = ext.list_filter(start_matches, function(id)
		if ext.list_find(search_term_fn(data.entries[id]), function(search_term)
			return ext.string_starts(search_term, term)
		end) then return true end
	end)

	return #filtered ~= 0 and filtered or nil
end

function util.check_dict_data(data)
	if not data then
		msg.error("no data loaded for dictionary")
		return false
	end
	return true
end

local function load_transform(cfg)
	local status, trf_loader = pcall(require, "dict.transform." .. cfg.id)
	if status then
		local args = cfg.args or {}
		return trf_loader(table.unpack(args))
	else return nil, "unknown ID: " .. cfg.id end
end

function util.apply_transforms(term, trf_cfg)
	local terms = {term}
	if not trf_cfg or #trf_cfg == 0 then
		return terms
	end

	for _, trf_cfg in ipairs(trf_cfg) do
		local trf, err = load_transform(trf_cfg)
		if trf then
			for _, res in ipairs(trf(term)) do
				ext.list_insert_cond(terms, res)
			end
		else
			msg.error("ignoring invalid transformation '" .. trf_cfg.id .. "': " .. err)
		end
	end

	return terms
end

function util.lookup_common_transform(term, config, data)
	local terms = util.apply_transforms(term, config.transformations)

	local results = {}
	for _, term in ipairs(terms) do
		local indices = data.index[term]
		if indices then
			for _, res in ipairs(indices) do
				ext.list_insert_cond(results, res)
			end
		end
	end
	return results
end

return util
