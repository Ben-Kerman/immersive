local extension = {}

function extension.list_find(list, predicate)
	local test = predicate
	if type(predicate) ~= "function" then
		test = function(val) return val == predicate end
	end
	for i, val in ipairs(list) do
		if test(val) then return val, i end
	end
end

function extension.list_slice(list, start, length)
	local slice = {}
	for i = start, start + length do
		table.insert(slice, list[i])
	end
	return slice
end

function extension.list_range(list, from, to)
	if not to then to = #list
	elseif to < 0 then to = #list + to + 1 end
	return extension.list_slice(list, from, to - from)
end

function extension.list_compare(list_a, list_b, cmp)
	if list_a == list_b then return true end
	if not list_a ~= not list_b then
		return false
	end
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

function extension.list_max(list, cmp)
	if not cmp then
		cmp = function(a ,b) return a < b end
	end

	local max = list[1]
	for i, v in ipairs(list) do
		if cmp(max, v) then max = v end
	end
	return max
end

function extension.list_filter(list, predicate)
	local res = {}
	for _, val in ipairs(list) do
		if predicate(val) then
			table.insert(res, val)
		end
	end
	return res
end

function extension.list_map(list, mapper)
	if not mapper then
		mapper = function(val) return val end
	end

	local res = {}
	for i, val in ipairs(list) do
		table.insert(res, mapper(val, i))
	end
	return res
end

function extension.list_flat_map(list, mapper)
	if not mapper then
		mapper = function(val) return val end
	end

	local res = {}
	for i, elem in ipairs(list) do
		for _, map_elem in ipairs(mapper(elem, i)) do
			table.insert(res, map_elem)
		end
	end
	return res
end

function extension.list_reverse(list)
	local res = {}
	for i = #list, 1, -1 do
		table.insert(res, list[i])
	end
	return res
end

function extension.list_unique(list)
	local res = {}
	for _, elem in ipairs(list) do
		if not extension.list_find(res, elem) then
			table.insert(res, elem)
		end
	end
	return res
end

function extension.compact_list(list, init_len)
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

function extension.list_append(tgt, src, inplace)
	local res
	if inplace then res = tgt
	else
		res = {}
		for _, elem in ipairs(tgt) do
			table.insert(res, elem)
		end
	end

	if src then
		for _, elem in ipairs(src) do
			table.insert(res, elem)
		end
	end
	return res
end

function extension.list_insert_cond(list, value)
	if not extension.list_find(list, value) then
		table.insert(list, value)
	end
end

function extension.map_filter_keys(map, predicate)
	local res = {}
	for key, val in pairs(map) do
		if predicate(key, val) then
			res[key] = val
		end
	end
	return res
end

function extension.map_map(map, mapper)
	local res = {}
	for key, val in pairs(map) do
		local mapped_key, mapped_val = mapper(key, val)
		local new_key = mapped_key and mapped_key or key
		local new_val = mapped_val and mapped_val or val
		res[new_key] = new_val
	end
	return res
end

function extension.map_merge(target, source)
	local res = {}
	for key, val in pairs(target) do
		res[key] = val
	end
	if source then
		for key, val in pairs(source) do
			res[key] = val
		end
	end
	return res
end

function extension.string_starts(str, prefix)
	return str:find(prefix, 1, true) == 1
end

function extension.string_ends(str, suffix)
	local _, last_pos str:find(suffix, 1, true)
	return last_pos == #str
end

function extension.string_trim(str, where)
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

function extension.string_split(str, pattern, filter_empty)
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

function extension.num_limit(num, min, max)
	if not num then
		return min and min or max
	end

	if min then
		local lower = math.max(num, min)
		if max then
			return math.min(lower, max)
		else return lower end
	elseif max then
		local upper = math.min(num, max)
		if min then
			return math.max(upper, min)
		else return upper end
	else return num end
end

return extension
