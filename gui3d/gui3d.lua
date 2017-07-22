local playerGui do
	local players = game:GetService'Players'
	local player = players.LocalPlayer
	while not player do
		wait()
		player = players.LocalPLayer
	end
	playerGui = player:WaitForChild'PlayerGui'
end

local part = Instance.new("Part")
	part.Transparency = 1
	part.Anchored = true
	part.CanCollide = false
	part.Size = Vector3.new(1, 1, 1)
	part.Parent = workspace

local runService = game:GetService'RunService'
local camera = workspace.CurrentCamera
local renderListener, cameraListener
local guis = {}

local tan, rad = math.tan, math.rad

local function update()
	part.CFrame = camera.CFrame
end

local function updateScreenSize()
	local size = camera.ViewportSize
	for i = 1, #guis do
		guis[i].Size = UDim2.new(0, size.X, 0, size.Y)
	end
end

local function hookupCamera()
	if cameraListener then
		cameraListener:Disconnect()
	end
	cameraListener = camera:GetPropertyChangedSignal'ViewportSize':Connect(updateScreenSize)
end

workspace:GetPropertyChangedSignal'CurrentCamera':Connect(function ()
	camera = workspace.CurrentCamera
end)

playerGui.ChildRemoved:Connect(function (child)
	for i = 1, #guis do
		if guis[i] == child then
			table.remove(guis, i)
			break
		end
	end
	if #guis == 0 and renderListener then
		renderListener:Disconnect()
		renderListener = nil
	end
end)

hookupCamera()

return function (depth)
	if not renderListener then renderListener = runService.RenderStepped:Connect(update) end
	local size = camera.ViewportSize
	local gui = Instance.new("BillboardGui")
	gui.Adornee = part
	gui.LightInfluence = 0
	gui.Size = UDim2.new(0, size.X, 0, size.Y)
	gui.Parent = playerGui
	gui.StudsOffset = Vector3.new(0, 0, -depth)
	table.insert(guis, gui)
	return gui
end
