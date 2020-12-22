local key_bindings = {}

local function add_bindings_internal(bindings, global)
	for i, binding in ipairs(bindings) do
		if not not binding.global == global then
			local add_fn = binding.global and mp.add_key_binding or mp.add_forced_key_binding

			local flags = binding.repeatable and {repeatable = true} or nil
			add_fn(binding.default, binding.id, binding.action, flags)
		end
	end
end

function key_bindings.add_global_bindings(bindings)
	add_bindings_internal(bindings, true)
end

function key_bindings.add_bindings(bindings)
	add_bindings_internal(bindings, false)
end

function key_bindings.remove_bindings(bindings)
	for _, binding in ipairs(bindings) do
		if not binding.global then
			mp.remove_key_binding(binding.id)
		end
	end
end

return key_bindings
