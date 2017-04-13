local queueSize = 256

-- CLIENT ------------------------------------

local replicatedStorage = game:GetService'ReplicatedStorage'
local httpService = game:GetService'HttpService'

local folder = replicatedStorage:WaitForChild'Sockets'
local remoteEvent = folder:WaitForChild'Emit'
local remoteFunction = folder:WaitForChild'Query'

local module = {}
local userSocket

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
	remoteEvent:FireServer(name, ...)
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
	return remoteFunction:InvokeServer(name, ...)
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

userSocket = createSocket()

remoteEvent.OnClientEvent:connect(function (name, ...)
	userSocket:RunListeners(name, ...)
end)

remoteFunction.OnClientInvoke = function (name, ...)
	return userSocket:RunCallback(name, ...)
end

remoteEvent:FireServer()

return userSocket
