local util = require "util"
local templater = require "templater"

local function get_conf(config)
	local default = {
		reading_sep = "　",
		variant_sep = "・",
		reading_template = "{{reading}}【{{variants}}】",
		def_digits = nil,
		def_prefix = "{{num}}. ",
		def_sep = "; ",
		tag_sep = ", ",
		tag_template = [[<span style="font-size: 0.8em">{{tags}}</span>]]
	}

	local filtered = util.map_filter_keys(config, function(key)
		return util.string_starts(key, "export:")
	end)

	for key, val in pairs(filtered) do
		default[string.sub(key, 8)] = val
	end

	return default
end

return function(entry, config)
	local cfg = get_conf(config)
	local lines = {}

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
		local vars = ""
		if reading.vars then
			vars = table.concat(reading.vars, cfg.variant_sep)
		end
		return templater.render(cfg.reading_template, {
			reading = reading.rdng,
			variants = vars
		})
	end)

	return table.concat(reading_strs, cfg.reading_sep)
end
