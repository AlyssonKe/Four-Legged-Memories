--// Services
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--// Variables
local packages = ReplicatedStorage.Packages

--// Modules
local Trove = require(packages.Trove)
local Signal = require(packages.Signal)

local Module = {
	sliders = {},
}
Module.__index = Module

function Module.new(button, mainFrame, min, max, decimal, multiply, realTime)
	if not button or not mainFrame then
		warn("Button or frame doesn't exist.")
		return
	end

	-- If the slider already exists it will it destroy to update another one
	if Module.sliders[mainFrame] then
		Module.sliders[mainFrame]:destroy()
	end

	local self = setmetatable({}, Module)
	self.button = button
	self.mainFrame = mainFrame
	self.value = 0
	self.min = min or 0
	self.max = max or 1

	self._decimal = decimal -- Amount of numbers after the ","
	self._realTime = realTime -- If will update in real time
	self._multiply = multiply -- multiply the value by a number. e.g. if the value is 3 and the multiply is 2 the value will be 6
	self._dragging = false
	self._trove = Trove.new()
	self._movement = nil

	self.changed = Signal.new()
	self.ended = Signal.new()

	self:release()

	Module.sliders[mainFrame] = self

	return self
end

function Module:update(percent)
	local oldValue = self.value
	local newValue = self.min + ((self.max - self.min) * percent)

	if self._decimal then
		newValue = tonumber(string.format("%." .. (self._decimal or 0) .. "f", newValue))
	else
		newValue = math.floor((newValue + 0.5) * (self._multiply or 1))
	end

	self.value = newValue

	local valueText = self.mainFrame.Parent:FindFirstChild("Value")
	if valueText and valueText:IsA("TextLabel") then
		valueText.Text = newValue
	end

	if self.value ~= oldValue and self._realTime then
		self.changed:Fire(newValue)
	end
end

function Module:set(value)
	local button = self.button
	local bar = self.mainFrame:FindFirstChild("Bar")

	if not bar then
		return
	end

	value = math.clamp(value, self.min, self.max)
	self.value = value

	local percent = (value - self.min) / (self.max - self.min)
	self:update(percent)
	self.changed:Fire(value)

	button.Position = UDim2.fromScale(percent, 0.5)
	local colorGradient = bar:FindFirstChild("Color") and bar.Color:FindFirstChild("UIGradient")
	if colorGradient then
		colorGradient.Offset = Vector2.new(percent, 0)
	end
end

function Module:release()
	local button = self.button
	local selectedBall = button:FindFirstChild("SelectedBall")
	local bar = self.mainFrame:FindFirstChild("Bar")
	local barSize = bar and bar.AbsoluteSize

	if not bar then
		return
	end

	-- Update bar size if frame size increases
	bar:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
		barSize = bar.AbsoluteSize
	end)

	-- Movement function
	local function Movement()
		if self._movement then
			self._trove:Remove(self._movement)
		end

		self._movement = self._trove:Add(
			UserInputService.InputChanged:Connect(function(Input)
				if self._dragging then
					local value

					if Input.KeyCode == Enum.KeyCode.Thumbstick1 then
						local movement = Input.Position.X
						if math.abs(movement) > 0.25 then
							value = button.Position.X.Scale + (movement > 0 and 0.01 or -0.01)
						end
					elseif
						Input.UserInputType == Enum.UserInputType.MouseMovement
						or Input.UserInputType == Enum.UserInputType.Touch
					then
						local BarPosition = bar.AbsolutePosition
						local MousePosition = Input.Position
						local difference_mouse = MousePosition.X - BarPosition.X
						value = difference_mouse / barSize.X
					end

					if value then
						value = math.clamp(value, 0, 1)
						button.Position = UDim2.fromScale(value, 0.5)
						local colorGradient = bar:FindFirstChild("Color") and bar.Color:FindFirstChild("UIGradient")
						if colorGradient then
							colorGradient.Offset = Vector2.new(value, 0)
						end

						self:update(value)
					end
				end
			end),
			"Disconnect"
		)
	end

	-- CONNECTION
	-- Input (Mobile and Mouse)
	self._trove:Add(bar.InputBegan:Connect(function(Input)
		if
			Input.UserInputType == Enum.UserInputType.MouseButton1
			or Input.UserInputType == Enum.UserInputType.Touch
		then
			self._dragging = true
			if selectedBall then
				selectedBall.Visible = true
			end

			Movement()
		end
	end))
	self._trove:Add(button.InputBegan:Connect(function(Input)
		if
			Input.UserInputType == Enum.UserInputType.MouseButton1
			or Input.UserInputType == Enum.UserInputType.Touch
		then
			self._dragging = true
			if selectedBall then
				selectedBall.Visible = true
			end

			Movement()
		end
	end))
	self._trove:Add(UserInputService.InputEnded:Connect(function(Input)
		if
			Input.UserInputType == Enum.UserInputType.MouseButton1
			or Input.UserInputType == Enum.UserInputType.Touch
		then
			if self._dragging then
				self.changed:Fire(self.value, true) -- Set Data
			end
			self._dragging = nil
			if selectedBall then
				selectedBall.Visible = false
			end

			if self._movement then
				self._trove:Remove(self._movement)
			end
		end
	end))

	-- Selection Gained (Gamepad)
	self._trove:Add(button.SelectionGained:Connect(function()
		self._dragging = true
		if selectedBall then
			selectedBall.Visible = true
		end

		Movement()
	end))
	self._trove:Add(button.SelectionLost:Connect(function()
		if self._dragging then
			self.changed:Fire(self.value, true)
		end

		self._dragging = nil
		if selectedBall then
			selectedBall.Visible = false
		end

		if self._movement then
			self._trove:Remove(self._movement)
		end
	end))
end

function Module:destroy()
	if Module.sliders[self.mainFrame] then
		Module.sliders[self.mainFrame] = nil
	end

	self._trove:Destroy()
	setmetatable(self, nil)
	table.clear(self)
end

return Module
