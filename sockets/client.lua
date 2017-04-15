local requestQueueSize = 256

-------------------------------------------------

local httpService = game:GetService'HttpService'
local replicatedStorage = game:GetService'ReplicatedStorage'

local folder = replicatedStorage:WaitForChild'Sockets'
local event = folder:WaitForChild'Event'
local request = folder:WaitForChild'Request'
local response = folder:WaitForChild'Response'

-------------------------------------------------

function generateId()
	return httpService:GenerateGUID(false)
end

-- CONNECTION -----------------------------------

local connection = {}
connection.__index = connection

function connection:Disconnect()
	for i = 1, #self.Listeners do
		if self.Listeners[i][1] == self.Id then
			table.remove(self.Listeners, i)
			break
		end
	end
	self.Listeners = nil
end

connection.disconnect = connection.Disconnect

function createThreads(listeners)
	local threads = {}
	for i = 1, #listeners do
		table.insert(threads, coroutine.create(listeners[i][2]))
	end
	return threads
end

function createConnection(listeners, listener)
	local id = generateId()
	table.insert(listeners, 1, {id, listener})
	return setmetatable({
		Id = id,
		Listeners = listeners,
	}, connection)
end

-- SIGNAL ---------------------------------------

local signal = {}
signal.__index = signal

function signal:Connect(listener)
	return createConnection(self.Listeners, listener)
end

function signal:Fire(...)
	local threads = createThreads(self.Listeners)
	for i = 1, #threads do
		coroutine.resume(threads[i], ...)
	end
end

signal.connect = signal.Connect

function createSignal()
	return setmetatable({
		Listeners = {}
	}, signal)
end

-- SOCKET GROUP ---------------------------------

local group = {}

function createGroup(socket, name)
	return setmetatable({
		Name = name,
		Socket = socket
	}, group)
end

-- SERVER SOCKET --------------------------------

local socket = {}
socket.__index = socket
socket.__newindex = error

function socket:Listen(name, listener)
	if not self.Callbacks[name] then
		self:SetCallback(name, listener)
	end
	local connection = createConnection(self.Listeners[name], listener)
	self:ExecuteEventQueue(name)
	return connection
end

function socket:Emit(name, ...)
	event:FireServer(name, ...)
end

function socket:RunListeners(name, ...)
	local listeners = self.Listeners[name]
	if #listeners > 0 then
		local threads = createThreads(listeners)
		for i = 1, #threads do
			coroutine.resume(threads[i], ...)
		end
	else
		local queue = self.Queue.Events[name]
		if #queue < requestQueueSize then
			table.insert(queue, {...})
		else
			warn("Max event queue reached for", name, "event will not be queued")
		end
	end
end

function socket:ExecuteEventQueue(name)
	local queue = self.Queue.Events[name]
	while #queue > 0 do
		local args = queue[1]
		self:RunListeners(name, unpack(args))
		table.remove(queue, 1)
	end
end

function socket:SetCallback(name, callback)
	self.Callbacks[name] = callback
	self:ExecuteRequestQueue(name)
end

function socket:Request(name, ...)
	local id = generateId()
	request:FireServer(id, name, ...)
	local args
	if self.Responses[id] then
		args = self.Responses[id]
	else
		repeat
			args = {response.OnClientEvent:wait()}
			local responseId = table.remove(args, 1)
		until responseId == id
	end
	return unpack(args)
end

function socket:RunCallback(name, requestId, ...)
	local callback = self.Callbacks[name]
	if callback then
		response:FireServer(requestId, name, callback(...))
	else
		local queue = self.Queue.Requests[name]
		if #queue < requestQueueSize then
			table.insert(queue, {requestId, ...})
		else
			warn("Max event queue reached for", name, "event will not be queued")
		end
	end
end

function socket:ExecuteRequestQueue(name)
	local queue = self.Queue.Requests[name]
	while #queue > 0 do
		local args = queue[1]
		local requestId = table.remove(args, 1)
		local thread = coroutine.create(socket.RunCallback)
		coroutine.resume(thread, self, name, requestId, unpack(args))
		table.remove(queue, 1)
	end
end

function socket:GetGroup(name)
	local group = self.Groups[name]
	if not group then
		group = createGroup(self, name)
		self.Groups[name] = group
	end
	return group
end

socket.Connect = socket.Listen
socket.connect = socket.Listen
socket.Invoke = socket.Request
socket.Fire = socket.Emit

local notNil = {__index = function (s, i)
	local t={} rawset(s, i, t) return t
end}

function createSocket(player)
	return setmetatable({
		Player = player,
		Listeners = setmetatable({}, notNil),
		Callbacks = {},
		Queue = {
			Requests = setmetatable({}, notNil),
			Events = setmetatable({}, notNil)
		},
		Responses = {},
		Groups = {},
		Rooms = {},
		Disconnected = createSignal()
	}, socket)
end

-------------------------------------------------

local groupSeperator = ":::"

group.__index = function (self, index)
	local property = rawget(self.Socket, index)
	if property then
		return property
	else
		local method = rawget(group, index)
		if method then
			return method
		else
			local fn = function (group, name, ...)
				return socket[index](group.Socket, group.Name .. groupSeperator .. name, ...)
			end
			rawset(group, index, fn)
			return fn
		end
	end
end

-------------------------------------------------

userSocket = createSocket()

-------------------------------------------------

event.OnClientEvent:connect(function (name, ...)
	userSocket:RunListeners(name, ...)
end)

request.OnClientEvent:connect(function (requestId, name, ...)
	userSocket:RunCallback(name, requestId, ...)
end)

response.OnClientEvent:connect(function (requestId, ...)
	userSocket.Responses[requestId] = {...}
	wait(1)
	userSocket.Responses[requestId] = nil
end)

-------------------------------------------------

event:FireServer()

return userSocket
