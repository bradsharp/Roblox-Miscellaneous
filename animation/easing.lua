local easingLibrary = {
	[Enum.EasingDirection.In] = {},
	[Enum.EasingDirection.Out] = {},
	[Enum.EasingDirection.InOut] = {},	
}

linear = function (t, d) 
	return t / d
end

easingLibrary[Enum.EasingDirection.In][Enum.EasingStyle.Linear] = linear
easingLibrary[Enum.EasingDirection.Out][Enum.EasingStyle.Linear] = linear
easingLibrary[Enum.EasingDirection.InOut][Enum.EasingStyle.Linear] = linear

easingLibrary[Enum.EasingDirection.In][Enum.EasingStyle.Quad] = function (t, d) 
	return pow(t / d, 2)
end

easingLibrary[Enum.EasingDirection.Out][Enum.EasingStyle.Quad] = function (t, d)
	t = t / d
	return -t * (t - 2)
end

easingLibrary[Enum.EasingDirection.InOut][Enum.EasingStyle.Quad] = function (t, d)
	t = t / d * 2
	if t < 1 then 
		return pow(t, 2) / 2
	end
	return -(((t - 1) * (t - 3) - 1)) / 2
end

easingLibrary[Enum.EasingDirection.In][Enum.EasingStyle.Quart] = function (t, d) 
	return pow(t / d, 4)
end

easingLibrary[Enum.EasingDirection.Out][Enum.EasingStyle.Quart] = function (t, d) 
	return -(pow(t / d - 1, 4) - 1)
end

easingLibrary[Enum.EasingDirection.InOut][Enum.EasingStyle.Quart] = function (t, d)
	t = t / d * 2
	if t < 1 then 
		return pow(t, 4) / 2
	end
	return -(pow(t - 2, 4) - 2) / 2
end

easingLibrary[Enum.EasingDirection.In][Enum.EasingStyle.Quint] = function (t, d) 
	return pow(t / d, 5)
end

easingLibrary[Enum.EasingDirection.Out][Enum.EasingStyle.Quint] = function (t, d) 
	return (pow(t / d - 1, 5) + 1)
end

easingLibrary[Enum.EasingDirection.InOut][Enum.EasingStyle.Quint] = function (t, d)
	t = t / d * 2
	if t < 1 then 
		return pow(t, 5) / 2
	end
	return (pow(t - 2, 5) + 2) / 2
end

easingLibrary[Enum.EasingDirection.In][Enum.EasingStyle.Sine] = function (t, d) 
	return -cos(t / d * (pi / 2)) + 1
end

easingLibrary[Enum.EasingDirection.Out][Enum.EasingStyle.Sine] = function (t, d) 
	return sin(t / d * (pi / 2))
end

easingLibrary[Enum.EasingDirection.InOut][Enum.EasingStyle.Sine] = function (t, d) 
	return -(cos(pi * t / d) - 1) / 2
end

function calculatePAS(p,a,d)
	p, a = p or d * 0.3, a or 0
	if a < 1 then 
		return p, 1, p / 4 
	end
	return p, a, p / (2 * pi) * asin(1/a)
end

easingLibrary[Enum.EasingDirection.In][Enum.EasingStyle.Elastic] = function (t, d, a, p)
	local s
	if t == 0 then 
		return 0 
	end
	t = t / d
	if t == 1 then 
		return 1 
	end
	p,a,s = calculatePAS(p,a,d)
	t = t - 1
	return -(a * pow(2, 10 * t) * sin((t * d - s) * (2 * pi) / p))
end

easingLibrary[Enum.EasingDirection.Out][Enum.EasingStyle.Elastic] = function (t, d, a, p)
	local s
	if t == 0 then 
		return 0
	end
	t = t / d
	if t == 1 then 
		return 1 
	end
	p,a,s = calculatePAS(p,a,d)
	return a * pow(2, -10 * t) * sin((t * d - s) * (2 * pi) / p) + 1
end

easingLibrary[Enum.EasingDirection.InOut][Enum.EasingStyle.Elastic] = function (t, d, a, p)
	local s
	if t == 0 then 
		return 0
	end
	t = t / d * 2
	if t == 2 then 
		return 1
	end
	p,a,s = calculatePAS(p,a,d)
	t = t - 1
	if t < 0 then 
		return -0.5 * (a * pow(2, 10 * t) * sin((t * d - s) * (2 * pi) / p))
	end
	return a * pow(2, -10 * t) * sin((t * d - s) * (2 * pi) / p ) * 0.5 + 1
end

easingLibrary[Enum.EasingDirection.In][Enum.EasingStyle.Back] = function (t, d, s)
	s = s or 1.70158
	t = t / d
	return t * t * ((s + 1) * t - s)
end

easingLibrary[Enum.EasingDirection.Out][Enum.EasingStyle.Back] = function (t, d, s)
	s = s or 1.70158
	t = t / d - 1
	return (t * t * ((s + 1) * t + s) + 1)
end

easingLibrary[Enum.EasingDirection.InOut][Enum.EasingStyle.Back] = function (t, d, s)
	s = (s or 1.70158) * 1.525
	t = t / d * 2
	if t < 1 then 
		return (t * t * ((s + 1) * t - s)) / 2
	end
	t = t - 2
	return (t * t * ((s + 1) * t + s) + 2) / 2
end

easingLibrary[Enum.EasingDirection.Out][Enum.EasingStyle.Bounce] = function (t, d)
	t = t / d
	if t < 1 / 2.75 then 
		return (7.5625 * t * t) 
	end
	if t < 2 / 2.75 then
		t = t - (1.5 / 2.75)
		return (7.5625 * t * t + 0.75)
	elseif t < 2.5 / 2.75 then
		t = t - (2.25 / 2.75)
		return (7.5625 * t * t + 0.9375)
	end
	t = t - (2.625 / 2.75)
	return (7.5625 * t * t + 0.984375)
end

easingLibrary[Enum.EasingDirection.In][Enum.EasingStyle.Bounce] = function (t, d) 
	return 1 - easingLibrary[Enum.EasingDirection.Out][Enum.EasingStyle.Bounce](d - t, d)
end

easingLibrary[Enum.EasingDirection.InOut][Enum.EasingStyle.Bounce] = function (t, d)
	if t < d / 2 then 
		return easingLibrary[Enum.EasingDirection.In][Enum.EasingStyle.Bounce](t * 2, d) * 0.5
	end
	return easingLibrary[Enum.EasingDirection.Out][Enum.EasingStyle.Bounce](t * 2 - d, d) * 0.5 + 1 * .5
end

return easingLibrary
