local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ContextActionService = game:GetService('ContextActionService')

local Signal = require(ReplicatedStorage.Packages.Signal)
local Knit = require(ReplicatedStorage.Packages.Knit)
local Trove = require(ReplicatedStorage.Packages.Trove)
local table = require(ReplicatedStorage.Packages.table)
local Action = require(ReplicatedStorage.classes.action)
local Promise = require(ReplicatedStorage.Packages.Promise)

local ActionBind = {}
ActionBind.__index = ActionBind

ActionBind.BoundActionStore = nil

local dataController = nil

export type ActionBind = {
    ActionRepo: {Action},
    ActionFired: Signal.Signal,
    ActionAdded: Signal.Signal
}

local function addToActionState()
    
end

function ActionBind.new(): ActionBind
    local self = setmetatable({}, ActionBind)

    self._trove = Trove.new()
    self.ActionRepo = {}
    self.ActionFired = self._trove:Construct(Signal)
    self.ActionAdded = self._trove:Construct(Signal)
    self.ActionRemoved = self._trove:Construct(Signal)

    return self
end

function ActionBind:BindAction(action: Action)
    ContextActionService:BindActionAtPriority(action.Name, function(actionName: string, inputState: Enum.UserInputState, inputObject: InputObject)
        action.Action(actionName, inputState, inputObject)
        action.Fired:Fire()
    end, false, action.Priority, action.Keybind)

    self.BoundActionStore:dispatch({
        type = 'ADD_BIND',
        bind = {
            keybind = action.Keybind,
            name = action.Name,
            priority = action.Priority
        }
    })

    self.ActionAdded:Fire(action)

    return action
end

function ActionBind:UnbindAction(action: Action.Action)
    ContextActionService:UnbindAction(action.Name)
    
    self.BoundActionStore:dispatch({
        type = 'REMOVE_BIND',
        bind = {
            keybind = action.Keybind,
        }
    })

    self.ActionRemoved:Fire(action)
end

function ActionBind:getBoundActions()
    local state = self.BoundActionStore:getState()
    return state
end

function ActionBind:Destroy()
    for _, action in pairs(self.ActionRepo) do
        self:UnbindAction(action.Name)
        action:Destroy()
    end
    self = nil
end

function ActionBind:__start__()
    return Promise.new(function(resolve)
        dataController = Knit.GetController("data")
        self.BoundActionStore = dataController.cacheManager:getCache('boundActions')
        resolve(true)
    end)
end

return ActionBind
