-- Immersive is licensed under the terms of the GNU GPL v3: https://www.gnu.org/licenses/; © 2021 Ben Kerman

local ext = require "utility.extension"
local helper = require "utility.helper"
local kbds = require "systems.key_bindings"
local msg = require "systems.message"
local ssa = require "systems.ssa"
local utf_8 = require "utility.utf_8"
local sys = require "systems.system"

local overlay = mp.create_osd_overlay("ass-events")

local function default_update_handler(self, visible, has_sel, curs_pos, segments)
	if visible then
		overlay.data = ssa.generate(self:default_generator(has_sel, curs_pos, segments))
		overlay:update()
	else overlay:remove() end
end

TextSelect = {}
TextSelect.__index = TextSelect

function TextSelect:default_generator(has_sel, curs_pos, segments)
	local cursor = self:cursor()
	local ssa_definition
	if has_sel then
		ssa_definition = {
			segments[1],
			curs_pos < 0 and cursor or "",
			{
				style = {"text_select", "selection"},
				segments[2]
			},
			curs_pos > 0 and cursor or "",
			segments[3],
		}
	else
		ssa_definition = {
			segments[1],
			cursor,
			segments[2]
		}
	end
	return {
		style = "text_select",
		full_style = self.style_reset,
		ssa_definition
	}
end

function TextSelect:cursor()
	local curs_size = self.font_size * 8
	local pbo = curs_size / 6
	return {
		style = {
			border_x = 0.75,
			border_y = 0,
			shadow_x = 1.5,
			shadow_y = 0,
			primary_color = "FFFFFF",
			border_color = "FFFFFF",
			shadow_color = "000000",
			primary_alpha = "00",
			border_alpha = "00",
			shadow_alpha = "00"
		},
		string.format("{\\p4\\pbo%d}m 0 0 l 1 0 l 1 %d l 0 %d{\\p0}", pbo, curs_size, curs_size)
	}
end

function TextSelect:has_sel()
	return self.sel.to - self.sel.from ~= 0
end

function TextSelect:reset_sel()
	self.sel.from = 0
	self.sel.to = 0
end

local function classify_cp(cp)
	if not cp then return "nil" end
	if helper.is_space_or_break(cp) then return "space" end

	if (0x3041 <= cp and cp <= 0x309f) then return "hiragana" end
	if (0x30a0 <= cp and cp <= 0x30ff) then return "katakana" end
	if (0xff65 <= cp and cp <= 0xff9f) then return "hw-katakana" end

	if (0x0010 <= cp and cp <= 0x0019) or (0x0041 <= cp and cp <= 0x005A) or (0x0061 <= cp and cp <= 0x007A) -- Basic Latin/ASCII
	or (0x00c0 <= cp and cp <= 0x00ff and cp ~= 0x00D7 and cp ~= 0x00F7) -- Latin-1 Supplement
	or (0x0100 <= cp and cp <= 0x017f) -- Latin Extended-A
	or (0x0180 <= cp and cp <= 0x024f) -- Latin Extended-B
	or (0x02b0 <= cp and cp <= 0x02ff) -- Spacing Modifier Letters
	or (0x1e00 <= cp and cp <= 0x1eff) -- Latin Extended Additional
	or (0x2c60 <= cp and cp <= 0x2c7f) -- Latin Extended-C
	or (0xa720 <= cp and cp <= 0xa7ff) -- Latin Extended-D
	or (0xab30 <= cp and cp <= 0xab6f) -- Latin Extended-E
	or (0xFB00 <= cp and cp <= 0xFB06) -- Alphabetic Presentation Forms
	or (0xff10 <= cp and cp <= 0xff19) or (0xff21 <= cp and cp <= 0xff3a) or (0xff41 <= cp and cp <= 0xff5a) -- Halfwidth and Fullwidth Forms
	then return "latin" end

	if  (0x4E00 <= cp and cp <=  0x9FFF) -- CJK Unified Ideographs
	or  (0x3300 <= cp and cp <=  0x33FF) -- CJK Compatibility
	or  (0x3400 <= cp and cp <=  0x4DBF) -- CJK Unified Ideographs Extension A
	or  (0xFE30 <= cp and cp <=  0xFE4F) -- CJK Compatibility Forms
	or  (0xF900 <= cp and cp <=  0xFAFF) -- CJK Compatibility Ideographs
	or (0x20000 <= cp and cp <= 0x2A6DF) -- CJK Unified Ideographs Extension B
	or (0x2A700 <= cp and cp <= 0x2B73F) -- CJK Unified Ideographs Extension C
	or (0x2B740 <= cp and cp <= 0x2B81F) -- CJK Unified Ideographs Extension D
	or (0x2B820 <= cp and cp <= 0x2CEAF) -- CJK Unified Ideographs Extension E
	or (0x2CEB0 <= cp and cp <= 0x2EBEF) -- CJK Unified Ideographs Extension F
	or (0x30000 <= cp and cp <= 0x3134F) -- CJK Unified Ideographs Extension G
	or (0x2F800 <= cp and cp <= 0x2FA1F) -- CJK Compatibility Ideographs Supplement
	then return "ideograph" end

	return "other"
end

local function group_text(cdpts)
	local last_class = classify_cp(cdpts[1])
	local groups = {{
		class = last_class,
		first = 1
	}}
	for i, cp in ipairs(cdpts) do
		local class = classify_cp(cp)
		if class == last_class then
			table.insert(groups[#groups], cp)
		else
			groups[#groups].last = i - 1
			table.insert(groups, {
				class = class,
				first = i,
				cp
			})
			last_class = class
		end
	end
	groups[#groups].last = #cdpts
	return groups
end

local function find_group_index(pos, groups)
	if pos < 1 then return 1 end

	for i, group in ipairs(groups) do
		if group.first <= pos and pos <= group.last then
			return i
		end
	end
	return #groups
end

local mvmt_type = {char = {}, word = {}, max = {}}
local mvmt_dir = {left = {}, right = {}}

function TextSelect:move_curs(mdir, mtype, sel)
	local new_sel = {
		curs = self.sel.curs,
		from = self.sel.from,
		to = self.sel.to
	}

	local dir_left = mdir == mvmt_dir.left
	local was_front = self.sel.curs == self.sel.from

	if mtype == mvmt_type.max then
		new_sel.curs = dir_left and 1 or #self.cdpts + 1
		if sel then
			local side = was_front and "to" or "from"
			new_sel.from = dir_left and 1 or self.sel[side]
			new_sel.to = dir_left and self.sel[side] or #self.cdpts + 1
		else
			new_sel.from = new_sel.curs
			new_sel.to = new_sel.curs
		end
	elseif mtype == mvmt_type.word then
		local groups = group_text(self.cdpts)

		local function gt(a, b) return a > b end
		local function lt(a, b) return a < b end

		local dir, offset, bound, from, to, first
		local crs_cmp, bnd_cmp
		if dir_left then
			dir, offset, bound, from, to, first = -1, 0, 1, "from", "to", "first"
			crs_cmp, bnd_cmp = gt, lt
		else
			dir, offset, bound, from, to, first = 1, 1, #groups, "to", "from", "last"
			crs_cmp, bnd_cmp = lt, gt
		end

		local cur_group = find_group_index(self.sel.curs - offset, groups)
		if crs_cmp(self.sel.curs - offset, groups[cur_group][first]) then
			new_sel.curs = groups[cur_group][first] + offset
		elseif cur_group ~= bound then
			local new_group
			if groups[cur_group + dir].class == "space" then
				new_group = crs_cmp(cur_group + (dir * 2), bound) and cur_group + (dir * 2) or bound
			else
				new_group = cur_group + dir
			end
			new_sel.curs = groups[new_group][first] + offset
		end

		if sel then
			if self:has_sel() then
				if self.sel.curs == self.sel[to] and bnd_cmp(new_sel.curs, self.sel[from]) then
					new_sel[from] = new_sel.curs
					new_sel[to] = self.sel[from]
				else
					if was_front then
						new_sel.from = new_sel.curs
					else new_sel.to = new_sel.curs end
				end
			else
				if dir_left then
					new_sel.from = new_sel.curs
				else new_sel.to = new_sel.curs end
			end
		else
			new_sel.from = new_sel.curs
			new_sel.to = new_sel.curs
		end
	else
		if not sel and self:has_sel() then
			if dir_left then
				new_sel.curs = new_sel.from
				new_sel.to = new_sel.from
			else
				new_sel.curs = new_sel.to
				new_sel.from = new_sel.to
			end
		else
			local curs_pos = new_sel.curs + (dir_left and -1 or 1)
			new_sel.curs = ext.num_limit(curs_pos, 1, #self.cdpts + 1)
			if not sel then
				new_sel.from = new_sel.curs
				new_sel.to = new_sel.curs
			elseif self:has_sel() then
				local side = was_front and "from" or "to"
				new_sel[side] = new_sel.curs
			else
				local side = dir_left and "from" or "to"
				new_sel[side] = new_sel.curs
			end
		end
	end
	self.sel = new_sel
	if sys.platform == "lnx" then
		local selection = self:selection()
		if selection and #selection ~= 0 then
			sys.set_primary_sel(selection)
		end
	end
	self:update(true)
end

function TextSelect:show()
	kbds.add(self.bindings)
	self:update(true)
end

function TextSelect:hide()
	kbds.remove(self.bindings)
	self:update(false)
end

function TextSelect:selection(force)
	if force and not self:has_sel() then
		msg.info("no text selected")
		return nil
	end
	return utf_8.string(ext.list_range(self.cdpts, self.sel.from, self.sel.to - 1))
end

function TextSelect:finish(force)
	local sel = self:selection(force)
	if not sel then return end

	self:hide()
	return sel
end

local base_keys = {
	[mvmt_dir.left] = {
		[mvmt_type.char] = "LEFT",
		[mvmt_type.word] = "Ctrl+LEFT",
		[mvmt_type.max] = "HOME"
	},
	[mvmt_dir.right] = {
		[mvmt_type.char] = "RIGHT",
		[mvmt_type.word] = "Ctrl+RIGHT",
		[mvmt_type.max] = "END"
	}
}

local sel_modifier = "Shift+"

local binding_ids = {
	[mvmt_dir.left] = {
		[mvmt_type.char] = {
			[false] = "prev_char",
			[true] = "prev_char_sel"
		},
		[mvmt_type.word] = {
			[false] = "prev_word",
			[true] = "prev_word_sel"
		},
		[mvmt_type.max] = {
			[false] = "home",
			[true] = "home_sel"
		}
	},
	[mvmt_dir.right] = {
		[mvmt_type.char] = {
			[false] = "next_char",
			[true] = "next_char_sel"
		},
		[mvmt_type.word] = {
			[false] = "next_word",
			[true] = "next_word_sel"
		},
		[mvmt_type.max] = {
			[false] = "end",
			[true] = "end_sel"
		}
	}
}

function TextSelect:new(text, update_handler, font_size, no_style_reset, curs_pos)
	if not curs_pos then curs_pos = 1 end

	local ts
	ts = {
		cdpts = utf_8.codepoints(text),
		sel = {curs = curs_pos, from = curs_pos, to = curs_pos},
		update_handler = update_handler and update_handler or default_update_handler,
		font_size = font_size and font_size or ssa.query{"text_select", "font_size"},
		style_reset = not no_style_reset,
		bindings = (function()
			local tbl = {group = "text_select"}
			for mdir, mtypes in pairs(binding_ids) do
				for mtype, sels in pairs(mtypes) do
					for sel, id in pairs(sels) do
						local key = base_keys[mdir][mtype]
						table.insert(tbl, {
							id = id,
							default = sel and sel_modifier .. key or key,
							action = function() ts:move_curs(mdir, mtype, sel) end,
							repeatable = true
						})
					end
				end
			end
			return tbl
		end)()
	}
	return setmetatable(ts, TextSelect)
end

function TextSelect:update(visible)
	if not visible then
		self:update_handler(false)
		return
	end

	local segments = {}
	local curs_pos
	local has_sel = self:has_sel()
	if has_sel then
		table.insert(segments, utf_8.string(ext.list_range(self.cdpts, 1, self.sel.from - 1)))
		table.insert(segments, utf_8.string(ext.list_range(self.cdpts, self.sel.from, self.sel.to - 1)))
		table.insert(segments, utf_8.string(ext.list_range(self.cdpts, self.sel.to, #self.cdpts)))
		curs_pos = self.sel.curs == self.sel.from and -1 or 1
	else
		table.insert(segments, utf_8.string(ext.list_range(self.cdpts, 1, self.sel.curs - 1)))
		table.insert(segments, utf_8.string(ext.list_range(self.cdpts, self.sel.curs, #self.cdpts)))
		curs_pos = 0
	end
	self:update_handler(true, has_sel, curs_pos, segments)
end

return TextSelect
