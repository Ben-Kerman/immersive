local key_bindings = {}

function key_bindings.add_bindings(bindings, id)
	for i, binding in ipairs(bindings) do
		local flags = binding.repeatable and {repeatable = true} or nil
		mp.add_forced_key_binding(binding.key, id .. i, binding.action, flags)
	end
end

function key_bindings.remove_bindings(bindings, id)
	for i, _ in ipairs(bindings) do
		mp.remove_key_binding(id .. i)
	end
end

return key_bindings
