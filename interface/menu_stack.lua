-- Immersive is licensed under the terms of the GNU GPL v3: https://www.gnu.org/licenses/; © 2020 Ben Kerman

local stack = {}

local function exec_top(fn_name)
	if #stack ~= 0 then
		local top = stack[#stack]
		top[fn_name](top)
	end
end

local menu_stack = {}

function menu_stack.push(menu)
	if not menu then return end

	exec_top("hide")
	table.insert(stack, menu)
	exec_top("show")
end

function menu_stack.pop(count)
	if not count then count = 1 end
	for i = 1, count do
		exec_top("cancel")
		table.remove(stack)
	end
	exec_top("show")
end

function menu_stack.clear()
	for _, menu in ipairs(stack) do
		menu:cancel()
	end
	stack = {}
end

function menu_stack.save(count)
	exec_top("hide")

	local menus = {}
	for i = 1, count do
		table.insert(menus, table.remove(stack))
	end
	exec_top("show")
	return menus
end

function menu_stack.restore(menus)
	exec_top("hide")

	for i = #menus, 1, -1 do
		table.insert(stack, menus[i])
	end
	exec_top("show")
end

function menu_stack.drop(menus)
	for _, menu in ipairs(menus) do
		menu:cancel()
	end
end

function menu_stack.top()
	return stack[#stack]
end

return menu_stack
