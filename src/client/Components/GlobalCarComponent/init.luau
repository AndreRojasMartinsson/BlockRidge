--[=[
CarComponent
@date May 13, 2022
@author RootEntry 2022
@description Like the CarComponent however Global instead of Local (applies to all clients)
]=]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Component = require(ReplicatedStorage:WaitForChild("Packages").Component)

local CarComponent = Component.new({
	Tag = "ServerCar",
	Ancestors = { workspace },
})

CarComponent.RenderPriority = Enum.RenderPriority.Last.Value

function CarComponent:Construct()
	-- Modules act as independent units that control a specific sector of a car.
	self.Modules = {}
end

function CarComponent:Start()
	-- Setup Modules
	for _, v in ipairs(script:GetChildren()) do
		if v:IsA("ModuleScript") then
			local module = require(v).new(self)
			self.Modules[module.Name] = module
		end
	end
end

function CarComponent:Stop()
	for _, v in pairs(self.Modules) do
		v:Destroy()
	end
end

return CarComponent
