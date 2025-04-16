local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")

local Knit = require(ReplicatedStorage.Packages.Knit)
local promise = require(ReplicatedStorage.Packages.Promise)
local concur = require(ReplicatedStorage.Packages.Concur)

Knit.ComponentsLoaded = false
Knit.Player = Players.LocalPlayer
Knit.Character = Knit.Player.Character or Knit.Player.CharacterAdded:Wait()
Knit.Shared = ReplicatedStorage:WaitForChild("Shared")
Knit.OnComponentsLoaded = function()
	return promise.new(function(resolve)
		if Knit.ComponentsLoaded then
			resolve()
		end

		local c = concur.spawn(function()
			while true do
				if Knit.ComponentsLoaded then
					break
				end

				task.wait()
			end
		end)

		c:OnCompleted(function(err, msg)
			if err then
				warn(err)
			end
			resolve()
		end)
	end)
end

-- Recursively load modules unless its inside of a module.
local function loadModules(Parent)
	for _, v in ipairs(Parent:GetChildren()) do
		if v:IsA("Folder") then
			loadModules(v)
		end

		if v:IsA("ModuleScript") then
			require(v)
		end
	end
end

loadModules(script.Parent.Controllers)
Knit.Start()
	:andThen(function()
		loadModules(script.Parent.Components)
		Knit.ComponentsLoaded = true

		Knit.OnComponentsLoaded():andThen(function()
			CollectionService:AddTag(Knit.Character, "Character")
		end)
	end)
	:catch(warn)
