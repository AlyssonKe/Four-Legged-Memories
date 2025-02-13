--// Modules
local Camera = require(script.Parent.Parent.Camera)
local FootstepsSounds = require(script.FootstepsSounds)

local Character = {}

function Character.onCharacterAdded(character: Model)
	if not character then
		return
	end

	local humanoid: Humanoid = character:WaitForChild("Humanoid")
	local humanoidRootPart = character:WaitForChild("HumanoidRootPart")
	local runningSound: Sound = humanoidRootPart:WaitForChild("Running")

	Camera.new() -- Create player camera

	print("Camera")

	-- Footstep
	humanoid:GetPropertyChangedSignal("FloorMaterial"):Connect(function()
		local floorMaterial = humanoid.FloorMaterial
		local footstep

		footstep = FootstepsSounds[floorMaterial] or FootstepsSounds.Default

		if footstep and runningSound then
			runningSound.SoundId = footstep.id
			runningSound.Volume = footstep.volume or 0.5
			runningSound.PlaybackSpeed = footstep.playbackSpeed or 1
		end
	end)

	-- Remove climbing state
	humanoid:SetStateEnabled(Enum.HumanoidStateType.Climbing, false)
	humanoid:SetStateEnabled(Enum.HumanoidStateType.PlatformStanding, false)
end

return Character
