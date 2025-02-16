--// Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--// Variables
local Shared = ReplicatedStorage.Shared

--// Modules
local Character = require(script.Character)
local Utils = require(Shared.Utils)

local Player = {}

function Player.onPlayerAdded(player: Player)
	print("ENTROU O PLAYER")
	-- Character
	Utils.onCharacterAdded(player, function(character)
		print(character)
		if Utils.waitForCharacterLoad(character) then
			print("CHARACTER")
			Character.onCharacterAdded(character)
		end
	end)
end

function Player.onPlayerRemoving(player: Player)
	print("Saiu")
end

function Player:start()
	Utils.onPlayerAdded(function(player: Player)
		self.onPlayerAdded(player)
	end)

	Players.PlayerRemoving:Connect(function(player: Player)
		self.onPlayerRemoving(player)
	end)
end

return Player
