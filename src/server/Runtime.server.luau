local CollectionService = game:GetService("CollectionService")
local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Packages.Knit)
local promise = require(ReplicatedStorage.Packages.Promise)
local concur = require(ReplicatedStorage.Packages.Concur)

Knit.ComponentsLoaded = false
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

loadModules(script.Parent.Services)
Knit.Start()
	:andThen(function()
		loadModules(script.Parent.Components)
		Knit.ComponentsLoaded = true

		Knit.OnComponentsLoaded():andThen(function()
			CollectionService:AddTag(ServerScriptService, "_serverDone")
		end)
	end)
	:catch(warn)
