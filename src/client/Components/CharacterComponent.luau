local StarterGui = game:GetService("StarterGui")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Component = require(ReplicatedStorage:WaitForChild("Packages").Component)
local Knit = require(ReplicatedStorage.Packages.Knit)

local CharacterComponent = Component.new({
	Tag = "Character",
	Ancestors = { workspace },
})

CharacterComponent.RenderPriority = Enum.RenderPriority.Character.Value

function CharacterComponent:RenderSteppedUpdate()
	local character = Knit.Player.Character

	if character then
		for _, part in ipairs(character:GetDescendants()) do
			if part:IsA("BasePart") and (string.find(part.Name, "Leg") or string.find(part.Name, "Arm")) then
				-- Remember that LTM is a multiplier; 0-values will not force different transparency
				part.LocalTransparencyModifier = 0
			end
		end
	end
end

function CharacterComponent:Start()
	Knit.Player:WaitForChild("Cuffer", 8)
	self.newCuffAnim = Instance.new("Animation")
	self.newCuffAnim.AnimationId = "rbxassetid://10004541220"
	self.newCuffAnim.Parent = script

	self.newCuffedAnim = Instance.new("Animation")
	self.newCuffedAnim.AnimationId = "rbxassetid://10004536027"
	self.newCuffedAnim.Parent = script

	local humanoid = self.Instance:WaitForChild("Humanoid")

	self.CuffTrack = humanoid:LoadAnimation(self.newCuffAnim)
	self.CuffedTrack = humanoid:LoadAnimation(self.newCuffedAnim)

	Knit.Player.Cuffer:GetPropertyChangedSignal("Value"):Connect(function()
		if Knit.Player.Cuffer.Value ~= nil then
			self.CuffTrack:Play()
			StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)
		else
			self.CuffTrack:Stop()
			StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, true)
		end
	end)

	Knit.Player.Grabbing:GetPropertyChangedSignal("Value"):Connect(function()
		if Knit.Player.Grabbing.Value ~= nil then
			self.CuffedTrack:Play()
		else
			self.CuffedTrack:Stop()
		end
	end)
end

function CharacterComponent:Destroy() end

return CharacterComponent
