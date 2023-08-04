--!nonstrict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Jupiter = require(ReplicatedStorage.Packages.Jupiter)

export type Bridge = {
	LinkedBridge: any;
	Connections: {({})->any};
	Start: {(nil) -> nil};
}

type void = nil

local BRIDGE_FOLDER = script.bridges

local remotes = Jupiter.CreateController({
	Name = 'remotes'
})

remotes.Bridges = {}
remotes.BridgeConnections = {}

local function registerBridges()
	for _, bridge in BRIDGE_FOLDER:GetChildren() do
		if not bridge:IsA('ModuleScript') then
			continue
		end
		local loadedBridge = require(bridge)
		remotes.Bridges[loadedBridge.Name] = loadedBridge
		print(`Loaded {loadedBridge.Name}`)
	end
end

local function createConnections()
	for _, bridge: Bridge in remotes.Bridges do
		local linkedBridge = bridge.LinkedBridge
		linkedBridge:Connect(function(...)
			print(`Fired`)
			local Args = {...}
			for _, fn in bridge.Connections do
				task.spawn(function()
					fn(unpack(Args))
				end)
			end
		end)
	end
end

local function runBridgeStartFuncs()
	for _, bridge: Bridge in remotes.Bridges do
		if type(bridge.Start) == 'function' then
			bridge.Start()
		end
	end
end

function remotes:getBridgeByKey(bridgeKey: string): Bridge
	assert(type(bridgeKey) == 'string', `Bridge key must be string got {typeof(bridgeKey)}`)
	assert(#bridgeKey > 0, `Cannot get bridge by empty bridgeKey string`)
	assert(self.Bridges[bridgeKey] ~= nil, `Bridge does not exist`)
	return self.Bridges[bridgeKey]	
end

function remotes:connect(bridgeKey: string, fn: ({any}) -> nil): void
	local bridge: Bridge = self:getBridgeByKey(bridgeKey)
	if bridge ~= nil then
		table.insert(bridge.Connections, fn)
	end
	return nil
end

function remotes:fireServer(bridgeKey: string, ...: any)
	local Args = {...}
	local bridge: Bridge = self:getBridgeByKey(bridgeKey)
	if bridge ~= nil then
		bridge.LinkedBridge:Fire(unpack(Args))
	end
end

function remotes:__init__(): void
	registerBridges()
	return nil
end

function remotes:__start__(): void
	runBridgeStartFuncs()
	createConnections()
	return nil
end

return remotes
