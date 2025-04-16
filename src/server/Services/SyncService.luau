local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Packages.Knit)

local SyncService = Knit.CreateService({
	Name = "SyncService",
	Client = {},
})

function SyncService:GetLatency()
	return true
end

function SyncService.Client:GetLatency()
	return self.Server:GetLatency()
end

return SyncService
