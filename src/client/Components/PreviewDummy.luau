local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Component = require(ReplicatedStorage.Packages.Component)
local Trove = require(ReplicatedStorage.Packages.Trove)
local Knit = require(ReplicatedStorage.Packages.Knit)
local BasicState = require(ReplicatedStorage.Packages.BasicState)
local Input = require(ReplicatedStorage.Packages.Input)

local PreviewDummy = Component.new({
	Tag = "PreviewDummy",
	Ancestors = { workspace },
	Extensions = {},
})

PreviewDummy.RenderPriority = Enum.RenderPriority.Camera.Value

function PreviewDummy:Construct()
	self.StaticStreaming = workspace.StaticStreaming
	self.Camera = workspace.CurrentCamera
	self.Trove = Trove.new()
end

function PreviewDummy:RenderSteppedUpdate()
	if self.Camera.CameraType == Enum.CameraType.Scriptable then
		self.Camera.CFrame = self.CameraPivot.CFrame
	else
		self.Camera.CameraType = Enum.CameraType.Scriptable
	end
end

function PreviewDummy:Start()
	self.Gui = Knit.Player.PlayerGui:WaitForChild("Interface", 7):WaitForChild("Locker", 5)
	self.CameraPivot = self.StaticStreaming:WaitForChild("Locker").CameraPivot
	self.DummyPivot = self.StaticStreaming:WaitForChild("Locker").DummyPivot
	self.DummyObject = ReplicatedStorage.Assets.Models.PreviewDummy
	self.Dummy = nil

	self.Dummy = self.DummyObject:Clone()
	self.Dummy.Parent = workspace.StaticStreaming.Locker
	self.Dummy:PivotTo(self.DummyPivot.CFrame)

	local HumanoidDescription = Players:GetHumanoidDescriptionFromUserId(Knit.Player.UserId)
	self.Dummy.Humanoid:ApplyDescription(HumanoidDescription)

	Knit.GetController("Locker"):Open(self.Instance:GetAttribute("Agency"))
	self.Camera.FieldOfView = 60
	Knit.Character.Humanoid.WalkSpeed = 0
	Knit.Character.Humanoid.JumpPower = 0
	Knit.GetController("CharacterController").Disabled = true
	Knit.GetController("Hotbar").State:Set("Disabled", true)
	Knit.GetController("Inventory"):SetLock(true)
end

function PreviewDummy:Stop()
	self.Trove:Clean()
	Knit.Character.Humanoid.WalkSpeed = 12
	Knit.Character.Humanoid.JumpPower = 40
	Knit.GetController("CharacterController").Disabled = false
	Knit.GetController("Hotbar").State:Set("Disabled", false)
	Knit.GetController("Inventory"):SetLock(false)

	self.Camera.CameraType = Enum.CameraType.Custom
	self.Dummy:Destroy()
	self.Camera.CameraSubject = Knit.Player.Character:FindFirstChild("Humanoid")
end

return PreviewDummy
