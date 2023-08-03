local module = {}

local Players = game:GetService('Players')
local Player = Players.LocalPlayer
local Character = Player.Character or Player.CharacterAdded:Wait()
local Mouse = Player:GetMouse()
Mouse.TargetFilter = workspace.Zones

local ReplicatedStorage = game:GetService('ReplicatedStorage')
local UserInputService = game:GetService('UserInputService')
local Packages = ReplicatedStorage:WaitForChild('Packages')
local RunService = game:GetService('RunService')

local cameraShaker = require(ReplicatedStorage.Modules.CameraShaker)
local camera = workspace.CurrentCamera
local camShake = cameraShaker.new(Enum.RenderPriority.Camera.Value, function(shakeCFrame)
	camera.CFrame = camera.CFrame * shakeCFrame
end)

local FastCast = require(Packages.Shared.FastCastRedux)
local ItemInfo = require(ReplicatedStorage.Databases.Items)
local Knit = require(ReplicatedStorage.Packages.Shared.Knit)
local GunCursorID = require(ReplicatedStorage.Databases.Icons).GunCursor
local GunCursorID = require(ReplicatedStorage.Databases.Icons).GunCursor

local magazine = nil;
local CombatService = nil;
local Tool = nil;
local dcFunction = nil;
local mouseDown = false
local debounce = false
local actiondebounce = false
local reloaddebounce = false
local Reloading = false
local Equipped = false
local gunData = nil;
local mousedownConnect = nil;
local mouseDownAutoConnect = nil;
local PlayerAnims
function doDebounce()
	debounce = true
	task.wait(gunData.Cooldown)
	debounce = false
end

function doActionDebounce()
	actiondebounce = true
	task.wait(.25)
	actiondebounce = false
end

function doReloadDebounce()
	reloaddebounce = true
	task.wait(2)
	reloaddebounce = false
end

local connections = {}
function module:OnEquip(tool, ...)
	gunData = ItemInfo.Firearms[tool.Name]		
	mouseDown = false;
	magazine = tool.LoadedMagazine:FindFirstChildOfClass('Tool')
	Tool = tool
	Equipped = true
	Mouse.Icon = GunCursorID
	Tool.LoadedMagazine.ChildAdded:Connect(function(child)
		if child:IsA("Tool") then
			magazine = child
		end
	end)
	if Tool.SlideBack.Value == true then
		PlayerAnims:SlideBroke("Zalio P2")
	end
	if Tool.Ease.Value == true then
		PlayerAnims:Ease("Zalio P2")
	else
		PlayerAnims:Idle("Zalio P2")
	end
	Tool.SlideBack.Changed:Connect(function()
		if Tool.SlideBack.Value == true then
			PlayerAnims:SlideBroke("Zalio P2")
		end
	end)
	CombatService = Knit.GetService('CombatService')
	if tool:IsDescendantOf(Player.Character) then
		CombatService:CheckChamber(Tool)
		mousedownConnect = UserInputService.InputBegan:Connect(function(input,mddb)
			mouseDown = true
			if input.UserInputType == Enum.UserInputType.MouseButton1 and not mddb and Equipped == true and Tool.Ease.Value == false and Reloading == false then
				if mouseDown and not debounce then
					task.spawn(doDebounce)
						
						local pos = UserInputService:GetMouseLocation()
						local ray = workspace.CurrentCamera:ViewportPointToRay(pos.X, pos.Y)
						
						CombatService:RequestFireGun(Tool, ray,Mouse.Hit.Position)
					if Tool.ChamberEmpty.Value == false and Tool.SlideBack.Value == false and magazine.Ammunition.Value >=1 and Reloading == false and Equipped == true then
							if Tool.Name == "Raptor A1" then
								PlayerAnims:Recoil("Raptor A1")
							elseif Tool.Name == "Zalio P2" then
							PlayerAnims:Recoil("Zalio P2")
							camShake:Start()
							camShake:ShakeOnce(2,2,.2,.4)
							end
						end	
				end
			elseif input.KeyCode == Enum.KeyCode.R and not mddb and Equipped == true and Tool.Ease.Value == false and Reloading == false then
				if mouseDown and not reloaddebounce then
					task.spawn(doReloadDebounce)
					local hasammo = false
					for i,v in pairs(Player.Backpack:GetChildren()) do
						if v:IsA("Tool") then
							if v:FindFirstChild("Ammunition") then
								if v:FindFirstChild("Ammunition").Value >=1 then
									hasammo = true
								end
							end
						end
					end
					if hasammo == true then
						Reloading = true
						CombatService:RequestReload(Tool)
						if Tool.Name == "Raptor A1" then
							PlayerAnims:Recoil("Raptor A1")
						elseif Tool.Name == "Zalio P2" then
							PlayerAnims:Reload("Zalio P2")
						end
					end
					wait(1.3)
					Reloading = false
				end
			elseif input.KeyCode == Enum.KeyCode.T and not mddb and Equipped == true and Tool.Ease.Value == false and Reloading == false then
				if mouseDown and not actiondebounce then
					task.spawn(doActionDebounce)
					if Tool:WaitForChild("SlideBack").Value == false then
						Tool:WaitForChild("SlideBack").Value = true
						CombatService:SlideBack(Tool)
						if Tool.Name == "Raptor A1" then
							PlayerAnims:Back("Raptor A1")
						elseif Tool.Name == "Zalio P2" then
							PlayerAnims:Back("Zalio P2")
						end
					else
						Tool:WaitForChild("SlideBack").Value = false
						CombatService:SlideForward(Tool)
						if Tool.Name == "Raptor A1" then
							PlayerAnims:Forward("Raptor A1")
						elseif Tool.Name == "Zalio P2" then
							PlayerAnims:Forward("Zalio P2")
						end
					end
				end
			elseif input.KeyCode == Enum.KeyCode.Y and not mddb and Equipped == true and Reloading == false then
				if mouseDown and not actiondebounce then
					task.spawn(doActionDebounce)
					if Tool.Ease.Value == false then
						Tool.Ease.Value = true
						PlayerAnims:Idle("End")
						if Tool.Name == "Raptor A1" then
							PlayerAnims:Ease("Raptor A1")
						elseif Tool.Name == "Zalio P2" then
							PlayerAnims:Ease("Zalio P2")
						end
					else
						Tool.Ease.Value = false
						PlayerAnims:Ease("End")
						PlayerAnims:Idle("Zalio P2")
					end
				end
			elseif input.KeyCode == Enum.KeyCode.U and not mddb and Equipped == true and Reloading == false then
				if mouseDown and not actiondebounce then
					task.spawn(doActionDebounce)
					if Tool.HasLight.Value == true then
						CombatService:ToggleLight(Tool)
					end
				end
			end
		end)
		mouseDownAutoConnect = UserInputService.InputEnded:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 then
				mouseDown = false
			end
		end)
			
	end
end


local function CharacterAdded(character)
	PlayerAnims = require(Character:WaitForChild("PlayerAnims"))
	Character = game.Players.LocalPlayer.Character or game.Players.LocalPlayer.CharacterAdded:Wait()
	Character:WaitForChild("Humanoid").Died:Connect(function()
		magazine = nil;
		Tool = nil;
		dcFunction = nil;
		mouseDown = false
		Mouse.Icon = ""
		debounce = false
		Equipped = false
	end)
	magazine = nil;
	Tool = nil;
	dcFunction = nil;
	mouseDown = false
	Mouse.Icon = ""
	debounce = false
	Equipped = false
end

if game.Players.LocalPlayer.Character then
	CharacterAdded(game.Players.LocalPlayer.Character)
end

game.Players.LocalPlayer.CharacterAdded:Connect(CharacterAdded)

function module:OnUnequip(tool, ...)
	magazine = nil;
	Tool = nil;
	dcFunction = nil;
	mouseDown = false
	Mouse.Icon = ""
	debounce = false
	Equipped = false
	mousedownConnect:Disconnect()
	mouseDownAutoConnect:Disconnect()
end


return module
