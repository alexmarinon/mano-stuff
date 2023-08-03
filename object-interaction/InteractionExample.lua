local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Jupiter = require(ReplicatedStorage.Packages.Jupiter)
local signalRepo = require(ReplicatedStorage.databases.signalRepo)

local interfaceController = Jupiter.GetController('interface')

local QuartermasterOpenDoor = {
    ObjectName = "Quartermaster\'s Office",
    ActionName = "Enter",
    Duration = 2,
    MaxDistance = 25
}

function QuartermasterOpenDoor:execute(target: Instance)
    signalRepo.QuartermasterOpenDoor:Fire()
    target.IsHome.Value = false
end

function QuartermasterOpenDoor:holdBegan(target)
    if target.IsHome.Value == true then
        target.Knock:Play()
    else
        target.Quiet:Play()
        interfaceController:sendCaption('Quartermaster', 'Shhhh.', 3)
    end
end

function QuartermasterOpenDoor:holdEnded(target)
    if target == nil or target:FindFirstChild('Quiet') == nil then return end
    if target.Knock.IsPlaying then
        target.Knock:Stop()
    end
end


return QuartermasterOpenDoor
