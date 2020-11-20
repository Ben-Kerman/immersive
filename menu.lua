Menu = {}
Menu.__index = Menu

function Menu:new(data, enabled)
	local m = {
		_overlay = mp.create_osd_overlay("ass-events"),
		data = data,
		enabled = enabled and true,
		show_bindings = false
	}
	return setmetatable(m, Menu)
end

function Menu:enable()
	mp.add_forced_key_binding("h", "_ankisubs-menu_show-bindings", function()
		self.show_bindings = not self.show_bindings
		self:redraw()
	end)
	for i, binding in ipairs(self.data.bindings) do
		mp.add_forced_key_binding(binding.key, "_ankisubs-menu_binding-" .. i, binding.action)
	end
	self.enabled = true
	self:redraw()
end

function Menu:disable()
	mp.remove_key_binding("_ankisubs-menu_show-bindings")
	for i, _ in ipairs(self.data.bindings) do
		mp.remove_key_binding("_ankisubs-menu_binding-" .. i)
	end
	self.enabled = false
	self:redraw()
end

function Menu:redraw()
	if self.enabled then
		local lines = {"{\\an4"}
		for _, info in ipairs(self.data.infos) do
			local display = info.display and info.display(info.value) or info.value
			table.insert(lines, string.format([[{\b1}%s{\b0}: %s]], info.name, display))
		end

		if self.show_bindings then
			table.insert(lines, "{\\i1}Key Bindings{\\i0}:")
			for _, binding in ipairs(self.data.bindings) do
				table.insert(lines,
					string.format([[\h\h\h\h{\b1}%s{\b0}: %s]], binding.key, binding.desc))
			end
		else table.insert(lines, [[{\i1}Press {\b1}h{\b0} to show key bindings{\i0}]]) end
		self._overlay.data = table.concat(lines, "\\N")
		self._overlay:update()
	else self._overlay:remove() end
end
