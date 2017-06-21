local event = {}
event.__index = event

function event:Connect(listener)
	return self.Bind.Event:connect(function (key)
		listener(unpack(self.Cache[key]))
	end)
end

function event:Wait()
	return unpack(self.Cache[self.Bind.Event:wait()])
end

function event:Fire(...)
	local key = tick()
	self.Cache[key] = {...}
	self.Bind:Fire(key)
	self.Cache[key] = nil
end

event.connect = event.Connect
event.wait = event.Wait

function event:Destroy()
	self.Bind:Destroy()
	self.Bind = nil
	self.Cache = nil
end

function event.new()
	return setmetatable({
		Bind = Instance.new("BindableEvent"),
		Cache = {},
	}, event)
end

return event
