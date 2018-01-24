local typeError = "bad argument to 'bind' (function expected, got %s)"

local bind = {}
local toIndex, fromIndex = {}, {}

function bind:__index(index)
	local indexType = type(index)
	if indexType ~= "number" then error("Index must be numeric", 2) end
	local binding = fromIndex[index]
	if not binding then
		binding = {}
		toIndex[binding] = index
		fromIndex[index] = binding
	end
	return binding
end

function bind:__call(...)
	local boundArgs = {...}
	local binding = {}
	for i = 1, #boundArgs do
		local arg = boundArgs[i]
		local index = toIndex[arg]
		if index then binding[i] = index end
	end
	local callback = table.remove(boundArgs)
	local callbackType = type(callback)
	if callbackType ~= "function" then error(typeError:format(callbackType), 2) end
	return function (...)
		local args = {...}
		for i, j in pairs(binding) do
			print(i, j, args[j], boundArgs[i])
			boundArgs[i] = args[j]
		end
		callback(unpack(boundArgs))
	end
end

return setmetatable(bind, bind)
