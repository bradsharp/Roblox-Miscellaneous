-- MIT License Copyright (c) 2016 Brad Sharp https://github.com/BradSharp/roblox

local httpService = game:GetService'HttpService'
local domain = "https://discordapp.com/api/webhooks"

local module = {}

local hookMetatable = {
	__index = {
		ClassName = "DiscordWebhook",
		GetAsync = function (self)
			return httpService:GetAsync(domain .. "/" .. self.URL)
		end,
		PostAsync = function (self, content, username, avatar, tts, file, embeds)
			return httpService:PostAsync(
				domain .. "/" .. self.URL,
				httpService:JSONEncode{
					content = content,
					username = username,
					avatar_url = avatar,
					tts = tts,
					file = file,
					embeds = embeds
				}
			)
		end
	},
	__newindex = error
}

function module.RegisterHook(id, token) 
	return setmetatable({
		URL = id .. "/" .. token
	}, hookMetatable)
end

return module
