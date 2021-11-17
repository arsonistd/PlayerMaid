
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

    @function new
    @within PlayerMaid
	@param synax -- Used to other garbage cleaning syntax? Specify which janitor to change method names. (Maid, Janitor, Dumpster)
	@return playerMaid -- The player maid object
]=]
function PlayerMaid.new(syntax)
	local self = setmetatable({}, PlayerMaid)

	self._players = {}
	local players = Players:GetPlayers()
	local index, player = next(players)
	while players do
		self._players[player.UserId] = {}	
		index, player = next(players)
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
	@return objectIndex number -- The index of the object
]=]
function PlayerMaid:Add(player: any, obj: any)
	-- Assert arg 1
	if player == nil then
		error("Argument1 is missing or nil")
	elseif player.Parent ~= game.Players then
		error("Argument1 is not a player in game")
	end
	-- Assert arg 2
	if obj == nil then
		error("Argument 2 is missing or nil")
	elseif type(obj) ~= "function" or typeof(obj) ~= "RBXScriptConnection" or obj.Destroy == nil or type(obj) == "table" then
		error("Argument 2 must be a function, RBXScriptConnection, has a cleanup method or is a table with a destroy method.")
	elseif type(obj) == "table" then
		local function checkIfTableHasCleanupMethod(table)
			for _, cleanupMethod in ipairs({"destroy", "Destroy", "Disconnect"}) do
				if table[cleanupMethod] then
					return true
				end
			end
			return false
		end
		if checkIfTableHasCleanupMethod(obj) ~= true then
			error("If argument 2 is a table it must include a cleanup method (destroy, Destroy, Disconnect)")
		end
	end
		local playerContainer = self._players[player.UserId]
		local objectIndex = #playerContainer+1
		self._players[player.UserId][objectIndex] = obj
	return objectIndex
end



--[=[
	Removes specific index in the player's objects without cleaning.
				
	@function Remove
	@within PlayerMaid
	@param player any -- The player that you you would like to remove the object from.
	@param object any -- The object that will be removed.
]=]--
function PlayerMaid:Remove(player: any, index)
	local playerObjs = self._players[player.UserId]
	playerObjs[index] = nil
end



--[=[
	Cleans specific index in the player's objects.
				
	@function CleanObj
	@within PlayerMaid
	@param player any -- The player that you you would like to clean the object from.
	@param object any -- The object that will be cleaned.
]=]--
function PlayerMaid:CleanObj(player: any, index)
	local playerObjs = self._players[player.UserId]
	local obj = playerObjs[index]
	if obj then
		self:_cleanObj(obj)
		playerObjs[index] = nil
	end
end



--[=[
    Cleans up all the objects on every player, Does not disconnect player adding/removing signals.

    @function Clean
    @within PlayerMaid
]=]
function PlayerMaid:Clean()
	-- Cleanup every player
	local playerContainer = self._players
	local userId, playerObj = next(playerContainer)
	while playerObj do
		self:CleanPlayer(userId)
		userId, playerObj = next(playerContainer)
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

	local objIndex, obj = next(playerObjs)
	while obj do
		self:_cleanObj(obj)
		objIndex, obj = next(playerObjs)
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


-- Private functions
function PlayerMaid:_cleanObj(obj)
	if type(obj) == "RBXScriptConnection" then
		obj:Disconnect()
	elseif type(obj) == "function" then
		obj()
	elseif obj.Destroy then
		obj:Destroy()
	elseif type(obj) == "Table" then
		for _, cleanupMethod in ipairs({"destroy", "Destroy", "Disconnect"}) do
				if table[cleanupMethod] then
					table[cleanupMethod]()
				end
			end
		end
	end
end

return PlayerMaid
