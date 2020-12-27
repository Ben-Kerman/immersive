local config = require "systems.config"
local templater = require "systems.templater"
local utf_8 = require "utility.utf_8"
local ext = require "utility.extension"

local function get_conf(config)
	local default = {
		digits = nil,
		reading_template = "{{reading}}{{variants:【:】:・}}",
		definition_template = "{{tags:<span style=\"font-size\\: 0.8em\">:</span><br>:, }}{{num}}. {{keywords:::; }}",
		template = "{{readings[1]}}:{{readings[2:] (:):　}}<br>{{definitions:::<br>}}",
		use_single_template = true,
		single_template = "{{readings[1]::　}}:{{readings[2:] (:):　}} {{keywords:::; }}"
	}

	local filtered = ext.map_filter_keys(config, function(key)
		return ext.string_starts(key, "export:")
	end)

	for key, val in pairs(filtered) do
		key_no_prefix = string.sub(key, 8)
		if type(default[key_no_prefix]) == "boolean" then
			val = config.convert_bool(val)
		end
		default[key_no_prefix] = val
	end

	return default
end

local function format_number(num, digit_str)
	local basic = tostring(num)
	if not digit_str then return basic end

	local replacements = utf_8.codepoints(digit_str)
	local digits = utf_8.codepoints(basic)
	local new_digits = {}
	for _, digit in ipairs(digits) do
		table.insert(new_digits, replacements[digit - 47])
	end
	local ret = utf_8.string(new_digits)
	return ret
end

return function(entry, config, tag_map)
	local cfg = get_conf(config)

	local readings = {}
	for _, sub_entry in ipairs(entry) do
		for _, reading in ipairs(sub_entry.rdng) do
			local exst_rdng = ext.list_find(readings, function(rdng)
				return rdng.rdng == reading.rdng
			end)
			if exst_rdng and reading.vars then
				if not exst_rdng.vars then exst_rdng = reading.vars
				else
					for _, var in ipairs(reading.vars) do
						if not ext.list_find(exst_rdng.vars, var) then
							table.insert(reading.vars, var)
						end
					end
				end
			elseif not exst_rdng then
				table.insert(readings, reading)
			end
		end
	end

	local reading_strs = ext.list_map(readings, function(reading)
		local vars = reading.vars and reading.vars or {}
		return templater.render(cfg.reading_template, {
			reading = {data = reading.rdng},
			variants = {data = vars}
		})
	end)

	local last_tag_ids
	local definitions = ext.list_map(entry, function(sub_entry, i)
		local tag_template_data
		local tag_ids =  ext.string_split(sub_entry.dtgs, " ")
		if not ext.list_compare(last_tag_ids, tag_ids) then
			tag_template_data = {
				data = tag_ids,
				transform = function(tag_id)
					local tag_data = tag_map[tag_id]
					return tag_data and tag_data.desc or "(UNKNOWN TAG)"
				end
			}
			last_tag_ids = tag_ids
		end

		return {
			tags = tag_template_data and tag_template_data or false,
			num = {
				data = i,
				transform = function(num) return format_number(num, cfg.digits) end
			},
			keywords = {data = sub_entry.defs}
		}
	end)

	if #definitions == 1 and cfg.use_single_template then
		return templater.render(cfg.single_template, {
			readings = {data = reading_strs},
			keywords = definitions[1].keywords
		})
	else
		return templater.render(cfg.template, {
			readings = {data = reading_strs},
			definitions = {
				data = definitions,
				transform = function(def_data)
					return templater.render(cfg.definition_template, def_data)
				end
			}
		})
	end
end
