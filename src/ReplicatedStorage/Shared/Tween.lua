--// Services
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--// Modules
-- local Remotes = require(ReplicatedStorage:WaitForChild("Remotes"))

local Tween = {}

function Tween.new(instance: Instance, tweenInfo: TweenInfo, change, doNotPlay: boolean)
	if not instance then
		return
	end

	local tween = TweenService:Create(instance, tweenInfo, change)

	if doNotPlay ~= false then
		tween:Play()
	end
	return tween
end

function Tween.scale(instance: Model, tweenInfo: TweenInfo, sizeAmount: number, doNotPlay, startedScale: number)
	if not instance or not instance:IsA("Model") then
		return
	end

	local numberValue = Instance.new("NumberPose")
	numberValue.Value = startedScale or instance:GetScale()

	local tween = TweenService:Create(numberValue, tweenInfo, { Value = sizeAmount })

	numberValue:GetPropertyChangedSignal("Value"):Connect(function()
		instance:ScaleTo(math.clamp(numberValue.Value, 0.001, math.huge))
	end)

	if doNotPlay ~= false then
		tween:Play()
	end

	tween.Completed:Connect(function()
		numberValue:Destroy()
		tween:Destroy()
	end)

	tween.Destroying:Connect(function()
		numberValue:Destroy()
	end)

	return tween
end

function Tween.pivot(instance: PVInstance, tweenInfo: TweenInfo, targetPivot: CFrame, doNotPlay: boolean, doNotDestroyAfterFinish: boolean)
	if not instance then
		return
	end

	local cframeValue = Instance.new("CFrameValue")
	cframeValue.Value = instance:GetPivot()
	
	local tween = TweenService:Create(cframeValue, tweenInfo, { Value = targetPivot })

	cframeValue:GetPropertyChangedSignal("Value"):Connect(function()
		instance:PivotTo(cframeValue.Value)
	end)

	if doNotPlay ~= false then
		tween:Play()
	end

	if not doNotDestroyAfterFinish then
		tween.Completed:Connect(function()
			cframeValue:Destroy()
			tween:Destroy()
		end)
	end

	tween.Destroying:Connect(function()
		cframeValue:Destroy()
	end)

	return tween
end

if RunService:IsClient() then
	-- Remotes.Tween.new.listen(function(data: table)
	-- 	Tween.new(data.instance, TweenInfo.new(unpack(data.tweenInfo)), data.changes, data.doNotPlay)
	-- end)
	-- Remotes.Tween.pivot.listen(function(data: table)
	-- 	Tween.pivot(data.instance, TweenInfo.new(unpack(data.tweenInfo)), data.cframe, data.doNotPlay)
	-- end)
	-- Remotes.Tween.scale.listen(function(data: table)
	-- 	Tween.scale(data.instance, TweenInfo.new(unpack(data.tweenInfo)), data.size, data.doNotPlay)
	-- end)
end

return Tween