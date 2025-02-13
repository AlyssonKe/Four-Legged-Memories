--// Services
local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

--// Variables
local packages = ReplicatedStorage.Packages
local sounds = ReplicatedStorage.Sounds

local buttonClickSound: Sound = sounds:FindFirstChild("Click")
local buttonHoverSound: Sound = sounds:FindFirstChild("ButtonHover")

--// Modules
local Signal = require(packages.Signal)
local Trove = require(packages.Trove)

-- Types
type buttonSettings = {
	animations: table?,
	cooldown: number?,
	keys: { Enum.KeyCode }?,
	playClickedSound: boolean?,
}

local Button = {}
Button.__index = Button

function Button.new(button: GuiButton, Settings: buttonSettings)
	if not button then
		return
	end

	Settings = Settings or {}

	local self = setmetatable({
		_trove = Trove.new(),

		onClick = Signal.new(),
		onHover = Signal.new(),

		button = button,

		Settings = Settings or {},
	}, Button)

	-- Button connections
	self._trove:Connect(button.Activated, function()
		self:click()
	end)

	self._trove:Connect(button.MouseEnter, function()
		self:hover(true)
	end)

	self._trove:Connect(button.MouseLeave, function()
		self:hover(false)
	end)

	self._trove:Connect(button.SelectionGained, function()
		self:hover(true)
	end)

	self._trove:Connect(button.SelectionLost, function()
		self:hover(false)
	end)

	-- Keys
	if Settings.keys then
		self._trove:Connect(UserInputService.InputBegan, function(input: InputObject, gameProcessed: boolean)
			if table.find(Settings.keys, input.KeyCode) and not gameProcessed then
				self:click()
			end
		end)
	end

	-- Why not use .Destroyed? sometimes it just not fire
	self._trove:Connect(button.AncestryChanged, function(_, parent)
		if not parent then
			self._trove:Destroy()
		end
	end)

	return self
end

function Button:click()
	local cooldown: number? = self.Settings.cooldown ~= nil and self.Settings.cooldown or 0.05
	if cooldown then
		local now: number = time()
		local lastClick: number? = self._lastClick

		if lastClick and (now - lastClick) <= cooldown then
			return
		end

		self._lastClick = now
	end

	if self.Settings.playClickedSound then
		local clickSound: Sound = (
			typeof(self.Settings.playClickedSound) == "Instance"
			and self.Settings.playClickedSound:IsA("Sound")
			and self.Settings.playClickedSound:Clone()
		) or (buttonClickSound and buttonClickSound:Clone())
		if clickSound then
			clickSound.Parent = sounds
			clickSound:Play()
			Debris:AddItem(clickSound, clickSound.TimeLength)
		end
	end

	self.onClick:Fire()
end

function Button:hover(hover: boolean)
	self.isHovering = hover
	self.onHover:Fire(hover)

	if self.Settings.playHoverSound ~= false and hover then
		local hoverSound: Sound = (
			typeof(self.Settings.playHoverSound) == "Instance"
			and self.Settings.playHoverSound:IsA("Sound")
			and self.Settings.playHoverSound:Clone()
		) or (buttonClickSound and buttonClickSound:Clone())
		if hoverSound then
			hoverSound.Parent = sounds
			hoverSound:Play()
			Debris:AddItem(hoverSound, hoverSound.TimeLength)
		end
	end
end

function Button:destroy()
	self._trove:Destroy()

	table.clear(self)
	setmetatable(self, nil)
end

return Button
