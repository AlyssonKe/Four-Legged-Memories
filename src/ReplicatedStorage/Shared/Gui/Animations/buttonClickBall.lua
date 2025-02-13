--// Services
local Debris = game:GetService("Debris")
local Players = game:GetService("Players")

--// Variables
local localPlayer = Players.LocalPlayer

local playerMouse = localPlayer:GetMouse()

--// Modules
local Tween = require(script.Parent.Parent.Parent.Tween)

local CIRCLE_IMAGE = "rbxassetid://11516513250"

return function(button: GuiObject, properties: table)
	if not button then
		return
	end

	properties = properties or {}

	playerMouse = localPlayer:GetMouse()

	local circle = Instance.new("ImageLabel")
	circle.Name = "Ball"
	circle.AnchorPoint = Vector2.new(0.5, 0.5)
	circle.BackgroundTransparency = 1
	circle.Position =
		UDim2.fromOffset(playerMouse.X - button.AbsolutePosition.X, playerMouse.Y - button.AbsolutePosition.Y)
	circle.Size = UDim2.fromScale(0, 0)
	circle.SizeConstraint = Enum.SizeConstraint.RelativeYY
	circle.ZIndex = 20
	circle.Image = CIRCLE_IMAGE
	circle.ImageColor3 = properties.Color or Color3.fromRGB(255, 255, 255)
	circle.Parent = button

	Debris:AddItem(circle, 0.5)

	Tween.new(
		circle,
		TweenInfo.new(0.25, Enum.EasingStyle.Sine, Enum.EasingDirection.Out),
		{ Size = properties.Size or UDim2.fromScale(1, 1) }
	)
	task.wait(0.05)
	Tween.new(circle, TweenInfo.new(0.2, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), { ImageTransparency = 1 })
end
