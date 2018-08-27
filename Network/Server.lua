--[[
	
	API
	void network:Fire(<string> id, <player> player, <tuple> ...)
	void network:Fire(<string> id, <players> players, <tuple> ...)
	
	void network:Invoke(<string> id, <player> player, <tuple> ..., <function(<player> player, <tuple> ...)> callback)
	void network:Invoke(<string> id, <players> players, <tuple> ..., <function(<player> player, <tuple> ...)> callback)
	
	void network:Event(<string> id, <function(<player> player, <tuple> ...)> callback)
	void network:Invoked(<string> id, <function(<player> player, <tuple> ...)> callback)

--]]

local network = {}

local remotes do
	local replicatedStorage = game:GetService("ReplicatedStorage")
	remotes = replicatedStorage:FindFirstChild("NetworkRemotes")
	if not remotes then
		remotes = Instance.new("Folder")
		remotes.Name = "NetworkRemotes"
		remotes.Parent = replicatedStorage
	end
end

local function getEvent(k)
	local n = "Event_" .. k
	local e = remotes:FindFirstChild(n)
	if not e then
		e = Instance.new("RemoteEvent")
		e.Name = n
		e.Parent = remotes
	end
	return e
end

local function getFunction(k)
	local n = "Function_" .. k
	local f = remotes:FindFirstChild(n)
	if not f then
		f = Instance.new("RemoteFunction")
		f.Name = n
		f.Parent = remotes
	end
	return f
end

function network:Fire(n, p, ...)
	local e = getEvent(n)
	if type(p) == "table" then
		for i = 1, #p do
			e:FireClient(p[i], ...)
		end
	else
		e:FireClient(p, ...)
	end
end

function network:Invoke(n, p, ...)
	local a = { ... }
	local c = table.remove(a)
	local f = getFunction(n)
	if type(p) == "table" then
		for i = 1, #p do
			spawn(function ()
				c(p[i], f:InvokeClient(p[i], unpack(a)))
			end)
		end
	else
		spawn(function ()
			c(p, f:InvokeClient(p, unpack(a)))
		end)
	end
end

function network:Event(n, c)
	return getEvent(n).OnServerEvent:Connect(c)
end

function network:Invoked(n, c)
	getFunction(n).OnServerInvoke = c
end

return network
