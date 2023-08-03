-- ProgressionManager.lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Jupiter = require(ReplicatedStorage.Packages.Jupiter)
local Signal = require(ReplicatedStorage.Packages.Signal)
local StoryComponent = require(script.storyComponent)
local Promise = require(ReplicatedStorage.Packages.Promise)
local ReplicaService = require(ServerScriptService.Packages.ReplicaService)

local testFire = Signal.new()
local canGo = false

local progression = Jupiter.CreateService({
    Name = "progression",
    Client = {
        CurrentStep = Jupiter.CreateProperty(3)
    }
})

local function getStorySteps()
    return Promise.new(function(resolve)
        local steps = {}
        for _, step in script.storyList:GetChildren() do
            local stepModule = require(step)
            progression.steps[stepModule.Index] = stepModule
        end
        resolve()
    end)
end

progression.steps = {
    
}
progression.currentStep = 1

function progression:getObjectiveStep()
    return self.Client.CurrentStep:Get()
end

function progression:setObjectiveStep(value: number)
    return self.Client.CurrentStep:Set(value)
end

function progression:beginLoop()
    while self.currentStep <= #self.steps do
        local step = self.steps[self.currentStep]
        print(`[Server] step at {self.currentStep}`)
        step:Begin()
        step.Completed:Wait()
        print(`Completed (server-side)`)
        self.currentStep = self.currentStep + 1
        self.Client.CurrentStep:Set(self.currentStep)
        print(`[Server] Story value now at {self.currentStep}`)
    end
    --[[return Promise.new(function(resolve, reject)
        while self.currentStep <= #self.steps do
            local step = self.steps[self.currentStep]
            print(self.currentStep)
            step:Begin()
            step.Completed:Wait()
            print(`Completed (server-side)`)
            self.currentStep = self.currentStep + 1
            self.Client.CurrentStep:Set(self.currentStep)
            warn(self.Client.CurrentStep:Get())
        end
        resolve()
    end)]]
end

function progression:__init__()
    
end

function progression:__start__()
    getStorySteps():await()
    self:beginLoop()
end

return progression
