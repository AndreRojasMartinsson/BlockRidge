local TestCarPartInt = {}
TestCarPartInt.Type = "TestCarPart"

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Knit = require(ReplicatedStorage.Packages.Knit)

local Config = require(ReplicatedStorage.Shared.Modules.Config)
local Items = Config("Items")

local DebouncePlayer = {}

local function Cast(Origin, EndPosition, Ignore)
	local RaycastParam = RaycastParams.new()
	RaycastParam.FilterType = Enum.RaycastFilterType.Exclude
	RaycastParam.FilterDescendantsInstances = Ignore
	RaycastParam.IgnoreWater = true

	local result = workspace:Raycast(Origin, (EndPosition - Origin), RaycastParam)
	return result
end

function TestCarPartInt.CheckSpawnObstruction(SpawnPad, IgnoreList)
	local RAY_LENGTH = 5
	local OriginPosition = (SpawnPad.CFrame).Position
	local EndPosition = (SpawnPad.CFrame * CFrame.new(5, 0, 0)).Position
	local result = Cast(OriginPosition, EndPosition, IgnoreList)

	print(result)

	if result.Instance == nil then
		return true
	end

	return false
end

function TestCarPartInt.Verify(Player, Part)
	local char = Player.Character
	local humanoid = char and char:WaitForChild("Humanoid")

	if char and humanoid then
		if humanoid.Health > 0 then
			return true, { ["F"] = "Spawn Car" }
		end
	end

	return false, {}
end

function TestCarPartInt.Init()
	Players.PlayerRemoving:Connect(function(player)
		DebouncePlayer[player] = nil
	end)
end

function TestCarPartInt.Execute(Player, Part, Key)
	if Key == Enum.KeyCode.F then
		DebouncePlayer[Player] = DebouncePlayer[Player] or false

		if DebouncePlayer[Player] == false then
			DebouncePlayer[Player] = true

			if Part and Part:FindFirstChild("Dealer") then
				Knit.GetService("VehicleService"):SpawnCar(Player, Part:FindFirstChild("Dealer").Value)
			end

			task.delay(1, function()
				DebouncePlayer[Player] = false
			end)
		end
	end
end

return TestCarPartInt
