--// Modules
local Tween = require(script.Parent.Tween)
local Utils = require(script.Parent.Utils)

return function(frame, progress, attributes)
	local Right = frame:FindFirstChild("Right")
	local Left = frame:FindFirstChild("Left")
	if Right and Left then
		if typeof(progress) ~= "number" then
			return
		end

		attributes = attributes or {}
		local style = Enum.EasingStyle.Linear
		local direction = Enum.EasingDirection.Out

		local allProgress = progress * 360
		if progress <= 0.5 then
			if attributes.duration == 0 then
				Left.Progress.UIGradient.Rotation = -180
			else
				if attributes.resetAfter then
					Right.Progress.UIGradient.Rotation = 0
					Left.Progress.UIGradient.Rotation = -180
				end

				Tween.new(
					Right.Progress.UIGradient,
					TweenInfo.new(
						attributes.duration or 0.5,
						attributes.style or style,
						attributes.direction or direction
					),
					{
						Rotation = math.clamp(allProgress, 0, 180),
					}
				)
			end
		elseif progress > 0.5 then
			if attributes.duration == 0 then
				Right.Progress.UIGradient.Rotation = 180
				Left.Progress.UIGradient.Rotation = math.clamp(allProgress - 360, -180, 0)
			else
				if attributes.resetAfter then
					Right.Progress.UIGradient.Rotation = 0
					Left.Progress.UIGradient.Rotation = -180
				end

				local previousProgressTime =
					Utils.percentageBetweenRange(180, 0, attributes.duration or 0.5, allProgress)
				Tween.new(
					Right.Progress.UIGradient,
					TweenInfo.new(previousProgressTime, attributes.style or style, attributes.direction or direction),
					{
						Rotation = 180,
					}
				)
				task.wait(previousProgressTime)

				local nowProgressTime =
					Utils.percentageBetweenRange((allProgress - 180), 0, attributes.duration or 0.5, allProgress)
				print(nowProgressTime, previousProgressTime)
				Tween.new(
					Left.Progress.UIGradient,
					TweenInfo.new(nowProgressTime, attributes.style or style, attributes.direction or direction),
					{
						Rotation = math.clamp(allProgress - 360, -180, 0),
					}
				)
			end
		end
	end
end
