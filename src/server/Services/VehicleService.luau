local CollectionService = game:GetService("CollectionService")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Knit = require(ReplicatedStorage.Packages.Knit)
local Config = require(ReplicatedStorage.Shared.Modules.Config)
local VehiclesModule = Config("Vehicles")
local WebhookService = require(ReplicatedStorage.Shared.Modules.WebhookService)

local RateLimitPlayers = {}
local function RateLimit(Player: Player, Args: { any })
	-- Rate Limit to 5 requests per secondper player
	if RateLimitPlayers[Player] == nil then
		RateLimitPlayers[Player] = {
			Requests = 0,
			LastRequest = 0,
		}
	end
	local RateLimit = RateLimitPlayers[Player]
	local Time = tick()
	if Time - RateLimit.LastRequest < 0.2 then
		RateLimit.Requests = RateLimit.Requests + 1
		if RateLimit.Requests > 5 then
			return false, "You are sending too many requests. Please try again later."
		end
	else
		RateLimit.Requests = 0
	end
	RateLimit.LastRequest = Time

	return true
end

local VehicleService = Knit.CreateService({
	Name = "VehicleService",
	Client = {
		OpenTrunk = Knit.CreateSignal(),
		CloseTrunk = Knit.CreateSignal(),
		OnUpdate = Knit.CreateSignal(),
	},
	Middleware = {
		RateLimit,
	},
})

function VehicleService:_onPlayerAdded(Player: Player)
	self.DataService
		:Get("Vehicle", "Global", Player.UserId)
		:andThen(function(data)
			if data then
				self.Players[Player] = data
				self.Client.OnUpdate:Fire(Player)
			else
				self.Players[Player] = {
					[HttpService:GenerateGUID(false)] = {
						Asset = "DHS20ExpLTBR",
						Fuel = 100,
						Health = 100,
						Color = BrickColor.random().Name,
						Trunk = {},
					},
				}
				self.Client.OnUpdate:Fire(Player)
			end
		end)
		:catch(warn)
end

function VehicleService:Transfer(Player, ItemUID, CarUID)
	--! DO SECURITY CHECKS LATER
	local DataTable = self.Players[Player]
	if DataTable then
		local CarTable = DataTable[CarUID]
		if CarTable then
			if CarTable.Trunk[ItemUID] then
				Knit.GetService("InventoryService")
					:AddItem(Player, CarTable.Trunk[ItemUID].Id, 1, CarTable.Trunk[ItemUID].Attributes)
				CarTable.Trunk[ItemUID] = nil
				self.Client.OnUpdate:Fire(Player)
			end
		end
	end
end

function VehicleService:AddItem(Player, CarUID, ItemID, Amount, Attributes)
	assert(Attributes, "Missing attributes")
	local DataTable = self.Players[Player]
	if DataTable then
		local CarTable = DataTable[CarUID]
		if CarTable then
			local Trunk = CarTable.Trunk

			local DataTable = Knit.GetService("InventoryService"):GetData(Player)
			local ItemsTable = DataTable.Items

			if ItemsTable then
				if ItemsTable[ItemID] then
					for _ = 1, Amount do
						local UID = HttpService:GenerateGUID(false)
						Trunk[UID] = {
							Attributes = Attributes,
							Id = tonumber(ItemsTable[ItemID].Id),
						}
					end

					self.Client.OnUpdate:Fire(Player)
				end
			end
		end
	end

	self.Client.OnUpdate:Fire(Player)
end

function VehicleService.Client:Transfer(Player, ItemUID, CarUID)
	return self.Server:Transfer(Player, ItemUID, CarUID)
end

function VehicleService:_onPlayerRemoving(Player: Player)
	-- Dont Save Items in a Police Car.
	for uid, data in pairs(self.Players[Player]) do
		local assetName = data.Asset
		if VehiclesModule[assetName] then
			local dataTable = VehiclesModule[assetName].LEO
			if dataTable then
				self.Players[Player][uid].Trunk = {}
			end
		end
	end

	self.DataService
		:Set("Vehicle", "Global", Player.UserId, function()
			return self.Players[Player]
		end)
		:finally(function()
			self.Players[Player] = nil
		end)
		:catch(warn)
end

function VehicleService:GetData(Player)
	return self.Players[Player]
end

function VehicleService.Client:Get(Player)
	return self.Server:GetData(Player)
end

function VehicleService:OpenTrunk(Player, UID)
	self.Client.OpenTrunk:Fire(Player, UID)
end

function VehicleService:CloseTrunk(Player)
	self.Client.CloseTrunk:Fire(Player)
end

function VehicleService:Cast(Origin, EndPosition, Ignore)
	local RaycastParam = RaycastParams.new()
	RaycastParam.FilterType = Enum.RaycastFilterType.Blacklist
	RaycastParam.FilterDescendantsInstances = Ignore
	RaycastParam.IgnoreWater = true

	local result = workspace:Raycast(Origin, (EndPosition - Origin), RaycastParam)
	return result
end

function VehicleService:CheckSpawnObstruction(SpawnPad, IgnoreList)
	local RAY_LENGTH = 5
	local OriginPosition = (SpawnPad.CFrame).Position
	local EndPosition = (SpawnPad.CFrame * CFrame.new(0, 5, 0)).Position
	local result = self:Cast(OriginPosition, EndPosition, IgnoreList)

	if result then
		return false
	else
		return true
	end
end

function VehicleService:SpawnCar(Player, Dealer)
	if Dealer then
		-- TODO: FIX DEALER STUFF
		local DataTable = self.Players[Player]
		for k, Vehicle in pairs(DataTable) do
			if Vehicle then
				local NewVehicle = ReplicatedStorage.Assets.Vehicles:FindFirstChild(Vehicle.Asset)
				if NewVehicle then
					local ObstructedPads = 0
					local SpawnPad
					if workspace:WaitForChild("StaticStreaming").SpawnPads:FindFirstChild(Dealer) then
						for _, v in
							ipairs(
								workspace:WaitForChild("StaticStreaming").SpawnPads:FindFirstChild(Dealer):GetChildren()
							)
						do
							if
								self:CheckSpawnObstruction(
									v,
									{ workspace.Ignore, workspace:WaitForChild("StaticStreaming").SpawnPads }
								) ~= true
							then
								ObstructedPads = ObstructedPads + 1
							else
								SpawnPad = v
								break
							end
						end

						if
							ObstructedPads
							== #workspace:WaitForChild("StaticStreaming").SpawnPads:FindFirstChild(Dealer):GetChildren()
						then
							return Knit.GetService("NotificationService"):SendBypass(
								{ Player },
								"Obstructed Pad!",
								"All spawn pads are obstructed.",
								"rbxassetid://10345627286",
								"Alert",
								10
							)
						end

						if SpawnPad then
							if self.Vehicles[k] then
								self.Vehicles[k].Model:Destroy()
							end

							NewVehicle = NewVehicle:Clone()
							NewVehicle:SetAttribute("Owner", Player.UserId)
							NewVehicle:SetAttribute("UID", k)
							NewVehicle:SetPrimaryPartCFrame(SpawnPad.CFrame * CFrame.new(0, 5, 0))
							NewVehicle.Parent = workspace.Vehicles
							CollectionService:AddTag(NewVehicle, "ServerCar")
							self.Vehicles[k] = {
								Model = NewVehicle,
								Attributes = Vehicle,
							}

							Knit.GetService("NotificationService"):SendBypass(
								{ Player },
								"Spawned a Car!",
								"You have successfully spawned a new car.",
								"rbxassetid://10345627286",
								"Success",
								10
							)

							-- print(
							-- 	SpawnTemplate:format(
							-- 		Player.Name,
							-- 		tostring(os.date("%c", os.time())),
							-- 		Vehicle.Name,
							-- 		Dealer,
							-- 		Player.UserId
							-- 	)
							-- )

						end
					end
				end
				break
			end
		end
	end
end

function VehicleService:KnitStart()
	self.DataService = Knit.GetService("DataService")

	-- Init Players
	for _, Player in pairs(Players:GetPlayers()) do
		self:_onPlayerAdded(Player)
	end

	Players.PlayerAdded:Connect(function(Player)
		self:_onPlayerAdded(Player)
	end)

	Players.PlayerRemoving:Connect(function(Player)
		self:_onPlayerRemoving(Player)
	end)

	game:BindToClose(function()
		if RunService:IsStudio() then
			return task.wait(3)
		end

		local finished = Instance.new("BindableEvent")
		local allPlayers = Players:GetPlayers()
		local leftPlayers = #allPlayers

		for _, Player in pairs(allPlayers) do
			task.spawn(function()
				self:_onPlayerRemoving(Player)
				leftPlayers -= 1
				if leftPlayers == 0 then
					finished:Fire()
				end
			end)
		end

		finished.Event:Wait()
		finished:Destroy()
	end)
end

function VehicleService:KnitInit()
	self.Vehicles = {}
	self.Players = {}
end

return VehicleService
