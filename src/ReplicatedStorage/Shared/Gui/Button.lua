--// Services
local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

--// Variables
local packages = ReplicatedStorage.Packages
local sounds = ReplicatedStorage.Sounds

--// Modules
local Animations = require(script.Parent.Animations)
local Signal = require(packages:WaitForChild("Signal"))
local Trove = require(packages:WaitForChild("Trove"))

-- Types
type buttonSettings = {
	animations: table?,
	cooldown: number?,
	keys: { Enum.KeyCode }?,
	playClickedSound: boolean?,
}

-- Service
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
	local cooldown: number? = self.Settings.cooldown
	if cooldown then
		local now: number = time()
		local lastClick: number? = self._lastClick

		if lastClick and (now - lastClick) <= cooldown then
			return
		end

		self._lastClick = now
	end

	local animations: table? = self.Settings.animations and self.Settings.animations.onClick
	if animations then
		for _, v in animations do
			if Animations[v] then
				Animations[v](self.button)
			end
		end
	end

	if self.Settings.playClickedSound ~= false then
		local clickSound: Sound = sounds.Click:Clone()
		clickSound.Parent = sounds
		clickSound:Play()
		Debris:AddItem(clickSound, clickSound.TimeLength)
	end

	self.onClick:Fire()
end

function Button:hover(hover: boolean)
	self.isHovering = hover
	self.onHover:Fire(hover)

	local animations: table? = self.Settings.animations and self.Settings.animations.onHover
	if animations then
		for _, v in animations do
			if Animations[v] then
				Animations[v](self.button, hover)
			end
		end
	end
end

function Button:destroy()
	self._trove:Destroy()
end

return Button
