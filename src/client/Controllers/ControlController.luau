local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Packages.Knit)
local Input = require(ReplicatedStorage.Packages.Input)
local Trove = require(ReplicatedStorage.Packages.Trove)

local ControlController = Knit.CreateController({ Name = "ControlController" })

function ControlController:KnitStart()
	self.Keyboard.KeyDown:Connect(function(key: Enum.KeyCode)
		if key == Enum.KeyCode.LeftShift then
			Knit.GetController("CharacterController"):SetSpeed(true)
		end
	end)

	self.Keyboard.KeyUp:Connect(function(key: Enum.KeyCode)
		if key == Enum.KeyCode.LeftShift then
			Knit.GetController("CharacterController"):SetSpeed(false)
		end
	end)
end

function ControlController:KnitInit()
	self.Keyboard = Input.Keyboard.new()
	self.Trove = Trove.new()
end

return ControlController
