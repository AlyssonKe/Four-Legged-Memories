--// Services
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

--// Variables
local Shared = ReplicatedStorage.Shared
local lights = CollectionService:GetTagged("LightsFlicker")

--// Modules
local Tween = require(Shared.Tween)

local Module = {
	frequency = 225,
	lightningFrequency = 7,
}

local nextStep = tick() + math.random(0, Module.frequency) / 10

--// Update collection service
-- Lights
CollectionService:GetInstanceAddedSignal("LightsFlicker"):Connect(function(instance)
	table.insert(lights, instance)
end)
CollectionService:GetInstanceRemovedSignal("LightsFlicker"):Connect(function(instance)
	local index = table.find(lights, instance)
	if index then
		table.remove(lights, index)
	end
end)

function Module.initialize()
	RunService.Heartbeat:Connect(function()
		if tick() >= nextStep then -- Only run after a certain amount of time, may want to add a random delay between lights flickering so it is even more random
			nextStep = tick() + math.random(25, 75) / Module.frequency
			for index = 1, #lights do -- Loop through all of the lights
				local part: Part = lights[index]
				if not part or not part:IsA("BasePart") or not part.Parent or part:GetAttribute("NoFlicker") then
					continue
				end

				local lightPower = part:GetAttribute("LightPower") or 1

				local lightsTable = {}
				local partsTable = { part }

				-- Setting light data in table
				for _, v in part:GetDescendants() do
					if v:IsA("Light") then
						table.insert(lightsTable, v)
					elseif v.Name == "Lamp" and v:IsA("BasePart") then
						table.insert(partsTable, v)
					end
				end

				-- Execute light
				for _, v in lightsTable do
					local originalBrightness = v:GetAttribute("OriginalBrightness")
					if not originalBrightness then
						originalBrightness = v.Brightness
						v:SetAttribute("OriginalBrightness", originalBrightness)
					end

					Tween.new(
						v,
						TweenInfo.new(0.05, Enum.EasingStyle.Sine, Enum.EasingDirection.Out),
						{ Brightness = originalBrightness * lightPower }
					)
				end

				for _, v in partsTable do
					local originalColor = v:GetAttribute("OriginalColor")
					if not originalColor then
						originalColor = v.Color
						v:SetAttribute("OriginalColor", originalColor)
					end

					local H, S, V = originalColor:ToHSV()
					Tween.new(
						v,
						TweenInfo.new(0.05, Enum.EasingStyle.Sine, Enum.EasingDirection.Out),
						{ Color = Color3.fromHSV(H, S, (V * lightPower)) }
					)
				end

				if lightPower < 0.1 then
					lightPower = 1
				elseif lightPower > 0.5 then
					lightPower = 0.1
				else
					lightPower = 0.75
				end

				-- -- Sound
				-- local sound = part:FindFirstChild("FlickerSound")
				-- if sound then
				-- 	PlayClientSound(sound, part, { volume = (lightPower * (0.02 - 0.125) / 1) + 0.125 })
				-- else
				-- 	PlayClientSound(sounds.LightFlicker, part, { volume = (lightPower * (0.02 - 0.125) / 1) + 0.125 })
				-- end

				part:SetAttribute("LightPower", math.random(1, 20) / 20)
			end
		end

		-- if tick() >= nextStepLightning then -- Only run after a certain amount of time, may want to add a random delay between lights flickering so it is even more random
		-- 	nextStepLightning = tick() + math.random(25, 100) / Module.lightningFrequency

		-- 	local randomWaitDisableLight = math.random(5, 12)
		-- 	local time = math.random(2, 4)

		-- 	PlayClientSound(sounds.Thunders.Thunder1)
		-- 	for _ = 1, time do
		-- 		local randomWait = math.random(7, 15)

		-- 		for _, v in pairs(lightning) do
		-- 			task.spawn(function()
		-- 				if v:IsA("Attachment") then
		-- 					local light = v:FindFirstChildWhichIsA("Light")
		-- 					if light then
		-- 						light.Enabled = true
		-- 						task.wait(randomWaitDisableLight / 100)
		-- 						light.Enabled = false
		-- 					end
		-- 				end
		-- 			end)
		-- 		end
		-- 		task.wait(randomWait / 100)
		-- 	end

		-- 	if time == 3 then
		-- 		PlayClientSound(sounds.Thunders.Thunder2)
		-- 	end
		-- 	if time == 4 then
		-- 		PlayClientSound(sounds.Thunders.Thunder3)
		-- 	end
		-- end
	end)

	print("Lights flicker initialized.")
	return
end

function Module.toggleModelLights(model, active)
	if typeof(model) ~= "Instance" or not model:IsA("Model") then
		return
	end

	local lightsTable = {}
	local partsTable = {}

	lights = CollectionService:GetTagged("LightsFlicker")

	local mainLamp = model:FindFirstChild("MainLamp", true)
	if mainLamp then
		table.insert(partsTable, mainLamp) -- Set main lamp in parts table

		if table.find(lights, mainLamp) then -- Remove flicker if it has
			mainLamp:SetAttribute("NoFlicker", if not active then true else nil)
		end

		-- Setting light data in table
		for _, v in pairs(mainLamp:GetDescendants()) do
			if v:IsA("BasePart") then
				table.insert(partsTable, v)
			end
		end
		for _, v in pairs(model:GetDescendants()) do
			if v:IsA("Light") then
				table.insert(lightsTable, v)
			end
		end
	end

	-- Execute light
	for _, v in lightsTable do
		local originalBrightness = v:GetAttribute("OriginalBrightness")
		if not originalBrightness then
			originalBrightness = v.Brightness
			v:SetAttribute("OriginalBrightness", originalBrightness)
		end

		Tween.new(
			v,
			TweenInfo.new(0.05, Enum.EasingStyle.Sine, Enum.EasingDirection.Out),
			{ Brightness = (v:GetAttribute("OriginalBrightness") or 1) / (1 / if active then 1 else 0) }
		)
	end

	for _, v in partsTable do
		local originalColor = v:GetAttribute("OriginalColor")
		if not originalColor then
			originalColor = v.Color
			v:SetAttribute("OriginalColor", originalColor)
		end

		local H, S, V = originalColor:ToHSV()
		Tween.new(
			v,
			TweenInfo.new(0.05, Enum.EasingStyle.Sine, Enum.EasingDirection.Out),
			{ Color = Color3.fromHSV(H, S, (V / (1 / if active then 1 else 0))) }
		)
	end
end

function Module.flickerLightsModel(model, attributes)
	local mainLamp = model and model:FindFirstChild("MainLamp")
	if not mainLamp then
		return
	end

	attributes = attributes or {}

	local startTick = tick()

	local duration = attributes.duration or 5
	-- local changeFrequency = attributes.changeFrequency or nil
	local flickerFrequency = attributes.frequency or 100
	local toggleLightAfterEnd = attributes.toggleLightAfterEnd
	local changeColor = attributes.changeColor or {}

	-- -- Change flicker frequency
	-- task.spawn(function()
	-- 	if changeFrequency then
	-- 		for _i = flickerFrequency, flickerFrequency / 2, -((flickerFrequency / duration) / 4) do
	-- 			task.wait(0.25)
	-- 			if changeFrequency == "Increase" then
	-- 				flickerFrequency += (flickerFrequency / duration) / 4
	-- 			elseif changeFrequency == "Decrease" then
	-- 				flickerFrequency -= (flickerFrequency / duration) / 4
	-- 			end
	-- 		end
	-- 	end
	-- end)

	local lightsData = { mainLamp }
	for _, v in mainLamp:GetDescendants() do
		if v:IsA("Light") or v:IsA("BasePart") or (v:IsA("ImageLabel") and v.Name == "LightEffect") then
			table.insert(lightsData, v)
		end
	end

	local connection

	local function flicker(lightPower)
		for _, v in lightsData do
			local originalColor = v:GetAttribute("OriginalColor")
			if not originalColor then
				if v:IsA("BasePart") or v:IsA("Light") then
					originalColor = v.Color
				elseif v:IsA("Image") then
					originalColor = v.ImageColor3
				end

				v:SetAttribute("OriginalColor", originalColor)
				--print(originalColor)
			end

			local color = originalColor
			if lightPower == 0.6 and changeColor.flicker then
				color = changeColor.color
			end

			local H, S, V = color:ToHSV()

			--print(lightPower, flickerNextStep, color)
			if v:IsA("BasePart") or v:IsA("Light") then
				v.Color = Color3.fromHSV(H, S, (V * lightPower))
			elseif v:IsA("Image") then
				v.ImageColor3 = Color3.fromHSV(H, S, (V * lightPower))
			end

			if v:IsA("Light") then
				local originalBrightness = v:GetAttribute("OriginalBrightness")
				if not originalBrightness then
					originalBrightness = v.Brightness
					v:SetAttribute("OriginalBrightness", originalBrightness)
				end

				v.Brightness = originalBrightness * lightPower
			end
		end

		-- Sound
		-- local sound = mainLamp:FindFirstChild("FlickerSound")
		-- if sound then
		-- 	PlayClientSound(sound, mainLamp, { volume = (lightPower * (0.1 - 0.25) / 1) + 0.25 })
		-- else
		-- 	PlayClientSound(sounds.LightFlicker, mainLamp, { volume = (lightPower * (0.1 - 0.25) / 1) + 0.25 })
		-- end
	end

	local flickerNextStep = 0
	connection = RunService.Heartbeat:Connect(function(_deltaTime)
		if tick() >= flickerNextStep then
			flickerNextStep = tick() + math.random(5, 60) / flickerFrequency
			local lightPower = mainLamp:GetAttribute("LightPower") or 1

			if lightPower == 0.1 then
				lightPower = 0.4
			elseif lightPower == 0.6 then
				lightPower = 0.1
			else
				lightPower = 1
			end

			flicker(lightPower)

			lightPower = math.random(1, 10) / 10

			flicker(lightPower)

			mainLamp:SetAttribute("LightPower", lightPower)
		end
	end)

	task.spawn(function()
		repeat
			task.wait()
		until tick() - startTick > duration

		if connection then
			connection:Disconnect()
		end

		if toggleLightAfterEnd ~= nil then
			if table.find(lights, mainLamp) then -- Remove flicker if it has
				mainLamp:SetAttribute("NoFlicker", if not toggleLightAfterEnd then true else nil)
			end

			for _, v in lightsData do
				local originalColor

				if changeColor.stayWhenFinish then
					originalColor = changeColor.color
				else
					if v:GetAttribute("OriginalColor") then
						originalColor = v:GetAttribute("OriginalColor")
					end
				end

				if toggleLightAfterEnd then
					local H, S, V = originalColor:ToHSV()

					if v:IsA("BasePart") or v:IsA("Light") then
						v.Color = Color3.fromHSV(H, S, (V / (1 / if toggleLightAfterEnd then 1 else 0)))
					elseif v:IsA("Image") then
						v.ImageColor3 =
							Color3.fromHSV(Color3.fromHSV(H, S, (V / (1 / if toggleLightAfterEnd then 1 else 0))))
					end
				end

				if v:IsA("Light") then
					local originalBrightness = v:GetAttribute("OriginalBrightness")
					if not originalBrightness then
						originalBrightness = v.Brightness
						v:SetAttribute("OriginalBrightness", originalBrightness)
					end

					v.Brightness = (v:GetAttribute("OriginalBrightness") or 1)
						/ (1 / if toggleLightAfterEnd then 1 else 0)
				end
			end
		end
	end)
end

function Module.toggleMapLights(map, active)
	if typeof(map) ~= "Instance" or not map:IsA("Model") or not map:FindFirstChild("Map") then
		return
	end

	local mainLampsTable = {}
	local lightsTable = {}
	local partsTable = {}

	local lamps = map.Map:FindFirstChild("Lamps")
	if lamps then
		for _, v in pairs(lamps:GetChildren()) do
			if v:FindFirstChild("MainLamp") then
				table.insert(mainLampsTable, v)
			end
		end
	end

	-- Skybox if the map have one
	local skybox = map.Map:FindFirstChild("Skybox")
	if skybox then
		-- Setting light data in table
		for _, v: Instance in pairs(skybox:GetChildren()) do
			if v:IsA("BasePart") then
				-- Check if skybox part has a light instance
				for _, light in pairs(v:GetChildren()) do
					if light:IsA("Light") then
						table.insert(lightsTable, light)
					end
				end

				table.insert(partsTable, v)
			end
		end
	end

	-- Check if main lamps parts have others lights parts
	for _, mainLamps in mainLampsTable do
		local mainLamp = mainLamps:IsA("Model") and mainLamps:FindFirstChild("MainLamp", true)
		if mainLamp then
			table.insert(partsTable, mainLamp) -- Set main lamp in parts table

			if table.find(lights, mainLamp) then -- Remove flicker if it has
				mainLamp:SetAttribute("NoFlicker", if not active then true else nil)
			end

			-- Setting light data in table
			for _, v in pairs(mainLamp:GetDescendants()) do
				if v:IsA("Light") then
					table.insert(lightsTable, v)
				end

				if v:IsA("BasePart") then
					table.insert(partsTable, v)
				end
			end
		end
	end

	-- Execute light
	for _, v in lightsTable do
		local originalBrightness = v:GetAttribute("OriginalBrightness")
		if not originalBrightness then
			originalBrightness = v.Brightness
			v:SetAttribute("OriginalBrightness", originalBrightness)
		end

		Tween.new(v, TweenInfo.new(0.05, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {
			Brightness = (v:GetAttribute("OriginalBrightness") or 1) / (1 / if active then 1 else 0),
		})
	end

	for _, v in partsTable do
		local originalColor = v:GetAttribute("OriginalColor")
		if not originalColor then
			originalColor = v.Color
			v:SetAttribute("OriginalColor", originalColor)
		end

		local H, S, V = originalColor:ToHSV()
		Tween.new(
			v,
			TweenInfo.new(0.05, Enum.EasingStyle.Sine, Enum.EasingDirection.Out),
			{ Color = Color3.fromHSV(H, S, (V / (1 / if active then 1 else 0))) }
		)
	end
end

function Module.flickerLightsMap(map, attributes)
	if typeof(map) ~= "Instance" or not map:IsA("Model") then
		return
	end
	attributes = attributes or {}

	local startTick = tick()

	local duration = attributes.duration or 5
	local changeFrequency = attributes.changeFrequency or nil
	local flickerFrequency = attributes.frequency or 100
	local changeSkybox = attributes.changeSkybox or false
	local toggleLightAfterEnd = attributes.toggleLightAfterEnd

	-- Change flicker frequency
	task.spawn(function()
		if changeFrequency then
			for _i = flickerFrequency, flickerFrequency / 2, -((flickerFrequency / duration) / 4) do
				task.wait(0.25)
				if changeFrequency == "Increase" then
					flickerFrequency += (flickerFrequency / duration) / 4
				elseif changeFrequency == "Decrease" then
					flickerFrequency -= (flickerFrequency / duration) / 4
					print(flickerFrequency)
				end
			end
		end
	end)

	local mainLampsTable = {}

	local lamps = map:FindFirstChild("Map") and map.Map:FindFirstChild("Lamps")
	if lamps then
		for _, v in pairs(lamps:GetChildren()) do
			local mainLamp = v:FindFirstChild("MainLamp")
			if mainLamp then
				table.insert(mainLampsTable, mainLamp)
			end
		end
	end

	local skybox = changeSkybox and map.Map:FindFirstChild("Skybox")

	task.spawn(function()
		for _i = 1, 100000 do
			task.wait(math.random(25, 75) / flickerFrequency)
			if tick() - startTick > duration then
				break
			end

			for _, part in mainLampsTable do
				local lightPower = part:GetAttribute("LightPower") or 1

				local lightsTable = {}
				local partsTable = { part }

				-- Setting light data in table
				for _, v in part:GetDescendants() do
					if v:IsA("Light") then
						table.insert(lightsTable, v)
					elseif v.Name == "Lamp" and v:IsA("BasePart") then
						table.insert(partsTable, v)
					end
				end

				-- Execute light
				for _, v in lightsTable do
					local originalBrightness = v:GetAttribute("OriginalBrightness")
					if not originalBrightness then
						originalBrightness = v.Brightness
						v:SetAttribute("OriginalBrightness", originalBrightness)
					end

					Tween.new(
						v,
						TweenInfo.new(0.05, Enum.EasingStyle.Sine, Enum.EasingDirection.Out),
						{ Brightness = originalBrightness * lightPower }
					)
				end

				for _, v in partsTable do
					local originalColor = v:GetAttribute("OriginalColor")
					if not originalColor then
						originalColor = v.Color
						v:SetAttribute("OriginalColor", originalColor)
					end

					local H, S, V = originalColor:ToHSV()
					Tween.new(
						v,
						TweenInfo.new(0.05, Enum.EasingStyle.Sine, Enum.EasingDirection.Out),
						{ Color = Color3.fromHSV(H, S, (V * lightPower)) }
					)
				end

				if lightPower < 0.1 then
					lightPower = 1
				elseif lightPower > 0.5 then
					lightPower = 0.1
				else
					lightPower = 0.75
				end

				-- -- Sound
				-- local sound = part:FindFirstChild("FlickerSound")
				-- if sound then
				-- 	PlayClientSound(sound, part, { volume = (lightPower * (0.1 - 0.25) / 1) + 0.25 })
				-- else
				-- 	PlayClientSound(sounds.LightFlicker, part, { volume = (lightPower * (0.1 - 0.25) / 1) + 0.25 })
				-- end

				part:SetAttribute("LightPower", math.random(1, 20) / 20)
			end

			-- Skybox if the map have one
			if skybox then
				local lightPower = skybox:GetAttribute("LightPower") or 1

				-- Setting light data in table
				for _, v: Instance in pairs(skybox:GetChildren()) do
					if v:IsA("BasePart") then
						-- Check if skybox part has a light instance
						for _, light in pairs(v:GetChildren()) do
							if light:IsA("Light") then
								local originalBrightness = light:GetAttribute("OriginalBrightness")
								if not originalBrightness then
									originalBrightness = light.Brightness
									light:SetAttribute("OriginalBrightness", originalBrightness)
								end

								Tween.new(
									light,
									TweenInfo.new(0.05, Enum.EasingStyle.Sine, Enum.EasingDirection.Out),
									{ Brightness = originalBrightness * lightPower }
								)
							end
						end

						local originalColor = v:GetAttribute("OriginalColor")
						if not originalColor then
							originalColor = v.Color
							v:SetAttribute("OriginalColor", originalColor)
						end

						local H, S, V = originalColor:ToHSV()
						Tween.new(
							v,
							TweenInfo.new(0.05, Enum.EasingStyle.Sine, Enum.EasingDirection.Out),
							{ Color = Color3.fromHSV(H, S, (V * lightPower)) }
						)
					end
				end

				if lightPower < 0.1 then
					lightPower = 1
				elseif lightPower > 0.5 then
					lightPower = 0.1
				else
					lightPower = 0.75
				end

				skybox:SetAttribute("LightPower", math.random(1, 20) / 20)
			end
		end

		if toggleLightAfterEnd ~= nil then
			Module.toggleMapLights(map, toggleLightAfterEnd)
		end
	end)
end

return Module
