local library = {}
local bindable = Instance.new("BindableEvent")

library.running = coroutine.running
library.create = coroutine.create
library.wrap = coroutine.wrap

local args = {}

function library.resume(thread, ...)
	local arguments = args[thread]
	args[thread] = {...}
	bindable:Fire(thread)
	return unpack(arguments)
end

function library.yield(...)
	local thread = coroutine.running()
	args[thread] = {...}
	repeat until bindable.Event:Wait() == thread
	local arguments = args[thread]
	args[thread] = nil
	return unpack(arguments)
end

return library
