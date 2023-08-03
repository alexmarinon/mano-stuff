local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BridgeNet = require(ReplicatedStorage.Packages.BridgeNet)

warn(`Loaded`)

local VoteBridge = {
	Name = "Vote",
	Bridge = BridgeNet.CreateBridge("Vote"),
	Connections = {
		function(...)
			local Args = {...}
			print(Args[1])
		end,
	}
}

return VoteBridge
