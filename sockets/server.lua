local queueSize = 256

-- SERVER ------------------------------------

local players = game:GetService'Players'
local replicatedStorage = game:GetService'ReplicatedStorage'
local httpService = game:GetService'HttpService'

local folder = Instance.new("Folder")
local remoteEvent = Instance.new("RemoteEvent")
local remoteFunction = Instance.new("RemoteFunction") 

local module = {}
local sockets = {}

local connection = {}
connection.__index = connection

function connection:Disconnect()
	if self.Connected then
		local listeners = {}
		for i = 1, #listeners do
			if listeners[i][1] == self.Id then
				table.remove(listeners, i)
				break
			end
		end
		self.Listeners = nil
		self.Connected = false
	else
		error("Already disconnected")
	end
end

connection.disconnect = connection.Disconnect

function createThreads(listeners)
	local threads = {}
	for _, listener in ipairs(listeners) do
		table.insert(threads, coroutine.create(listener[2]))
	end
	return threads
end

function resumeThreads(threads, ...)
	for i = 1, #threads do
		coroutine.resume(threads[i], ...)
	end
end

function createConnection(listeners, listener)
	local id = httpService:GenerateGUID(false)
	table.insert(listeners, {id, listener})
	return setmetatable({
		Connected = true,
		Listeners = listeners,
		Id = id
	}, connection)
end

local socket = {}
socket.__index = socket

function socket:Connect(name, listener)
	if type(name) == "function" then
		listener, name = name
		return createConnection(self.Listeners, listener)
	else
		local connection = createConnection(self.Listeners[name], listener)
		self:ExecuteListenerQueue(name)
		return connection
	end
end

function socket:Emit(name, ...)
	remoteEvent:FireClient(self.Player, name, ...)
end

function socket:RunListeners(name, ...)
	if #self.Listeners[name] > 0 then
		local globalThreads, threads = createThreads(self.Listeners),
			createThreads(self.Listeners[name])
		resumeThreads(globalThreads, ...)
		resumeThreads(threads, ...)
	elseif #self.Queue < queueSize then
		table.insert(self.Queue[name], {...})
	else
		warn("Event not queued, queue length exceeded")
	end
end

function socket:ExecuteListenerQueue(name)
	local queue = self.Queue[name]
	while #queue > 0 do
		local args = queue[1]
		self:RunListeners(name, unpack(args))
		table.remove(queue, 1)
	end
end

function socket:On(name, callback)
	self.Callbacks[name] = callback
end

function socket:Query(name, ...)
	return remoteFunction:InvokeClient(self.Player, name, ...)
end

function socket:RunCallback(name, ...)
	while not self.Callbacks[name] do
		wait()
	end
	return self.Callbacks[name](...)
end

function socket:Destroy()
	for i in pairs(self) do
		self[i] = nil
	end
	self.Alive = false
end

local notNil = {__index = function (self, index)
	local t = {} rawset(self, index, t) return t
end}

socket.Listen = socket.On
socket.Fire = socket.Emit
socket.Invoke = socket.Query
socket.connect = socket.Connect

function createSocket(player)
	return setmetatable({
		Player = player,
		Listeners = setmetatable({}, notNil),
		Callbacks = {},
		Queue = setmetatable({}, notNil)
	}, socket)
end

function module:Emit(name, ...)
	remoteEvent:FireAllClients(name, ...)
end

function module:Query(name, ...)
	local args = {...}
	local callback = table.remove(args)
	for _, player in ipairs(players:GetChildren()) do
		coroutine.wrap(function (...)
			callback(remoteFunction:InvokeClient(player, name, ...))
		end)(unpack(args))
	end
end

function module:GetSocket(player)
	return sockets[player]
end

function module:GetSockets()
	return sockets
end

function module:EmitClients(clients, name, ...)
	for _, player in ipairs(clients) do
		remoteEvent:FireClient(player, name, ...)
	end
end

function module:QueryClients(clients, name, ...)
	local args = {...}
	local callback = table.remove(args)
	for _, player in ipairs(clients) do
		coroutine.wrap(function (...)
			callback(remoteFunction:InvokeClient(player, name, ...))
		end)(unpack(args))
	end
end

local connected = {}

function runConnectListeners(player, socket)
	resumeThreads(createThreads(connected.Listeners),
		player, socket)
end

function connected:Connect(callback)
	return createConnection(connected.Listeners, callback)
end

function connected:Wait()
	return sockets[players.PlayerAdded:wait()]
end

connected.wait = connected.Wait
connected.connect = connected.Connect
connected.Listeners = {}

module.Connected = connected
module.Invoke = module.Query
module.Fire = module.Emit
module.FireClients = module.EmitClients
module.InvokeClients = module.QueryClients

remoteEvent.OnServerEvent:connect(function (player, name, ...)
	local socket = sockets[player]
	if socket then
		socket:RunListeners(name, ...)
	elseif name == nil and player.Parent == players then
		socket = createSocket(player)
		sockets[player] = socket
		wait()
		runConnectListeners(player, socket)
	end
end)

remoteFunction.OnServerInvoke = function (player, name, ...)
	local socket = sockets[player]
	if socket then
		return socket:RunCallback(name, ...)
	end
end

players.PlayerRemoving:connect(function (player)
	local socket = sockets[player]
	socket:RunListeners("Disconnect")
	socket:Destroy()
	sockets[player] = nil
end)

remoteEvent.Name = "Emit"
remoteFunction.Name = "Query"
remoteEvent.Parent = folder
remoteFunction.Parent = folder

folder.Name = "Sockets"
folder.Parent = replicatedStorage

return module
