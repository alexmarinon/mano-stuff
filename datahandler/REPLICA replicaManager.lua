local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Jupiter = require(ReplicatedStorage.Packages.Jupiter)
local ReplicaController = require(ReplicatedStorage.Packages.ReplicaController)
local callbacks = nil

local replicas = Jupiter.CreateController({
	Name = 'replicas'
})

function replicas:__init__()
	
end

function replicas:__start__()
	callbacks = require(script.callbacks)
	ReplicaController.ReplicaOfClassCreated('DataToken'..Players.LocalPlayer.UserId, function(replica)
		for path, _ in pairs(callbacks) do
			replica:ListenToChange({path}, function(newValue)
				callbacks[path](replica, newValue)
			end)
		end
	end)
	ReplicaController.RequestData()
end

return replicas

-- REPLICA EXAMPLE

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local callbacks = {}

local Jupiter = require(ReplicatedStorage.Packages.Jupiter)

local cachesController = Jupiter.GetController('caches')
local playerDataCache = cachesController:getCache('playerData')

callbacks.Currency = function(replica, newValue)
	playerDataCache:dispatch({
		type = 'SET_PROFILE_KEY',
		key = 'Currency',
		value = newValue
	})
end

return callbacks
