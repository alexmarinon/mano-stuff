local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StoryComponent = require(script.Parent.Parent.storyComponent)
local Jupiter = require(ReplicatedStorage.Packages.Jupiter)

local ambienceService = Jupiter.GetService('ambience')
local entitiesService = Jupiter.GetService('entities')

return StoryComponent.new({
    Index = 1,
    CanComplete = function()
        return true
    end,
    OnCompletion = function()
        print("Completed")
    end,
    OnBegin = function()
        ambienceService:setWeather('HeavyRainstorm')
        print("Began")
    end,
    CheckProgressionSignal = entitiesService.Cache['QuartermasterDoor'].Opened,
})
