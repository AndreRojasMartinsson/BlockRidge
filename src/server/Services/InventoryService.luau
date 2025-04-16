local CollectionService = game:GetService("CollectionService")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")

local Knit = require(ReplicatedStorage.Packages.Knit)
local TaskQueue = require(ReplicatedStorage.Packages.TaskQueue)

local Config = require(ReplicatedStorage.Shared.Modules.Config)
local ItemsModule = Config("Items")

local InventoryService = Knit.CreateService({
	Name = "InventoryService",
	Client = {
		OnUpdate = Knit.CreateSignal(),
		DrawnUpdate = Knit.CreateSignal(),
	},
})

function InventoryService:_onPlayerAdded(Player: Player)
	self.DataService
		:Get("Inventory", "Global", Player.UserId)
		:andThen(function(data)
			if data then
				self.Players[Player] = data

				self.Client.OnUpdate:Fire(Player)
			else
				self.Client.OnUpdate:Fire(Player)

				self.Players[Player] = {
					Equipped = {},
					Items = {},
				}
			end
		end)
		:catch(warn)
end

function InventoryService:_onPlayerRemoving(Player: Player)
	self.DataService
		:Set("Inventory", "Global", Player.UserId, function()
			return self.Players[Player]
		end)
		:finally(function()
			self.Players[Player] = nil
		end)
		:catch(warn)
end

-- *
function InventoryService:EquipItem(Player, UID)
	if Player.CurrentVehicle.Value ~= nil then
		return
	end
	if Player.Cuffer.Value ~= nil then
		return
	end
	local DataTable = self.Players[Player]
	local Items = DataTable.Items
	local Equipped = DataTable.Equipped

	-- * Check if same type already equipped
	local Id = Items[UID].Id

	local Exists = false
	for k, v in pairs(Equipped) do
		if tonumber(v.Id) == tonumber(Id) then
			Exists = true
			break
		end
	end

	-- * CHeck if Slot is taken
	local ThisItemSlot = ItemsModule[Id].Slot
	for k, v in pairs(Equipped) do
		local ItemData = ItemsModule[v.Id]
		if ItemData then
			if ItemData.Slot == ThisItemSlot then
				Exists = true
				break
			end
		end
	end

	if Equipped[UID] or Exists == true then
		self.Client.OnUpdate:Fire(Player)

		return false
	else
		if Items[UID] then
			-- * Equip It
			local _ItemID = Items[UID].Id
			if _ItemID then
				local _ItemData = ItemsModule[_ItemID].Slot
				if _ItemData ~= -1 then
					DataTable.Equipped[UID] = {
						Id = Items[UID].Id,
					}
					self.Client.OnUpdate:Fire(Player)
				end
			end
		else
			return false
		end
	end
end

function InventoryService:UnequipItem(Player, UID)
	if Player.CurrentVehicle.Value ~= nil then
		return
	end
	if Player.Cuffer.Value ~= nil then
		return
	end

	local DataTable = self.Players[Player]
	local Items = DataTable.Items
	local Equipped = DataTable.Equipped

	if Equipped[UID] then
		if Items[UID] then
			DataTable.Equipped[UID] = nil
			self.Client.OnUpdate:Fire(Player)
		else
			return false
		end
	else
		return false
	end
end

function InventoryService:DropItem(Player, UID)
	if Player.CurrentVehicle.Value ~= nil then
		return
	end
	if Player.Cuffer.Value ~= nil then
		return
	end
	local DataTable = self.Players[Player]
	local Items = DataTable.Items

	if Items[UID] and Player.Character and Player.Character:FindFirstChild("HumanoidRootPart") then
		self:UnequipItem(Player, UID)

		local newDropModel = ReplicatedStorage.Assets.Inventory.DropTemplate:Clone()
		newDropModel.CFrame = Player.Character:FindFirstChild("HumanoidRootPart").CFrame
		newDropModel.Name = Items[UID].Id

		local Decoded = Items[UID].Attributes
		local Encoded = HttpService:JSONEncode(Decoded)

		newDropModel:SetAttribute("Attributes", Encoded)
		newDropModel.Parent = workspace.Ignore

		CollectionService:AddTag(newDropModel, "__Interactive__")

		Items[UID] = nil
		-- TODO: Notification
		self.Client.OnUpdate:Fire(Player)
	end
end

function InventoryService:Clear(Player)
	if Player.CurrentVehicle.Value ~= nil then
		return
	end
	if Player.Cuffer.Value ~= nil then
		return
	end
	self.Players[Player] = { Items = {}, Equipped = {} }
	self.Client.OnUpdate:Fire(Player)
end

function InventoryService:HasItem(Player, Id)
	local DataTable = self.Players[Player]
	local Items = DataTable.Items

	local has = false
	for k, v in pairs(Items) do
		if v.Id == Id then
			has = true
			break
		end
	end

	return has
end

function InventoryService:_HasItemUID(Player, UID)
	local DataTable = self.Players[Player]
	local Items = DataTable.Items

	local has = false
	for k in pairs(Items) do
		if k == UID then
			has = true
			break
		end
	end

	return has
end

function InventoryService.Client:HasItem(Player, Id)
	return self.Server:HasItem(Player, Id)
end

function InventoryService:RemoveItem(Player, Id)
	if self:HasItem(Player, Id) == true then
		local DataTable = self.Players[Player]
		local Items = DataTable.Items

		local mat = -1
		for k, v in pairs(Items) do
			if v.Id == Id then
				mat = k
				break
			end
		end

		if mat ~= -1 then
			Items[mat] = nil
			self.Client.OnUpdate:Fire(Player)
		end
	end
end

function InventoryService:RemoveSpecificItem(Player, UID)
	local DataTable = self.Players[Player]
	local Items = DataTable.Items
	local Equipped = DataTable.Equipped

	if Items[UID] then
		Items[UID] = nil
	end

	if Equipped[UID] then
		Equipped[UID] = nil
	end
	self.Client.OnUpdate:Fire(Player)
end

function InventoryService:AddItem(Player, Id, Amount, Attributes)
	assert(Attributes, "Missing attributes")

	if Player.CurrentVehicle.Value ~= nil then
		return
	end
	if Player.Cuffer.Value ~= nil then
		return
	end
	local DataTable = self.Players[Player]
	local Items = DataTable.Items

	local uids = {}
	for _ = 1, Amount do
		local UID = HttpService:GenerateGUID(false)
		Items[UID] = {
			Attributes = Attributes,
			Id = tonumber(Id),
		}
		table.insert(uids, UID)
	end

	self.Client.OnUpdate:Fire(Player)
	return uids
end

function InventoryService:Draw(Player, UID)
	if self:_HasItemUID(Player, UID) then
		if self.Drawn[Player] == UID then
			return false
		end

		if self.Drawn[Player] == "" or self.Drawn[Player] ~= UID then
			-- Draw the item
			local ItemData = self.Players[Player].Items[UID]
			if ItemData then
				local ItemTable = ItemsModule[ItemData.Id]
				if ItemTable then
					local char = Player.Character
					if char:FindFirstChild(ItemTable.Asset) then
						return false
					end

					local Tool = ServerStorage.Tools:FindFirstChild(ItemTable.Asset)
					if Tool then
						-- Setup
						self.Drawn[Player] = UID
						local new = Tool:Clone()
						new:SetAttribute("Type", ItemTable.Type)
						new:SetAttribute("UID", UID)
						new.Parent = char

						local newMotor6D = Instance.new("Motor6D")
						newMotor6D.Part0 = char:FindFirstChild("Left Arm")
						newMotor6D.Name = "HandleMotor6"
						newMotor6D.Part1 = new:FindFirstChild("Handle")
						newMotor6D.Parent = char:FindFirstChild("Torso")

						CollectionService:AddTag(new, "BaseTool")

						return { true, new }
					end
				end
			end
		end
	end

	return false
end

function InventoryService:GetRounds(Player, ItemTable)
	if ItemTable and ItemTable.Mag then
		local rounds = 0
		for _, v in ipairs(ItemTable.Mag) do
			local _rounds = self:GetAvailableRoundsInMags(Player, v)

			rounds += _rounds
		end

		return rounds
	end

	return 0
end
function InventoryService:Set(Player: Player, UID: { string }, Key, Value: { any })
	local Inv = self:GetData(Player)
	local Items = Inv.Items

	for idx, val in ipairs(UID) do
		local Item = Items[val]

		if not Item then
			return false
		end

		if not Item.Attributes then
			return false
		end

		if not Item.Attributes[Key] then
			return false
		end

		Inv.Items[val].Attributes[Key] = Value[idx]
	end

	self.Client.OnUpdate:Fire(Player)
	return true
end

function InventoryService:GetAttribute(Player, UID, Key)
	local Inv = self:GetData(Player)
	if Inv.Items[UID] then
		if Inv.Items[UID].Attributes and Inv.Items[UID].Attributes[Key] then
			return Inv.Items[UID].Attributes[Key]
		end
	end
end

function InventoryService.Client:GetRounds(Player, ItemTable)
	return self.Server:GetRounds(Player, ItemTable)
end

function InventoryService:GetAvailableRoundsInMags(Player, MagType)
	local Rounds = 0
	local inventory = self:GetData(Player)
	local items = inventory.Items

	for uid, data in pairs(items) do
		local ItemData = ItemsModule[data.Id]
		if ItemData then
			if ItemData.Type == "Mag" and data.Attributes and data.Attributes.Rounds and ItemData.Asset == MagType then
				Rounds += data.Attributes.Rounds
			end
		end
	end

	return Rounds
end

function InventoryService.Client:GetAvailableRoundsInMags(Player)
	return self.Server:GetAvailableRoundsInMags(Player)
end

function InventoryService:GetDrawn(Player)
	return self.Drawn[Player]
end

function InventoryService:GetFirearmRounds(Player)
	local Inventory = self:GetData(Player)
	local Drawn = self:GetDrawn(Player)
	local Items = Inventory.Items

	local Item = Items[Drawn]
	if Item and Item.Attributes and Item.Attributes.Rounds then
		return Item.Attributes.Rounds
	end

	return 0
end

function InventoryService.Client:GetDrawn(Player)
	return self.Server:GetDrawn(Player)
end

function InventoryService:Holster(Player, UID)
	task.wait(0.1)
	if self:_HasItemUID(Player, UID) then
		if self.Drawn[Player] == UID then
			self.Drawn[Player] = ""

			local char = Player.Character
			if char:FindFirstChild("Torso") then
				if char:FindFirstChild("Torso"):FindFirstChild("HandleMotor6") then
					char.Torso:FindFirstChild("HandleMotor6"):Destroy()
					CollectionService:RemoveTag(char:FindFirstChildOfClass("Model"), "BaseTool")
					char:FindFirstChildOfClass("Model"):Destroy()
				end
			end
		end
	end
end

function InventoryService.Client:Draw(Player, UID)
	return self.Server:Draw(Player, UID)
end

function InventoryService.Client:Holster(Player, UID)
	return self.Server:Holster(Player, UID)
end

function InventoryService:Transfer(Player, ItemUID, CarUID)
	if Player.CurrentVehicle.Value ~= nil then
		return
	end
	if Player.Cuffer.Value ~= nil then
		return
	end
	--! DO SECURITY CHECKS LATER
	local DataTable = self.Players[Player]
	if DataTable then
		if DataTable.Items[ItemUID] then
			Knit.GetService("VehicleService"):AddItem(Player, CarUID, ItemUID, 1, DataTable.Items[ItemUID].Attributes)
			self.Players[Player].Items[ItemUID] = nil

			self.Client.OnUpdate:Fire(Player)
		end
	end
end

function InventoryService:TransferTo(Player, Target, ItemUID)
	if Player.CurrentVehicle.Value ~= nil then
		return
	end
	if Player.Cuffer.Value ~= nil then
		return
	end
	--! DO SECURITY CHECKS LATER
	local DataTable = self.Players[Player]
	local TargetDataTable = self.Players[Target]

	if DataTable and TargetDataTable then
		local ItemData = DataTable.Items[ItemUID]
		if ItemData then
			self:UnequipItem(Player, ItemUID)
			self:AddItem(Target, ItemData.Id, 1, ItemData.Attributes)
			DataTable.Items[ItemUID] = nil

			self.Client.OnUpdate:Fire(Player)
			self.Client.OnUpdate:Fire(Target)
			ReplicatedStorage.Search:FireClient(Player, Target, TargetDataTable)
		end
	end
end

-- TODO FIX IT SO IT UNEQUIPS GUN WHEN TRANSFERRING

function InventoryService:TransferFrom(Player, Target, ItemUID)
	if Player.CurrentVehicle.Value ~= nil then
		return
	end
	if Player.Cuffer.Value ~= nil then
		return
	end
	--! DO SECURITY CHECKS LATER
	local DataTable = self.Players[Player]
	local TargetDataTable = self.Players[Target]

	if DataTable and TargetDataTable then
		local ItemData = TargetDataTable.Items[ItemUID]
		if ItemData then
			self:UnequipItem(Target, ItemUID)
			self:AddItem(Player, ItemData.Id, 1, ItemData.Attributes)

			TargetDataTable.Items[ItemUID] = nil

			self.Client.OnUpdate:Fire(Player)
			self.Client.OnUpdate:Fire(Target)
			ReplicatedStorage.Search:FireClient(Player, Target, TargetDataTable)
		end
	end
end

function InventoryService.Client:TransferFrom(Player, Target, ItemUID)
	return self.Server:TransferFrom(Player, Target, ItemUID)
end

function InventoryService.Client:TransferTo(Player, Target, ItemUID)
	return self.Server:TransferTo(Player, Target, ItemUID)
end

function InventoryService.Client:Transfer(Player, ItemId, CarUID)
	return self.Server:Transfer(Player, ItemId, CarUID)
end

function InventoryService.Client:DropItem(Player, UID)
	if Player.CurrentVehicle.Value ~= nil then
		return
	end
	if Player.Cuffer.Value ~= nil then
		return
	end
	return self.Server:DropItem(Player, UID)
end

function InventoryService.Client:EquipItem(Player, UID)
	if Player.CurrentVehicle.Value ~= nil then
		return
	end
	if Player.Cuffer.Value ~= nil then
		return
	end
	return self.Server:EquipItem(Player, UID)
end

function InventoryService.Client:UnequipItem(Player, UID)
	if Player.CurrentVehicle.Value ~= nil then
		return
	end
	if Player.Cuffer.Value ~= nil then
		return
	end
	return self.Server:UnequipItem(Player, UID)
end

function InventoryService:GetData(Player)
	return self.Players[Player]
end

function InventoryService.Client:Get(Player)
	return self.Server:GetData(Player)
end

-- ********************************************************************************************************************************************************
-- * New Function Seperation ******************************************************************************************************************************
-- ********************************************************************************************************************************************************

function InventoryService:SetDrawn(Player, UID)
	local Inv = self:GetData(Player)
	local Equipped = Inv.Equipped

	if not Equipped[UID] then
		if self.Drawn[Player] == UID then
			self.Drawn[Player] = ""

			Knit.GetService("ToolService"):Unequip(Player, UID)
			self.Client.DrawnUpdate:Fire(Player, self.Drawn[Player])
		end
		return false
	end

	if self.Drawn[Player] == UID then
		Knit.GetService("ToolService"):Unequip(Player, UID)
		self.Drawn[Player] = ""
	else
		if self.Drawn[Player] == "" then
			self.Drawn[Player] = UID
			Knit.GetService("ToolService"):Equip(Player, UID)
		else
			Knit.GetService("ToolService"):Unequip(Player, self.Drawn[Player])
			self.Drawn[Player] = ""
		end
	end

	self.Client.DrawnUpdate:Fire(Player, self.Drawn[Player])

	return true
end
--*
function InventoryService.Client:SetDrawn(Player, UID)
	return self.Server:SetDrawn(Player, UID)
end
--*

function InventoryService:GetChamberRounds(Player, UID)
	local Inventory = self:GetData(Player)
	local Items = Inventory.Items
	local Item = Items[UID]

	if not Item then
		return false
	end

	if not Item.Attributes.Rounds then
		return false
	end

	return Item.Attributes.Rounds
end
--*
function InventoryService.Client:GetChamberRounds(Player, UID)
	return self.Server:GetChamberRounds(Player, UID)
end
--*
function InventoryService:GetTotalRounds(Player, MagType)
	local Inventory = self:GetData(Player)
	local Items = Inventory.Items

	local rounds = 0
	for _, data in pairs(Items) do
		local ItemData = ItemsModule[data.Id]
		if not ItemData then
			continue
		end

		if not ItemData.Type == "Mag" then
			continue
		end

		if ItemData.Asset == MagType then
			rounds += data.Attributes.Rounds
		end
	end

	return rounds
end
--*
function InventoryService.Client:GetTotalRounds(Player, MagType)
	return self.Server:GetTotalRounds(Player, MagType)
end

function InventoryService:KnitStart()
	self.Drawn = {}
	self.DataService = Knit.GetService("DataService")

	-- Init Players
	for _, Player in pairs(Players:GetPlayers()) do
		self.Drawn[Player] = ""
		self:_onPlayerAdded(Player)
	end

	Players.PlayerAdded:Connect(function(Player)
		self.Drawn[Player] = ""

		self:_onPlayerAdded(Player)
	end)

	Players.PlayerRemoving:Connect(function(Player)
		self.Drawn[Player] = nil
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

function InventoryService:KnitInit()
	self.Players = {}
end

return InventoryService
