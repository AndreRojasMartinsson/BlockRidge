local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local Knit = require(ReplicatedStorage.Packages.Knit)
local Component = require(ReplicatedStorage.Packages.Component)
local BasicState = require(ReplicatedStorage.Packages.BasicState)
local Trove = require(ReplicatedStorage.Packages.Trove)

local WeaponComponent = Component.new({
	Tag = "ClientWeapon",
})

WeaponComponent.RenderPriority = Enum.RenderPriority.Input.Value

-- Local Util Functions
local Tween = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut)

local function Lerp(a, b, t)
	return a * (1 - t) + (b * t)
end

local function IsFirstPerson()
	local Cam = workspace.CurrentCamera
	local Character = Knit.Character
	local Head = Character:WaitForChild("Head")

	if (Head.CFrame.Position - Cam.CFrame.Position).Magnitude < 1 then
		return true
	else
		return false
	end
end

function WeaponComponent:Construct()
	self.Trove = Trove.new()
	self.State = BasicState.new({
		Rounds = 0,
		Equipped = false,
		Aiming = false,
		CurrentShot = 0,
		LastClick = tick(),
	})
end

function WeaponComponent:Start()
	self.Trove:Add(self.State:GetChangedSignal("Aiming"):Connect(function(new)
		if new == false then
			UserInputService.MouseIconEnabled = true
			TweenService:Create(workspace.CurrentCamera, Tween, {
				FieldOfView = 70,
			}):Play()
			--* AimTrack:Stop()
		else
			UserInputService.MouseIconEnabled = false
			TweenService:Create(workspace.CurrentCamera, Tween, {
				FieldOfView = 55,
			}):Play()
			--* AimTrack:Play()
		end
	end))

	self.Trove:Add(UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton2 then
			self.State:Set("Aiming", false)
		end
	end))

	self.Trove:Add(UserInputService.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton2 then
			if self.State:Get("Aiming") == false and IsFirstPerson() then
				self.State:Set("Aiming", true)
			end
		end
	end))

	self.Trove:Add(UserInputService.InputChanged:Connect(function()
		if IsFirstPerson() and self.State:Get("Aiming") then
			UserInputService.MouseDeltaSensitivity = 0.5
		else
			UserInputService.MouseDeltaSensitivity = 1
		end
	end))
end

function WeaponComponent:Stop() end

function WeaponComponent:RenderSteppedUpdate(dt)
	if self.State:Get("Equipped") then
		self.Instance:WaitForChild("Handle").LocalTransparencyModifier = 0
		if IsFirstPerson() then
			UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
		else
			UserInputService.MouseBehavior = Enum.MouseBehavior.Default
		end
	end
end

return WeaponComponent
