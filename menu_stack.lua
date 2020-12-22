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

function menu_stack.pop()
	exec_top("cancel")
	table.remove(stack)
	exec_top("show")
end

function menu_stack.clear()
	exec_top("cancel")
	stack = {}
end

return menu_stack
