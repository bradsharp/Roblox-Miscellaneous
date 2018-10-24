local bind = {}
local lookup = {}

function bind:__index(index)
	if type(index) ~= "number" then error("Index must be numeric") end
	local value = {}
	rawset(self, index, value)
	lookup[value] = index
	return value
end

function bind:__call(...)
	local args = {...}
	local method = table.remove(args)
	if type(method) ~= "function" then error("bad argument to 'bind' (function expected") end
	local binding = {}
	for i = 1, #args do
		local value = args[i]
		local index = lookup[value]
		if index then binding[i] = index end
	end
	return function (...)
		local unbound = {...}
		for i, j in pairs(binding) do
			args[i] = unbound[j]
		end
		return method(unpack(args))
	end
end

return setmetatable({}, bind)
