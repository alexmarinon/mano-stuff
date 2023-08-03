-- ROBLOX services:

local ReplicatedStorage = game:GetService('ReplicatedStorage')
local Players = game:GetService('Players')
local ServerScriptService = game:GetService('ServerScriptService')
local CollectionService = game:GetService('CollectionService')
local ServerStorage = game:GetService('ServerStorage')
local ServerLibrary = ServerStorage.ServerLibrary
local ServerAssets = ServerLibrary.Assets
local Doors = ServerAssets.Doors

-- Locations:

local Packages = ReplicatedStorage:WaitForChild('Packages')
local Databases = ReplicatedStorage.Databases

-- Modules:

local Knit = require(Packages.Shared.Knit)
local GlobalSettings = require(Databases.GlobalSettings)
local Permissions = require(Databases.Permissions)

-- Local functions

local doorReplaceParts = CollectionService:GetTagged('ReplaceDoor')

-- Main

local DoorService = Knit.CreateService({
	Name = 'DoorService',
	Client = {},
})

function DoorService:KnitInit()
	--[[for _, object in ipairs(doorReplaceParts) do
		local cloned = Doors[object.Name]:Clone()
		cloned:SetPrimaryPartCFrame(object.CFrame)
		cloned.Parent = workspace.Map.Doors
		object:Destroy()
		for _, doorPart in cloned.Door:GetDescendants() do
			if doorPart:IsA('BasePart') then
				doorPart.Anchored = false
			end
		end
	end
	]]--
end

function DoorService.Client:ToggleDoor(player: Player, door: Model, prompt: ProximityPrompt)
	if door:IsDescendantOf(workspace) then
		local permission = prompt:GetAttribute('PermissionToTrigger')
		if Permissions:VerifyPermission(player, permission) then
			local targetAngle = nil;
			local doorRoot = door.Door.DoorRoot
			local interactionPart = prompt.Parent
			local openSound = interactionPart.Open
			local closeSound = interactionPart.Close
			local autoCloseTime = door.AutocloseTime.Value
			local queuedAutoclose = door.QueuedAutoclose
			if door.Debounce.Value == true then
				return
			end
			door.Debounce.Value = true
			if door.Opened.Value == true then
				targetAngle = 0
				closeSound:Play()
			else
				if door.Name == "ES_GateBar" then
					targetAngle = 80
				else
					targetAngle = 100
				end
				openSound:Play()
			end
			for _,v in door:GetDescendants() do
				if v:IsA('HingeConstraint') then
					v.TargetAngle = targetAngle
				end
			end
			wait(1)
			door.Debounce.Value = false
			door.Opened.Value = not door.Opened.Value
			door.Opened.Changed:Connect(function()
				if door.Opened.Value == false then
					return
				end
			end)
			queuedAutoclose.Value += 1
			task.wait(autoCloseTime)
			if door.Opened.Value == true and queuedAutoclose.Value <= 1 then
				targetAngle = 0
				for _,v in door:GetDescendants() do
					if v:IsA('HingeConstraint') then
						v.TargetAngle = targetAngle
					end
				end
				closeSound:Play()
				door.Opened.Value = not door.Opened.Value
				queuedAutoclose.Value = 0
			else
				queuedAutoclose.Value -= 1
			end
		else
			if door.InteractionRoot:FindFirstChild("DoorLocked") then
				door.InteractionRoot:FindFirstChild("DoorLocked"):Play()
			end
		end
	end
end

return DoorService
