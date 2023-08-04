local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Jupiter = require(ReplicatedStorage.Packages.Jupiter)
local ProfileService = require(ServerScriptService.Packages.ProfileService)

local Profile = require(script.Profile)
local profileTemplate = require(script.Template)

local playerDataStore = ProfileService.GetProfileStore("PlayerData", profileTemplate)

local playerData = Jupiter.CreateService({
	Name = 'playerData'
})

playerData.LoadedProfiles = {}

local function onPlayerAdded(player: Player)
	local profile = playerDataStore:LoadProfileAsync("Player_"..player.UserId)
	if profile ~= nil then
		local profileWrapper = Profile.new(player, profile)
		profileWrapper:addUserId(player.UserId)
		profileWrapper:reconcile()
		profileWrapper:listenToRelease(function()
			playerData.LoadedProfiles[player] = nil
			player:Kick()
		end)
		if player:IsDescendantOf(Players) == true then
			playerData.LoadedProfiles[player] = profileWrapper
			print(`Loaded profile for {player.Name}`)
			print(profileWrapper)
		else
			profileWrapper:release()
		end
	else
		player:Kick(`Could not load data!`)
	end
end

local function onPlayerRemoving()
	
end

function playerData:__init__()
	print(`Init player data`)
	Players.PlayerAdded:Connect(onPlayerAdded)
	Players.PlayerRemoving:Connect(function(player: Player)
		local profile = playerData.LoadedProfiles[player]
		if profile ~= nil then
			profile:release()
		end
	end)
end

function playerData:__start__()
	for _, player in Players:GetPlayers() do
		onPlayerAdded(player)
	end
end

return playerData
