local kbds = require "key_bindings"
local ssa = require "ssa"

Menu = {}
Menu.__index = Menu

function Menu:new(data, enabled)
	local m = {
		_overlay = mp.create_osd_overlay("ass-events"),
		data = data,
		enabled = enabled or false,
		show_bindings = false
	}
	return setmetatable(m, Menu)
end

function Menu:enable()
	mp.add_forced_key_binding("h", "_ankisubs-menu_show-bindings", function()
		self.show_bindings = not self.show_bindings
		self:redraw()
	end)
	kbds.add_bindings(self.data.bindings)
	self.enabled = true
	self:redraw()
end

function Menu:disable()
	mp.remove_key_binding("_ankisubs-menu_show-bindings")
	kbds.remove_bindings(self.data.bindings)
	self.enabled = false
	self:redraw()
end

local help_hint_off = ssa.generate{
	base_style = "menu_help",
	base_override = "menu_help",
	"Press ",
	{
		style = "key",
		text = "h"
	},
	" to show key bindings"
}
local help_hint_on = ssa.generate{
	base_style = "menu_help",
	base_override = "menu_help",
	"Key Bindings (",
	{
		style = "key",
		text = "h"
	},
	" to hide)"
}

function Menu:redraw()
	if self.enabled then
		local ssa_lines = {}

		if self.data.bindings then
			local ssa_definition = {
				base_style = "menu_help"
			}
			if self.show_bindings then
				table.insert(ssa_definition, {
					style = "hint",
					text = help_hint_on,
					newline = true
				})
				for _, binding in ipairs(self.data.bindings) do
					table.insert(ssa_definition, [[\h\h\h]])
					table.insert(ssa_definition, {
						style = "key",
						text = binding.default
					})
					table.insert(ssa_definition, ": ")
					table.insert(ssa_definition, binding.desc)
					if binding.global then table.insert(ssa_definition, " (global)") end
					table.insert(ssa_definition, {
						text = "",
						newline = true
					})
				end
			else
				table.insert(ssa_definition, {
					style = "hint",
					text = help_hint_off
				})
			end
			local osd_spacer = string.format([[{\fs%d}\h\N]], mp.get_property_number("osd-font-size"))
			table.insert(ssa_lines, osd_spacer .. ssa.generate(ssa_definition))
		end

		if self.data.infos and not self.show_bindings then
			local ssa_definition = {
				base_style = "menu_info"
			}
			for _, info in ipairs(self.data.infos) do
				local display = info.display and info.display(info.value) or info.value
				table.insert(ssa_definition, {
					style = "key",
					text = info.name
				})
				table.insert(ssa_definition, ": ")
				table.insert(ssa_definition, {
					text = display,
					newline = true
				})
			end
			table.insert(ssa_lines, ssa.generate(ssa_definition))
		end

		self._overlay.data = table.concat(ssa_lines, "\n")
		self._overlay:update()
	else self._overlay:remove() end
end
