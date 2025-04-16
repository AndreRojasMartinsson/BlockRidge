local DropInt = {}
DropInt.Type = "Drop"

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Knit = require(ReplicatedStorage.Packages.Knit)

local Config = require(ReplicatedStorage.Shared.Modules.Config)
local Items = Config("Items")

local DebouncePlayer = {}
function DropInt.Init()
	Players.PlayerRemoving:Connect(function(player)
		DebouncePlayer[player] = nil
	end)
end

function DropInt.Verify(Player, Part)
	local char = Player.Character
	local humanoid = char and char.Humanoid

	if char and humanoid then
		if humanoid.Health > 0 then
			if Part then
				local Id = Part.Name
				local ItemData = Items[tonumber(Id)]
				if ItemData then
					return true, { ["F"] = "Pick up " .. ItemData.Name }
				end
			end
		end
	end

	return false, {}
end

function DropInt.Execute(Player, Part, Key)
	if Key == Enum.KeyCode.F then
		local char = Player.Character
		local humanoid = char and char.Humanoid

		if char and humanoid then
			if humanoid.Health > 0 then
				local Id = Part.Name
				local ItemData = Items[tonumber(Id)]
				if ItemData then
					DebouncePlayer[Player] = DebouncePlayer[Player] or false

					if DebouncePlayer[Player] == false then
						DebouncePlayer[Player] = true

						local Encoded = Part:GetAttribute("Attributes")
						local Decoded = HttpService:JSONDecode(Encoded)

						Knit.GetService("InventoryService"):AddItem(Player, tonumber(Id), 1, Decoded or {})
						Knit.GetService("NotificationService"):SendBypass(
							{ Player },
							"Picked Up Item!",
							"You have picked up a " .. ItemData.Name .. " from the ground.",
							"rbxassetid://10345701041",
							"Info",
							8
						)
						Part:Destroy()
						task.delay(1, function()
							DebouncePlayer[Player] = false
						end)
					end
				end
			end
		end

		-- TODO ADD ATTRIBUTES TO IT TOO
	end
end

return DropInt
