-- Immersive is licensed under the terms of the GNU GPL v3: https://www.gnu.org/licenses/; © 2020 Ben Kerman

local cfg = require "systems.config"
local msg = require "systems.message"
local ext = require "utility.extension"

local config = (function()
	local config = {}
	local raw_cfg = cfg.load_subcfg("keys")
	for _, section in ipairs(raw_cfg) do
		config[section.name] = section.entries
	end
	config.global = raw_cfg.global
	return config
end)()

local global_bindings = {}

local key_bindings = {}

function key_bindings.query_key(id, group)
	if not group then group = "global" end
	local grp = config[group]
	if grp then return grp[id] end
end

local function params_for(binding, group)
	local group = binding.global and "global" or group
	local cfg_key = key_bindings.query_key(binding.id, group)
	local key = cfg_key and cfg_key or binding.default

	local id = binding.global and binding.id or group .. "-" .. binding.id

	return key, id
end

local function add_internal(bindings, global)
	for i, binding in ipairs(bindings) do
		if not not binding.global == global then
			local add_fn = binding.global and mp.add_key_binding or mp.add_forced_key_binding
			local key, id = params_for(binding, bindings.group)
			local flags = binding.repeatable and {repeatable = true} or nil

			msg.trace("key add " .. id .. " " .. key)
			add_fn(key, id, binding.action, flags)
		end
	end
end

function key_bindings.create_global(bindings)
	add_internal(bindings, true)
	ext.list_append(global_bindings, bindings, true)
end

function key_bindings.add(bindings)
	add_internal(bindings, false)
end

local function remove_internal(bindings, global)
	for _, binding in ipairs(bindings) do
		if not not binding.global == global then
			local _, id = params_for(binding, bindings.group)

			msg.trace("key remove " .. id)
			mp.remove_key_binding(id)
		end
	end
end

function key_bindings.disable_global()
	remove_internal(global_bindings, true)
end

function key_bindings.enable_global()
	add_internal(global_bindings, true)
end

function key_bindings.remove(bindings)
	remove_internal(bindings, false)
end

return key_bindings
