--// Services
local Players = game:GetService("Players")

--// Variables
local localPlayer = Players.LocalPlayer
local playerGui = localPlayer:WaitForChild("PlayerGui")

-- Load player guis
for _, gui in script.ScreenGuis:GetChildren() do
	if gui:IsA("ScreenGui") then
		gui.Parent = playerGui
	end
end

local loadedModules = {}
local function loadModules(folder: Folder)
	for _, module in folder:GetDescendants() do
		if module:IsA("ModuleScript") then
			loadedModules[module.Name] = require(module)
		end
	end
end

loadModules(script:WaitForChild("Controllers"))

for _, controller in loadedModules do
	if typeof(controller) == "table" and controller.start then
		print(_, loadedModules)
		--task.spawn(function()
		controller:start()
		--end)
	end
end

-- print("Client loaded!")
-- Remotes.Player.clientLoaded:send()

-- Game analytics
-- local GameAnalytics = require(ReplicatedStorage:WaitForChild("GameAnalytics"))
-- GameAnalytics:initClient()

return false
