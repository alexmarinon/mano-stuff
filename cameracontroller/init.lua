local ReplicatedStorage = game:GetService('ReplicatedStorage')
local Players = game:GetService('Players')
local Player = Players.LocalPlayer
local RunService = game:GetService('RunService')
local TweenService = game:GetService('TweenService')

local Jupiter = require(ReplicatedStorage.Packages.Jupiter)
local Signal = require(ReplicatedStorage.Packages.Signal)

local camera = Jupiter.CreateController({
	Name = 'camera'
})

camera.RenderName = "CustomCamRender"
camera.Priority = Enum.RenderPriority.Camera.Value
camera.Distance = 10
camera.BaseFOV = 70
camera.Locked = false
camera.ActiveCustomRender = true
camera.LockedFOV = 70
camera.isShaking = false

local TweenToFOVTime = 0.25
local TweenCameraInfo = TweenInfo.new(TweenToFOVTime, Enum.EasingStyle.Linear, Enum.EasingDirection.Out)

local FOVModifier = require(ReplicatedStorage.classes.fovModifier)

local RenderFOVList = FOVModifier.RenderFOVList

local function hideCameraCutscenePoints()
	for _, part in pairs(workspace.CutscenePoints:GetChildren()) do
		part.Transparency = 1
	end
end

function camera:SumOfFOV()
	local amount = 0
	for _, v in pairs(RenderFOVList) do
		amount += v
	end
	return amount
end

function camera:TweenFOVTo(amount: number)
	local cam = workspace.CurrentCamera
	local Tween = TweenService:Create(cam, TweenCameraInfo, {FieldOfView = amount})
	Tween:Play()
	task.wait(TweenToFOVTime)
	Tween.Completed:Wait()
	Tween:Destroy()
end

function camera:SetFOV(number)
	self.LockedFOV = number
end

function camera:LockTo(part: Part)
	if (self.Locked) then return end
    local cam = workspace.CurrentCamera
    self.Locked = true
    cam.CameraType = Enum.CameraType.Scriptable
    RunService:BindToRenderStep(self.RenderName, self.Priority, function()
        local offset = part.CFrame:VectorToWorldSpace(Vector3.new(0, 0, -self.Distance))
        cam.CFrame = part.CFrame * CFrame.new(0, 0, -self.Distance)
    end)
end

function camera:Unlock()
	if (not self.Locked) then return end
	local cam = workspace.CurrentCamera
	self.Locked = false
	cam.CameraType = Enum.CameraType.Custom
	RunService:UnbindFromRenderStep(self.RenderName)
	workspace.CurrentCamera.CFrame = workspace.CurrentCamera.CFrame
end

function camera:Shake(duration: number, magnitude: number, frequency: number, upDown: boolean, upDownMagnitude: number)
	if self.isShaking then return end
	self.isShaking = true
	local cam = workspace.CurrentCamera
	local start = os.clock()
	local offsetX = math.random(0, 1000)
	local offsetY = math.random(0, 1000)
	local offsetZ = math.random(0, 1000)
	RunService:BindToRenderStep(self.RenderName.."_Shake", self.Priority, function()
		local elapsed = os.clock() - start
		if elapsed >= duration then
			RunService:UnbindFromRenderStep(self.RenderName.."_Shake")
		else
			local scaledMagnitude = magnitude / 100
			local noiseX = math.noise(os.clock() * frequency + offsetX, 0, 0)
			local noiseY = math.noise(0, os.clock() * frequency + offsetY, 0)
			local noiseZ = math.noise(0, 0, os.clock() * frequency + offsetZ)
			local oscillationY = 0

			if upDown then
				oscillationY = math.sin(elapsed * frequency) * magnitude
			end

			local rotation = Vector3.new(noiseX, noiseY, noiseZ) * scaledMagnitude
			local perlinRotation = Vector3.new(math.noise(noiseX + offsetX, 0, 0), math.noise(0, noiseY + offsetY + oscillationY, 0), math.noise(0, 0, noiseZ + offsetZ)) / 110
			rotation = rotation + perlinRotation
			cam.CFrame = cam.CFrame * CFrame.Angles(rotation.X, rotation.Y, rotation.Z)
		end
	end)
end

function camera:StopShake()
	RunService:UnbindFromRenderStep(self.RenderName.."_Shake")
	workspace.CurrentCamera.CFrame = workspace.CurrentCamera.CFrame
	self.isShaking = false
end

function camera:__init__()
	hideCameraCutscenePoints()

	local cam = workspace.CurrentCamera
	RunService.RenderStepped:Connect(function(deltaTime)
		if not self.Locked then
			self:TweenFOVTo(self:SumOfFOV())
		end
		if self.Locked then
			self:TweenFOVTo(self.LockedFOV)
		end
	end)
	local BaseFOV = FOVModifier.new('Base', 70)
	BaseFOV:Bind()
	self:Unlock()
end

function camera:__start__()
	Players.LocalPlayer.CameraMaxZoomDistance = 0
	self:StopShake()
end

return camera
