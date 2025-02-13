--// Services
local TweenService = game:GetService("TweenService")

return function(oldValue: number, goalValue: number, properties: table)
	properties = properties or {}

	local numberValue = Instance.new("NumberValue")
	numberValue.Value = oldValue or 0

	local tween = TweenService:Create(
		numberValue,
		TweenInfo.new(
			properties.duration or 1,
			properties.easingStyle or Enum.EasingStyle.Sine,
			properties.easingDirection or Enum.EasingDirection.Out
		),
		{ Value = goalValue }
	)
	tween:Play()

	tween.Completed:Connect(function()
		numberValue:Destroy()
		tween:Destroy()
	end)

	tween.Destroying:Connect(function()
		numberValue:Destroy()
	end)

	return numberValue
end
