local Dispenser = {}
Dispenser.Type = "Dispenser"

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Knit = require(ReplicatedStorage.Packages.Knit)

local Config = require(ReplicatedStorage.Shared.Modules.Config)
local Items = Config("Items")

local DebouncePlayer = {}
function Dispenser.Init()
	Players.PlayerRemoving:Connect(function(player)
		DebouncePlayer[player] = nil
	end)
end

function Dispenser.Verify(Player, Part)
	local char = Player.Character
	local humanoid = char and char.Humanoid

	if not char or not humanoid then
		return false, {}
	end

	if humanoid.Health <= 0 then
		return false, {}
	end

	if not Part then
		return false, {}
	end

	local Id: IntValue = Part:FindFirstChild("Item")
	if not Id then
		return false, {}
	end

	local ItemData = Items[Id.Value]
	if not ItemData then
		return false, {}
	end

	return true, { ["F"] = "Dispense (" .. ItemData.Name .. ")" }
end

function Dispenser.Execute(Player, Part, Key)
	DebouncePlayer[Player] = DebouncePlayer[Player] or false
	if Key == Enum.KeyCode.F then
		local Id: number = Part:FindFirstChild("Item").Value
		local ItemData = Items[Id]

		if not ItemData then
			return
		end

		if DebouncePlayer[Player] == false then
			DebouncePlayer[Player] = true
			Knit.GetService("InventoryService"):AddItem(Player, Id, 1, ItemData.Attributes)
			Knit.GetService("NotificationService"):SendBypass(
				{ Player },
				"Dispensed Item!",
				"You have dispensed a " .. ItemData.Name .. ".",
				"rbxassetid://10345701041",
				"Misc",
				10
			)
			task.delay(0.5, function()
				DebouncePlayer[Player] = false
			end)
		end
	end
end

return Dispenser
