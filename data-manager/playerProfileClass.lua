local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local ServerStorage = game:GetService("ServerStorage")

local table = require(ReplicatedStorage.Packages.table)
local Signal = require(ReplicatedStorage.Packages.Signal)
local ReplicaService = require(ServerStorage.serverPackages.ReplicaService)

local Profile = {}
Profile.__index = Profile

export type Profile = {
    _profileObject: table,
    _player: Player,
    DataChanged: Signal.Signal,
    Data: table,
    listenToRelease: (callback: () -> (nil)) -> nil,
    getData: (category: table?) -> table,
    release: () -> nil
}

function Profile.new(player: Player, profileObject: table): Profile
    local self = setmetatable({}, Profile)
    self._profileObject = profileObject;
    self._player = player

    self.DataChanged = Signal.new()

    self.Data = {}

    self.Replica = ReplicaService.NewReplica({
        ClassToken = ReplicaService.NewClassToken("DataToken"..player.UserId),
        Data = self._profileObject.Data,
        Replication = self._player
    })

    setmetatable(self.Data, {
        __index = function(_, key)
            return self._profileObject.Data[key]
        end,
        __newindex = function(_, key, value)
            if self._profileObject.Data[key] == nil then
                error("Attempt to set non-existent key '"..key.."' in profile data. You can only edit the top-level domain.")
            end
            self._profileObject.Data[key] = value
            self.Replica:SetValue({key}, self._profileObject.Data[key])
            self.DataChanged:Fire(key, self._profileObject.Data[key])
        end
    })

    return self
end


function Profile:listenToRelease(callback): table
    return self._profileObject:ListenToRelease(callback)
end

function Profile:getData(category: table?): nil
    local data = self._profileObject.Data
    if category then
        return data[category]
    else
        return data
    end
end

function Profile:getDataCopy(category: table?): nil
    return table.clone(self:getData(category))
end

function Profile:release()
    self.Replica:Destroy()
    self.Replica = nil
    return self._profileObject:Release()
end

return Profile
