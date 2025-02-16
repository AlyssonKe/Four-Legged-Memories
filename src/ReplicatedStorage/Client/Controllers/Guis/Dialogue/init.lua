--// Services
local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

--// Variables
local packages = ReplicatedStorage.Packages
local Shared = ReplicatedStorage.Shared
local sounds = ReplicatedStorage.Sounds

--// Modules
local DialoguesData = require(script.DialoguesData)
local GuiController = require(script.Parent.Parent.GuiController)
local TranslationHelper = require(Shared.TranslationHelper)
local Trove = require(packages.Trove)
local Tween = require(Shared.Tween)
local Utils = require(Shared.Utils)

--// Guis
local dialoguesGui = GuiController:getScreenGui("Dialogues")
if not dialoguesGui then
	return false
end

local dialogueFrame: Frame = dialoguesGui.Frame
local dialogueLabel: TextLabel = dialogueFrame.DialogueLabel

local Dialogues = {
	current = nil,
}
Dialogues.__index = Dialogues

function Dialogues.new(dialogue: string, dialogueType: string, part: string)
	local dialogueData = DialoguesData[dialogue]
		and DialoguesData[dialogue][dialogueType]
		and DialoguesData[dialogue][dialogueType][part]
	if not dialogueData then
		return
	end

	local self = setmetatable({
		_trove = Trove.new(),

		finished = false,
		paused = false,
		started = false,

		dialogue = dialogue,
		dialogueData = dialogueData,
		part = part,
	}, Dialogues)

	self:construct()

	return self
end

function Dialogues:construct()
	local translatedText = TranslationHelper.translateByKey(self.dialogueData.translatorKey, {})
		or self.dialogueData.subtitle

	local newLabel = dialogueLabel:Clone()
	newLabel.Text = translatedText
	newLabel.UIGradient.Offset = Vector2.new(0, 0)
	newLabel.TextSize = Utils.percentageBetweenRange(dialogueFrame.AbsoluteSize.X, 16, 36, 1280)
	newLabel.Visible = true
	newLabel.Parent = dialogueFrame

	self.tween = TweenService:Create(newLabel.UIGradient, TweenInfo.new(2), { Offset = Vector2.new(1, 0) })

	self._trove:Add(function()
		self.tween:Cancel()

		newLabel.UIGradient.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 1),
			NumberSequenceKeypoint.new(0.025, 0),
			NumberSequenceKeypoint.new(1, 0),
		})
		newLabel.UIGradient.Offset = Vector2.new(0, 0)
		Tween.new(newLabel.UIGradient, TweenInfo.new(2), { Offset = Vector2.new(1, 0) })

		Debris:AddItem(newLabel, 2)
		
		task.wait(1)
	end)
end

function Dialogues:play()
	if self.audio then
		if self.localAudio and self:checkForCharacter() then
			self.audioInstance = self._trove:Add(self.audio:Clone())
			self.audioInstance.Parent = self.character.PrimaryPart
			self.audioInstance:Play()

			task.spawn(function()
				self.audioInstance.Ended:Wait()
				self.audioInstance:Destroy()
			end)
		else
			self.audioInstance = self._trove:Add(self.audio:Clone())
			self.audioInstance.Parent = sounds
			self.audioInstance:Play()

			task.spawn(function()
				self.audioInstance.Ended:Wait()
				self.audioInstance:Destroy()
			end)
		end
	end

	self.tween:Play()

	self.elapsed = 0
	self._trove:Add(RunService.Heartbeat:Connect(function(deltaTime)
		if not self.paused then
			self.elapsed += deltaTime / (self.dialogueData.duration or 1)
			if self.elapsed > 1 then
				self.finished = true
				return
			end
		end
	end))

	repeat
		task.wait()
	until self.finished or self.skipped

	self:destroy()
end

function Dialogues:pause(pause: boolean)
	if pause ~= nil then
		self.paused = pause
	else
		self.paused = not self.paused
	end

	if self.paused then
		self.tween:Pause()

		if self.animationInstance then
			self.animationInstance:AdjustSpeed(0)
		end
		if self.audioInstance then
			self.audioInstance:Pause()
		end
	else
		self.tween:Play()

		if self.animationInstance then
			self.animationInstance:AdjustSpeed(1)
		end
		if self.audioInstance then
			self.audioInstance:Resume()
		end
	end
end

function Dialogues:skip()
	self.skipped = true
end

function Dialogues:destroy()
	if Dialogues.current == self then
		Dialogues.current = nil
	end

	self._trove:Destroy()
	setmetatable(self, nil)
	table.clear(self)
end

function Dialogues:start()
	task.wait(1)
	task.spawn(function()
		self.new("Part1", "Dialogue", "P1-1"):play()
		self.new("Part1", "Dialogue", "P1-2"):play()
		self.new("Part1", "Dialogue", "P1-3"):play()
	end)
	-- print("TEXT")
	-- self:newDialogue(
	-- 	"[Death]: Eu sei que é difícil, Bruce. Mas você viveu uma vida extraordinária, e agora chegou o momento de descansar.",
	-- 	6
	-- )
	-- task.wait(6)
	-- self:newDialogue("[Bruce]: Naquele dia fazer as coisas começou a ficar mais difícil pra mim…", 6)
end

return Dialogues
