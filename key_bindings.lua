local cfg = require "config"

local config = (function()
	local config = {}
	local raw_cfg = cfg.load_subcfg("keys")
	for _, section in ipairs(raw_cfg) do
		config[section.name] = section.entries
	end
	config.global = raw_cfg.global
	return config
end)()

local key_bindings = {}

function key_bindings.query_key(id, group)
	if not group then group = "global" end
	local grp = config[group]
	if grp then return grp[id] end
end

local function params_for_binding(binding, group)
	local group = binding.global and "global" or group
	local cfg_key = key_bindings.query_key(binding.id, group)
	local key = cfg_key and cfg_key or binding.default

	local id = binding.global and binding.id or group .. "-" .. binding.id

	return key, id
end

local function add_bindings_internal(bindings, global)
	for i, binding in ipairs(bindings) do
		if not not binding.global == global then
			local add_fn = binding.global and mp.add_key_binding or mp.add_forced_key_binding
			local key, id = params_for_binding(binding, bindings.group)
			local flags = binding.repeatable and {repeatable = true} or nil

			add_fn(key, id, binding.action, flags)
		end
	end
end

function key_bindings.create_global_bindings(bindings)
	add_bindings_internal(bindings, true)
end

function key_bindings.add_bindings(bindings)
	add_bindings_internal(bindings, false)
end

function key_bindings.remove_bindings(bindings)
	for _, binding in ipairs(bindings) do
		if not binding.global then
			local _, id = params_for_binding(binding, bindings.group)
			mp.remove_key_binding(id)
		end
	end
end

return key_bindings
