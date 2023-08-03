local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Jupiter = require(ReplicatedStorage.Packages.Jupiter)
local BridgeNet = require(ReplicatedStorage.Packages.BridgeNet)

local remotes = Jupiter.CreateController({
	Name = 'remotes'
})

export type Bridge = {
	Name: string;
	Bridge: typeof(BridgeNet.CreateBridge(''));
	Connections: {({}) -> any}
}

remotes.Bridges = {}

local function registerBridges()
	for _, bridge in script.bridges:GetChildren() do
		if bridge:IsA('ModuleScript') then
			local bridge: Bridge = require(bridge)
			remotes.Bridges[bridge.Name] = bridge
			print(`Registered bridge {bridge.Name}`)
		end
	end
end

local function connectAllBridges()
	for _, bridge: Bridge in remotes.Bridges do
		bridge.Bridge:Connect(function(...)
			print(`Request recieved for bridge {bridge.Name}`)
			for _, fn in bridge.Connections do
				fn(...)
			end
		end)
	end
end

function remotes:getBridgeByKey(bridgeKey: string)
	assert(type(bridgeKey) == 'string', `Bridge key is not a string`)
	assert(#bridgeKey > 0, `bridgeKey length must be > 0`)
	assert(self.Bridges[bridgeKey] ~= nil, `Bridge not found!`)
	return self.Bridges[bridgeKey]
end

function remotes:addConnectionToBridge(bridgeKey: string, fn: ({any}) -> any)
	local bridge: Bridge = self:getBridgeByKey(bridgeKey)
	table.insert(bridge.Connections, fn)
end

function remotes:__init__()
	registerBridges()
end

function remotes:__start__()
	connectAllBridges()
end

return remotes
