local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Packages.Knit)
local Shake = require(ReplicatedStorage.Packages.Shake)

local CharacterController = Knit.CreateController({ Name = "CharacterController" })
CharacterController.Disabled = false

function CharacterController:Created(Character)
	local Humanoid: Humanoid = Character:WaitForChild("Humanoid")

	self.Humanoid = Humanoid
	Humanoid.Died:Connect(function()
		self.Humanoid = nil
		self.Dead = true
	end)

	Humanoid.WalkSpeed = 12
	Humanoid.JumpPower = 45
end

function CharacterController:IsWater(Pos)
	local VoxelPosition = workspace.Terrain:WorldToCell(Pos)
	local VoxelRegion = Region3.new(VoxelPosition * 4, (VoxelPosition + Vector3.new(1, 1, 1)) * 4)
	local MaterialMap = workspace.Terrain:ReadVoxels(VoxelRegion, 4)
	local VoxelMaterial = MaterialMap[1][1][1]
	return VoxelMaterial == Enum.Material.Water
end

function CharacterController:SetSpeed(running)
	if self.Disabled == true then
		return
	end

	if self.Dead == false and self.Humanoid and self.MovementEnabled == true then
		if running then
			-- TODO: Bypass this if player is aiming
			TweenService:Create(self.Camera, TweenInfo.new(0.5, Enum.EasingStyle.Quad), {
				FieldOfView = 80,
			}):Play()
			TweenService:Create(self.Humanoid, TweenInfo.new(0.5, Enum.EasingStyle.Quad), {
				WalkSpeed = 50,
			}):Play()
		else
			-- TODO: Bypass this if player is aiming
			TweenService:Create(self.Humanoid, TweenInfo.new(0.5, Enum.EasingStyle.Quad), {
				WalkSpeed = 12,
			}):Play()
			TweenService:Create(self.Camera, TweenInfo.new(0.5, Enum.EasingStyle.Quad), {
				FieldOfView = 70,
			}):Play()
		end
	end
end

function CharacterController:ToggleMovement()
	if self.Disabled == true then
		return
	end

	if self.Dead == true then
		return
	end

	if self.Humanoid then
		self.MovementEnabled = not self.MovementEnabled

		self.Humanoid.WalkSpeed = self.MovementEnabled and 12 or 0
		self.Humanoid.JumpPower = self.MovementEnabled and 45 or 0

		return self.MovementEnabled
	end
end

function CharacterController:KnitStart()
	Players.LocalPlayer.CharacterAdded:Connect(function(character)
		self.Dead = false
		self:Created(character)
	end)

	self:Created(Players.LocalPlayer.Character)
end

function CharacterController:KnitInit()
	-- Essential Variables
	self.Running = false
	self.MovementEnabled = true
	self.Dead = false
	self.DrownLoop = nil
	self.Camera = workspace.CurrentCamera
end

return CharacterController
