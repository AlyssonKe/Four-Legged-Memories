--// Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--// Variables
local localPlayer = Players.LocalPlayer
local Shared = ReplicatedStorage.Shared

--// Modules
local Character = require(script.Character)
local Utils = require(Shared.Utils)

local PlayerController = {}

function PlayerController:start()
	-- Character
	Utils.onCharacterAdded(localPlayer, function(character)
		Utils.waitForCharacterLoad(character)
		Character.onCharacterAdded(character)
	end)
end

return PlayerController
