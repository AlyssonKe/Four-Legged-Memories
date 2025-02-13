--// Services
local Players = game:GetService("Players")

--// Variables
local localPlayer = Players.LocalPlayer

local playerGui = localPlayer:WaitForChild("PlayerGui")
local topBar = playerGui:WaitForChild("TopBar")

--// Modules
local changeNumberText = require(script.Parent.changeNumberText)
local Tween = require(script.Parent.Parent.Parent.Tween)

return function(item: string, value: number)
	local topBarItem: GuiObject = topBar and topBar:FindFirstChild(item, true)
	if not topBarItem then
		return
	end

	local valueLenght = string.len(value)
	local textSize = 13

	topBarItem.Size = UDim2.new(0, valueLenght * textSize, 1, 0)
	topBarItem.Amount.TextSize = 25

	Tween.new(topBarItem, TweenInfo.new(0.2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, 0, true), {
		Size = UDim2.new(0, topBarItem.Size.X.Offset + 20, 1.5, 0),
	})

	Tween.new(topBarItem.Amount, TweenInfo.new(0.2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, 0, true), {
		TextSize = 40,
	})

	local oldValue = tonumber(topBarItem.Amount.Text)

	local amountValue = changeNumberText(oldValue, value, { duration = 0.25 })
	topBarItem.Amount.Text = value
	amountValue:GetPropertyChangedSignal("Value"):Connect(function()
		topBarItem.Amount.Text = tostring(math.floor(amountValue.Value))
	end)
	changeNumberText(topBarItem.Amount, value)
end
