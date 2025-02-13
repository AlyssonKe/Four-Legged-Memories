--!strict
-- By Hasted o melhor! :)
--// Services
local Players = game:GetService("Players")

local Utils = {}

-- Players
function Utils.onPlayerAdded(callback)
	for _, player: Player in Players:GetPlayers() do
		task.spawn(callback, player)
	end

	return Players.PlayerAdded:Connect(callback)
end

function Utils.checkPlayer(player: Player)
	return player and player.Parent
end

function Utils.movePlayer(player: Player, cframe: CFrame, ignoreVelocityReset: boolean?): boolean
	local character: Model = Utils.checkPlayer(player) and (player.Character or player.CharacterAdded:Wait())
	if Utils.waitForCharacterLoad(character) then
		local humanoid: Humanoid = character:FindFirstChild("Humanoid")
		if humanoid then
			local seatPart: Seat = humanoid.SeatPart
			if seatPart and humanoid.Sit then
				seatPart.Disabled = true
				humanoid.Sit = false

				repeat
					task.wait()
				until humanoid.Sit == false

				task.wait(0.1)

				seatPart.Disabled = false
			end
		end

		local primaryPart = character.PrimaryPart
		if primaryPart and not ignoreVelocityReset then
			primaryPart.AssemblyLinearVelocity = Vector3.zero
			primaryPart.AssemblyAngularVelocity = Vector3.zero
		end

		character:PivotTo(cframe)

		return true
	end

	return false
end

function Utils.getPlayerPosition(player: Player): CFrame?
	local character: Model = Utils.checkPlayer(player) and (player.Character or player.CharacterAdded:Wait())

	if Utils.waitForCharacterLoad(character) then
		return character:GetPivot()
	end

	return nil
end

function Utils.waitForCharacterLoad(character: Model)
	local player = Players:GetPlayerFromCharacter(character)
	if not player then
		return false
	end

	return Utils.waitFor(function()
		return player.Parent -- Player is in game!
			and character:IsDescendantOf(workspace) -- Is in workspace
			and character:FindFirstChildWhichIsA("Attachment", true) -- Has attachments inside of it
	end, 5)
end

function Utils.onCharacterAdded(player: Player, callback: (Model, Player) -> ())
	local characterInstance = player.Character or player.CharacterAdded:Wait()
	if characterInstance then
		task.spawn(callback, characterInstance, player)
	end

	return player.CharacterAdded:Connect(function(character)
		callback(character, player)
	end)
end

function Utils.loadAnimationInPlayer(player: Player, animation: Animation | string | number)
	local character = Utils.checkPlayer(player) and (player.Character or player.CharacterAdded:Wait())

	if Utils.waitForCharacterLoad(character) then
		return Utils.loadAnimation(character, animation)
	end

	return nil, nil
end

function Utils.friendsInGame(player: Player)
	local playerList = {}
	for _, v: Player in pairs(Players:GetPlayers()) do
		if player:IsFriendsWith(v.UserId) then
			table.insert(playerList, v)
		end
	end

	return playerList
end

function Utils.getPlayerNearPart(part: Part, radius: number)
	if not part then
		return
	end

	local players = {}

	for _, player: Player in pairs(Players:GetPlayers()) do
		local humanoidRootPart = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
		if humanoidRootPart and (part.Position - humanoidRootPart.Position).Magnitude <= (radius or 10) then
			table.insert(players, player)
		end
	end

	return players
end

-- Tables
local function deepCopy(tbl: { any })
	local newTable = table.clone(tbl)
	for index, value in newTable do
		if type(value) == "table" then
			newTable[index] = deepCopy(value)
		end
	end

	return newTable
end

function Utils.deepCopyTable<T>(t: T): T
	return deepCopy(t :: any) :: T
end

function Utils.mapTable<T, M>(t: { T }, map: (T, number, { T }) -> M): { M }
	local newT = table.create(#t)

	for index, value in t do
		newT[index] = map(value, index, t)
	end

	return newT
end

function Utils.getTableLength(targetTable): number
	local count = 0

	for _ in targetTable do
		count += 1
	end

	return count
end

function Utils.percentageBetweenRange(percentage: number, min: number, max: number, finalPercentage: number)
	return (percentage * (max - min) / (finalPercentage or 100)) + min
end

function Utils.getRandomByPercentage(table: table, min: number, max: number)
	local choose = Random.new():NextNumber(min or 1, max or 100)
	local item
	local first
	local bound = 0
	for i, v in pairs(table) do
		if not first then
			first = i
		end

		if choose > bound and choose <= bound + v then
			item = i
		end
		bound = bound + v
	end

	return item or first
end

function Utils.setAnchor(object: Instance, target: boolean)
	if object:IsA("BasePart") then
		object.Anchored = target
	end

	for _, instance in object:GetDescendants() do
		if instance:IsA("BasePart") then
			instance.Anchored = target
		end
	end
end

function Utils.setCanCollide(object: Instance, target: boolean)
	if object:IsA("BasePart") then
		object.CanCollide = target
	end

	for _, instance in object:GetDescendants() do
		if instance:IsA("BasePart") then
			instance.CanCollide = target
		end
	end
end

function Utils.waitFor(callback: () -> any, timeout: number)
	local t = timeout
	while t > 0 do
		if callback() then
			return true
		end

		t -= task.wait()
	end

	return false
end

function Utils.loadAnimation(model: Model, animation: Animation | string | number): AnimationTrack?
	local animationInstance: Animation

	local t: string = typeof(animation)
	if t ~= "Instance" then
		animationInstance = Instance.new("Animation")
		animationInstance.AnimationId = if t == "string" and not tonumber(animation)
			then animation :: string
			else `rbxassetid://{animation}`
	end

	local animator = model:FindFirstChildWhichIsA("Animator", true)
	if animator then
		local animationTrack = animator:LoadAnimation(animationInstance or (animation :: Animation))

		local function doDestroy()
			animationTrack:Stop()

			if animationInstance then
				animationInstance:Destroy()
				animationInstance = nil
			end
		end

		model.AncestryChanged:Connect(function(_, newParent)
			if newParent then
				return
			end

			doDestroy()
		end)

		model.Destroying:Connect(doDestroy)
		animationTrack.Destroying:Connect(doDestroy)

		return animationTrack
	end

	return nil
end

function Utils.weld(part0: BasePart, part1: BasePart)
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = part0
	weld.Part1 = part1
	weld.Parent = part0

	return weld
end

local ids = 0
local reusableIds = {}

function Utils.useId()
	local targetId = ids + 1
	if targetId >= 1114111 then
		local reusableId = reusableIds[1]
		assert(reusableId, "No IDs left")

		targetId = reusableId
		table.remove(reusableIds, 1)
	end

	ids = targetId

	return utf8.char(ids), function()
		table.insert(reusableIds, targetId)
	end
end

local random = Random.new()

export type WeightedPicker<T> = (number?) -> T

function Utils.getWeights<T>(things: { [T]: number }): ({ [number]: number }, { T }, number, number)
	local n: number = 0
	local totalWeight: number = 0
	local options: { T } = {}
	local relativeWeights: { [number]: number } = {}

	for option, relativeWeight in things do
		n += 1
		totalWeight += relativeWeight

		options[n] = option
		relativeWeights[n] = relativeWeight
	end

	for i = 1, n do
		relativeWeights[i] /= totalWeight
	end

	return relativeWeights, options, n, totalWeight
end

function Utils.getMotorInitialC0(motor6D: Motor6D)
	local initialC0 = motor6D:GetAttribute("InitialC0")
	if not initialC0 then
		initialC0 = motor6D.C0
		motor6D:SetAttribute("InitialC0", initialC0)
	end

	return initialC0
end

function Utils.getModelMass(model: Model)
	if not model then
		return
	end

	local returnMass = 0
	for _, v in pairs(model:GetDescendants()) do
		if v:IsA("BasePart") then
			returnMass += v:GetMass()
		end
	end

	return returnMass
end

function Utils.getWeightedPicker<T>(things: { [T]: number }): WeightedPicker<T>
	local relativeWeights: { [number]: number }, options: { T }, n: number = Utils.getWeights(things)

	return function(picked: number?): T
		local selectedNumber: number = if picked then picked else random:NextNumber()

		for i = 1, n do
			selectedNumber -= relativeWeights[i]

			if selectedNumber < 0 then
				return options[i]
			end
		end

		return options[n]
	end,
		relativeWeights
end

function Utils.lerp<T>(start: any, goal: any, alpha: number): T
	return start + (goal - start) * alpha
end

function Utils.incrementAttribute(instance: Instance, attribute: string, value, min: number, max: number)
	if not instance or not attribute or not instance:GetAttribute(attribute) then
		return
	end

	instance:SetAttribute(
		attribute,
		math.clamp(instance:GetAttribute(attribute) + (value or 0), min or 0, max or math.huge)
	)
end

-- Properties
function Utils.checkProperty(instance, table)
	for i, v in pairs(table) do
		if instance:FindFirstChild(i) and typeof(v) == "table" then
			Utils.checkProperty(instance[i], v)
		elseif Utils.hasProperty(instance, i) then
			instance[i] = v
		end
	end
end

function Utils.hasProperty(instance, property)
	local success = pcall(function()
		return instance[property]
	end)

	if success then
		return true
	end
end

-- Time
function Utils.secondsConverter(secs, type, separeted)
	if typeof(secs) == "number" then
		if secs >= 86400 or type == "Days" then
			if separeted then
				return secs / 60 ^ 2 / 24, secs / 60 ^ 2 % 24, secs / 60 % 60, secs % 60
			else
				return string.format(
					"%02i:%02i:%02i:%02i",
					secs / 60 ^ 2 / 24,
					secs / 60 ^ 2 % 24,
					secs / 60 % 60,
					secs % 60
				)
			end
		elseif secs >= 3600 and secs < 86400 or type == "Hours" then
			if separeted then
				return secs / 60 ^ 2 % 24, secs / 60 % 60, secs % 60
			else
				return string.format("%02i:%02i:%02i", secs / 60 ^ 2 % 24, secs / 60 % 60, secs % 60)
			end
		elseif secs < 3600 then
			if separeted then
				return secs / 60 % 60, secs % 60
			else
				return string.format("%02i:%02i", secs / 60 % 60, secs % 60)
			end
		end
	end
end

function Utils.formatNumber(number: number)
	if not number then
		return
	end

	local str = tostring(number)
	local reverseString = str:reverse():gsub("(%d%d%d)", "%1."):reverse()
	return reverseString:gsub("^%.", "")
end

return Utils
