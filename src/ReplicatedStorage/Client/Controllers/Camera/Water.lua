--// Services
local CollectionService = game:GetService("CollectionService")
local Lighting = game:GetService("Lighting")
local SoundService = game:GetService("SoundService")

--// Variables
local camera: Camera = workspace.CurrentCamera
local waterBlur: BlurEffect = Lighting.WaterBlur
local waterColorCorrection: ColorCorrectionEffect = Lighting.WaterColorCorrection
local waterParts = CollectionService:GetTagged("WaterPart")

local Water = {}

--// Update collection service
CollectionService:GetInstanceAddedSignal("WaterPart"):Connect(function(instance)
	table.insert(waterParts, instance)
end)
CollectionService:GetInstanceRemovedSignal("WaterPart"):Connect(function(instance)
	local index = table.find(waterParts, instance)
	if index then
		table.remove(waterParts, index)
	end
end)

function Water.checkIsInWater()
	local inWater = false
	-- print(inWater, waterParts)
	for _, water in waterParts do
		local objectSpaceCameraPosition = water.CFrame:PointToObjectSpace(camera.CFrame.Position)

		if
			(math.abs(objectSpaceCameraPosition.X) > water.Size.X / 2)
			or (math.abs(objectSpaceCameraPosition.Y) > water.Size.Y / 2)
			or (math.abs(objectSpaceCameraPosition.Z) > water.Size.Z / 2)
		then
			-- Out of bounds on the X axis
			inWater = false
			continue
		end

		inWater = true

		waterBlur.Size = water:GetAttribute("BlurSize") or 13
		waterColorCorrection.Brightness = water:GetAttribute("Brightness") or 0.02
		waterColorCorrection.Contrast = water:GetAttribute("Contrast") or -0.02
		waterColorCorrection.Saturation = water:GetAttribute("Saturation") or -0.05
		waterColorCorrection.TintColor = water:GetAttribute("WaterColor") or water.Color

		break
	end

	waterBlur.Enabled = inWater
	waterColorCorrection.Enabled = inWater
	SoundService.AmbientReverb = if inWater then Enum.ReverbType.UnderWater else Enum.ReverbType.NoReverb
end

return Water
