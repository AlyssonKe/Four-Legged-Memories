local loadedModules = {}
local function loadModules(folder)
	for _, module in folder:GetDescendants() do
		if module:IsA("ModuleScript") then
			print(module)
			loadedModules[module.Name] = require(module)
		end
	end
end

loadModules(script.Parent:WaitForChild("Services"))

for _, controller in loadedModules do
	if typeof(controller) == "table" and controller.start then
		task.spawn(function()
			controller:start()
		end)
	end
end
