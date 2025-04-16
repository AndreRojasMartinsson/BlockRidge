--[=[
Server Car
@date May 13, 2022
@author RootEntry 2022
@description Car Class for the Server Car Component
]=]
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Component = require(ReplicatedStorage:WaitForChild("Packages").Component)
local Trove = require(ReplicatedStorage:WaitForChild("Packages").Trove)
local Silo = require(ReplicatedStorage:WaitForChild("Packages").Silo)

local Knit = require(ReplicatedStorage.Packages.Knit)

local Class = {}
Class.ClassName = "ServerCar"
Class.__index = Class

function Class.new(Vehicle)
	local self = setmetatable({}, Class)
	self.Vehicle = Vehicle
	self.Trove = Trove.new()
	return self
end

function Class:HookIndicators()
	local lights = self.Vehicle.Body.Lights
	task.spawn(function()
		while true do
			local LI = lights:GetAttribute("LI")
			local RI = lights:GetAttribute("RI")
			if LI == false and RI == false then
				if lights and lights:FindFirstChild("LI") and lights:FindFirstChild("RI") then
					lights.LI.Material = Enum.Material.SmoothPlastic
					lights.RI.Material = Enum.Material.SmoothPlastic
					for _, v in ipairs(lights.LI:GetChildren()) do
						if v:IsA("Attachment") then
							v.SpotLight.Enabled = false
						end
					end
					for _, v in ipairs(lights.RI:GetChildren()) do
						if v:IsA("Attachment") then
							v.SpotLight.Enabled = false
						end
					end
					task.wait(0.8)
				end
			end

			if LI == true then
				lights.LI.Material = Enum.Material.Neon
				lights.RI.Material = Enum.Material.SmoothPlastic
				for _, v in ipairs(lights.LI:GetChildren()) do
					if v:IsA("Attachment") then
						v.SpotLight.Enabled = true
					end
				end
				for _, v in ipairs(lights.RI:GetChildren()) do
					if v:IsA("Attachment") then
						v.SpotLight.Enabled = false
					end
				end
			end
			if RI == true then
				lights.LI.Material = Enum.Material.SmoothPlastic
				lights.RI.Material = Enum.Material.Neon
				for _, v in ipairs(lights.LI:GetChildren()) do
					if v:IsA("Attachment") then
						v.SpotLight.Enabled = false
					end
				end
				for _, v in ipairs(lights.RI:GetChildren()) do
					if v:IsA("Attachment") then
						v.SpotLight.Enabled = true
					end
				end
			end
			task.wait(0.5)
			if LI == true then
				lights.LI.Material = Enum.Material.SmoothPlastic
				lights.RI.Material = Enum.Material.SmoothPlastic
				for _, v in ipairs(lights.LI:GetChildren()) do
					if v:IsA("Attachment") then
						v.SpotLight.Enabled = false
					end
				end
				for _, v in ipairs(lights.RI:GetChildren()) do
					if v:IsA("Attachment") then
						v.SpotLight.Enabled = false
					end
				end
			end
			if RI == true then
				lights.LI.Material = Enum.Material.SmoothPlastic
				lights.RI.Material = Enum.Material.SmoothPlastic
				for _, v in ipairs(lights.LI:GetChildren()) do
					if v:IsA("Attachment") then
						v.SpotLight.Enabled = false
					end
				end
				for _, v in ipairs(lights.RI:GetChildren()) do
					if v:IsA("Attachment") then
						v.SpotLight.Enabled = false
					end
				end
			end
			task.wait(0.5)
		end
	end)
end

function Class:SetLights(Light, State)
	local lightObj = self.Vehicle.Body.Lights:FindFirstChild(Light)
	if lightObj == nil then
		return
	end

	local RL = self.Vehicle.Body.Lights.RL

	RL.Material = State and Enum.Material.Neon or Enum.Material.SmoothPlastic
	RL.Transparency = State and 0.3 or 0

	for _, v in ipairs(RL:GetChildren()) do
		if v:IsA("Attachment") then
			v.SpotLight.Enabled = State
		end
	end

	lightObj.Material = State and Enum.Material.Neon or Enum.Material.SmoothPlastic
	lightObj.Transparency = State and 0.3 or 0
	for _, v in ipairs(lightObj:GetChildren()) do
		if v:IsA("Attachment") then
			v.SpotLight.Enabled = State
		end
	end
end

function Class:SetIndicator(Ind, State)
	self.Vehicle.Body.Lights:SetAttribute(Ind, State)
end

function Class:SetHorn(State)
	self.Vehicle.Essentials.Root.Horn.Playing = State
end

function Class:Destroy()
	self.Trove:Destroy()
	self.Player = nil
	self.Keyboard:Destroy()
	self = nil
end

return Class
