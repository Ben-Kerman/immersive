local kbds = require "key_bindings"
local ssa = require "ssa"

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
	kbds.add_bindings(self.data.bindings, "_ankisubs-menu_binding-")
	self.enabled = true
	self:redraw()
end

function Menu:disable()
	mp.remove_key_binding("_ankisubs-menu_show-bindings")
	kbds.remove_bindings(self.data.bindings, "_ankisubs-menu_binding-")
	self.enabled = false
	self:redraw()
end

local function ssa_format(str, cat, id)
	return ssa.format(str, ssa.get{cat, id}, ssa.get{cat, "base"})
end
local help_hint_off = ssa_format(string.format("Press %s to show key bindings", ssa_format("h", "menu_help", "key")), "menu_help", "help")
local help_hint_on = ssa_format(string.format("Key Bindings (%s to hide)", ssa_format("h", "menu_help", "key")), "menu_help", "help")

function Menu:redraw()
	if self.enabled then
		local ssa_lines = {}

		if self.data.bindings then
			local binding_lines = {
				string.format("{\\fs%d}\\N%s",
				              mp.get_property_number("osd-font-size"),
				              ssa.generate({"menu_help", "base"}, nil, true))
			}
			if self.show_bindings then
				table.insert(binding_lines, help_hint_on)
				for _, binding in ipairs(self.data.bindings) do
					table.insert(binding_lines, string.format([[\h\h\h%s: %s]], ssa_format(binding.key, "menu_help", "key"), binding.desc))
				end
			else table.insert(binding_lines, help_hint_off) end
			table.insert(ssa_lines, table.concat(binding_lines, "\\N"))
		end

		local info_lines = {ssa.generate({"menu_info", "base"}, nil, true)}
		if self.data.infos then
			for _, info in ipairs(self.data.infos) do
				local display = info.display and info.display(info.value) or info.value
				table.insert(info_lines, string.format([[%s: %s]], ssa_format(info.name, "menu_info", "key"), display))
			end
			if not self.show_bindings then table.insert(ssa_lines, table.concat(info_lines, "\\N")) end
		end

		self._overlay.data = table.concat(ssa_lines, "\n")
		self._overlay:update()
	else self._overlay:remove() end
end
