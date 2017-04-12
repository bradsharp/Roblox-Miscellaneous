----------------
-- CONNECTION --
----------------

local connection = {}
connection.__index = connection

function connection:Disconnect()
	if self.Connected then
		for i = 1, #self.Table do
			if self.Table[i] == self.Listener then
				table.remove(self.Table, i)
				break
			end
		end
		self.Connected = false
	else
		error("Already disconnected")
	end
end

connection.disconnect = connection.Disconnect

function createConnection(tab, lis)
	return setmetatable({
		Connected = true,
		Table = tab,
		Listener = lis
	}, connection)
end

------------
-- SIGNAL --
------------

local signal = {}
signal.__index = signal

function signal:Connect(listener)
	local connection = createConnection(self.Listeners, listener)
	table.insert(self.Listeners, listener)
	return connection
end

function signal:Wait()
	local current = self.Switch
	while current == self.Switch do
		wait()
	end
	return unpack(self.Args)
end

function signal:Fire(...)
	print'Fired'
	self.Args = {...}
	self.Switch = not self.Switch
	for _, listener in ipairs(self.Listeners) do
		spawn(function ()
			listener(unpack(self.Args))
		end)
	end
end

signal.connect = signal.Connect
signal.wait = signal.Wait

function createSignal()
	return setmetatable({
		Listeners = {},
		Switch = false,
		Args = {}
	}, signal)
end
