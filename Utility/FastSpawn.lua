local fastSpawn do
	local event = Instance.new("BindableEvent")
	local f, args, n
	event.Event:Connect(function () f(unpack(args, n)) end)
	function fastSpawn(callback, ...)
		f, args, n = callback, {...}, select("#", ...)
		event:Fire()
    end
end
