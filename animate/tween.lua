-- MIT License Copyright (c) 2016 Brad Sharp https://github.com/BradSharp/roblox

local tweens = {}

local easingLibrary = {
	[Enum.EasingDirection.In] = {},
	[Enum.EasingDirection.Out] = {},
	[Enum.EasingDirection.InOut] = {},	
}

function getType(prop)
	local _
	if pcall(function () _ = prop.Number end) then
		return updateBrickColor
	elseif pcall(function () _ = prop.r end) then
		return updateRGB
	elseif pcall(function () _ = prop.X.Offset end) then
		return updateUDim2
	elseif pcall(function () _ = prop.p end) then
		return updateCFrame
	elseif pcall(function () _ = prop.Z end) then
		return updateVector3
	elseif pcall(function () _ = prop.Keypoints end) then
		return updateNumberSequence
	elseif pcall(function () _ = prop.X end) then
		return updateVector2
	elseif type(prop) == "number" then
		return updateNumber
	else
		warn("Attempt to animate an unsupported datatype, value will still be set once duration has elapsed.")
		return update
	end
end

function enumify(value, enumType)
	if type(value) == "userdata" then
		return value
	else
		for i, v in pairs(Enum[enumType]:GetEnumItems()) do
			if value == v.Name or value == v.Value then
				return v
			end
		end
	end
end

function sub(func)
	local event = Instance.new'BindableEvent' event.Event:connect(func)
	return function (...) event:Fire(...) end
end

function animate(object, property, newValue, direction, style, duration, override, callback)
	if object and property and newValue then
		local oldValue, updater
		if object:IsA'Model' and property == "CFrame" then
			updater = updateModelCFrame
			oldValue = object:GetPrimaryPartCFrame()
		else
			updater = getType(object[property])
			oldValue = object[property]
		end
		if oldValue == newValue then
			return
		end
		direction = enumify(direction, "EasingDirection") or Enum.EasingDirection.Out
		style = enumify(style, "EasingStyle") or Enum.EasingStyle.Sine
		override = override == nil and false or override
		duration = duration or 1
		local objectTweens = tweens[object]
		if not objectTweens then
			tweens[object] = {}
			objectTweens = tweens[object]
		end
		if not (objectTweens[property] and objectTweens[property][7]) then
			objectTweens[property] = {
				updater,
				oldValue,
				newValue,
				tick(),
				duration,
				easingLibrary[direction][style],
				override,
				callback and sub(callback) or nil
			}
			return true
		end
	end
	return false
end

function updateNumber(i, value, newValue, object, property)
	object[property] = value + ((newValue - value) * i)
end

function update(i, value, newValue, object, property)
	object[property] = newValue
end

function updateRGB(i, value, newValue, object, property)
	object[property] = value:lerp(newValue, i)
end

function updateNumberSequence(i, value, newValue, object, property)
	local oV = value.Keypoints[1].Value
	object[property] = NumberSequence.new(
		oV + ((newValue - oV) * i)
	)
end

function updateBrickColor(i, value, newValue, object, property)
	local oR, oG, oB, nR, nG, nB = value.r, value.g, value.b, newValue.r, newValue.g, newValue.b
	object[property] = BrickColor.new(
		oR + ((nR - oR) * i),
		oG + ((nG - oG) * i),
		oB + ((nB - oB) * i)
	)
end

function updateModelCFrame(i, value, newValue, object, property)
	object:SetPrimaryPartCFrame(value:lerp(newValue, i))
end

function updateCFrame(i, value, newValue, object, property)
	object[property] = value:lerp(newValue, i)
end

function updateVector2(i, value, newValue, object, property)
	object[property] = value:lerp(newValue, i)
end

function updateVector3(i, value, newValue, object, property)
	object[property] = value:lerp(newValue, i)
end

function updateUDim2(i, value, newValue, object, property)
	local oXO, oXS, oYO, oYS, nXO, nXS, nYO, nYS = value.X.Offset, value.X.Scale, value.Y.Offset, value.Y.Scale,
	newValue.X.Offset, newValue.X.Scale, newValue.Y.Offset, newValue.Y.Scale
	object[property] = UDim2.new(
		oXS + ((nXS - oXS) * i),
		oXO + ((nXO - oXO) * i),
		oYS + ((nYS - oYS) * i),
		oYO + ((nYO - oYO) * i)
	)
end

function updateAnimations()
	local time = tick()
	for object, objectTweens in pairs(tweens) do
		for property, tween in pairs(objectTweens) do
			if time - tween[4] >= tween[5] then
				tween[1](tween[6](1, 1), tween[2], tween[3], object, property)
				objectTweens[property] = nil
				if tween[8] then
					spawn(tween[8])
				end
			else
				tween[1](tween[6](time - tween[4], tween[5]), tween[2], tween[3], object, property)
			end
		end
	end
end

local pow, sin, cos, pi, sqrt, abs, asin = math.pow, math.sin, math.cos, math.pi, math.sqrt, math.abs, math.asin

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

if game:FindFirstChild'NetworkServer' then
	game:GetService'RunService'.Heartbeat:connect(updateAnimations)
else
	game:GetService'RunService':BindToRenderStep('Tween_Library', 1, updateAnimations)
end

return animate
