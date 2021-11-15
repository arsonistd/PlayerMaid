
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


local CleaningMethods = {
	["function"] = function(funct)
		funct()
	end);
	["Instance"] = function(object)
		object:Destroy()
	end);
	["RBXScriptConnection"] = function(connection)
		connection:Disconnect()
	end);
	["table"] = function(table)
		for i,v ipairs({"Destroy", "destroy", "disconnect"}) do
			if table[v] then
				table[v](table)
			end
		end
	end);
}


--[=[
    Creates a PlayerMaid object.

    @function new
    @within PlayerMaid
]=]
function PlayerMaid.new(syntax)
	local self = setmetatable({}, PlayerMaid)

	self._players = {}
	
	for _, player in pairs(Players:GetPlayers()) do
		self._players[player.UserId] = {}
	end

	self._playerAddedConnection = Players.PlayerAdded:Connect(function(player)
		if self.playerAddedCallback then
			self.playerAddedCallback(player)
		end
		self._players[player.UserId] = {}
		print(self._players)
	end)
	
	self._playerRemovingConnection = Players.PlayerRemoving:Connect(function(player)
		self:CleanPlayer(player.UserId)
		self._players[player.UserId] = nil
	end)

	if syntax then
		if string.lower(syntax) == "maid" then
			self.GiveTask = self.Add
			self.DoCleaning = self.Clean
			self.DoCleaningPlayer = self.CleanPlayer
			self.Remove = self.Remove
		elseif string.lower(syntax) == "janitor" then
			self.Add = self.Add
			self.Cleanup = self.Clean
			self.CleanupPlayer = self.CleanPlayer
		elseif string.lower(syntax) == "dumpster" then
			self.dump = self.Add
			self.burn = self.Clean
			self.burnPlayer = self.CleanPlayer
		elseif string.lower(syntax) == "trove" then
			-- syntax is already like trove ¯\_(ツ)_/¯
		end 
	end

	return self
end


--[=[
    Sets a callback function that will be fired when a player joins

    @function setPlayerAddedCallback
    @within PlayerMaid
    @param callback any -- The callback function that you want to fire
]=]
function PlayerMaid:setPlayerAddedCallback(callback)
    self.playerAddedCallback = callback
end


--[=[
    Indexes object in player's objects that will be cleaned

    @function Add
    @within PlayerMaid
    @param player any -- The player that will be in charge of cleaning
    @param object any -- The object that will be cleaned
	@return index number -- The index of the object
]=]
function PlayerMaid:Add(player: any, obj: any)
	assert(player ~= nil, "Argument 1 is missing or nil")
	assert(obj ~= nil, "Argument 2 is missing or nil")

	if obj then
		local playerContainer = self._players[player.UserId]
		local index = #playerContainer+1
		self._players[player.UserId][index] = CleaningMethods[typeof(obj)]
		return index
	end
end


--[=[
	Cleans specific index in the player's 
				
	@function Remove
	@within PlayerMaid
	@param object any -- The object that will be cleaned on all players
]=]--
function PlayerMaid:Remove(player: any, index)
						
end


--[=[
    Cleans up all the objects on every player, Does not disconnect player adding/removing signals.

    @function Clean
    @within PlayerMaid
]=]
function PlayerMaid:Clean()
	-- Cleanup every player
	for userId, playerObjs in pairs(self._players) do
		self:CleanPlayer(userId)
	end
end


--[=[
    Cleans up all the objects on specified player.

    @function CleanPlayer
    @within PlayerMaid
    @param userId number -- The player's UserId that you want to clean.
]=]
function PlayerMaid:CleanPlayer(userId)
	local playerObjs = self._players[userId]

	local object, clean = next(playerObjs)
	while object ~= nil do
		CleaningMethods(object)
		playerObjs[object] = nil
		object, clean = next(playerObjs)
	end

	self._players[userId] = {}
end

--[=[
    Cleans up all the objects on every player, will also disconnect all player adding/removing signals.

    @function Destroy
    @within PlayerMaid
]=]
function PlayerMaid:Destroy()
	self._playerAddedConnection:Disconnect()
	self._playerRemovingConnection:Disconnect()

	self:Clean()

	self._players = {}
end

return PlayerMaid
