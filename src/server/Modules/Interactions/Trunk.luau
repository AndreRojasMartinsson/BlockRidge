local TrunkInt = {}
TrunkInt.Type = "Trunk"

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Knit = require(ReplicatedStorage.Packages.Knit)

local Config = require(ReplicatedStorage.Shared.Modules.Config)
local Items = Config("Items")

function TrunkInt.Verify(Player, Part)
	local char = Player.Character
	local humanoid = char and char.Humanoid

	if char and humanoid then
		if humanoid.Health > 0 then
			local Car = Part.Parent.Parent.Parent
			local OwnerId = Car:GetAttribute("Owner")

			local TitleService = Knit.GetService("TitleService")
			if TitleService:CheckPermission(Player, "CanSearch") then
				if OwnerId == Player.UserId then
					return true, { ["F"] = "Access Trunk" }
				end

				return true, { ["X"] = "Search Trunk" }
			else
				if OwnerId == Player.UserId then
					return true, { ["F"] = "Access Trunk" }
				end
			end

			if OwnerId and Player.UserId == OwnerId then
			end
		end
	end

	return false, {}
end

local DebouncePlayer = {}
function TrunkInt.Init()
	Players.PlayerRemoving:Connect(function(player)
		DebouncePlayer[player] = nil
	end)
end

function TrunkInt.Execute(Player, Part, Key)
	if Key == Enum.KeyCode.F then
		DebouncePlayer[Player] = DebouncePlayer[Player] or false

		if DebouncePlayer[Player] == false then
			DebouncePlayer[Player] = true
			Knit.GetService("VehicleService"):OpenTrunk(Player, Part.Parent.Parent.Parent:GetAttribute("UID"))

			task.delay(1, function()
				DebouncePlayer[Player] = false
			end)
		end
	end
end

return TrunkInt
