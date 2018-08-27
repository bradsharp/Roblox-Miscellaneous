--[[
	
	API
	void network:Fire(<string> id, <tuple> ...)
	void network:Fire(<string> id, <tuple> ...)
	
	void network:Invoke(<string> id, <tuple> ..., <function(<tuple> ...)> callback)
	void network:Invoke(<string> id, <tuple> ..., <function(<tuple> ...)> callback)
	
	void network:Event(<string> id, <function(<tuple> ...)> callback)
	void network:Invoked(<string> id, <function(<tuple> ...)> callback)

--]]

local network = {}

local remotes = game:GetService("ReplicatedStorage"):WaitForChild("NetworkRemotes")

local function getEvent(k)
	return remotes:WaitForChild("Event_" .. k)
end

local function getFunction(k)
	return remotes:WaitForChild("Function_" .. k)
end

function network:Fire(n, ...)
	getEvent(n):FireServer(...)
end

function network:Invoke(n, ...)
	local a = { ... }
	spawn(function ()
		table.remove(a)(getFunction(n):InvokeServer(unpack(a)))
	end)
end

function network:Event(n, c)
	return getEvent(n).OnClientEvent:Connect(c)
end

function network:Invoked(n, c)
	getFunction(n).OnClientInvoke = c
end

return network
