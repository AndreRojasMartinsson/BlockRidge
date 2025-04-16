local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Packages.Knit)
local Promise = require(ReplicatedStorage.Packages.Promise)

local LockerService = Knit.CreateService({
	Name = "LockerService",
	Client = {},
})

function LockerService:ApplyToPlayer(Player, AccessoryData)
	local Character = Player.Character or Player.CharacterAdded:Wait()
	if Character then
		Character.Shirt.ShirtTemplate = AccessoryData.Shirt
		Character.Pants.PantsTemplate = AccessoryData.Pants

		-- Accessories
		Character.Humanoid:RemoveAccessories()

		for _, v in ipairs(AccessoryData.Accessories) do
			local Accessory = ReplicatedStorage.Accessories:FindFirstChild(v)
			if Accessory then
				local new = Accessory:Clone()
				Character.Humanoid:AddAccessory(new)
			end
		end
	end
	return true
end

function LockerService:Save(Player, Name, Data)
	self.DebouncePlayer[Player] = self.DebouncePlayer[Player] or false

	if self.DebouncePlayer[Player] == false then
		self.DebouncePlayer[Player] = true

		task.delay(5, function()
			self.DebouncePlayer[Player] = false
		end)

		if Data.Shirt and Data.Pants and Data.Accessories then
			if not self.Players[Player][Name] then
				self.Players[Player][Name] = Data
				return true
			end
		end
	end

	return false
end

function LockerService:Load(Player, Name)
	self.DebouncePlayer[Player] = self.DebouncePlayer[Player] or false

	if self.DebouncePlayer[Player] == false then
		self.DebouncePlayer[Player] = true

		task.delay(5, function()
			self.DebouncePlayer[Player] = false
		end)

		if self.Players[Player] and self.Players[Player][Name] then
			return self.Players[Player][Name]
		end
	end

	return false
end

function LockerService:GetData(Player)
	return self.Players[Player]
end

function LockerService.Client:GetData(Player)
	return self.Server:GetData(Player)
end

function LockerService.Client:Load(Player, Name)
	return self.Server:Load(Player, Name)
end

function LockerService.Client:Save(Player, Name, Data)
	return self.Server:Save(Player, Name, Data)
end

function LockerService.Client:ApplyToPlayer(Player, AccessoryData)
	return self.Server:ApplyToPlayer(Player, AccessoryData)
end

function LockerService:_onPlayerAdded(Player: Player)
	self.DataService
		:Get("Locker", "Global", Player.UserId)
		:andThen(function(data)
			if data then
				self.Players[Player] = data
			else
				self.Players[Player] = {}
			end
		end)
		:catch(warn)
end

function LockerService:_onPlayerRemoving(Player: Player)
	self.DataService
		:Set("Locker", "Global", Player.UserId, function()
			return self.Players[Player] or {}
		end)
		:finally(function()
			self.Players[Player] = nil
		end)
		:catch(warn)
end

function LockerService:KnitStart()
	self.DataService = Knit.GetService("DataService")
	self.Players = {}
	self.DebouncePlayer = {}

	-- Init Players
	for _, Player in pairs(Players:GetPlayers()) do
		self.Players[Player] = {}
		self:_onPlayerAdded(Player)
	end

	Players.PlayerAdded:Connect(function(Player)
		self:_onPlayerAdded(Player)
	end)

	Players.PlayerRemoving:Connect(function(player)
		self:_onPlayerRemoving(player)
		self.DebouncePlayer[player] = nil
	end)
end

return LockerService
