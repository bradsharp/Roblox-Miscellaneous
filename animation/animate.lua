local animations = {}
local easing = require(script:WaitForChild'Easing')

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

function update()
	local time = tick()
	for id, animation in pairs(animations) do
		if time - animation[2] >= animation[3] then
			animation[1](animation[8])
			animation[5] = true
			if animation[6] then
				spawn(animation[6])
			end
		else
			local i = animation[4](time - animation[2], animation[3])
			local v = animation[7] + (animation[8] - animation[7]) * i
			animation[9] = v
			animation[1](v)
		end
	end
end

game:GetService'RunService'[game:FindFirstChild'NetworkServer' 
	and "Heartbeat" or "RenderStepped"]:connect(update)

return function (id, f, initial, final, direction, style, duration, override, callback)
	if not animations[id] or animations[id][5] then
		direction = enumify(direction, "EasingDirection") or Enum.EasingDirection.Out
		style = enumify(style, "EasingStyle") or Enum.EasingStyle.Sine
		animations[id] = {
			f,
			tick(),
			duration or 1,
			easing[direction][style],
			override == nil and true,
			callback,
			initial or 0,
			final or 1,
		}
	end
end
