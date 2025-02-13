--// Services
local Players = game:GetService("Players")
local ProximityPromptService = game:GetService("ProximityPromptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

--// Variables
local shared = ReplicatedStorage.Shared
local packages = ReplicatedStorage.Packages

local guiAssets = ReplicatedStorage.GuiAssets
local localPlayer = Players.LocalPlayer
local playerGui = localPlayer:WaitForChild("PlayerGui")

local ProximityPromptsScreenGui = playerGui:WaitForChild("ProximityPrompts")

--// Modules
local Promise = require(packages:WaitForChild("Promise"))
local Trove = require(packages:WaitForChild("Trove"))
local Tween = require(shared.Tween)

local Module = {}
Module.__index = Module

-- Keys Icons
local gamepadButtonImage = {
	[Enum.KeyCode.ButtonX] = "rbxasset://textures/ui/Controls/xboxX.png",
	[Enum.KeyCode.ButtonY] = "rbxasset://textures/ui/Controls/xboxY.png",
	[Enum.KeyCode.ButtonA] = "rbxasset://textures/ui/Controls/xboxA.png",
	[Enum.KeyCode.ButtonB] = "rbxasset://textures/ui/Controls/xboxB.png",
	[Enum.KeyCode.DPadLeft] = "rbxasset://textures/ui/Controls/dpadLeft.png",
	[Enum.KeyCode.DPadRight] = "rbxasset://textures/ui/Controls/dpadRight.png",
	[Enum.KeyCode.DPadUp] = "rbxasset://textures/ui/Controls/dpadUp.png",
	[Enum.KeyCode.DPadDown] = "rbxasset://textures/ui/Controls/dpadDown.png",
	[Enum.KeyCode.ButtonSelect] = "rbxasset://textures/ui/Controls/xboxmenu.png",
	[Enum.KeyCode.ButtonL1] = "rbxasset://textures/ui/Controls/xboxLS.png",
	[Enum.KeyCode.ButtonR1] = "rbxasset://textures/ui/Controls/xboxRS.png",
}

local keyboardButtonImage = {
	[Enum.KeyCode.Backspace] = "rbxasset://textures/ui/Controls/backspace.png",
	[Enum.KeyCode.Return] = "rbxasset://textures/ui/Controls/return.png",
	[Enum.KeyCode.LeftShift] = "rbxasset://textures/ui/Controls/shift.png",
	[Enum.KeyCode.RightShift] = "rbxasset://textures/ui/Controls/shift.png",
	[Enum.KeyCode.Tab] = "rbxasset://textures/ui/Controls/tab.png",
}

local othersButtonImage = {
	["TouchTap"] = "rbxasset://textures/ui/Controls/TouchTapIcon.png",
}

local keyboardButtonIconMapping = {
	["'"] = "rbxasset://textures/ui/Controls/apostrophe.png",
	[","] = "rbxasset://textures/ui/Controls/comma.png",
	["`"] = "rbxasset://textures/ui/Controls/graveaccent.png",
	["."] = "rbxasset://textures/ui/Controls/period.png",
}

local keyCodeToTextMapping = {
	[Enum.KeyCode.LeftControl] = "Ctrl",
	[Enum.KeyCode.RightControl] = "Ctrl",
	[Enum.KeyCode.LeftAlt] = "Alt",
	[Enum.KeyCode.RightAlt] = "Alt",
	[Enum.KeyCode.F1] = "F1",
	[Enum.KeyCode.F2] = "F2",
	[Enum.KeyCode.F3] = "F3",
	[Enum.KeyCode.F4] = "F4",
	[Enum.KeyCode.F5] = "F5",
	[Enum.KeyCode.F6] = "F6",
	[Enum.KeyCode.F7] = "F7",
	[Enum.KeyCode.F8] = "F8",
	[Enum.KeyCode.F9] = "F9",
	[Enum.KeyCode.F10] = "F10",
	[Enum.KeyCode.F11] = "F11",
	[Enum.KeyCode.F12] = "F12",
}

function Module.toggleProximityPrompts(enabled)
	if ProximityPromptsScreenGui then
		ProximityPromptsScreenGui.Enabled = enabled
		ProximityPromptService.Enabled = enabled
	end
end

function Module:newPrompt(prompt: ProximityPrompt, inputType, gui)
	local selfPrompt = setmetatable({
		_trove = Trove.new(),
	}, self)

	local promptBillBoard = guiAssets.PromptTemplate:Clone()
	selfPrompt._trove:Add(promptBillBoard)

	local buttonFrame = promptBillBoard.ButtonFrame
	local main = buttonFrame.Main
	local keyIcon = main.KeyIcon
	local keyText = main.KeyText
	local progressBar = main.Progress
	local info = buttonFrame.Info
	local actionText = info.ActionText
	local objectText = info.ObjectText

	progressBar.UIGradient.Offset = Vector2.new(0, 1)
	local holdTween = selfPrompt._trove:Add(
		Tween.new(
			progressBar.UIGradient,
			TweenInfo.new(prompt.HoldDuration, Enum.EasingStyle.Linear),
			{ Offset = Vector2.new(0, 0) },
			false
		)
	)

	local function updatePrompt()
		actionText.Text = prompt.ActionText
		objectText.Text = prompt.ObjectText

		-- Disable if doesn't have text
		if prompt.ActionText == "" then
			actionText.Visible = false
		end
		if prompt.ObjectText == "" then
			objectText.Visible = false
		end
		if prompt.HoldDuration <= 0 then
			progressBar.Visible = false
		end

		keyText.Text = ""
		keyIcon.Image = ""
		keyIcon.Visible = false

		main.Size = UDim2.fromScale(1, 1)

		--// Set input icon
		if inputType == Enum.ProximityPromptInputType.Gamepad then
			if gamepadButtonImage[prompt.GamepadKeyCode] then
				keyIcon.Image = gamepadButtonImage[prompt.GamepadKeyCode]
				keyIcon.Visible = true
			end
		elseif inputType == Enum.ProximityPromptInputType.Touch then
			keyIcon.Image = othersButtonImage["TouchTap"]
			keyIcon.Visible = true
		else
			local buttonTextString = UserInputService:GetStringForKeyCode(prompt.KeyboardKeyCode)

			local buttonTextImage = keyboardButtonImage[prompt.KeyboardKeyCode]
			if not buttonTextImage then
				buttonTextImage = keyboardButtonIconMapping[buttonTextString]
			end

			if not buttonTextImage then
				local keyCodeMappedText = keyCodeToTextMapping[prompt.KeyboardKeyCode]
				if prompt.KeyboardKeyCode == Enum.KeyCode.Space then
					buttonTextString = "SPACE"
				elseif keyCodeMappedText then
					buttonTextString = keyCodeMappedText
				end
			end

			if buttonTextImage then
				keyIcon.Image = buttonTextImage
				keyIcon.Visible = true
			elseif buttonTextString ~= nil and buttonTextString ~= "" then
				keyText.Text = buttonTextString
				keyIcon.Visible = false
			else
				main.Visible = false
				error(
					"ProximityPrompt '"
						.. prompt.Name
						.. "' has an unsupported keycode for rendering UI: "
						.. tostring(prompt.KeyboardKeyCode)
				)
			end
		end
	end
	updatePrompt()
	-- Update when prompt change some property
	selfPrompt._trove:Add(prompt.Changed:Connect(function()
		updatePrompt()
	end))

	local lastInputType = Enum.UserInputType.Keyboard
	selfPrompt._trove:Add(UserInputService.InputChanged:Connect(function(input, _gameProcessed)
		if
			(
				input.UserInputType == Enum.UserInputType.Keyboard
				or input.UserInputType == Enum.UserInputType.Touch
				or input.UserInputType == Enum.UserInputType.Gamepad1
			) and lastInputType ~= input.UserInputType
		then
			lastInputType = input.UserInputType
			updatePrompt()
		end
	end))

	if inputType == Enum.ProximityPromptInputType.Touch or prompt.ClickablePrompt then
		local buttonDown = false

		-- Input Began
		buttonFrame.InputBegan:Connect(function(input)
			if
				(
					input.UserInputType == Enum.UserInputType.MouseButton1
					or input.UserInputType == Enum.UserInputType.Touch
				) and input.UserInputState ~= Enum.UserInputState.Change
			then
				prompt:InputHoldBegin()
				buttonDown = true
			end
		end)

		-- Input End
		buttonFrame.InputEnded:Connect(function(input)
			if
				input.UserInputType == Enum.UserInputType.MouseButton1
				or input.UserInputType == Enum.UserInputType.Touch
			then
				if buttonDown then
					buttonDown = false
					prompt:InputHoldEnd()
				end
			end
		end)

		promptBillBoard.Active = true
	end

	local function scaleButtonHold()
		return Promise.new(function(resolve, _reject, onCancel)
			local tween = Tween.new(
				buttonFrame.UIScale,
				TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
				{ Scale = 1.15 }
			)

			if onCancel(function()
				tween:Cancel()
				buttonFrame.UIScale.Scale = 1
			end) then
				return
			end

			Promise.delay(0.2):andThen(resolve)
		end)
	end

	-- Connections
	local holdBeganButton
	selfPrompt._trove:Add(prompt.PromptButtonHoldBegan:Connect(function()
		progressBar.Visible = true
		holdTween:Play()

		holdBeganButton = scaleButtonHold():andThen(function()
			holdBeganButton = nil
		end)
	end))

	selfPrompt._trove:Add(prompt.PromptButtonHoldEnded:Connect(function()
		progressBar.Visible = false
		holdTween:Cancel()
		progressBar.UIGradient.Offset = Vector2.new(0, 1)

		if holdBeganButton then
			holdBeganButton:cancel()
		end

		buttonFrame.UIScale.Scale = 1
	end))

	local function hideButtonPromise()
		return Promise.new(function(resolve, _reject, onCancel)
			local tween = Tween.new(
				buttonFrame.UIScale,
				TweenInfo.new(0.2, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
				{ Scale = 0 }
			)

			if onCancel(function()
				tween:Cancel()
			end) then
				return
			end

			Promise.delay(0.2):andThen(resolve)
		end)
	end

	local hideButton
	-- triggered/ended
	selfPrompt._trove:Add(prompt.Triggered:Connect(function()
		hideButton = hideButtonPromise():andThen(function()
			hideButton = nil
			buttonFrame.Visible = false
		end)
	end))

	selfPrompt._trove:Add(prompt.TriggerEnded:Connect(function()
		if hideButton then
			hideButton:cancel()
		end

		buttonFrame.UIScale.Scale = 1
		buttonFrame.Visible = true
	end))

	promptBillBoard.Adornee = prompt.Parent
	promptBillBoard.Parent = gui

	-- Highlight
	local highlight = Instance.new("Highlight")
	highlight.Name = "ObjectStroke"
	highlight.DepthMode = Enum.HighlightDepthMode.Occluded
	highlight.FillColor = Color3.fromRGB(255, 255, 255)
	highlight.FillTransparency = 10
	highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
	highlight.OutlineTransparency = 0.1
	highlight.Parent = prompt.Parent
	selfPrompt._trove:Add(highlight)

	return selfPrompt
end

function Module:destroy()
	self._trove:Destroy()
	setmetatable(self, nil)
	table.clear(self)
end

ProximityPromptService.PromptShown:Connect(function(prompt, inputType)
	if prompt.Style == Enum.ProximityPromptStyle.Default then
		return
	end

	local newPrompt = Module:newPrompt(prompt, inputType, ProximityPromptsScreenGui)
	prompt.PromptHidden:Wait()
	newPrompt:destroy()
end)

return Module
