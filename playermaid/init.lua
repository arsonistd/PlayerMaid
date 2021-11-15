-- PlayerMaid.lua
-- ArsonistD
-- Started : 11/14/2021
-- Last Edit : 11/14/2021

local Players = game:GetService("Players")

--[=[
    @class PlayerMaid

    Another garbage collection library that wraps around PlayerAdded and PlayerRemoving.
]=]
local PlayerMaid = {}
PlayerMaid.__index = PlayerMaid


--[=[
    Creates a PlayerMaid object.

    PlayerMaid.new() -> ()
]=]
function PlayerMaid.new()
    local self = setmetatable({}, PlayerMaid)

    self._players = {}

    self._playerAddedConnection = Players.PlayerAdded:Connect(function(player)
        self._players[player.UserId] = {}
    end)
    self._playerRemovingConnection = Players.PlayerRemoving:Connect(function(player)
        self:_cleanPlayer(player.UserId)
    end)

    return self
end


--[=[
    Indexes object in player's objects that will be cleaned

    PlayerMaid:Add(player: player, obj: any) -> ()
]=]
function PlayerMaid:


--[=[
    Cleans up all the objects on every player, will also disconnect all player adding/removing signals.

    PlayerMaid:Destroy() -> ()
]=]
function PlayerMaid:Destroy()
    self._playerAddedConnection:Disconnect()
    self._playerRemovingConnection:Disconnect()

    self:Clean()

    self._players = {}
end


--[=[
    Cleans up all the objects on every player, Does not disconnect player adding/removing signals.

    PlayerMaid:Clean() -> ()
]=]
function PlayerMaid:Clean()
    -- Cleanup every player
    for userId, playerObjs in pairs(self._players) do
        self:CleanPlayer(userId)
    end
end


--[=[
    Cleans up all the objects on specified player.

    PlayerMaid:Clean(userId: number) -> ()
]=]
function PlayerMaid:CleanPlayer(userId)
    local playerObjs = self._players[userId]


    -- Clean connections
    for _, obj in pairs(playerObjs) do
        if typeof(obj) == "RBXScriptConnection" then
            obj:Disconnect()
            playerObjs[_] = nil
        end
    end

    -- Fire functions that are indexed
    for _, obj in pairs(playerObjs) do
        if type(obj) == "function" then -- If object is a function then call it
            obj()
            playerObjs[_] = nil
        end
    end

    -- Destroy objs that are indexed
    for _, obj in pairs(playerObjs) do
        if obj.Destroy then -- If obj has a destroy method then Destroy()
            task:Destroy()
            playerObjs[_] = nil
        end
    end

    self._players[userId] = {}
end

return PlayerMaid
