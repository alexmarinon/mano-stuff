local playerDataManager = {}

local Players = game:GetService('Players')
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local ServerStorage = game:GetService('ServerStorage')
local RunService = game:GetService('RunService')

local loadedProfiles = require(script.Parent.loadedProfiles)
local ProfileService = require(ServerStorage.serverPackages.ProfileService)

local ProfileClass = require(ReplicatedStorage.classes.profile)

local PROFILE_TEMPLATE = require(script.Parent.profileTemplate)

playerDataManager.PlayerDataStore = ProfileService.GetProfileStore('PlayerDataStore', PROFILE_TEMPLATE)

if RunService:IsStudio() then
    playerDataManager.PlayerDataStore = playerDataManager.PlayerDataStore.Mock
end

function playerDataManager:onPlayerAdded(player: Player)
    if not self.PlayerDataStore then
        warn('PlayerDataStore not initialized')
        repeat 
            task.wait(1) 
        until playerDataManager.PlayerDataStore ~= nil
    end
    print(`{player.Name} profile fetching!`)
    local playerProfileObject = self.PlayerDataStore:LoadProfileAsync("Player_"..player.UserId, "ForceLoad")
    print(`{player.Name} profile is {playerProfileObject}!`)
    local profile: ProfileClass.Profile = nil
    if playerProfileObject ~= nil then
        profile = ProfileClass.new(player, playerProfileObject)
    end
    print(`{player.Name} profile actual is {profile}!`)
    if profile ~= nil then
        profile:listenToRelease(function()
            loadedProfiles[player] = nil
        end)
        if player:IsDescendantOf(Players) then
            loadedProfiles[player] = profile
        else
            profile:release()
        end
    else
        player:Kick('Unable to load your data. Please rejoin.')
    end
end

function playerDataManager:onPlayerRemoved(player: Player)
    local profile = loadedProfiles[player]

    if profile then
        profile:release()
    end
end

function playerDataManager:getLoadedProfile(player: Player)
    assert(typeof(player) == "Instance" and player:IsA('Player'), "Invalid player")
    local profile = loadedProfiles[player]
    if profile == nil then
        return warn(`Profile for {player.Name} does not exist`)
    end
    return profile
end

function playerDataManager:getDefaultTemplate()
    return PROFILE_TEMPLATE
end

return playerDataManager
