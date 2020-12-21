local helper = require "helper"
require "menu"
require "text_select"

-- forward declarations
local menu
local overlay = mp.create_osd_overlay("ass-events")
local word_sel, def_sel

local function cancel()
	menu:disable()
	overlay:remove()
	if word_sel then
		word_sel:finish()
		word_sel = nil
	end
	if def_sel then
		def_sel:finish()
		def_sel = nil
	end
end

local function lookup(prefix)
	if def_sel then
		cancel()
	else
		local selection = word_sel:finish(true)
		if not selection then
			mp.osd_message("No word selected")
			return nil
		end

		word_sel = nil
		def_sel = DefinitionSelect:new(selection, prefix)
		if not def_sel then
			mp.osd_message("No entry found for selected word")
			start_tgt_sel()
		end
	end
end

local bindings = {
	{
		id = "lookup_active-exact",
		default = "ENTER",
		desc = "Look up selected word",
		action = lookup
	},
	{
		id = "lookup_active-partial",
		default = "Shift+ENTER",
		desc = "Look up words starting with selection",
		action = function() lookup(true) end
	},
	{
		id = "lookup_active-cancel",
		default = "ESC",
		desc = "Cancel lookup",
		action = cancel
	}
}

menu = Menu:new{bindings = bindings}

local lookup_active = {}

function lookup_active.begin()
	local sub_text = helper.check_active_sub()
	if sub_text then
		word_sel = TextSelect:new(sub_text, function(has_sel, curs_pos, segments)
			overlay.data = word_sel:default_generator(has_sel, curs_pos, segments)
			overlay:update()
		end)
		word_sel:start()
		menu:enable()
	end
end

return lookup_active
