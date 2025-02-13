--// Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

--// Variables
local camera: Camera = workspace.CurrentCamera
local localPlayer = Players.LocalPlayer
local packages = ReplicatedStorage.Packages
local Shared = ReplicatedStorage.Shared

--// Modules
local CameraConfig = require(script.Config)
local GuiController = require(script.Parent.GuiController)
local Spring = require(Shared.Spring)
local Utils = require(Shared.Utils)
local Trove = require(packages.Trove)
local Water = require(script.Water)

--// Frames
local mouseIcon: ScreenGui = GuiController:getScreenGui("MouseIcon")

local Camera = {
	currentCamera = nil,
}
Camera.__index = Camera

function Camera.new(cameraType: string)
	local character = localPlayer.Character or localPlayer.CharacterAdded:Wait()
	if not character then
		return
	end

	if Camera.currentCamera then
		Camera.currentCamera:destroy()
	end

	local humanoid: Humanoid = character:WaitForChild("Humanoid")
	local humanoidRootPart: Part = character:WaitForChild("HumanoidRootPart")
	local head: Part = character:WaitForChild("Head")

	if not humanoidRootPart or not head or not humanoid or humanoid.Health <= 0 then
		return
	end
	head.CanCollide = true

	local self = setmetatable({
		_trove = Trove.new(),
		cameraType = cameraType or "Default",
		lastCamera = cameraType or "Default",

		cameraTarget = nil,

		character = character,
		humanoid = humanoid,
		humanoidRootPart = humanoidRootPart,
		head = head,
		bodyTransparencyPartsData = {},

		camPos = camera.CFrame.Position,
		targetCamPos = camera.CFrame.Position,
		angleX = 0,
		angleY = 0,
		targetAngleX = 0,
		targetAngleY = 0,

		lockMouse = true,
	}, Camera)

	self._cameraTrove = self._trove:Add(Trove.new())

	self:construct()

	Camera.currentCamera = self

	return self
end

function Camera:updateLockMouse()
	local freeMouse = not self.lockMouse or self.cameraType == "LookTarget" or GuiController.inMenu

	if
		freeMouse
		and UserInputService.MouseBehavior ~= Enum.MouseBehavior.Default
		and UserInputService.MouseBehavior ~= Enum.MouseBehavior.LockCurrentPosition
	then
		UserInputService.MouseBehavior = Enum.MouseBehavior.Default
		UserInputService.MouseIconEnabled = true
		mouseIcon.Icon.Visible = false
	elseif not freeMouse and UserInputService.MouseBehavior ~= Enum.MouseBehavior.LockCenter then
		UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
		UserInputService.MouseIconEnabled = false
		mouseIcon.Icon.Visible = true
	end
end

function Camera:construct()
	-- Free mouse
	self._trove:Add(UserInputService.InputBegan:Connect(function(input, _gameProcessedEvent)
		if input.KeyCode == CameraConfig.MOUSE_UNLOCK_KEY and not GuiController.inMenu then
			self.lockMouse = false
		end
	end))

	self._trove:Add(UserInputService.InputEnded:Connect(function(input, _gameProcessedEvent)
		if input.KeyCode == CameraConfig.MOUSE_UNLOCK_KEY and self.cameraType ~= "LookTarget" then
			self.lockMouse = true
		end
	end))

	self._trove:Add(UserInputService.WindowFocused:Connect(function()
		if self.cameraType ~= "LookTarget" and not GuiController.inMenu then
			self.lockMouse = true
		end
	end))

	self:changeCameraType(self.cameraType)
end

function Camera:changeCameraType(cameraType: string)
	self.lastCamera = self.cameraType

	self._cameraTrove:Clean()

	if cameraType == "LockHead" then -- Usually for player animations
		self:lockHead()
	elseif cameraType == "LookTarget" then -- To lock camera to a target or to panoramic camera
		self:lookTarget()
	else
		self:default()
	end

	self.cameraType = cameraType
	self.lastCamera = cameraType
end

function Camera:impulseSpring(vector: Vector3)
	if vector ~= vector then
		return
	end

	local magnitude = vector.Magnitude / 0.015
	if magnitude >= 1000 then
		vector *= (1000 / magnitude)
	end

	self.bobSpring.x:SetGoal(-vector.X / 1)
	self.bobSpring.y:SetGoal(-vector.Y / 1)
end

function Camera:default()
	-- Create springs
	if not self.spring then
		self.spring = Vector3.zero --Spring.new(Vector3.zero)
		-- self.spring.Damper = 0.5
		-- self.spring.Speed = 8
	end

	if not self.bobSpring then
		self.bobSpring = {
			x = Spring.new(5, 4, 35, 0, 0.25, 0),
			y = Spring.new(5, 4, 35, 0, 0.25, 0),
		}
	end

	if not self.recoilSpring then
		self.recoilSpring = {
			x = Spring.new(6, 4.5, 50, 0, 0.25, 0),
			y = Spring.new(6, 4.5, 50, 0, 0.25, 0),
		}
	end

	if not self.moveSpring then
		self.moveSpring = {
			x = Spring.new(7, 10, 200, 0, 2, self.humanoidRootPart.Position.X),
			y = Spring.new(7, 10, 200, 0, 2, self.humanoidRootPart.Position.Y),
			z = Spring.new(7, 10, 200, 0, 2, self.humanoidRootPart.Position.Z),
		}
	end

	-- Camera movement
	self._cameraTrove:Add(UserInputService.InputChanged:Connect(function(input, gameProcessedEvent)
		if
			input.UserInputType == Enum.UserInputType.MouseMovement
			or (not gameProcessedEvent and input.UserInputType == Enum.UserInputType.Touch)
			or input.KeyCode == Enum.KeyCode.Thumbstick2
		then
			local delta = Vector2.new(input.Delta.X * 0.3, input.Delta.Y * 0.3) * (100 / 100)

			if input.KeyCode == Enum.KeyCode.Thumbstick2 then
				return
			end

			self:impulseSpring(delta)

			local X = self.targetAngleX - delta.Y
			self.targetAngleX = (X >= 40 and 40) or (X <= -80 and -80) or X
			self.targetAngleY = (self.targetAngleY - delta.X) % 360
		end
	end))

	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude

	RunService:BindToRenderStep("FirstPersonCamera", Enum.RenderPriority.Camera.Value + 1, function(deltaTime)
		if not self.humanoidRootPart or not self.humanoidRootPart.Parent then -- if there isn't HumanoidRootPart will return
			return
		end

		self.moveSpring.x:SetGoal(self.humanoidRootPart.Position.X)
		self.moveSpring.y:SetGoal(self.humanoidRootPart.Position.Y)
		self.moveSpring.z:SetGoal(self.humanoidRootPart.Position.Z)

		self:updateLockMouse()

		camera.CameraType = Enum.CameraType.Scriptable
		-- self.bobSpring.Speed = Utils.percentageBetweenRange(
		-- 	100, --(PlayerConfig.configData.SmoothCamera and PlayerConfig.configData.SmoothCamera.value) or 100,
		-- 	30,
		-- 	15
		-- )

		-- -- Console configuration
		-- if PlayerInputs.inputs.thumbstickInput ~= nil then
		-- 	local consoleDelta = Vector2.new(
		-- 		PlayerInputs.inputs.thumbstickInput.Position.X * 0.3,
		-- 		PlayerInputs.inputs.thumbstickInput.Position.Y * -1 * 0.3
		-- 	) * 12 * ((PlayerConfig.configData.MouseSensitivity and PlayerConfig.configData.MouseSensitivity.value) or 100 / 100)

		-- 	if consoleDelta.Magnitude - 0.25 < 0.3 then
		-- 		consoleDelta = Vector2.new(0, 0)
		-- 	end
		-- 	self:impulseSpring(consoleDelta.Unit * math.max(consoleDelta.Magnitude - 0.25, 0) * 1.1 * deltaTime * 60) -- 60 * deltaTime

		-- 	local X = self.targetAngleX - consoleDelta.Y
		-- 	self.targetAngleX = (X >= 80 and 80) or (X <= -80 and -80) or X
		-- 	self.targetAngleY = (self.targetAngleY - consoleDelta.X) % 360
		-- end

		-- if self.lastCamera ~= "Default" then -- Reset angles to front view camera
		-- 	self.targetAngleX = 0
		-- 	self.targetAngleY = self.humanoidRootPart.Orientation.Y
		-- end

		local _x1, y1, _z1 = camera.CFrame:ToOrientation()
		local _x2, y2, _z2 = self.humanoidRootPart.CFrame:ToOrientation()

		self.humanoidRootPart.CFrame *= CFrame.Angles(0, y1 - y2, 0)

		self.camPos += (self.targetCamPos - self.camPos) * 0.28
		self.angleX = self.angleX + (self.targetAngleX - self.angleX) * 0.35

		local dist = self.targetAngleY - self.angleY
		dist = math.abs(dist) > 180 and dist - (dist / math.abs(dist)) * 360 or dist
		self.angleY = (self.angleY + dist * 0.35) % 360

		-- moveOffsetX = self.moveSpring.x.Velocity * deltaTime + 0.5 * self.moveSpring.x.Acceleration * deltaTime ^ 2
		-- moveOffsetY = self.moveSpring.y.Velocity * deltaTime + 0.5 * self.moveSpring.y.Acceleration * deltaTime ^ 2
		-- moveOffsetZ = self.moveSpring.z.Velocity * deltaTime + 0.5 * self.moveSpring.z.Acceleration * deltaTime ^ 2

		-- print("RootPart Position:", self.humanoidRootPart.Position)
		-- print("Move Offsets:", moveOffsetX, moveOffsetY, moveOffsetZ)
		-- print("Spring Velocities:", self.moveSpring.x.Velocity, self.moveSpring.y.Velocity, self.moveSpring.z.Velocity)
		-- print(
		-- 	"Spring Accelerations:",
		-- 	self.moveSpring.x.Acceleration,
		-- 	self.moveSpring.y.Acceleration,
		-- 	self.moveSpring.z.Acceleration
		-- )
		-- print("Spring Accelerations:", self.moveSpring.x.Offset, self.moveSpring.y.Offset, self.moveSpring.z.Offset)

		local finalCF = CFrame.new(self.moveSpring.x.Offset, self.moveSpring.y.Offset, self.moveSpring.z.Offset)
			* CFrame.Angles(0, math.rad(self.angleY), 0)
			* CFrame.Angles(math.rad(self.angleX), 0, 0)
			-- * CFrame.Angles(math.rad(-20), 0, 0)
			* CFrame.new(0, 2, 10) -- Offset
			* CFrame.Angles(0, math.rad(90), 0) -- Offset
			* CFrame.Angles(
				math.rad(math.clamp(self.bobSpring.y.Offset + 0 + self.recoilSpring.y.Offset, -88, 88)),
				0,
				0
			)
			* CFrame.Angles(
				0,
				math.rad(math.clamp(self.bobSpring.x.Offset, -20, 20)),
				math.rad(math.clamp(self.bobSpring.x.Offset, -20, 20))
			)

		local head = self.head
		params.FilterDescendantsInstances = { self.character }

		local result = workspace:Raycast(head.Position, finalCF.Position - head.Position, params)
		if result ~= nil then
			local ObstructionDisplacement = (result.Position - head.Position)
			local ObstructionPosition = head.Position
				+ (ObstructionDisplacement.Unit * (ObstructionDisplacement.Magnitude - 1))
			local _x, _y, _z, r00, r01, r02, r10, r11, r12, r20, r21, r22 = finalCF:GetComponents()

			finalCF = CFrame.new(
				ObstructionPosition.x,
				ObstructionPosition.y,
				ObstructionPosition.z,
				r00,
				r01,
				r02,
				r10,
				r11,
				r12,
				r20,
				r21,
				r22
			)
		end

		camera.CFrame = finalCF
	end)

	self._cameraTrove:Add(function()
		RunService:UnbindFromRenderStep("FirstPersonCamera")

		if self.spring then
			self.spring = nil
		end
		if self.bobSpring then
			self.bobSpring = nil
		end
		if self.recoilSpring then
			self.recoilSpring = nil
		end
	end)
end

function Camera:destroy()
	if self.currentCamera == self then
		self.currentCamera = nil
	end

	self._trove:Destroy()

	setmetatable(self, nil)
	table.clear(self)
end

return Camera
