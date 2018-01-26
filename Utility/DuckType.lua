local TYPE_ERROR = "bad argument #%d to '%s' (%s expected, got %s)"

local typeCheckedFunction = {}
typeCheckedFunction.__index = typeCheckedFunction

local getFunctionName do
	local trace = debug.traceback
	local match = "getFunctionName.-Line %d+ %- %w-%s(.-)\n"
	function getFunctionName()
		return trace():match(match) or "..."
	end
end

local verify do
	local compareType do
		local function getTableType(t)
			local metatable = getmetatable(t)
			return type(metatable) == "table" and rawget(metatable, "__type") or "table"
		end
		function compareType(arg, e)
			local t = typeof(arg)
			if t == e then return true end
			if t == "Instance" then return arg:IsA(e) end
			if t == "table" then return getTableType(arg) == e end
			return false
		end
	end
	function verify(args, signature)
		for i = 1, #signature do
			local arg = args[i]
			local e = signature[i]
			if e == "..." then break end
			if not compareType(arg, e) then return false, i, e, typeof(arg) end
		end
		return true
	end
end

function typeCheckedFunction:__call(...)
	local args = {...}
	local signatures = self.Signatures
	local index, expected, actual = 0
	for i = 1, #signatures do
		local signature = signatures[i]
		local success, i, e, t = verify(args, signature)
		if success then return self.Call(...) end
		if i > index then index, expected, actual = i, e, t end
	end
	error(TYPE_ERROR:format(index, getFunctionName(), expected, actual), 2)
end

function typeCheckedFunction:AddSignature(...)
	local args = {...}
	for i = 1, #args do
		local t = type(args[i])
		if t ~= "string" then error(TYPE_ERROR:format(i, getFunctionName(), "string", t), 2) end
	end
	table.insert(self.Signatures, args)
end

return function (...)
	local args = {...}
	local callback = table.remove(args)
	for i = 1, #args do
		local t = type(args[i])
		if t ~= "string" then error(TYPE_ERROR:format(i, getFunctionName(), "string", t), 2) end
	end
	return setmetatable({
		Signatures = {args},
		Call = callback
	}, typeCheckedFunction)
end
