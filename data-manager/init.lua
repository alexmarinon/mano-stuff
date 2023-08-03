local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")

local Knit = require(ReplicatedStorage.Packages.Knit)

local loadedProfiles = require(script.loadedProfiles)

local data = Knit.CreateService({
    Name = "data"
})

data.playerDataManager = require(script.playerDataManager)
data.serverListManager = require(script.serverListManager)
data.cacheManager = require(script.cacheManager)

function data:onInit()

    Players.PlayerAdded:Connect(function(player: Player)
        self.playerDataManager:onPlayerAdded(player)
    end)
    Players.PlayerRemoving:Connect(function(player: Player)
        self.playerDataManager:onPlayerRemoved(player)
    end)
    game:BindToClose(function()
        for _, player in Players:GetPlayers() do
            self.playerDataManager:onPlayerRemoved(player)
        end
    end)
end

function data:onStart()
    for _, player in Players:GetPlayers() do
        if not loadedProfiles[player] then
            self.playerDataManager:onPlayerAdded(player)
        end
    end

    self.cacheManager:start()
    self.serverListManager:start()
end

return data
