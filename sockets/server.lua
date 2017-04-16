local requestQueueSize = 256

-------------------------------------------------

local httpService = game:GetService'HttpService'
local replicatedStorage = game:GetService'ReplicatedStorage'
local players = game:GetService'Players'

local folder = Instance.new("Folder")
local event = Instance.new("RemoteEvent")
local request = Instance.new("RemoteEvent")
local response = Instance.new("RemoteEvent")

local module = {}
local sockets = {}

-------------------------------------------------

function generateId()
	return httpService:GenerateGUID(false)
end

local notNil = {__index = function (s, i)
	local t={} rawset(s, i, t) return t
end}

local function assert(condition, message)
	if not condition == true then
		error(message, 3)
	end
end

-- CONNECTION -----------------------------------

local connection = {}
connection.__index = connection
connection.__mode = "v"

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

function createCallbacks(listeners)
	local callbacks = {}
	for i = 1, #listeners do
		table.insert(callbacks, coroutine.wrap(listeners[i][2]))
	end
	return callbacks
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

function signal:Wait()
	table.insert(self.Threads, coroutine.running())
	local output repeat
		output = {coroutine.yield()}
		local success = table.remove(output, 1)
	until success == true
	coroutine.yield()
	return unpack(output)
end

function signal:Fire(...)
	for i = #self.Threads, 1, -1 do
		coroutine.resume(self.Threads[i], true, ...)
		table.remove(self.Threads, i)
	end
	local threads = createCallbacks(self.Listeners)
	for i = 1, #threads do
		threads[i](...)
	end
end

signal.connect = signal.Connect
signal.wait = signal.Wait

function createSignal()
	return setmetatable({
		Threads = {},
		Listeners = {}
	}, signal)
end

-- SOCKET GROUP ---------------------------------

local group = {}

function group.__tostring(self)
	return self.Name
end

function createGroup(socket, name)
	return setmetatable({
		Name = name,
		Socket = socket
	}, group)
end

-- SERVER SOCKET --------------------------------

local socket = {}
socket.__index = socket
socket.__newindex = function (_, index)
	error(index .. " is not a valid member of Socket", 0)
end

function socket:Listen(name, listener)
	assert(self.Alive, "Socket is dead")
	if not self.Callbacks[name] then
		self:SetCallback(name, listener)
	end
	local connection = createConnection(self.Listeners[name], listener)
	self:ExecuteEventQueue(name)
	return connection
end

function socket:Emit(name, ...)
	assert(self.Alive, "Socket is dead")
	event:FireClient(self.Player, name, ...)
end

function socket:RunListeners(name, ...)
	if self.Alive then
		local listeners = self.Listeners[name]
		if #listeners > 0 then
			local threads = createCallbacks(listeners)
			for i = 1, #threads do
				threads[i](...)
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
	assert(self.Alive, "Socket is dead")
	self.Callbacks[name] = callback
	self:ExecuteRequestQueue(name)
end

function socket:Request(name, ...)
	assert(self.Alive, "Socket is dead")
	local id = generateId()
	request:FireClient(self.Player, id, name, ...)
	local args
	if self.Responses[id] then
		args = self.Responses[id]
	else
		repeat
			args = {response.OnServerEvent:wait()}
			local player = table.remove(args, 1)
			local responseId = table.remove(args, 1)
		until player == self.Player and responseId == id
	end
	return unpack(args)
end

function socket:RunCallback(name, requestId, ...)
	if self.Alive then
		local callback = self.Callbacks[name]
		if callback then
			response:FireClient(self.Player, requestId, callback(...))
		else
			local queue = self.Queue.Requests[name]
			if #queue < requestQueueSize then
				table.insert(queue, {requestId, ...})
			else
				warn("Max event queue reached for", name, "event will not be queued")
			end
		end
	end
end

function socket:ExecuteRequestQueue(name)
	local queue = self.Queue.Requests[name]
	while #queue > 0 do
		local args = queue[1]
		local requestId = table.remove(args, 1)
		local thread = coroutine.wrap(socket.RunCallback)
		thread(self, name, requestId, unpack(args))
		table.remove(queue, 1)
	end
end

function socket:GetGroup(name)
	assert(self.Alive, "Socket is dead")
	local group = self.Groups[name]
	if not group then
		group = createGroup(self, name)
		self.Groups[name] = group
	end
	return group
end

function socket:JoinRoom(name)
	assert(self.Alive, "Socket is dead")
	local room = module.Rooms[name]
	for i = 1, #room do
		if room[i] == self then
			return
		end
	end
	table.insert(room, self) 
end

function socket:LeaveRoom(name)
	assert(self.Alive, "Socket is dead")
	local room = module.Rooms[name]
	for i = 1, #room do
		if room[i] == self then
			table.remove(room, i)
			return
		end
	end
end

function socket.__tostring(self)
	return "Socket " .. tostring(self.Player)
end

function socket:Destroy()
	self.Listeners = nil
	self.Callbacks = nil
	self.Queue = nil
	self.Responses = nil
	self.Rooms = nil
	self.Groups = nil
	self.Player = nil
	self.Alive = false
end

function socket:Disconnect(msg)
	assert(self.Alive, "Socket is dead")
	self.Alive = false
	self.Player:Kick(msg or "You have been disconnected")
end

socket.Connect = socket.Listen
socket.connect = socket.Listen
socket.Invoke = socket.Request
socket.Fire = socket.Emit

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
		Alive = true,
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
	
-- MODULE --------------------------------------

local weak = {__mode="v"}
local notNilWeak = {__index = function (s, i)
	local t=setmetatable({}, weak) rawset(s, i, t) return t
end}

module.Connected = createSignal()
module.Rooms = setmetatable({}, notNilWeak)
module.Callbacks = {}

function module:GetSocket(player)
	return sockets[player]
end

function module:GetSockets()
	local s = {}
	for _, v in pairs(sockets) do
		table.insert(s, v)
	end
	return s
end

function module:Emit(name, ...)
	event:FireAllClients(name, ...)
end

function module:Request(name, ...)
	local id = generateId()
	local args = {...}
	module.Callbacks[id] = table.remove(args)
	request:FireAllClients(name, id, unpack(args))
end

function module:EmitRoom(room, name, ...)
	for i = 1, #room do
		if room[i].Alive then
			event:FireClient(room[i].Player, name, ...)
		end
	end
end

function module:RequestRoom(room, name, ...)
	local id = generateId()
	local args = {...}
	module.Callbacks[id] = table.remove(args)
	for i = 1, #room do
		if room[i].Alive then
			request:FireClient(room[i].Player, name, unpack(args))
		end
	end
end

function module:EmitClients(players, name, ...)
	for i = 1, #players do
		event:FireClient(players[i], name, ...)
	end
end

function module:RequestClients(players, name, ...)
	local id = generateId()
	local args = {...}
	module.Callbacks[id] = table.remove(args)
	for i = 1, #players do
		request:FireClient(players[i], name, unpack(args))
	end
end

module.Fire = module.Emit
module.Invoke = module.Request
module.FireRoom = module.EmitRoom
module.InvokeRoom = module.RequestRoom
module.FireClients = module.EmitClients
module.InvokeClients = module.RequestClients

-------------------------------------------------

event.OnServerEvent:connect(function (player, name, ...)
	local socket = sockets[player]
	if socket then
		socket:RunListeners(name, ...)
	elseif name == nil then
		socket = createSocket(player)
		sockets[player] = socket
		module.Connected:Fire(socket)
	else
		error("Socket does not exist")
	end
end)

request.OnServerEvent:connect(function (player, requestId, name, ...)
	local socket = sockets[player]
	if socket then
		socket:RunCallback(name, requestId, ...)
	else
		error("Socket does not exist")
	end
end)

response.OnServerEvent:connect(function (player, requestId, ...)
	local callback = module.Callbacks[requestId]
	local socket = sockets[player]
	if callback then
		callback(socket, ...)
	elseif socket then
		socket.Responses[requestId] = {...}
		wait(1)
		socket.Responses[requestId] = nil
	end
end)

players.PlayerRemoving:connect(function (player)
	local socket = sockets[player]
	sockets[player] = nil
	socket.Disconnected:Fire()
	socket:Destroy()
end)

-------------------------------------------------

event.Name = "Event"
request.Name = "Request"
response.Name = "Response"
folder.Name = "Sockets"

event.Parent = folder
request.Parent = folder
response.Parent = folder
folder.Parent = replicatedStorage

return module
