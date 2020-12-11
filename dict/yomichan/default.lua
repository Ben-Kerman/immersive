local util = require "util"
local templater = require "templater"
local utf_8 = require "utf_8"

local function get_conf(config)
	local default = {
		digits = nil,
		reading_template = "{{reading}}{{【:】:variants}}",
		header_template = "{{readings[1]}}:{{ (:):readings[2:]}}",
		tag_template = "<span style=\"font-size: 0.8em\">{{tags}}</span><br>\n",
		def_template = "{{tag_list}}{{num}}. {{keywords}}",
		template = "{{header}}<br>\n{{definitions}}"
	}

	local filtered = util.map_filter_keys(config, function(key)
		return util.string_starts(key, "export:")
	end)

	for key, val in pairs(filtered) do
		default[string.sub(key, 8)] = val
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
			local exst_rdng = util.list_find(readings, function(rdng)
				return rdng.rdng == reading.rdng
			end)
			if exst_rdng and reading.vars then
				if not exst_rdng.vars then exst_rdng = reading.vars
				else
					for _, var in ipairs(reading.vars) do
						if not util.list_find(exst_rdng.vars, var) then
							table.insert(reading.vars, var)
						end
					end
				end
			else
				table.insert(readings, reading)
			end
		end
	end

	local reading_strs = util.list_map(readings, function(reading)
		local vars = reading.vars and reading.vars or {}
		return templater.render(cfg.reading_template, {
			reading = {data = reading.rdng},
			variants = {
				data = vars,
				sep = "・"
			}
		})
	end)

	local last_tags
	local definitions = util.list_map(entry, function(sub_entry, i)
		local tag_list = ""

		if last_tags ~= sub_entry.dtgs then
			local tags = util.string_split(sub_entry.dtgs, " ")

			tag_list = templater.render(cfg.tag_template, {
				tags = {
					data = tags,
					transform = function(tag_id)
						local tag_data = tag_map[tag_id]
						return tag_data and tag_data.desc or "UNKNOWN TAG"
					end,
					sep = ", "
				}
			})
			last_tags = sub_entry.dtgs
		end

		return templater.render(cfg.def_template, {
			tag_list = {data = tag_list},
			num = {
				data = i,
				transform = function(num) return format_number(num, cfg.digits) end
			},
			keywords = {
				data = sub_entry.defs,
				sep = "; "
			}
		})
	end)

	local header = templater.render(cfg.header_template, {
		readings = {
			data = reading_strs,
			sep = "　"
		}
	})

	return templater.render(cfg.template, {
		header = {data = header},
		definitions = {
			data = definitions,
			sep = "<br>\n"
		}
	})
end
