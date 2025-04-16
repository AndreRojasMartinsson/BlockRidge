local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Packages.Knit)

local OverrideService = Knit.CreateService({
	Name = "OverrideService",
	Client = {},
})

function OverrideService:Override(Player, Target)
	if Player and Target then
		if Target:IsA("Player") then
			local Data = Knit.GetService("InventoryService"):GetData(Target)
			if Data then
				local ret = ReplicatedStorage.ConsentOverride:InvokeClient(Player, Target)
				if ret == true then
					ReplicatedStorage.Search:FireClient(Player, Target, Data)
					Knit.GetService("NotificationService"):SendBypass(
						{ Target },
						"Search Overriden!",
						Player.Name .. " has overriden your search.",
						"rbxassetid://10342716476",
						"Alert",
						40
					)
				end
			end
		end
	end
end

return OverrideService
