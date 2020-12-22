local helper = require "helper"
require "menu"
require "text_select"

-- forward declarations
local menu
local word_sel, def_sel

local function cancel()
	menu:disable()
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
	group = "lookup_active",
	{
		id = "exact",
		default = "ENTER",
		desc = "Look up selected word",
		action = lookup
	},
	{
		id = "partial",
		default = "Shift+ENTER",
		desc = "Look up words starting with selection",
		action = function() lookup(true) end
	},
	{
		id = "cancel",
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
		word_sel = TextSelect:new(sub_text)
		word_sel:start()
		menu:enable()
	end
end

return lookup_active
