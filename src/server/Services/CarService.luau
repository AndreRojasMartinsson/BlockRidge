--[=[
Car Service
@date May 13, 2022
@author RootEntry 2022
@description Utility Service for Cars
]=]
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Component = require(ReplicatedStorage:WaitForChild("Packages").Component)
local CarComponent = require(script.Parent.Parent.Components.CarServerComponent)
local Knit = require(ReplicatedStorage.Packages.Knit)

local Config = require(ReplicatedStorage.Shared.Modules.Config)
local Vehicles = Config("Vehicles")

local CarService = Knit.CreateService({
	Name = "CarService",
	Client = {},
})

function CarService:SetLights(Player, Vehicle, Light, State)
	local Character = Player.Character
	if not Character then
		return
	end

	local Humanoid = Character:FindFirstChild("Humanoid")
	if not Humanoid then
		return
	end

	local Essentials = Vehicle.Essentials
	if not Essentials then
		return
	end

	local DriveSeat = Vehicle.Essentials.Drive
	if not DriveSeat then
		return
	end

	if Humanoid.SeatPart ~= DriveSeat then
		return
	end

	local VehicleComponent = CarComponent:FromInstance(Vehicle)
	if not VehicleComponent then
		return
	end

	VehicleComponent.Class:SetLights(Light, State)
end

function CarService.Client:SetLights(Player, Vehicle, Light, State)
	return self.Server:SetLights(Player, Vehicle, Light, State)
end

function CarService:SetHorn(Player, Vehicle, State)
	local Character = Player.Character
	if Character == nil then
		return
	end

	local Humanoid = Character:FindFirstChild("Humanoid")
	if Humanoid == nil then
		return
	end

	if Vehicle == nil then
		return
	end

	local Essentials = Vehicle:FindFirstChild("Essentials")
	if Essentials == nil then
		return
	end

	local DriveSeat = Vehicle.Essentials.Drive
	if DriveSeat == nil then
		return
	end

	if Humanoid.SeatPart ~= DriveSeat then
		return
	end

	local VehicleComponent = CarComponent:FromInstance(Vehicle)
	if not VehicleComponent then
		return
	end

	VehicleComponent.Class:SetHorn(State)
end

function CarService.Client:SetHorn(Player, Vehicle, State)
	return self.Server:SetHorn(Player, Vehicle, State)
end

function CarService:SetIndicator(Player, Vehicle, Ind, State)
	local Character = Player.Character
	if Character == nil then
		return
	end

	local Humanoid = Character:FindFirstChild("Humanoid")
	if Humanoid == nil then
		return
	end

	if Vehicle == nil then
		return
	end

	local Essentials = Vehicle:FindFirstChild("Essentials")
	if Essentials == nil then
		return
	end

	local DriveSeat = Vehicle.Essentials.Drive
	if DriveSeat == nil then
		return
	end

	if Humanoid.SeatPart ~= DriveSeat then
		return
	end

	local VehicleComponent = CarComponent:FromInstance(Vehicle)
	if not VehicleComponent then
		return
	end

	VehicleComponent.Class:SetIndicator(Ind, State)
end

function CarService.Client:SetIndicator(Player, Vehicle, Ind, State)
	return self.Server:SetIndicator(Player, Vehicle, Ind, State)
end

function CarService:ChangeGear(Player, Vehicle, Up)
	local Character = Player.Character
	if Character == nil then
		return
	end

	local Humanoid = Character:FindFirstChild("Humanoid")
	if Humanoid == nil then
		return
	end

	if Vehicle == nil then
		return
	end

	local Essentials = Vehicle:FindFirstChild("Essentials")
	if Essentials == nil then
		return
	end

	local DriveSeat = Vehicle.Essentials.Drive
	if DriveSeat == nil then
		return
	end

	if Humanoid.SeatPart ~= DriveSeat then
		return
	end

	local VehicleComponent = CarComponent:FromInstance(Vehicle)
	if not VehicleComponent then
		return
	end

	local oldGear = Vehicle.Essentials.Root:GetAttribute("Gear")
	local increment = Up and 1 or -1
	local newGear = oldGear + increment

	Vehicle.Essentials.Root:SetAttribute("Gear", math.clamp(newGear, -1, 4))
end

function CarService.Client:ChangeGear(Player, Vehicle, Up)
	return self.Server:ChangeGear(Player, Vehicle, Up)
end

function CarService:SetPark(Player, Vehicle, State)
	local Character = Player.Character
	if not Character then
		return
	end

	local Humanoid = Character:FindFirstChild("Humanoid")
	if not Humanoid then
		return
	end

	local Essentials = Vehicle.Essentials
	if not Essentials then
		return
	end

	local DriveSeat = Vehicle.Essentials.Drive
	if not DriveSeat then
		return
	end

	if Humanoid.SeatPart ~= DriveSeat then
		return
	end

	local VehicleComponent = CarComponent:FromInstance(Vehicle)
	if not VehicleComponent then
		return
	end

	Vehicle.Essentials.Root:SetAttribute("Handbrake", State)
end

function CarService.Client:SetPark(Player, Vehicle, State)
	return self.Server:SetPark(Player, Vehicle, State)
end

function CarService:SetCruise(Player, Vehicle, State)
	local Character = Player.Character
	if not Character then
		return
	end

	local Humanoid = Character:FindFirstChild("Humanoid")
	if not Humanoid then
		return
	end

	local Essentials = Vehicle.Essentials
	if not Essentials then
		return
	end

	local DriveSeat = Vehicle.Essentials.Drive
	if not DriveSeat then
		return
	end

	if Humanoid.SeatPart ~= DriveSeat then
		return
	end

	local VehicleComponent = CarComponent:FromInstance(Vehicle)
	if not VehicleComponent then
		return
	end

	Vehicle.Essentials.Root:SetAttribute("Cruise", State)
	Vehicle.Essentials.Root:SetAttribute("CruiseSpeed", Vehicle.Essentials.Root.AssemblyLinearVelocity.Magnitude)
end

function CarService.Client:SetCruise(Player, Vehicle, State)
	return self.Server:SetCruise(Player, Vehicle, State)
end

local function validate(Player)
	local Char = Player.Character
	if Char == nil then
	end

	local Humanoid = Char:FindFirstChildOfClass("Humanoid")
	if Humanoid == nil then
	end

	local SeatPart = Humanoid.SeatPart
	if SeatPart == nil then
	end

	if SeatPart:IsA("VehicleSeat") and SeatPart.Name == "Drive" then
		local ClassTable = Vehicles[SeatPart.Parent.Parent.Name]
		if ClassTable then
			if ClassTable.ELS then
				return { true, SeatPart.Parent.Parent }
			else
			end
		end
	end
end

function CarService:KnitStart() end

return CarService
