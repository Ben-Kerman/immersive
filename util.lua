local util = {}

function util.list_find(list, predicate)
	if type(predicate) == "function" then
		for _, val in ipairs(list) do
			if predicate(val) then return val end
		end
	else
		for _, val in ipairs(list) do
			if val == predicate then return val end
		end
	end
end

function util.list_slice(list, start, length)
	local slice = {}
	for i = start, start + length do
		table.insert(slice, list[i])
	end
	return slice
end

function util.list_range(list, from, to)
	if to < 0 then to = #list + to + 1 end
	return util.list_slice(list, from, to - from)
end

function util.list_compare(list_a, list_b, cmp)
	if #list_a ~= #list_b then return false end

	if not cmp then
		cmp = function(a ,b) return a == b end
	end

	for i, val_a in ipairs(list_a) do
		if not cmp(val_a, list_b[i]) then
			return false
		end
	end
	return true
end

function util.list_max(list, cmp)
	if not cmp then
		cmp = function(a ,b) return a < b end
	end

	local max = list[1]
	for i, v in ipairs(list) do
		if cmp(max, v) then max = v end
	end
	return max
end

function util.list_filter(list, predicate)
	local res = {}
	for _, val in ipairs(list) do
		if predicate(val) then
			table.insert(res, val)
		end
	end
	return res
end

function util.list_map(list, mapper)
	local res = {}
	for i, val in ipairs(list) do
		table.insert(res, mapper(val, i))
	end
	return res
end

function util.compact_list(list, init_len)
	local next_index = 1
	for i = 1, init_len do
		if list[i] then
			if i ~= next_index then
				list[next_index] = list[i]
				list[i] = nil
			end
			next_index = next_index + 1
		end
	end
end

function util.map_filter_keys(map, predicate)
	local res = {}
	for key, val in pairs(map) do
		if predicate(key, val) then
			res[key] = val
		end
	end
	return res
end

function util.map_map(map, mapper)
	local res = {}
	for key, val in pairs(map) do
		local mapped_key, mapped_val = mapper(key, val)
		local new_key = mapped_key and mapped_key or key
		local new_val = mapped_val and mapped_val or val
		res[new_key] = new_val
	end
	return res
end

function util.string_starts(str, prefix)
	return str:find(prefix, 1, true) == 1
end

function util.string_ends(str, suffix)
	local _, last_pos str:find(suffix, 1, true)
	return last_pos == #str
end

function util.string_trim(str, where)
	local _, lead_end = str:find("^%s+")
	local trail_start, _ = str:find("%s+$")

	local first, last
	if not where or where == "start" then
		first = lead_end and lead_end + 1 or 1
	else first = 1 end
	if not where or where == "end" then
		last = trail_start and trail_start - 1 or #str
	else last = #str end
	return str:sub(first, last)
end

function util.string_split(str, pattern, filter_empty)
	if type(str) ~= "string"
	   or type(pattern) ~= "string"
	   or #pattern == 0 then
		return nil
	end
	local res = {}
	local start = 1
	while true do
		local m_start, m_end = str:find(pattern, start)
		if m_start then
			local sub = str:sub(start, m_start - 1)
			if not filter_empty or #sub > 0 then table.insert(res, sub) end
			start = m_end + 1
		else
			local sub = str:sub(start, #str)
			if not filter_empty or #sub > 0  then table.insert(res, sub) end
			break
		end
	end
	return res
end

return util
