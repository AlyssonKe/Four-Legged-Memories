--// Services
local Lighting = game:GetService("Lighting")

--// Variables
local menuBlur = Lighting:WaitForChild("MenuBlur")

--// Modules
local Tween = require(script.Parent.Parent.Parent.Tween)

return function(active: boolean, properties: table)
	if active then
		Tween.new(
			menuBlur,
			TweenInfo.new(0.25, Enum.EasingStyle.Sine, Enum.EasingDirection.Out),
			{ Size = properties and properties.Size or 25 }
		)
	else
		Tween.new(menuBlur, TweenInfo.new(0.25, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), { Size = 0 })
	end
end
