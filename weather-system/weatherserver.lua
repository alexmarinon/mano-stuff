local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local TweenService = game:GetService("TweenService")

local Knit = require(ReplicatedStorage.Packages.Knit)

local Classes = ReplicatedStorage.classes
local Weather = require(Classes.weather)
local baseWeatherObjects = require(ReplicatedStorage.databases.baseWeather)

local ambience = Knit.CreateService({
    Name = 'ambience',
    Client = {
        CurrentWeather = Knit.CreateProperty('Clear'),
        CreateLightningEffect = Knit.CreateSignal()
    }
})

ambience.ActiveLightningLoop = nil

local function weatherHasLightningEffects(weatherKey: string)
    return baseWeatherObjects[weatherKey].Properties.Meterology.ThunderVolume > 0
end

function ambience:setWeather(weatherKey: string)
    if weatherHasLightningEffects(weatherKey) then
        ambience.ActiveLightningLoop = task.spawn(function()
            while true do
                task.wait(math.random(25, 60))
                self.Client.CreateLightningEffect:FireAll()
            end
        end)
    else
        if ambience.ActiveLightningLoop ~= nil then
            task.cancel(ambience.ActiveLightningLoop)
            ambience.ActiveLightningLoop = nil
        end
    end
    self.Client.CurrentWeather:Set(weatherKey)
end

function ambience:getWeather()
    return self.Client.CurrentWeather:Get()
end

function ambience:KnitStart()
    
end
    
return ambience
