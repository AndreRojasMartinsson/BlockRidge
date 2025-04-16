local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local Component = require(ReplicatedStorage.Packages.Component)
local Trove = require(ReplicatedStorage.Packages.Trove)
local Knit = require(ReplicatedStorage.Packages.Knit)
local Input = require(ReplicatedStorage.Packages.Input)

local BaseTool = Component.new({
	Tag = "BaseTool",
	Extensions = {},
})

BaseTool.RenderPriority = Enum.RenderPriority.Camera.Value

function BaseTool:Construct()
	self.Trove = Trove.new()
	self.Mouse = Input.Mouse.new()
	self.Keyboard = Input.Keyboard.new()
	self.PlayerMouse = Knit.Player:GetMouse()
end

function BaseTool:RenderSteppedUpdate(dt)
	for _, v in ipairs(self.Instance:GetDescendants()) do
		if v:IsA("BasePart") then
			v.LocalTransparencyModifier = 0
		end
	end
end

function BaseTool:Start()
	local Type = self.Instance:GetAttribute("Type")
	if Type then
		if script:FindFirstChild(Type) then
			self.Class = require(script:FindFirstChild(Type)).new(self.Instance)
		end
	end
end

function BaseTool:Stop()
	if self.Class then
		self.Class:Destroy()
	end
end

return BaseTool
