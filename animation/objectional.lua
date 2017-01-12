local functional = require(script.Parent:WaitForChild'Functional')

function getType(prop)
	local _
	if pcall(function () _ = prop.Number end) then
		return updateBrickColor
	elseif pcall(function () _ = prop.r end) then
		return updateLerp
	elseif pcall(function () _ = prop.X.Offset end) then
		return updateLerp
	elseif pcall(function () _ = prop.p end) then
		return updateLerp
	elseif pcall(function () _ = prop.Z end) then
		return updateLerp
	elseif pcall(function () _ = prop.Keypoints end) then
		return updateNumberSequence
	elseif pcall(function () _ = prop.X end) then
		return updateLerp
	elseif type(prop) == "number" then
		return updateNumber
	else
		warn("Attempt to animate an unsupported datatype, value will still be set once duration has elapsed.")
		return update
	end
end

do
	local ids = {}
	local count = 0
	function getId(object)
		if not ids[object] then
			count = count + 1
			ids[object] = tonumber(count, 16)
		end
		return ids[object]
	end
end

function animate(object, property, newValue, ...)
	if object and property and newValue then
		local oldValue, updater
		if object:IsA'Model' and property == "CFrame" then
			updater = updateModelCFrame
			oldValue = object:GetPrimaryPartCFrame()
		else
			updater = getType(object[property])
			oldValue = object[property]
		end
		local id = "Object:" .. getId(object) .. ":" .. property
		local a = functional(id, function (i)
			updater(i, oldValue, newValue, object, property)
		end, 0, 1, ...)
	end
end

function updateNumber(i, value, newValue, object, property)
	object[property] = value + ((newValue - value) * i)
end

function update(i, value, newValue, object, property)
	object[property] = newValue
end

function updateLerp(i, value, newValue, object, property)
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

return animate
