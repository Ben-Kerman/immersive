-- Immersive is licensed under the terms of the GNU GPL v3: https://www.gnu.org/licenses/; © 2021 Ben Kerman

local cfg = require "systems.config"
local cfg_util = require "systems.config_util"
local msg = require "systems.message"
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
		single_template = "{{readings[1]}}:{{readings[2:] (:):　}} {{keywords:::; }}"
	}

	for key, val in pairs(config) do
		if ext.string_starts(key, "export:") then
			default[string.sub(key, 8)] = val
		end
	end

	return default
end

local function format_number(num, replacements)
	local basic = tostring(num)
	if not replacements then return basic end

	local digits = utf_8.codepoints(basic)
	local new_digits = {}
	for _, digit in ipairs(digits) do
		table.insert(new_digits, replacements[digit - 47])
	end
	local ret = utf_8.string(new_digits)
	return ret
end

return function(entry, config, tag_map)
	local exp_cfg = get_conf(config)

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
							table.insert(exst_rdng.vars, var)
						end
					end
				end
			elseif not exst_rdng then
				table.insert(readings, reading)
			end
		end
	end

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
				transform = function(num) return format_number(num, exp_cfg.digits) end
			},
			keywords = {data = sub_entry.defs}
		}
	end)

	local reading_data = {
		data = readings,
		transform = function(reading)
			return templater.render(exp_cfg.reading_template, {
				reading = {data = reading.rdng},
				variants = {data = reading.vars and reading.vars or {}}
			})
		end
	}

	if #definitions == 1 and exp_cfg.use_single_template then
		return templater.render(exp_cfg.single_template, {
			readings = reading_data,
			keywords = definitions[1].keywords
		})
	else
		return templater.render(exp_cfg.template, {
			readings = reading_data,
			definitions = {
				data = definitions,
				transform = function(definition)
					return templater.render(exp_cfg.definition_template, definition)
				end
			}
		})
	end
end
