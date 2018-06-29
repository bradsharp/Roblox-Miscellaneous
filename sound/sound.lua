local tweenService = game:GetService'TweenService'
local soundService = game:GetService'SoundService'
local module = {}

local group = {}
group.__index = group

function group:Fade(volume, duration)
	local tween = tweenService:Create(self.SoundGroup, TweenInfo.new(duration or 1), {
		Volume = volume
	})
	tween:Play()
	return tween
end

function group:SetVolume(volume)
	self.SoundGroup.Volume = volume
end

function group.new()
	return setmetatable({
		SoundGroup = Instance.new("SoundGroup", soundService)
	}, group)
end

local sound = {}
sound.__index = sound

function sound:SetGroup(group)
	local soundGroup = group and group.SoundGroup
	self.Sound.SoundGroup = soundGroup
	self.Sound.Parent = soundGroup or soundService
	self.Group = group
end

function sound:Fade(volume, duration)
	local tween = tweenService:Create(self.Sound, TweenInfo.new(duration or 1), {
		Volume = volume
	})
	tween:Play()
	return tween
end

function sound:FadeOut(duration)
	local tween, listener = self:Fade(0, duration)
	listener = tween.Completed:Connect(function (state)
		listener:Disconnect()
		if state == Enum.PlaybackState.Completed then
			self:Stop()
		end
	end)
end

function sound:WaitForLoad()
	local t = tick()
	if not self.Sound.IsLoaded then
		self.Sound.Loaded:Wait()
	end
	return tick() - t
end

function sound:Play()
	self.Sound:Play()
end

function sound:Stop()
	self.Sound:Stop()
end

function sound:Pause()
	self.Sound:Pause()
end

function sound:Resume()
	self.Sound:Resume()
end

function sound:GetLength()
	return self.Sound.TimeLength
end

function sound:SetLooped(looped)
	self.Sound.Looped = looped
end

function sound:SetVolume(volume)
	self.Sound.Volume = volume
end

function sound.new(id, group)
	local soundInstance = Instance.new("Sound")
	soundInstance.SoundId = "rbxassetid://" .. id
	soundInstance.Parent = group and group.SoundGroup or soundService
	soundInstance.SoundGroup = group and group.SoundGroup or nil
	return setmetatable({
		Sound = soundInstance,
		Group = group,
		Ended = soundInstance.Ended
	}, sound)
end

local playlist = {}
playlist.__index = playlist

function playlist:_BuildList()
	local list = {}
	for i = 1, self.NumTracks do
		if self.Sounds[i] then
			table.insert(list, self.Sounds[i])
		end
	end
	self.List = list
end

function playlist:_PlayTrack()
	if #self.List == 0 then
		if not self.Looped then return end
		self:_BuildList()
	end
	local index = 1
	if self.Random then
		index = math.random(1, #self.List)
	end
	local track = table.remove(self.List, index)
	self.ActiveSound = track
	self.ActiveListener = track.Ended:Connect(function ()
		self.ActiveListener:Disconnect()
		self:_PlayTrack()
	end)
	track:Play()
end

function playlist:Play()
	self:Stop()
	self:_BuildList()
	self:_PlayTrack()
end

function playlist:Stop()
	if self.ActiveSound then
		self.ActiveSound:Stop()
		self.ActiveListener:Disconnect()
	end
end

function playlist:FadeOut(duration)
	local tween, listener = self:Fade(0, duration)
	listener = tween.Completed:Connect(function (state)
		listener:Disconnect()
		if state == Enum.PlaybackState.Completed then
			self:Stop()
		end
	end)
end

function playlist:FadeIn(duration)
	self:Play()
	self:Fade(0.5, duration)
end

function playlist:WaitForLoad()
	repeat
		for i = 1, self.NumTracks do
			if self.Sounds[i] then
				return
			end
		end
		wait()
	until false
end

function playlist.new(...)
	local soundGroup = Instance.new("SoundGroup", soundService)
	local ids, sounds = {...}, {}
	for i = 1, #ids do
		local sound = Instance.new("Sound", soundGroup)
		sound.SoundId = "rbxassetid://" .. ids[i]
		sound.SoundGroup = soundGroup
		if sound.IsLoaded then
			-- Unlikely but let's not risk it ayy?
			sounds[i] = sound
		else
			local listener
			listener = sound.Loaded:Connect(function ()
				listener:Disconnect()
				sounds[i] = sound
			end)
		end
		
	end
	return setmetatable({
		SoundGroup = soundGroup,
		Sounds = sounds,
		Random = false,
		Looped = true,
		
		List = {},
		ActiveSound = nil,
		ActiveListener = nil,
		NumTracks = #ids
	}, playlist)
end

setmetatable(playlist, group)

module.Group = group
module.Sound = sound
module.Playlist = playlist

return module
