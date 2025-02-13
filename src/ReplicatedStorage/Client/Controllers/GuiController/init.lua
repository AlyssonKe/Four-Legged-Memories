--// Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

--// Variables
local packages = ReplicatedStorage.Packages
local Shared = ReplicatedStorage.Shared

local localPlayer = Players.LocalPlayer
local mouse = localPlayer:GetMouse()
local playerGui: PlayerGui = localPlayer:WaitForChild("PlayerGui")

--// Modules
local MobileGuiRetuning = require(script.MobileGuiRetuning)
local Promise = require(packages.Promise)
local Signal = require(packages.Signal)
local Trove = require(packages.Trove)
local Tween = require(Shared.Tween)
local Utils = require(Shared.Utils)

local GuiController = {
	isGamepad = UserInputService.GamepadEnabled,
	isMobile = UserInputService.TouchEnabled,

	screenGuis = {},
	frames = {},
	inputs = {},

	currentOpenedFrame = nil,
	inMenu = false,

	-- Modules
	Button = require(script.Button),
	Search = require(script.Search),
}
GuiController.__index = GuiController

type frameProperties = {
	openEasingStyle: Enum.EasingStyle?,
	openEasingDirection: Enum.EasingDirection?,
	openDuration: number?,
	closeEasingStyle: Enum.EasingStyle?,
	closeEasingDirection: Enum.EasingDirection?,
	closeDuration: number?,
	keyToClose: Enum?,
	doNotBlur: boolean?,
}
function GuiController.newFrame(frameName: string, frame: Frame, properties: frameProperties)
	if not frame or not frameName then
		return
	end

	if GuiController.frames[frameName] then
		return GuiController.frames[frameName]
	end

	properties = properties or {}

	local self = setmetatable({
		_trove = Trove.new(),
		frame = frame,
		openEasingStyle = properties.openEasingStyle or Enum.EasingStyle.Back,
		openEasingDirection = properties.openEasingDirection or Enum.EasingDirection.Out,
		openDuration = properties.openDuration or 0.3,
		closeEasingStyle = properties.closeEasingStyle or Enum.EasingStyle.Back,
		closeEasingDirection = properties.closeEasingDirection or Enum.EasingDirection.In,
		closeDuration = properties.closeDuration or 0.3,

		keyToClose = properties.keyToClose,

		doNotCloseWhenOpenAnotherFrame = properties.doNotCloseWhenOpenAnotherFrame,

		doNotBlur = properties.doNotBlur or false,
		doNotSoundEffect = properties.doNotSoundEffect or false,

		defaultAbsoluteSize = frame.AbsoluteSize,
		defaultAbsolutePosition = frame.AbsolutePosition,

		onOpen = Signal.new(),
		onClose = Signal.new(),
	}, GuiController)

	if GuiController.isMobile then
		frame.Active = true
	end

	GuiController.frames[frameName] = self

	return self
end

function GuiController:openFrame(nonEvent: boolean)
	-- if self.currentOpenedFrame then
	-- 	self:closeFrame()
	-- end

	if GuiController.currentFrame then
		GuiController.currentFrame:closeFrame(nil, true)
	end

	local uiScale: UIScale = self.frame:FindFirstChild("UIScale")
	if uiScale then
		if not nonEvent then
			self.onOpen:Fire()
		end

		GuiController.currentFrame = self

		--self.currentOpenedFrame = frame
		self.frame.Visible = true

		-- if not self.doNotSoundEffect then
		-- sounds.FrameOpen:Play()
		-- end

		-- if not self.doNotBlur then
		-- GuiController.Animations.screenBlur(true)
		-- end

		self._trove:Clean()

		GuiController.inMenu = true
		uiScale.Scale = 0

		self._trove:Add(
			Tween.new(
				uiScale,
				TweenInfo.new(self.openDuration, self.openEasingStyle, self.openEasingDirection),
				{ Scale = 1 }
			),
			"Cancel"
		)
		self._trove:Add(
			Promise.delay(self.openDuration or 0.3):andThen(function()
				uiScale.Scale = 1
			end),
			"cancel"
		)
	end
end

function GuiController:closeFrame(nonEvent: boolean, checkToClose: boolean)
	if checkToClose and self.doNotCloseWhenOpenAnotherFrame then
		return
	end

	local uiScale: UIScale = self.frame:FindFirstChild("UIScale")
	if uiScale then
		if not nonEvent then
			self.onClose:Fire()
		end

		self._trove:Clean()
		task.wait()

		uiScale.Scale = 1

		self._trove:Add(
			Tween.new(
				uiScale,
				TweenInfo.new(self.closeDuration, self.closeEasingStyle, self.closeEasingDirection),
				{ Scale = 0 }
			)
		)

		self._trove:Add(
			Promise.delay(self.closeDuration or 0.3):andThen(function()
				self.frame.Visible = false
				uiScale.Scale = 0
			end),
			"cancel"
		)

		if GuiController.currentFrame == self then
			GuiController.currentFrame = nil
			GuiController.inMenu = false

			-- if not self.doNotSoundEffect then
			-- 	sounds.FrameClose:Play()
			-- end
			-- if not self.doNotBlur then
			-- 	GuiController.Animations.screenBlur(false)
			-- end
		end

		task.wait(self.closeDuration)
	end
end

function GuiController.toggleGuis(enabled: boolean, guis: table | string, except: table)
	local guiTable = {}
	if typeof(guis) == "table" then
		for _, v in guis do
			local guiInstance = typeof(v) == "string" and playerGui:FindFirstChild(v)
			if guiInstance then
				table.insert(guiTable, guiInstance)
			end
		end
	elseif guis == "All" then
		if typeof(except) == "table" then
			for _, v in playerGui:GetChildren() do
				if not table.find(except, v.Name) then
					table.insert(guiTable, v)
				end
			end
		else
			guiTable = playerGui:GetChildren()
		end
	end

	for _, v: ScreenGui in guiTable do
		if v:IsA("ScreenGui") and v.Name ~= "TouchGui" then
			v.Enabled = if typeof(enabled) == "boolean" then enabled else false
		end
	end
end

function GuiController:getScreenGui(guiName: string)
	if not guiName then
		return
	end

	if self.screenGuis[guiName] then
		return self.screenGuis[guiName]
	else
		local screenGui = playerGui:WaitForChild(guiName, 15) :: ScreenGui
		if screenGui then
			self.screenGuis[guiName] = screenGui
			return screenGui
		end
	end
end

function GuiController:getFrameData(frameName: string)
	if not frameName then
		return
	end

	if self.frames[frameName] then
		return self.frames[frameName]
	else
		local screenGui: ScreenGui = self:getScreenGui(frameName)
		if screenGui and screenGui:FindFirstChild("GuiFrame") then
			local frameData = self.newFrame(frameName, screenGui.GuiFrame, { keyToClose = Enum.KeyCode.ButtonB })
			if frameData then
				return frameData
			end
		end
	end
end

function GuiController.isInFrame(frame)
	if not frame then
		return
	end

	local X = mouse.X
	local Y = mouse.Y

	if
		X > frame.AbsolutePosition.X
		and Y > frame.AbsolutePosition.Y
		and X < frame.AbsolutePosition.X + frame.AbsoluteSize.X
		and Y < frame.AbsolutePosition.Y + frame.AbsoluteSize.Y
	then
		return true
	else
		return false
	end
end

function GuiController.updateGuiAccordingToDevice()
	-- Hide all keys icons
	for _, v: GuiObject in pairs(playerGui:GetDescendants()) do
		if v:IsA("GuiObject") and (v.Name == "GamepadKey" or v.Name == "KeyboardKey" or v.Name == "MobileKey") then
			v.Visible = false

			if GuiController.isGamepad then
				if v.Name ~= "GamepadKey" then
					continue
				end
				v.Visible = true
			elseif GuiController.isMobile then
				if v.Name ~= "MobileKey" then
					continue
				end
				v.Visible = true
			elseif v.Name == "KeyboardKey" then
				v.Visible = true
			end
		end
	end

	task.spawn(function()
		local keysInformation: ScreenGui = GuiController:getScreenGui("KeysInformation")
		if keysInformation then
			if GuiController.isGamepad then
				keysInformation.KeysFrame.ConsoleSprintKey.Visible = true
			else
				keysInformation.KeysFrame.ConsoleSprintKey.Visible = false
			end
		end
	end)
end

function GuiController:gamepadConnected()
	GuiController.isGamepad = true
	GuiController.updateGuiAccordingToDevice()

	local keys = {}
	for _, v in pairs(UserInputService:GetGamepadState(Enum.UserInputType.Gamepad1)) do
		keys[v.KeyCode] = v
	end

	self.inputs.thumbstickInput = keys[Enum.KeyCode.Thumbstick2]
	table.clear(keys)
end

function GuiController:start()
	playerGui.ScreenOrientation = Enum.ScreenOrientation.LandscapeRight

	for _, v in playerGui:GetChildren() do
		if v:FindFirstChild("GuiFrame") then
			self.newFrame(v.Name, v.GuiFrame)
		end
	end

	--// Inputs
	-- Mobile
	if self.isMobile then
		for _, instance in pairs(playerGui:GetDescendants()) do
			local offsetData = MobileGuiRetuning[instance.Name]
			if offsetData then
				Utils.checkProperty(instance, offsetData)
			end
		end

		-- -- Disable side buttons title label on mobile
		-- local sideButtonsGUI: ScreenGui = self:getScreenGui("SideButtons")
		-- if sideButtonsGUI then
		-- 	local buttonFrames = {}

		-- 	-- Get labels
		-- 	local leftFrame = sideButtonsGUI:WaitForChild("LeftFrame")
		-- 	if leftFrame then
		-- 		local buttons = leftFrame:FindFirstChild("Buttons")
		-- 		if buttons then
		-- 			for _, v: Frame in buttons:GetChildren() do
		-- 				if v:IsA("Frame") and v.Name ~= "Shop" then
		-- 					table.insert(buttonFrames, v)
		-- 				end
		-- 			end
		-- 		end
		-- 	end
		-- 	local rightFrame = sideButtonsGUI:WaitForChild("RightFrame")
		-- 	if rightFrame then
		-- 		local frame = rightFrame:FindFirstChild("Frame")
		-- 		if frame then
		-- 			for _, v: Frame in frame:GetChildren() do
		-- 				if v:IsA("Frame") then
		-- 					table.insert(buttonFrames, v)
		-- 				end
		-- 			end
		-- 		end
		-- 	end

		-- 	-- Disable labels
		-- 	for _, v: Frame in buttonFrames do
		-- 		local titleLabel: TextLabel = v:FindFirstChild("Button") and v.Button:FindFirstChild("Title")
		-- 		if titleLabel then
		-- 			titleLabel.Visible = false
		-- 		end
		-- 	end
		-- end

		--local mobileButtons: ScreenGui = GuiController:getGui('MobileButtons')
		--if mobileButtons then
		--	mobileButtons.Frame.Visible = true
		--end
	end

	UserInputService.InputBegan:Connect(function(input, _gameProcessedEvent)
		if self.currentFrame then
			if self.currentFrame.keyToClose then
				if input.KeyCode == self.currentFrame.keyToClose then
					self.currentFrame:closeFrame()
				end
			end
		end
	end)

	self.updateGuiAccordingToDevice()

	-- Gamepad
	if self.isGamepad then
		self:gamepadConnected()
	end
	UserInputService.GamepadConnected:Connect(function()
		self:gamepadConnected()
	end)
	UserInputService.GamepadDisconnected:Connect(function()
		self.isGamepad = false
		self.updateGuiAccordingToDevice()

		self.inputs.thumbstickInput = nil
	end)
end

return GuiController
