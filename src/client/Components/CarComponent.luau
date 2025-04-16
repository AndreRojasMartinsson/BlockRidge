--[=[
CarComponent
@date May 13, 2022
@author RootEntry 2022
@description Client Component for Cars in Lockridge.
]=]
local CollectionService = game:GetService("CollectionService")
local TweenService = game:GetService("TweenService")
local ContextActionService = game:GetService("ContextActionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Component = require(ReplicatedStorage:WaitForChild("Packages").Component)
local PID = require(ReplicatedStorage:WaitForChild("Packages").PID)
local Promise = require(ReplicatedStorage:WaitForChild("Packages").Promise)

local Trove = require(ReplicatedStorage:WaitForChild("Packages").Trove)
local Keyboard = require(ReplicatedStorage:WaitForChild("Packages").Input).Keyboard
local Silo = require(ReplicatedStorage:WaitForChild("Packages").Silo)

local Knit = require(ReplicatedStorage.Packages.Knit)
local Config = require(ReplicatedStorage.Shared.Modules.Config)
local Vehicles = Config("Vehicles")
local CarClass = require(script.Parent.Parent.Modules.Car)

local CarComponent = Component.new({
	Tag = "Car",
	Ancestors = { workspace },
})

CarComponent.RenderPriority = Enum.RenderPriority.Input.Value

local tan, arctan = math.tan, math.atan

function CarComponent:Start()
	ReplicatedStorage.VehicleClient.OnClientEvent:Connect(function(state, veh)
		if state == false then
			CollectionService:RemoveTag(veh, "Car")
		end
	end)

	self.MPH_Multiplier = 0.681818
	self.WheelBase = 10.793
	self.TrackWidth = 5
	self.SteeringRatio = 15 / 1

	self.Keyboard = Keyboard.new()
	self.SteeringMultiplier = 40
	self.Trove = Trove.new()
	self.StartingAngle = -90
	self.VirtualWheelAngle = 30 / self.SteeringRatio
	self.LeftWheel_Angle = 0

	self.Class = CarClass.new(Knit.Player, self.Instance, self.Keyboard, CarComponent)

	self.RightWheel_Angle = 0
	self.StartT = tick()
	self.Switch = false
	self.CruisePID = PID.new(0, 1, 0.1, 0, 0)
	self.Camera = workspace.CurrentCamera
	self.LastY = 0
	self.Detection = false
	self.BrakeDuration = 0
	self.Humanoid = Knit.Player.Character:WaitForChild("Humanoid")
	self.BrakeStart = tick()
	self.ClassTable = Vehicles[self.Instance.Name]

	local Gui = ReplicatedStorage.Assets.GUI.RoundMeter:Clone()
	Gui.Model.Value = self.Instance
	Gui.Handler.Disabled = false
	Gui.Parent = Knit.Player.PlayerGui
	self.Gui = Gui

	for _, v in ipairs(self.Instance:GetDescendants()) do
		if v:IsA("BasePart") then
			CollectionService:AddTag(v, "IgnoreCamera")
		end
	end

	self.Class:LoadControls()

	-- Vehicle Object Constants
	self.Essentials = self.Instance:WaitForChild("Essentials")
	self.Root = self.Essentials:WaitForChild("Root")
	self._vehRunning = true
	self.Body = self.Instance:WaitForChild("Body")
	self.VehicleSeat = self.Essentials:WaitForChild("Drive")
	self.Wheels = self.Essentials:WaitForChild("Wheels")
	self.Constraints = self.Essentials:WaitForChild("Constraints")
end

function CarComponent:RenderSteppedUpdate()
	if self.Humanoid.SeatPart == self.VehicleSeat and self.Humanoid.Health > 0 then
		-- Cruise cOntrol
		if self.Root:GetAttribute("Cruise") == true then
			local currentCarSpeed = self.Root.AssemblyLinearVelocity.Magnitude
			local desiredSpeed = self.Root:GetAttribute("CruiseSpeed")
			local calculatedThrottle = self.CruisePID:Calculate(desiredSpeed, currentCarSpeed)
			self.VehicleSeat.ThrottleFloat = calculatedThrottle
		end

		-- TODO: Implement Silo to utilize it's state
		local CurrentFuel = self.Root:GetAttribute("Fuel")
		local Handbrake = self.Root:GetAttribute("Handbrake")
		local Gear = self.Root:GetAttribute("Gear")
		local GearTable = self.ClassTable.Gears[Gear + 2]
		local Throttle = self.VehicleSeat.ThrottleFloat
		local Steer = self.VehicleSeat.SteerFloat
		local VirtualWheelAngle = 30 / self.ClassTable.SteeringRatio

		for _, v in ipairs(self.Constraints:GetChildren()) do
			if v:IsA("HingeConstraint") then
				self.LeftWheel_Angle = -(
					self.ClassTable.StartingAngle
					- (
						arctan(
							(self.ClassTable.WheelBase * tan(VirtualWheelAngle))
								/ (
									self.ClassTable.WheelBase
									- 0.5 * self.ClassTable.TrackWidth * tan(VirtualWheelAngle)
								)
						) * self.ClassTable.SteeringMultiplier
					)
				)
				self.RightWheel_Angle = -(
					self.ClassTable.StartingAngle
					- (
						arctan(
							(self.ClassTable.WheelBase * tan(VirtualWheelAngle))
								/ (
									self.ClassTable.WheelBase
									+ 0.5 * self.ClassTable.TrackWidth * tan(VirtualWheelAngle)
								)
						) * self.ClassTable.SteeringMultiplier
					)
				)

				if v.Attachment1.Parent.Parent.Name == "FL" then
					v.TargetAngle = self.LeftWheel_Angle * -Steer
				else
					v.TargetAngle = self.RightWheel_Angle * -Steer
				end

				if Handbrake then
					if v.Attachment1.Parent.Parent.Name == "RL" or v.Attachment1.Parent.Parent.Name == "RR" then
						-- ABS Algorithm
						v.AngularVelocity = 0
						v.MotorMaxAcceleration = self.ClassTable.BrakeAcceleration * 3
						v.MotorMaxTorque = self.ClassTable.Torque * 2

						if tick() - self.StartT > 0.055 then
							v.AngularVelocity = 0
							v.MotorMaxAcceleration = 10 * 500
							v.MotorMaxTorque = 1500 * 5
							self.StartT = tick()
						end

						if v.Attachment1.Parent.Name == "Wheel" then
							v.Attachment1.Parent.CustomPhysicalProperties = PhysicalProperties.new(1.572, 0.6, 0, 1, 1)
						end
					else
						if Gear ~= 0 and Throttle ~= 0 then
							if Throttle > 0 and math.floor(CurrentFuel) > 0 then
								local torque = self.ClassTable.Gears[3] / math.abs(GearTable) * self.ClassTable.Torque
								v.MotorMaxTorque = torque / 50

								v.AngularVelocity = -(
									GearTable
									/ (self.Wheels.FL.Wheel.Size.Y / 2)
									/ self.MPH_Multiplier
								)
								v.MotorMaxAcceleration = (Throttle * self.ClassTable.Acceleration) / 50
							end
						end
					end
				else
					if v.Attachment1.Parent.Name == "Wheel" then
						v.Attachment1.Parent.CustomPhysicalProperties = PhysicalProperties.new(1.572, 1, 0, 1, 1)
					end

					if Gear ~= 0 and Throttle ~= 0 then
						if Throttle > 0 and math.floor(CurrentFuel) > 0 and Handbrake == false then
							local torque = self.ClassTable.Gears[3] / math.abs(GearTable) * self.ClassTable.Torque

							v.MotorMaxTorque = torque / 4
							v.AngularVelocity = -(GearTable / (self.Wheels.FL.Wheel.Size.Y / 2) / self.MPH_Multiplier)
							v.MotorMaxAcceleration = Throttle * self.ClassTable.Acceleration
						elseif Throttle < 0 then
							v.AngularVelocity = 0
							v.MotorMaxAcceleration = -Throttle * self.ClassTable.BrakeAcceleration
							v.MotorMaxTorque = 230_000
						end
					else
						v.AngularVelocity = 0
						v.MotorMaxAcceleration = 3
						v.MotorMaxTorque = 1_000
					end
				end
			end
		end
	end
end

function CarComponent:Stop()
	self.Keyboard:Destroy()
	self.Gui:Destroy()
	self.Trove:Destroy()

	for _, v in ipairs(self.Instance:GetDescendants()) do
		if v:IsA("BasePart") then
			CollectionService:RemoveTag(v, "IgnoreCamera")
		end
	end
end

return CarComponent
