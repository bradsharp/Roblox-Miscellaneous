local base = "https://raw.githubusercontent.com/BradSharp"

local modules = {
    luna = {
        Source = "/luna/master/luna.lua",
        Server = true,
        Client = true
    }
}

-- Initializing code

local httpService = game:GetService'HttpService'

for name, details in pairs(modules) do
    local module = Instance.new("ModuleScript")
    module.Source = httpService:GetAsync(base .. details.Source)
    module.Name = name
    if details.Server and details.Client then
        local clientModule = module:Clone()
        clientModule.Parent = game:GetService'StarterPlayer'
            .StarterPlayerScripts
        module.Parent = game:GetService'ServerScriptService'
    elseif details.Server then
        module.Parent = game:GetService'ServerScriptService'
    elseif details.Client then
        module.Parent = game:GetService'ServerScriptService'
    end
end

game.FilteringEnabled = true
game.StarterGui.ResetPlayerGuiOnSpawn = false
