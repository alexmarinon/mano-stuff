local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local objects = {}
local progressBar = require(script.Parent.progressBar)

local Player = Players.LocalPlayer
local PlayerGui = Player.PlayerGui

local SelectedObject = PlayerGui:WaitForChild('SelectedObject')
local OBJECT_NAME = SelectedObject.CanvasGroup.ObjectName
local ACTION_TEXT = SelectedObject.CanvasGroup.ActionName

local mouse = Player:GetMouse()
local executor = require(script.Parent.executor)

local currentTarget = nil
local highlight = nil

local function createHighlight()
    highlight = Instance.new('Highlight')
    highlight.FillTransparency = 1
    highlight.OutlineColor = Color3.new(255, 255, 255)
    highlight.Parent = nil
    return highlight
end

createHighlight()

local highlightTweenIn = TweenService:Create(highlight, TweenInfo.new(0.25, Enum.EasingStyle.Linear, Enum.EasingDirection.Out), { OutlineTransparency = 0.5 })
local displayUiTweenIn = TweenService:Create(SelectedObject.CanvasGroup, TweenInfo.new(0.25, Enum.EasingStyle.Linear, Enum.EasingDirection.Out),
    {GroupTransparency = 0}
)
local displayUiTweenOut = TweenService:Create(SelectedObject.CanvasGroup, TweenInfo.new(0.25, Enum.EasingStyle.Linear, Enum.EasingDirection.Out),
    {GroupTransparency = 1}
)

local function clearHighlight()
    if currentTarget then
        currentTarget = nil
    end
    highlight.Parent = nil
    displayUiTweenOut:Play()
end

local function addHighlight()
    print(currentTarget)
    local HighlightAdornee = currentTarget:FindFirstChild('HighlightAdornee').Value

    if not highlight or highlight == nil then
        createHighlight()
    end
    
    highlight.OutlineTransparency = 1
    highlight.Parent = HighlightAdornee
    highlightTweenIn:Play()

    local objectName, actionName = executor:getActionInfo(currentTarget.InteractionType.Value)
    OBJECT_NAME.Text = objectName
    ACTION_TEXT.Text = actionName
    displayUiTweenIn:Play()
end

function objects:__init__()
    progressBar:stopProcess()
end

function objects:__start__()
    local isMouseDown = false
    local mouseDownThread = nil
    local componentInfo = nil
    local onHoldBeganThread = nil

    mouse.Move:Connect(function()
        local target = mouse.Target
        if not CollectionService:HasTag(target, 'Interactable') then
            clearHighlight()
            return
        end

        local targetInfo = executor:getExecutionComponent(target.InteractionType.Value)

        if type(targetInfo.canShow) == 'function' then
            if targetInfo:canShow() == false then
                return
            end
        end

        local distance = (Players.LocalPlayer.Character.HumanoidRootPart.Position - target.Position).Magnitude
        if distance > targetInfo.MaxDistance then
            -- The player is too far from the object.
            return
        end

        if target and target:IsA("BasePart") and CollectionService:HasTag(target, "Interactable") then
            if currentTarget ~= target then
                clearHighlight()
                currentTarget = target
                addHighlight()
            end
        else
            clearHighlight()
        end
    end)

    UserInputService.InputBegan:Connect(function(input, gameProcessedEvent)
        if input.UserInputType  == Enum.UserInputType.MouseButton1 then
            local holdDownStart = tick()
            local inputEnded = nil
    
            local cacheTarget = currentTarget

            if cacheTarget == nil then return end
            if Players.LocalPlayer.Character == nil then return end
            
            componentInfo = executor:getExecutionComponent(cacheTarget.InteractionType.Value)

            if type(componentInfo.canShow) == 'function' then
                if componentInfo:canShow() == false then
                    return
                end
            end

            local distance = (Players.LocalPlayer.Character.HumanoidRootPart.Position - cacheTarget.Position).Magnitude
            if distance > componentInfo.MaxDistance then
                -- The player is too far from the object.
                return
            end

            inputEnded = UserInputService.InputEnded:Connect(function(input, gameProcessedEvent)
                if input.UserInputType == Enum.UserInputType.MouseButton1 and mouseDownThread then
                    progressBar:stopProcess()
                    task.cancel(mouseDownThread)
                    task.cancel(onHoldBeganThread)
                    if cacheTarget then
                        local distance = (Players.LocalPlayer.Character.HumanoidRootPart.Position - cacheTarget.Position).Magnitude
                        if distance > componentInfo.MaxDistance then
                            -- The player is too far from the object.
                            return
                        end
                        componentInfo:holdEnded(cacheTarget)  -- Pass cacheTarget instead of currentTarget
                        componentInfo = nil
                        mouseDownThread = nil
                    end
                    inputEnded:Disconnect()
                end
            end)
            
            if currentTarget == nil then
                return
            end
    
            componentInfo = executor:getExecutionComponent(cacheTarget.InteractionType.Value)
            progressBar:beginProgress(componentInfo.Duration, 1)
    
            mouseDownThread = task.spawn(function()
                onHoldBeganThread = task.spawn(function()
                    componentInfo:holdBegan(cacheTarget)
                end)
    
                task.wait(componentInfo.Duration)
                local holdDownDuration = tick() - holdDownStart
                if holdDownDuration >= 1 and cacheTarget then  -- Check if the button is still being held down
                    print(cacheTarget)
                    highlight.Parent = nil
                    
                    local distance = (Players.LocalPlayer.Character.HumanoidRootPart.Position - cacheTarget.Position).Magnitude
                    if distance > componentInfo.MaxDistance then
                        -- The player is too far from the object.
                        return
                    end
    
                    executor:commitObjectInteraction(cacheTarget)
                    task.cancel(onHoldBeganThread)
                    inputEnded:Disconnect()
                end
                progressBar:stopProcess()
            end)
        end
    end)
    
    
end

return objects
