local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Jupiter = require(ReplicatedStorage.Packages.Jupiter)

local caches = Jupiter.CreateController({
	Name = 'caches'
})

caches.LoadedCaches = {}

local function loadAllCaches()
	for _, cacheModule: ModuleScript in pairs(script:GetChildren()) do
		if cacheModule:IsA('ModuleScript') then
			caches.LoadedCaches[cacheModule.Name] = require(cacheModule)
		end
	end
end

local function runStartFuncs()
	for _, cache in caches.LoadedCaches do
		if type(cache.__init__) == 'function' then
			cache.__init__()
		end
	end
end

function caches:getCache(cacheKey: string)
	return self.LoadedCaches[cacheKey].Store
end

function caches:__init__()
	loadAllCaches()
end

function caches:__start__()
	runStartFuncs()
end

return caches

-- CACHE EXAMPLE

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Rodux = require(ReplicatedStorage.Packages.Rodux)

local initialState = {}

local reducer = Rodux.createReducer(initialState, {
	SET_PROFILE_KEY = function(state, action)
		local state = table.clone(state)
		state[action.key] = action.value
		print(`SETTING VIA DISPATCH FOR PLAYER_DATA`)
		print(state)
		return state
	end,
})

local store = Rodux.Store.new(reducer)

return {
	Store = store,
	__init__ = function()
		
	end,
}
