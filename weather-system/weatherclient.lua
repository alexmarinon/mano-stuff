local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lighting = game:GetService('Lighting')
local TweenService = game:GetService('TweenService')

local Knit = require(ReplicatedStorage.Packages.Knit)

local Classes = ReplicatedStorage.classes
local Weather = require(Classes.weather)

local baseWeatherObjects = require(ReplicatedStorage.databases.baseWeather)
local assets = require(ReplicatedStorage.databases.assets)

local rain = require(script.rain)
local wind = require(script.wind)

local lightningSounds = assets.Sound.Ambience.Weather.Lightning
local windSoundObject = workspace:WaitForChild('Wind')

local lightningSoundIds = {}
for _, soundId in pairs(lightningSounds) do
    table.insert(lightningSoundIds, soundId)
end

local ambienceService = nil

local ambience = Knit.CreateController({
    Name = 'ambience'
})

ambience.CachedLocalWeather = nil
ambience.CachedMeteoEffects = nil

local OBJECT_ASSOCIATIONS = {
    ['Clouds'] = workspace.Terrain.Clouds,
    ['Blur'] = Lighting.AmbienceBlur,
    ['ColorCorrection'] = Lighting.AmbienceColorCorrection,
    ['SunRays'] = Lighting.AmbienceSunRays,
    ['Bloom'] = Lighting.AmbienceBloom,
    ['Atmosphere'] = Lighting.Atmosphere,
    ['Lighting'] = Lighting,
    ['LightningEffect'] = Lighting.LightningCorrection
}

local ATMO_TWEEN_INFO = TweenInfo.new(10, Enum.EasingStyle.Sine, Enum.EasingDirection.Out, 0, false, 0)

local function tweenObjectPropertyAsync(object, propertyName, value)
    local propertyTable = {
        [propertyName] = value
    }
    local tween = TweenService:Create(object, ATMO_TWEEN_INFO, propertyTable)

    tween.Completed:Connect(function(playbackState)
        if playbackState == Enum.PlaybackState.Completed then
            tween:Destroy()
        end
    end)
    tween:Play()
end

local function setObjectEffects(weatherType)
    for categoryName, propertyCategory in pairs(weatherType.Properties) do
        if categoryName ~= 'Meterology' then
            for propertyName, propertyValue in pairs(propertyCategory) do
                tweenObjectPropertyAsync(OBJECT_ASSOCIATIONS[categoryName], propertyName, propertyValue)
            end
        end
    end
end

local function setMeterologicalEffects(weatherType: Weather.Weather)
    local meteoEffects = weatherType.Properties.Meterology

    local windDirection = meteoEffects.WindDirection
    local windSpeed = meteoEffects.WindSpeed
    local globalWind = windDirection * windSpeed
    local rainVolume = meteoEffects.RainVolume

    rain:SetTransparency(1 - rainVolume, ATMO_TWEEN_INFO)
    rain:SetVolume(rainVolume, ATMO_TWEEN_INFO)
    rain:SetDirection(Vector3.new(windDirection.X, -1, windDirection.Y) * (windSpeed / 10), ATMO_TWEEN_INFO)
    rain:SetIntensityRatio(rainVolume, ATMO_TWEEN_INFO)

    tweenObjectPropertyAsync(workspace, 'GlobalWind', globalWind)

    if rainVolume > 0 then
        rain:Enable()
    else
        rain:Disable()
    end

    if windSpeed > 5 then
        windSoundObject:Play()
    else
        windSoundObject:Stop()
    end
end

local function updateWindShake(meteoEffects)
    local windDirection = meteoEffects.WindDirection
    local windSpeed = meteoEffects.WindSpeed

    wind:SetDefaultSettings({
        WindDirection = windDirection,
        WindSpeed = windSpeed / 5,
        WindPower = windSpeed / 10,
    })

    wind:UpdateAllObjectSettings()
end

local function createLightningEffect()
    local lightningCorrection = game.Lighting.LightningCorrection
    local tween1 = TweenService:Create(lightningCorrection, TweenInfo.new(0.1, Enum.EasingStyle.Sine, Enum.EasingDirection.Out, 0, true), {Brightness = 0.6})
    local tween2 = TweenService:Create(lightningCorrection, TweenInfo.new(0.4, Enum.EasingStyle.Sine, Enum.EasingDirection.In), {Brightness = 0.8})
    local tween3 = TweenService:Create(lightningCorrection, TweenInfo.new(2, Enum.EasingStyle.Sine, Enum.EasingDirection.In), {Brightness = 0})
    tween1:Play()
    tween1.Completed:Wait()
    tween2:Play()
    tween2.Completed:Wait()
    tween3:Play()
    
    local lightningSound = workspace:FindFirstChild('LightningSound')
    if not lightningSound then
        lightningSound = Instance.new('Sound')
        lightningSound.Volume = 1.5
        lightningSound.Parent = workspace
    end

    lightningSound.SoundId = lightningSoundIds[math.random(1, #lightningSoundIds)]
    lightningSound:Play()
end

function ambience:setWeather(weatherType: Weather.Weather)
    setObjectEffects(weatherType)
    setMeterologicalEffects(weatherType)
    self.CachedMeteoEffects = weatherType.Properties.Meterology
end

function ambience:getBaseWeatherObject(key: string): Weather.Weather
    return baseWeatherObjects[key]
end

function ambience:KnitInit()
    wind:Init()
end

function ambience:KnitStart()
    ambienceService = Knit.GetService('ambience')
    ambienceService.CurrentWeather:Observe(function(weatherKey: string)
        ambience.CachedLocalWeather = weatherKey
        local weatherObject = ambience:getBaseWeatherObject(weatherKey)
        ambience:setWeather(weatherObject)
    end)

    ambienceService.CreateLightningEffect:Connect(createLightningEffect)
    
    workspace:GetPropertyChangedSignal('GlobalWind'):Connect(function(value)
        if not ambience.CachedMeteoEffects then return end
        updateWindShake(ambience.CachedMeteoEffects)
    end)
end

return ambience
