--!nonstrict

local executor = {}

local TYPE_STORE = script

executor.ExecutionTypeCache = {}

type void = nil

export type ExecutionType = {
	Triggered: ({}) -> any;
	TriggerEnd: ({}) -> any;
}

export type ActionType = 'Triggered' | 'TriggerEnded'

local function loadTypesIntoCache()
	for _, typeModule: ModuleScript in TYPE_STORE:GetChildren() do
		if typeModule:IsA('ModuleScript') then
			executor.ExecutionTypeCache[typeModule.Name] = require(typeModule)
		end
	end
end

local function runTypeStartFuncs()
	for _, executionType in executor.ExecutionTypeCache do
		if type(executionType.Start) == 'function' then
			executionType:Start()
		end
	end
end

function executor:getTypeFromKey(typeKey: string): ExecutionType? | void
	assert(type(typeKey) == 'string', `typeKey expected to be string but got {typeof(typeKey)}`)
	assert(#typeKey > 0, `typeKey provided was empty string`)
	
	local executionType = self.ExecutionTypeCache[typeKey]
	if executionType == nil then
		warn(`Attempted to index execution type {typeKey} which does not exist!`)
		return nil
	end
	return executionType
end

function executor:getTypeList(): {ExecutionType} | void
	return nil
end

function executor:execute(typeKey: string, actionType: ActionType, ...): {any}
	print(`Triggered in execute {typeKey} {actionType} {...} `)
	local Arguments = {...}
	local executionType: ExecutionType = self:getTypeFromKey(typeKey)
	local functionResult = nil
	local ok, result = pcall(function()
		print(`Init pcall with {actionType}`)
		if type(executionType[actionType]) == 'function' then
			print('Found print')
			functionResult = executionType[actionType](executionType, unpack(Arguments))
		end
	end)
	if ok then
		return {false}
	else
		return {result}
	end
end

function executor:__init__(): void
	loadTypesIntoCache()
	return nil
end

function executor:__start__(): void
	runTypeStartFuncs()
	return nil
end

return executor
