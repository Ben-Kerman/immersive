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
	mp.add_forced_key_binding("h", "menu-show_help", function()
		self.show_bindings = not self.show_bindings
		self:redraw()
	end)
	kbds.add_bindings(self.data.bindings)
	self.enabled = true
	self:redraw()
end

function Menu:disable()
	mp.remove_key_binding("menu-show_help")
	kbds.remove_bindings(self.data.bindings)
	self.enabled = false
	self:redraw()
end

local help_hint_off = {
	style = {"menu_help", "hint"},
	"Press ",
	{
		style = {"menu_help", "key"},
		"h"
	},
	" to show key bindings"
}
local help_hint_on = {
	style = {"menu_help", "hint"},
	newline = true,
	"Key Bindings (",
	{
		style = {"menu_help", "key"},
		"h"
	},
	" to hide)"
}

function Menu:redraw()
	if self.enabled then
		local ssa_lines = {}

		if self.data.bindings then
			local ssa_definition = {
				style = "menu_help",
				full_style = true
			}

			if self.show_bindings then
				table.insert(ssa_definition, help_hint_on)

				for _, binding in ipairs(self.data.bindings) do
					local binding_ssa_def = {
						newline = true,
						"\\h\\h\\h",
						{
							style = {"menu_help", "key"},
							binding.default
						},
						": ",
						binding.desc
					}
					if binding.global then
						table.insert(binding_ssa_def, " (global)")
					end
					table.insert(ssa_definition, binding_ssa_def)
				end
			else table.insert(ssa_definition, help_hint_off) end

			local osd_spacer = string.format([[{\fs%d}\h\N]], mp.get_property_number("osd-font-size"))
			table.insert(ssa_lines, osd_spacer .. ssa.generate(ssa_definition))
		end

		if self.data.infos and not self.show_bindings then
			local ssa_definition = {
				style = "menu_info",
				full_style = true
			}

			for _, info in ipairs(self.data.infos) do
				local display = info.display and info.display(info.value) or info.value
				table.insert(ssa_definition, {
					newline = true,
					{
						style = {"menu_info", "key"},
						info.name
					},
					": ",
					display
				})
			end
			table.insert(ssa_lines, ssa.generate(ssa_definition))
		end

		self._overlay.data = table.concat(ssa_lines, "\n")
		self._overlay:update()
	else self._overlay:remove() end
end
