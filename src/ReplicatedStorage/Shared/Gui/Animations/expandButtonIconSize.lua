--// Modules
local Tween = require(script.Parent.Parent.Parent.Tween)

type Properties = {
	duration: number,
	size: number,
}

return function(button: GuiObject, isHovering, properties: Properties)
	local icon = button and button:FindFirstChild("Icon", true)
	if not icon then
		return
	end

	properties = properties or {}

	local uiScale = icon:FindFirstChild("UIScale")
	if not uiScale then
		uiScale = Instance.new("UIScale")
		uiScale.Parent = icon
		uiScale.Scale = 1
	end
	if isHovering then
		Tween.new(uiScale, TweenInfo.new(properties.duration or 0.1, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {
			Scale = 1 + (properties.Size or 0.1),
		})
	else
		Tween.new(
			uiScale,
			TweenInfo.new(properties.duration or 0.1, Enum.EasingStyle.Sine, Enum.EasingDirection.Out),
			{ Scale = 1 }
		)
	end
end
