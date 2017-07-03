local SYNC_INTERVAL = 300
local SAMPLES = 30
local TOLERANCE = 0.5

local replicatedStorage = game:GetService'ReplicatedStorage'
local starterPlayer = game:GetService'StarterPlayer'
local runService = game:GetService'RunService'
local players = game:GetService'Players'

local remote = Instance.new("RemoteFunction")
remote.Name = "Shift"
remote.Parent = replicatedStorage

script.Responder.Parent = starterPlayer.StarterPlayerScripts

local module = {}
local shifts = {}
local syncing = {}
local logs = {}

local function singleShift(player)
	local tServer = tick()
	local t = remote:InvokeClient(player)
	local tClient = t - (tick() - tServer) / 2
	return tServer - tClient
end

function module.ClientToServer(player, t)
	return t + shifts[player]
end

function module.ServerToClient(player, t)
	return (t or tick()) - shifts[player]
end

local function sync(player)
	if not syncing[player] then
		local t = 0
		syncing[player] = true
		for i = 1, SAMPLES do
			t = t + singleShift(player)
			shifts[player] = (t / i)
		end
		syncing[player] = false
	end
end

local function resync(player)
	if not syncing[player] then
		local t = 0
		syncing[player] = true
		for i = 1, SAMPLES do
			t = t + singleShift(player)
		end
		shifts[player] = t / SAMPLES
		syncing[player] = false
	end
end

function module.Resync(player)
	coroutine.wrap(resync)(player)
end

function module.GetShift(player)
	return shifts[player]
end

function module.Verify(player, clientTime)
	local serverTime = tick()
	local log = logs[player]
	logs[player] = {
			Client = clientTime,
			Server = serverTime
	}
	if not log then return true end
	local clientElapsed = clientTime - log.Client
	local serverElapsed = serverTime - log.Server
	local difference = math.abs(clientElapsed - serverElapsed)
	return difference < TOLERANCE
end

local function playerAdded(player)
	shifts[player] = 0
	sync(player)
end

players.PlayerAdded:Connect(playerAdded)

for _, v in pairs(players:GetChildren()) do
	coroutine.wrap(playerAdded)(v)
end

players.PlayerRemoving:Connect(function (player)
	syncing[player] = nil
	shifts[player] = nil
	logs[player] = nil
end)

local last = 0

runService.Stepped:Connect(function (t)
	local current = t % SYNC_INTERVAL
	if current < last then
		for _, player in pairs(players:GetChildren()) do
			resync(player)
		end
	end
	last = current
end)

return module
