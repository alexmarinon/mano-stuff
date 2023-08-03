-- StoryComponent.lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Signal = require(ReplicatedStorage.Packages.Signal)
local Promise = require(ReplicatedStorage.Packages.Promise)

local StoryComponent = {}
StoryComponent.__index = StoryComponent

function StoryComponent.new(settings)
    local self = setmetatable({}, StoryComponent)

    self.OnBegin = settings.OnBegin
    self.OnCompletion = settings.OnCompletion
    self.CanComplete = settings.CanComplete
    self.Index = settings.Index

    self.CheckProgressionSignal = settings.CheckProgressionSignal or Signal.new()
    self.Completed = Signal.new()
    self.Began = Signal.new()

    self.CheckProgressionSignalConnection = self.CheckProgressionSignal:Connect(function(...)
        if self.CanComplete(...) then
            self:Complete()
        end
    end)

    return self
end

function StoryComponent:Begin()
    self.OnBegin()
    self.Began:Fire()
end

function StoryComponent:Complete()
    local promise = Promise.new(function(resolve)
        self.OnCompletion()
        resolve()
    end):andThen(function()
        self.CheckProgressionSignalConnection:Disconnect()
        self.Completed:Fire()
    end)
    return promise
end

return StoryComponent
