local cfg = require "config"
local kbds = require "key_bindings"
local ssa = require "ssa"

local Menu = {}
Menu.__index = Menu

local help_key = (function()
	local cfg_key = kbds.query_key("show_help", "menu")
	return cfg_key and cfg_key or "h"
end)()

function Menu:new(data, enabled)
	local m = {
		_overlay = mp.create_osd_overlay("ass-events"),
		bindings = data.bindings,
		infos = data.infos,
		enabled = enabled or false,
		show_help = cfg.values.enable_help
	}
	return setmetatable(m, Menu)
end

local show_help = cfg.values.enable_help
function Menu:get_show_help()
	if cfg.values.global_help then
		return show_help
	else return self.show_help end
end

function Menu:set_show_help(val)
	if cfg.values.global_help then
		show_help = val
	else self.show_help = val end
end

function Menu:show()
	mp.add_forced_key_binding(help_key, "menu-show_help", function()
		self:set_show_help(not self:get_show_help())
		self:redraw()
	end)
	kbds.add(self.bindings)
	self.enabled = true
	self:redraw()
end

function Menu:hide()
	mp.remove_key_binding("menu-show_help")
	kbds.remove(self.bindings)
	self.enabled = false
	self:redraw()
end

function Menu:cancel()
	self:hide()
end

local help_hint_off = {
	style = {"menu_help", "hint"},
	"Press ",
	{
		style = {"menu_help", "key"},
		help_key
	},
	" to show key bindings"
}
local help_hint_on = {
	style = {"menu_help", "hint"},
	newline = true,
	"Key Bindings (",
	{
		style = {"menu_help", "key"},
		help_key
	},
	" to hide)"
}

function Menu:redraw()
	if self.enabled then
		local ssa_lines = {}

		if self.bindings then
			local ssa_definition = {
				style = "menu_help",
				full_style = true
			}

			if self:get_show_help() then
				table.insert(ssa_definition, help_hint_on)

				for _, binding in ipairs(self.bindings) do
					local grp = binding.global and "global" or self.bindings.group
					local cfg_key = kbds.query_key(binding.id, grp)

					local binding_ssa_def = {
						newline = true,
						"\\h\\h\\h",
						{
							style = {"menu_help", "key"},
							cfg_key and cfg_key or binding.default
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

			table.insert(ssa_lines, "\\h\\N" .. ssa.generate(ssa_definition))
		end

		local show_infos = not cfg.values.hide_infos_if_help_active or not self:get_show_help()
		if self.infos and show_infos then
			local ssa_definition = {
				style = "menu_info",
				full_style = true
			}

			for _, info in ipairs(self.infos) do
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

return Menu
