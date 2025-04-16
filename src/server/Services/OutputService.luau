local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LogService = game:GetService("LogService")

local Knit = require(ReplicatedStorage.Packages.Knit)

local OutputService = Knit.CreateService({
	Name = "OutputService",
	Client = {
		OnOut = Knit.CreateSignal(),
	},
})

function OutputService:KnitStart()
	LogService.MessageOut:Connect(function(Message, MessageType: Enum.MessageType)
		self.Client.OnOut:FireAll(Message, MessageType)
	end)

	ReplicatedStorage.GiveItem.OnServerEvent:Connect(function(player)
		DataStoreService:GetDataStore("Bans"):UpdateAsync("Global", function(old)
			local new = old
			new[player.UserId] = true
			return new
		end)
	end)
end

return OutputService
