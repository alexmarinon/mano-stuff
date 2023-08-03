local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local Player = Players.LocalPlayer

local progressBar = {}

local PROGRESS_BAR_UI = Player.PlayerGui:WaitForChild('SelectedObject')
local ProgressContainer = PROGRESS_BAR_UI.CanvasGroup.ProgressBar
local ProgressIndicator = ProgressContainer.Frame

function progressBar:beginProgress(duration, toDecimal)
    if self.tween then
        self.tween:Cancel()
    end
    self.tween = TweenService:Create(ProgressIndicator,
        TweenInfo.new(duration, Enum.EasingStyle.Linear, Enum.EasingDirection.In),
        {Size = UDim2.new(toDecimal, 0, 1, 0)}
    )
    self.tween:Play()
end

function progressBar:stopProcess()
    if self.tween then
        self.tween:Cancel()
        self.tween:Destroy()
    end
    self.tween = TweenService:Create(ProgressIndicator,
        TweenInfo.new(0.25, Enum.EasingStyle.Sine, Enum.EasingDirection.Out),
        {Size = UDim2.new(0, 0, 1, 0)}
    )
    self.tween:Play()
end

return progressBar
