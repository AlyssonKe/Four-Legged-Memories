--// Services
local Players = game:GetService("Players")

local Character = {}
function Character.onCharacterAdded(character: Model)
	print(character)
	local player: Player = character and Players:GetPlayerFromCharacter(character)
	if not player then
		return
	end
end

return Character
