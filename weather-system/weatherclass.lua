export type Weather = {
    Name: string,
    Properties: {
        Meterology: {
            WindDirection: Vector3,
            WindSpeed: Vector3,
            RainVolume: number,
            SnowVolume: number,
            ThunderVolume: number         
        },
        Clouds: {
            Cover: number,
            Density: number,
            Color: Color3Value
        },
        Blur: {
            Size: number
        },
        ColorCorrection: {
            Brightness: number,
            Contrast: number,
            Saturation: number,
            TintColor: Color3Value,
        },
        SunRays: {
            Intensity: number,
            Spread: number,
        },
        Bloom: {
            Intensity: number,
            Size: number,
            Threshold: number,
        },
        Atmosphere: {
            Density: number,
            Offset: number,
        }
    }
}

local Weather = {}
Weather.__index = Weather

function Weather.new(name: string, properties: table): Weather
    local self = setmetatable({}, Weather)
    self.Name = name
    self.Properties = properties
    return self
end

return Weather
