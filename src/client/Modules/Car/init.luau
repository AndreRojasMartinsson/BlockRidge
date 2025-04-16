--[=[
Car
@date May 13, 2022
@author RootEntry 2022
@description Car Class for the Client Car Component
]=]
local ContextActionService = game:GetService("ContextActionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Component = require(ReplicatedStorage:WaitForChild("Packages").Component)
local Trove = require(ReplicatedStorage:WaitForChild("Packages").Trove)
local Silo = require(ReplicatedStorage:WaitForChild("Packages").Silo)

local Knit = require(ReplicatedStorage.Packages.Knit)

local Class = {}
Class.ClassName = "Car"
Class.__index = Class

function Class.new(Player, Vehicle, Keyboard, _Component)
	local self = setmetatable({}, Class)
	self.Player = Player
	self.Vehicle = Vehicle
	self.Component = _Component
	self.Controls = {}
	self.Keyboard = Keyboard
	self.CarService = Knit.GetService("CarService")
	self.Trove = Trove.new()

	self.Headlight = false
	self.Park = false
	self.Horn = false
	self.Gear = self.Vehicle.Essentials.Root:GetAttribute("Gear")
	self.RI = false
	self.LI = false
	self.Cruise = false

	-- ALPR
	self.ALPR_Rot = 0
	self.Rotating = 0
	self.TickCycle = tick()

	return self
end

function Class:LoadControls()
	for _, v in ipairs(script:GetChildren()) do
		require(v)(self)
	end
end

function Class:SetHeadlight(State)
	self.Headlight = State
	self.CarService:SetLights(self.Vehicle, "HL", State)
end

function Class:SetPark(State)
	self.Park = State
	self.CarService:SetPark(self.Vehicle, State)
end

function Class:SetCruise(State)
	self.Cruise = State
	self.CarService:SetCruise(self.Vehicle, State)
end

function Class:ChangeGear(Up)
	self.CarService:ChangeGear(self.Vehicle, Up)
end

function Class:SetIndicator(Ind, State)
	if Ind == "LI" then
		self.LI = State
	elseif Ind == "RI" then
		self.RI = State
	end

	self.CarService:SetIndicator(self.Vehicle, Ind, State)
end

function Class:RotateCone(inc)
	if inc == -1 then
		self.Rotating = -1
	elseif inc == 1 then
		self.Rotating = 1
	else
		self.Rotating = 0
	end
end

function Class:ToggleHorn(dat)
	self.Horn = dat
	self.CarService:SetHorn(self.Vehicle, dat)
end

function Class:Destroy()
	self.Trove:Destroy()
	self.Player = nil
	self.Keyboard:Destroy()
	self.Controls = {}
	self = nil
end

return Class
