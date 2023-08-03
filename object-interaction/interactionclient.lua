local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Jupiter = require(ReplicatedStorage.Packages.Jupiter)

local interaction = Jupiter.CreateController({
    Name = "interaction"
})

interaction.Objects = require(script.objects)
interaction.Executor = require(script.executor)

function interaction:__init__()
    self.Objects:__init__()
    self.Executor:__init__()
end

function interaction:__start__()
    self.Objects:__start__()
    self.Executor:__start__()
end

return interaction
