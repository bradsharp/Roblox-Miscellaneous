local event = {}
event.__index = event

function event:Connect(f)
	return self.Bindable.Event:connect(function (key)
		local t = self.Cache[key]
		f(unpack(t))
	end)
end

function event:Wait()
	local key = self.Bindable.Event:wait()
	local t = self.Cache[key]
	return unpack(t)
end

function event:Fire(...)
	local key = tick()
	self.Cache[key] = {...}
	self.Bindable:Fire(key)
	self.Cache[key] = nil
end

event.connect = event.Connect
event.wait = event.Wait

function createEvent()
	return setmetatable({
		Bindable = Instance.new("BindableEvent"),
		Cache = {}
	}, event)
end
