local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Packages.Knit)

local input = Knit.CreateController({
    Name = "input"
})

input.Mouse = require(script.Mouse)
input.ActionBind = require(script.ActionBind)
input.actionManager = require(script.ActionBind).new()
input.Action = require(ReplicatedStorage.classes.action)
input.Dragging = require(script.Dragging)

function input:onInit()
    self.LocalMouse = self.Mouse.new()
    self.Dragging:__init__(self.LocalMouse)
end

function input:onStart()
    
end

return input
