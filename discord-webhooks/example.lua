local discordApp = require(script.DiscordWebhooks)

local webhook = discordApp.RegisterHook("", "")

webhook:PostAsync(
	"Test message",
	"Brad_Sharp"
)
