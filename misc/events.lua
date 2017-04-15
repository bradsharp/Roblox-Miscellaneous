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

function signal:Run(...)
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
