local module = {}
local actions = {}

local Action = {}
Action.__index = Action

function Action:Bind(signal, check)
	local t = typeof(check)
	if not (t == "nil" or t == "function") then error("Invalid parameter 2 for check callback") end
	if not typeof(signal) == "RBXScriptSignal" then error("Invalid parameter 1 for signal") end
	if self.Listeners[signal] then error("Action is already bound to " .. tostring(signal)) end
	local name = tostring(signal):sub(8)
	local callback = check and function (...)
		if check(...) then
			self.Callback(name, ...)
		end
	end or function (...)
		self.Callback(name, ...)
	end
	self.Listeners[signal] = {callback, self.Active and signal:Connect(callback)}
end

function Action:Unbind(signal)
	if not typeof(signal) == "RBXScriptSignal" then error("Invalid parameter 1 for signal") end
	local data = self.Listeners[signal]
	if not data then error("Action is not bound to " .. tostring(signal)) end
	if data[2] then
		data[2]:Disconnect()
	end
	self.Listeners[signal] = nil
end

function Action:SetActive(active)
	if self.Active == active then return end
	self.Active = active
	if active then
		for listener, data in pairs(self.Listeners) do
			data[2] = listener:Connect(data[1])
		end
	else
		for listener, data in pairs(self.Listeners) do
			data[2]:Disconnect()
			data[2] = nil
		end
	end
end

function Action.new(callback)
	return setmetatable({
		Callback = callback,
		Listeners = {},
		Active = true
	}, Action)
end

function module:CreateAction(name, callback)
	if actions[name] then error("An action with that name already exists") end
	local action = Action.new(callback)
	actions[name] = action
	return action
end

function module:GetAction(name)
	return actions[name] or error("Action does not exist")
end

module.Action = Action

return module
