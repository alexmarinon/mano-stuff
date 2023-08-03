local executor = {}

local COMPONENTS_STORE = script.Parent.components
local COMPONENT_CACHE = {}

local function loadComponentCache()
    for _, module in COMPONENTS_STORE:GetChildren() do
        COMPONENT_CACHE[module.Name] = require(module)
    end
end

function executor:getExecutionComponent(key: string)
    assert(typeof(key) == "string", "key must be a string")
    assert(COMPONENT_CACHE[key] ~= nil, "key must be a valid component key")
    return COMPONENT_CACHE[key]
end

function executor:getActionInfo(key): {['objectName']: string, ['actionName']: string}
    assert(typeof(key) == "string", "key must be a string")
    assert(COMPONENT_CACHE[key] ~= nil, "key must be a valid component key")
    local component = self:getExecutionComponent(key)
    return component.ObjectName, component.ActionName
end

function executor:commitObjectInteraction(target: Instance)
    assert(typeof(target) == "Instance", "target must be an Instance")
    assert(target:FindFirstChild('InteractionType') ~= nil, "target must have an InteractionType value")

    warn(target)

    local interactionType = target.InteractionType.Value
    local component = self:getExecutionComponent(interactionType)
    component:execute(target)
end

function executor:__init__()
end

function executor:__start__()
    loadComponentCache()
end

return executor
