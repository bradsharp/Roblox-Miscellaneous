local playerGui do
	local players = game:GetService'Players'
	local player = players.LocalPlayer
	while not player do
		wait()
		player = players.LocalPLayer
	end
	playerGui = player:WaitForChild'PlayerGui'
end

local runService = game:GetService'RunService'
local camera = workspace.CurrentCamera
local renderListener, cameraListener
local guis = {}

local tan, rad = math.tan, math.rad

local function updateParts()
	local size, theta = camera.ViewportSize, tan(rad(camera.FieldOfView / 2))
	local ratio = size.X / size.Y
	for i = 1, #guis do
		local gui = guis[i]
		local height = 2 * gui.Depth * theta
		local width = height * ratio
		gui.Part.Size = Vector3.new(width, height, 1)
		gui.Part.CFrame = camera.CFrame * CFrame.new(0, 0, -gui.Depth - 0.5)
	end
end

local function updateGuis()
	for i = 1, #guis do
		guis[i].CanvasSize = camera.ViewportSize
	end
end

local function hookupCamera()
	if cameraListener then
		cameraListener:Disconnect()
	end
	cameraListener = camera:GetPropertyChangedSignal'ViewportSize':Connect(updateGuis)
end

workspace:GetPropertyChangedSignal'CurrentCamera':Connect(function ()
	camera = workspace.CurrentCamera
end)

playerGui.ChildRemoved:Connect(function (child)
	for i = 1, #guis do
		if guis[i].Gui == child then
			guis[i].Part:Destroy()
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
	if not renderListener then renderListener = runService.RenderStepped:Connect(updateParts) end
	local part = Instance.new("Part")
	local gui = Instance.new("SurfaceGui")
	gui.Adornee = part
	gui.LightInfluence = 0
	gui.Face = Enum.NormalId.Back
	gui.CanvasSize = camera.ViewportSize
	part.Transparency = 1
	part.CanCollide = false
	part.Anchored = true
	part.Parent = workspace
	gui.Parent = playerGui
	table.insert(guis, {
		Depth = depth,
		Gui = gui,
		Part = part
	})
	return gui
end
