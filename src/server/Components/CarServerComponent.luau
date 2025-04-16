--[=[
CarServerComponent
@date May 13, 2022
@author RootEntry 2022
@description Server Component for Cars in Lockridge.
]=]
local Players = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Component = require(ReplicatedStorage:WaitForChild("Packages").Component)
local Trove = require(ReplicatedStorage:WaitForChild("Packages").Trove)
local Knit = require(ReplicatedStorage.Packages.Knit)
local Config = require(ReplicatedStorage.Shared.Modules.Config)
local Vehicles = Config("Vehicles")

local CarClass = require(script.Parent.Parent.Modules.ServerCar)

local CarComponent = Component.new({
	Tag = "ServerCar",
	Ancestors = { workspace },
})

local function OnGearChange(self)
	if self.VehicleSeat.Throttle == 0 then
		self.GasTick = self.GasTick and tick()
	end
end

local function OnFloatChange(self)
	local float = self.VehicleSeat.ThrottleFloat
	if float > 0 then
		if not self.GasTick then
			self.GasTick = tick()
		end
	else
		self.GasTick = nil
	end
end

function CarComponent:SetupWelds()
	local SeatWeld = Instance.new("WeldConstraint")
	SeatWeld.Part0 = self.Root
	SeatWeld.Part1 = self.VehicleSeat
	SeatWeld.Parent = self.Root:WaitForChild("Welds")

	for _, v in ipairs(self.Instance:GetDescendants()) do
		if v.Name == "Holder" and v:IsDescendantOf(self.Wheels) then
			local Weld = Instance.new("WeldConstraint")
			Weld.Part0 = self.Root
			Weld.Part1 = v
			Weld.Parent = self.Root:WaitForChild("Welds")
		end

		if v:IsA("BasePart") and v:IsDescendantOf(self.Instance:WaitForChild("Body")) then
			local Weld = Instance.new("WeldConstraint")
			Weld.Part0 = self.Root
			Weld.Part1 = v
			Weld.Parent = self.Root

			v.Massless = true
		end

		if v.Parent.Name == "Wheel" and v:IsA("BasePart") then
			local Weld = Instance.new("WeldConstraint")
			Weld.Part0 = v.Parent
			Weld.Part1 = v
			Weld.Parent = self.Root:WaitForChild("Welds")

			v.CanCollide = false
			v.Massless = true
		end

		if v:IsA("BasePart") then
			v.Anchored = false
		end
	end
end

function CarComponent:ChildAdded(child)
	if not self.Active and child.Name == "SeatWeld" then
		self.Player = Players:GetPlayerFromCharacter(child.Part1.Parent)
		if self.Player then
			self.Active = true

			ReplicatedStorage.VehicleClient:FireClient(self.Player, true, self.Instance)

			self.Root.Engine.Playing = true
			self.Root.Wind.Playing = true
			self.Root.Gravel.Playing = true

			local char = child.Part1.Parent
			for _, idx in ipairs(char:GetChildren()) do
				if idx:IsA("Accessory") then
					idx.Handle.Transparency = 1
				end
			end

			self._seats[self.VehicleSeat] = char

			for _, v in ipairs(self.Instance:GetDescendants()) do
				if v:IsA("BasePart") then
					v:SetNetworkOwner(self.Player)
				end
			end
		end
	end
end

function CarComponent:ChildRemoved(child)
	if self.Active and child.Name == "SeatWeld" then
		self.Active = false
		ReplicatedStorage.VehicleClient:FireClient(self.Player, false, self.Instance)
		self.Player = nil

		self.Root.Engine.Playing = false
		self.Root.Wind.Playing = false
		self.Root.Gravel.Playing = false

		for k, vall in pairs(self._seats) do
			if k == self.VehicleSeat then
				local char = vall
				for _, idx in ipairs(char:GetChildren()) do
					if idx:IsA("Accessory") then
						idx.Handle.Transparency = 0
					end
				end

				self._seats[k] = nil
			end
		end

		for _, v in ipairs(self.Instance:GetDescendants()) do
			if v:IsA("BasePart") then
				v:SetNetworkOwner(nil)
			end
		end
	end
end

function CarComponent:HeartbeatUpdate(dT)
	local currentTick = tick()
	for _, v in ipairs(self.Constraints:GetChildren()) do
		if v:IsA("HingeConstraint") then
			v.MotorMaxTorque = self.ClassTable.Torque
			v.AngularSpeed = self.ClassTable.TurnSpeed
		elseif v:IsA("SpringConstraint") then
			v.FreeLength = self.ClassTable.Height
		elseif v:IsA("PrismaticConstraint") then
			v.UpperLimit = -self.ClassTable.Height
		end
	end

	local Throttle = self.VehicleSeat.ThrottleFloat
	local Speed = self.Wheels.FL.Wheel.AssemblyLinearVelocity.Magnitude
	local HandbrakeOn = self.Root:GetAttribute("Handbrake")

	local engineSpeed = self.Root.Engine.PlaybackSpeed
	local gearTopSpeed = math.abs(self.ClassTable.Gears[self.Root:GetAttribute("Gear") + 2])
	-- Multiply by 0.681818 to convert from SPS to MPH
	local speedPercent = math.clamp(Speed * 0.681818 / gearTopSpeed, 0.2, 1)

	if self.GasTick then
		engineSpeed = 0.8
			+ math.clamp((currentTick - self.GasTick) / 2, 0, 1)
				* (self.Root:GetAttribute("Gear") ~= 0 and speedPercent / 3 or 1)
	else
		engineSpeed = engineSpeed * 0.99
	end

	if self.Root:GetAttribute("Gear") == 0 then
		self.LERP_DELTA = 1.7
	else
		self.LERP_DELTA = 0.3
	end

	local targetSpeed = math.clamp(engineSpeed, 0.8, 2)
	local targetVol = math.clamp(0.3 + engineSpeed / 1.2, 0.3, 2)
	self.Root.Engine.PlaybackSpeed = self.Root.Engine.PlaybackSpeed
		+ self.LERP_DELTA * (targetSpeed - self.Root.Engine.PlaybackSpeed)
	self.Root.Engine.Volume = self.Root.Engine.Volume + self.LERP_DELTA * (targetSpeed - self.Root.Engine.Volume)
	self.Root.Wind.Volume = math.clamp(Speed / 70, 0.1, 4)
	self.Root.Gravel.Volume = math.clamp(Speed / 20, 0, 0.9)

	local CurrentFuel = self.Root:GetAttribute("Fuel")
	if CurrentFuel <= 0 then
		return
	end

	if self.Root:GetAttribute("Gear") == -1 then
		self.Body.Lights.RVL.Material = Enum.Material.Neon
		for _, v in ipairs(self.Body.Lights.RVL:GetChildren()) do
			v.SpotLight.Enabled = true
		end
	else
		self.Body.Lights.RVL.Material = Enum.Material.SmoothPlastic
		for _, v in ipairs(self.Body.Lights.RVL:GetChildren()) do
			v.SpotLight.Enabled = false
		end
	end

	if Throttle == 1 or Throttle == -1 then -- Ensure it wont consume fuel while driving
		local BurnRate = (Speed / 100) * dT

		self.Root:SetAttribute("Fuel", math.clamp(CurrentFuel - BurnRate, 0, math.huge))
	end

	if HandbrakeOn then
		if Speed > 3 then
			local Multiplier = 1
			if Throttle == 1 then
				Multiplier = 1.8
			else
				Multiplier = 1
			end

			for _, v in pairs(self.Constraints:GetChildren()) do
				if v:IsA("HingeConstraint") then
					if v.Attachment1.Parent.Name == "Wheel" then
						v.Attachment1.Parent.Parent.Axel.Attachment.ParticleEmitter.Enabled = true
						v.Attachment1.Parent.Parent.Axel.BrakeTrail.Enabled = true
					end
				end
			end
		else
			for _, v in pairs(self.Constraints:GetChildren()) do
				if v:IsA("HingeConstraint") then
					if v.Attachment1.Parent.Name == "Wheel" then
						v.Attachment1.Parent.Parent.Axel.Attachment.ParticleEmitter.Enabled = false
						v.Attachment1.Parent.Parent.Axel.BrakeTrail.Enabled = false
					end
				end
			end
		end
	else
		for _, v in pairs(self.Constraints:GetChildren()) do
			if v:IsA("HingeConstraint") then
				if v.Attachment1.Parent.Name == "Wheel" then
					v.Attachment1.Parent.Parent.Axel.Attachment.ParticleEmitter.Enabled = false
					v.Attachment1.Parent.Parent.Axel.BrakeTrail.Enabled = false
				end
			end
		end
	end
end

function CarComponent:Start()
	self.Instance:WaitForChild("Body", 8)
	self.Instance:WaitForChild("Essentials", 8)
	-- Vehicle Object Constants
	self.Essentials = self.Instance:WaitForChild("Essentials")
	self.Body = self.Instance:WaitForChild("Body")
	self.Root = self.Essentials:WaitForChild("Root")
	self.VehicleSeat = self.Essentials:WaitForChild("Drive")
	self.Wheels = self.Essentials:WaitForChild("Wheels")
	self.Constraints = self.Essentials:WaitForChild("Constraints")
	self.Active = false
	self.Player = nil
	self.FirstTimeRan = false
	self.GasTick = nil
	self.Trove = Trove.new()
	self.Class = CarClass.new(self.Instance)
	self.Class:HookIndicators()
	self.LERP_DATA = 0.2
	self.TiresBroken = {}
	--[[
	self.Seats = {
		FL = { self.VehicleSeat, false, nil },
		FR = { self.Body:WaitForChild("FR"), false, nil },
		RR = { self.Body:WaitForChild("RR"), false, nil },
		RL = { self.Body:WaitForChild("RL"), false, nil },
	}
	]]
	self.ClassTable = Vehicles[self.Instance.Name]

	self:SetupWelds()
	self.VehicleSeat.ChildAdded:Connect(function(child)
		self:ChildAdded(child)
	end)
	self.VehicleSeat.ChildRemoved:Connect(function(child)
		self:ChildRemoved(child)
	end)
	self.Root:GetAttributeChangedSignal("BrokenTires"):Connect(function()
		self.TiresBroken = string.split(self.Root:GetAttribute("BrokenTires"), ",")
	end)
	self.Root:GetAttributeChangedSignal("Gear"):Connect(function()
		OnGearChange(self)
	end)
	self.VehicleSeat:GetPropertyChangedSignal("ThrottleFloat"):Connect(function()
		OnFloatChange(self)
	end)

	self._seats = {}

	if self.Instance and self.Instance.Body then
		for _, v in ipairs(self.Instance.Body:GetDescendants()) do
			if v:IsA("Seat") then
				v.ChildAdded:Connect(function(c)
					if c.Name == "SeatWeld" then
						local _trgtPlayer = Players:GetPlayerFromCharacter(c.Part1.Parent)
						if _trgtPlayer then
							local char = c.Part1.Parent
							for _, idx in char:GetChildren() do
								if idx:IsA("Accessory") then
									idx.Handle.Transparency = 1
								end
							end

							self._seats[v] = char
						end
					end
				end)

				v.ChildRemoved:Connect(function(c)
					if c.Name == "SeatWeld" then
						for k, vall in pairs(self._seats) do
							if k == v then
								local char = vall
								for _, idx in char:GetChildren() do
									if idx:IsA("Accessory") then
										idx.Handle.Transparency = 0
									end
								end

								self._seats[k] = nil
							end
						end
					end
				end)
			end
		end
	end

	OnFloatChange(self)

	for _, v in ipairs(self.Instance:GetDescendants()) do
		if v:IsA("BasePart") then
			CollectionService:AddTag(v, "IgnoreCamera")
		end
	end
end

function CarComponent:Destroy()
	ReplicatedStorage.VehicleClient:FireClient(self.Player, false, self.Instance)
end

return CarComponent
