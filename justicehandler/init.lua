--[[

	JusticeService exposes functions for manipulating and conducting player arrests, searches, etc.

]]

-- ROBLOX services:

local ReplicatedStorage = game:GetService('ReplicatedStorage')
local Players = game:GetService('Players')
local ServerScriptService = game:GetService('ServerScriptService')

-- Locations:

local Packages = ReplicatedStorage:WaitForChild('Packages')
local Services = ServerScriptService.Services
local Databases = ReplicatedStorage.Databases

-- Modules:

local Knit = require(Packages.Shared.Knit)
local GlobalSettings = require(Databases.GlobalSettings)
local Permissions = require(Databases.Permissions)
local CriminalCode = require(Databases.CriminalCode)
local LoadedProfiles = require(Services.DataService.LoadedProfiles)

-- Local functions

local function NullifySessionStats(player)
	if player:IsDescendantOf(Players) then
		player:SetAttribute('Cuffed', false)
		player:SetAttribute('Grabbed', false)
		player:SetAttribute('Dragging', false)
		player:SetAttribute('SuspectBeingGrabbed', nil)
	end
end

-- Main

local JusticeService = Knit.CreateService({
	Name = 'JusticeService',
	Client = {
		ClientCuffPlayer = Knit.CreateSignal(),
		ClientGrabPlayer = Knit.CreateSignal(),
		ClientUpdateCuffText = Knit.CreateSignal(),
		ClientUpdateGrabText = Knit.CreateSignal()
	},
})

local BodyPartCollisions = {
	"LowerTorso",
	"UpperTorso",
	"Head",
	"HumanoidRootPart",
}


function toggleCanCollideCharacter(char: Model, status: boolean)
	for _,v in char:GetChildren() do
		if table.find(BodyPartCollisions,tostring(v.Name)) then
			v.CanCollide = status
		end
	end
end

function JusticeService.Client:BookPlayer(executor: Player, suspect: Player, charges, statement: string)
	local DataService = Knit.GetService('DataService')
	if Permissions:VerifyPermission(executor, 'PolicePowers') then
		if suspect.UserId == executor:GetAttribute('SuspectBeingGrabbed') and executor:GetAttribute('SuspectBeingGrabbed') ~= nil then
			if charges ~= nil then
				if suspect.Team ~= game.Teams.Incarcerated then
					local realStatement = nil;
					if statement == nil then
						realStatement = 'No statement provided'
					end
					local jailTime = 0
					for _, crime in charges do
						for _, section in CriminalCode.Sections do
							for key, value in section do
								if key == crime then
									jailTime += (value.Time * 60)
								end
							end
						end
					end
					DataService:AdjustTimeLeftInJail(suspect, jailTime)				
					DataService:AddRecord(suspect, charges, realStatement, executor)
					DataService:ListenForRelease(suspect)					
				end
			end
		end
	end
end

function JusticeService.Client:CuffPlayer(executor: Player, char: Model, prompt: ProximityPrompt)
	if char then
		if Permissions:VerifyPermission(executor, 'PolicePowers') then
			local suspect = Players:GetPlayerFromCharacter(char)
			if not suspect:GetAttribute('Cuffed') then
				if not executor:GetAttribute('Cuffed') then
					suspect:SetAttribute('Cuffed', true)
					char:FindFirstChildOfClass('Humanoid'):UnequipTools()
					JusticeService.Client.ClientCuffPlayer:Fire(executor, executor, suspect, true)
					JusticeService.Client.ClientCuffPlayer:Fire(suspect, executor, suspect, true)
					JusticeService.Client.ClientUpdateCuffText:FireAll(suspect, true)
					return true
				end
			else
				print('uncuffing')
				JusticeService.Client.ClientCuffPlayer:Fire(suspect, executor, suspect, false)
				JusticeService.Client.ClientUpdateCuffText:FireAll(suspect, false)
				toggleCanCollideCharacter(char, true)
				suspect:SetAttribute('Cuffed', false)
				suspect:SetAttribute('Grabbed', false)
				executor:SetAttribute('SuspectBeingGrabbed', nil)
				executor:SetAttribute('Dragging', false)
				return false
			end
		end
	end
end

function JusticeService.Client:GrabPlayer(executor: Player, char: Model, prompt: ProximityPrompt)
	if char then
		if Permissions:VerifyPermission(executor, 'PolicePowers') then
			local suspect = Players:GetPlayerFromCharacter(char)
			if not suspect:GetAttribute('Grabbed') then
				if not executor:GetAttribute('Cuffed') and not executor:GetAttribute('Grabbed') and not executor:GetAttribute('Dragging') then
					local master = executor.Character
					suspect:SetAttribute('Grabbed', true)
					toggleCanCollideCharacter(char, true)
					executor:SetAttribute('Dragging', true)
					executor:SetAttribute('SuspectBeingGrabbed', suspect.UserId)
					JusticeService.Client.ClientGrabPlayer:Fire(executor, executor, suspect, true)
					JusticeService.Client.ClientGrabPlayer:Fire(suspect, executor, suspect, true)
					JusticeService.Client.ClientUpdateGrabText:FireAll(suspect, true)
					char.Humanoid.Died:Connect(function()
						executor:SetAttribute('Dragging', false)
						executor:SetAttribute('SuspectBeingGrabbed', nil)
					end)
					return true
				end
			else
				toggleCanCollideCharacter(char, false)
				suspect:SetAttribute('Grabbed', false)
				executor:SetAttribute('Dragging', false)
				executor:SetAttribute('SuspectBeingGrabbed', nil)
				JusticeService.Client.ClientUpdateGrabText:FireAll(suspect, false)
				return false
			end
		end
	end
end

function JusticeService:KnitInit()
	for _, player in Players:GetPlayers() do
		NullifySessionStats(player)
	end
	Players.PlayerAdded:Connect(NullifySessionStats)
end

function JusticeService:KnitStart()
	
	local Permissions = require(Databases.Permissions)
	--[[for _, player in Players:GetPlayers() do
		task.spawn(listenForRelease, player)
	end
	Players.PlayerAdded:Connect(function(player)
		task.spawn(listenForRelease, player)
	end)]]--
end

return JusticeService
