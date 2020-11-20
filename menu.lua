Menu = {}
Menu.__index = Menu

function Menu:new(data, enabled)
	local m = {
		_overlay = mp.create_osd_overlay("ass-events"),
		data = data,
		enabled = enabled or true,
		show_bindings = false
	}
	setmetatable(m, Menu)
	return m
end

function Menu:enable()
	mp.add_forced_key_binding("h", "_ankisubs-menu_show-bindings", function()
		self.show_bindings = not self.show_bindings
		self:redraw()
	end)
	self.enabled = true
	self:redraw()
end

function Menu:disable()
	mp.remove_forced_key_binding("_ankisubs-menu_show-bindings")
	self.enabled = false
end

function Menu:redraw()
	local lines = {"{\\an4"}
	for _, info in ipairs(self.data.info) do
		table.insert(lines, string.format([[{\b1}%s{\b0}: %s]], info.name, info.value))
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
end
