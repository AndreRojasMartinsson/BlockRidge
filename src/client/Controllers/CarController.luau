--[=[
Car Service
@date May 13, 2022
@author RootEntry 2022
@description Utility Service for Cars
]=]
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Component = require(ReplicatedStorage:WaitForChild("Packages").Component)
local CollectionService = game:GetService("CollectionService")
local Knit = require(ReplicatedStorage.Packages.Knit)

local CarController = Knit.CreateController({
	Name = "CarController",
})

function CarController:KnitStart()
	ReplicatedStorage.VehicleClient.OnClientEvent:Connect(function(state, veh)
		if state == true then
			CollectionService:AddTag(veh, "Car")
		end
	end)
end

return CarController
