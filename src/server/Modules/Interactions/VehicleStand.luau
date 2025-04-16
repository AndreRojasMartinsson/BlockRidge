local VehicleStandInt = {}
VehicleStandInt.Type = "VehicleStand"

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Knit = require(ReplicatedStorage.Packages.Knit)

function VehicleStandInt.Verify(Player)
	local char = Player.Character
	local humanoid = char and char.Humanoid

	if char and humanoid then
		if humanoid.Health > 0 then
			return true, { ["F"] = "Access Dealership" }
		end
	end

	return false, {}
end

function VehicleStandInt.Init() end

function VehicleStandInt.Close(Player)
	Knit.GetService("Dealership"):Close(Player)
end

function VehicleStandInt.Execute(Player, _, Key)
	if Key == Enum.KeyCode.F then
		Knit.GetService("Dealership"):Open(Player)
	end
end

return VehicleStandInt
