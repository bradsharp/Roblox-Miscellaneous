local Signal		= {}
local Connection	= {}

Signal.__index = {}

function Signal.new()
	return setmetatable({
		__connections = {},
		__threads = {}
	}, Signal)
end

function Signal.__index:Fire(...)
	for _, connection in ipairs(self.__connections) do
		task.spawn(connection.__callback, ...)
	end
	for _, thread in ipairs(self.__threads) do
		task.spawn(thread.__callback, ...)
	end
	table.clear(self.__threads)
end

function Signal.__index:Defer(...)
	for _, connection in ipairs(self.__connections) do
		task.defer(connection.__callback, ...)
	end
	for _, thread in ipairs(self.__threads) do
		task.defer(thread.__callback, ...)
	end
	table.clear(self.__threads)
end

function Signal.__index:Connect(handler)
	local connection = Connection.new(handler)
	table.insert(self.__connections, connection)
	return connection
end

function Signal.__index:Wait()
	table.insert(self.__threads, coroutine.running())
	return coroutine.yield()
end

Connection.__index = {}

function Connection.new(signal, callback)
	return setmetatable({
		Connected = false,
		__callback = callback,
		__signal = signal
	}, Connection)
end

function Connection.__index:Disconnect()
	local connections = self.__signal.__connections
	local i = table.find(connections, self)
	if i > 0 then
		table.remove(connections, i)
	end
	self.Connected = false
end

return Signal
