local AUTOSAVE_ENABLED = true
local AUTOSAVE_INTERVAL = 60

local MAX_ATTEMPTS = 3

local VERSION = "0.0.0.0"

local SCHEMA = {
	NewPlayer = true,
	Spells = {},
	Inventory = {},
	Equipped = {
		Body = "",
		Hat = "",
		Face = "",
		Gear = ""
	}
}

-------------------------------------------------

local dataService = game:GetService'DataStoreService'
local dataStore = dataService:GetDataStore("PlayerData", VERSION)
local runService = game:GetService'RunService'
local players = game:GetService'Players'

local playerDataStores = {}
local module = {}

-------------------------------------------------

function performRequest(method, key, ...)
	local tries, data = 1
	local success, result = pcall(dataStore[method], dataStore, tostring(key), ...)
	while (not success) and tries < MAX_ATTEMPTS do
		tries = tries + 1
		warn(method, "failed to", key, "Attempting", tries, "of", MAX_ATTEMPTS)
		wait(1)
		success, result = pcall(dataStore[method], dataStore, ...)
	end
	return success, result
end

function merge(oldData, newData, refData, compare, index)
	if type(oldData) == "table" and type(newData) == "table" and type(refData) == "table" then
		local n = {}
		for i, v in pairs(newData) do
			n[i] = merge(oldData[i], v, refData[i], compare, i)
		end
		for i, v in pairs(oldData) do
			if newData[i] == nil then
				n[i] = merge(v, nil, refData[i], compare, i)
			end
		end
		return n
	elseif oldData ~= newData then
		return compare(oldData, newData, refData, index)
	else
		return oldData
	end
end

function deepTableCopy(t)
	if type(t) == 'table' then
		local n = {}
		for i, v in pairs(t) do
			n[i] = deepTableCopy(v)
		end
		return n
	else
		return t
	end
end

function getNameByUserId(userId)
	local success, result = pcall(players.GetNameFromUserIdAsync, players, userId)
	return success and result or "User:" .. userId
end

-------------------------------------------------

local playerDataStore = {}
playerDataStore.__index = playerDataStore

function runSync(self, callback, method, ...)
	callback(playerDataStore[method](self, ...))
end

function playerDataStore:PushAsync()
	if self:HasLoaded() then
		if self:HasChanged() then
			local conflict = false
			local success, result = performRequest("UpdateAsync", self.User.Id, function (old)
				if old == nil then
					return {Age = os.time(), Data = self.Data}
				else
					if old.Age > self.Age then
						conflict = false
						local newData = merge(old.Data, self.Data, self.ReferenceData, function (old, new, ref)
							if new ~= ref then conflict = true end
							return old
						end)
						if conflict then return old else
							return {Age = os.time(), Data = newData}
						end
					else
						return {Age = os.time(), Data = merge(old.Data, self.Data, self.ReferenceData, function (old, new, ref)
							if new == ref then return old else
								return new
							end
						end)}
					end
				end
			end)
			if success then
				if conflict then return false, "Conflict with outdated data, pull changes before pushing" else
					self.ReferenceData = deepTableCopy(self.Data)
					self.Age = result.Age
					return true
				end
			else return false, result end
		else return false, "Data unchanged" end
	else return false, "Data not loaded" end
end

function playerDataStore:PullAsync()
	local success, result = performRequest("GetAsync", self.User.Id)
	if success then
		if result then
			local outdated = result.Age < self.Age
			if outdated then
				warn("Older data was fetched")
			end
			self.Data = merge(self.Data, result.Data, self.ReferenceData, function (old, new, ref, index)
				if outdated then
					if old == ref then
						warn(index, "was unchanged locally, using older value")
						return new
					else
						return old
					end
				else
					return new			
				end
			end)
			self.Age = result.Age
			self.ReferenceData = deepTableCopy(self.Data)
		else
			self.Data = deepTableCopy(SCHEMA)
		end
		return true
	else
		return false, result
	end
end

function playerDataStore:SyncAsync()
	if self:HasLoaded() then
		local success, result = performRequest("UpdateAsync", self.User.Id, function (current)
			if current == nil then
				return {Age = os.time(), Data = self.Data}
			else
				local outdated = current.Age > self.Age
				return {Age = os.time(), Data = merge(current.Data, self.Data, self.ReferenceData, function (current, new, ref)
					if outdated then
						return current
					elseif new == ref then
						return current
					else
						return new
					end
				end)}
			end
		end)
		if success then
			self.Data = result.Data
			self.ReferenceData = deepTableCopy(self.Data)
			self.Age = result.Age
			return true
		else return false, result end
	else return false, "Data not loaded" end
end

function playerDataStore:Push(callback, ...)
	local push = coroutine.wrap(runSync)
	push(self, callback, "PushAsync", ...)
end

function playerDataStore:Pull(callback, ...)
	local pull = coroutine.wrap(runSync)
	pull(self, callback, "PullAsync", ...)
end

function playerDataStore:Sync(callback, ...)
	local sync = coroutine.wrap(runSync)
	sync(self, callback, "SyncAsync", ...)
end

function playerDataStore:HasChanged()
	local changed function changed(v1, v2)
		if type(v1) == "table" and type(v2) == "table" then
			for i, v in pairs(v1) do
				local r = changed(v, v2[i])
				if r then
					return true
				end
			end
			for i, v in pairs(v2) do
				if v1[i] == nil then
					return true
				end
			end
			return false
		elseif v1 ~= v2 then
			return true
		else
			return false
		end
	end
	return changed(self.Data, self.ReferenceData)
end

function playerDataStore:HasLoaded()
	return rawget(self, "Data") ~= nil
end

function playerDataStore:GetPlayer()
	return self.Player or players:GetPlayerByUserId(self.User.Id)
end

function createPlayerDataStore(userId)
	local player = players:GetPlayerByUserId(userId)
	return setmetatable({
		Player = player,
		User = {
			Name = player and player.Name or getNameByUserId(userId),
			Id = userId
		},
		Age = 0,
		Data = deepTableCopy(SCHEMA),
		ReferenceData = {},
	}, playerDataStore)
end

-------------------------------------------------

function module.GetPlayerData(player)
	local data = playerDataStores[player.UserId]
	if not data then
		data = createPlayerDataStore(player.UserId)
		playerDataStores[player.UserId] = data
	end
	return data
end

function module.GetPlayerDataByUserId(userId)
	local data = playerDataStores[userId]
	if not data then
		data = createPlayerDataStore(userId)
		playerDataStores[userId] = data
	end
	return data
end

module.Create = createPlayerDataStore

function module.PushAll(callback, inGame)
	for userId, data in pairs(playerDataStores) do
		if inGame == false or data:GetPlayer() then
			data:Push(callback)
		end
	end
end

function module.PullAll(callback, inGame)
	for userId, data in pairs(playerDataStores) do
		if inGame == false or data:GetPlayer() then
			data:Pull(callback)
		end
	end
end

function module.SyncAll(callback, inGame)
	for userId, data in pairs(playerDataStores) do
		if inGame == false or data:GetPlayer() then
			data:Sync(callback)
		end
	end
end

function module.SyncOnClose()
	local count, n = 0, 0
	for userId, data in pairs(playerDataStores) do
		if data:GetPlayer() then
			n = n + 1
			data:Push(function (success, result)
				count = count + 1
			end)
		end
	end
	repeat
		wait()
	until count == n
end

-------------------------------------------------

function playerAdded(player)
	local data = module.GetPlayerData(player)
end

players.PlayerRemoving:connect(function (player)
	local data = playerDataStores[player.UserId]
	if data then
		data:Sync()
		playerDataStores[player.UserId] = nil
	end
end)

game.Close:connect(module.SyncOnClose)

if AUTOSAVE_ENABLED then
	spawn(function ()
		while wait(AUTOSAVE_INTERVAL) do
			module.SyncAll()
		end
	end)
end

return module
