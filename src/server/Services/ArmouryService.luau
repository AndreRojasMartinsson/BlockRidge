local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Packages.Knit)
local WebhookService = require(ReplicatedStorage.Shared.Modules.WebhookService)

local ArmouryService = Knit.CreateService({
	Name = "ArmouryService",
	Client = {
		OnUpdate = Knit.CreateSignal(),
	},
})

local Config = require(ReplicatedStorage.Shared.Modules.Config)
local ItemsModule = Config("Items")
local ArmouryModule = Config("Armoury")

local function getItemDataFromName(Id)
	local ArmouryTable = ItemsModule
	local ret = nil
	local ret2 = nil

	for k, v in pairs(ArmouryTable) do
		if k == Id then
			ret = v
			ret2 = k
			break
		end
	end

	return ret, ret2
end

function ArmouryService:GiveItem(Player, Id)
	if ItemsModule[Id] then
		self.DebouncePlayer[Player] = self.DebouncePlayer[Player] or false

		if self.DebouncePlayer[Player] == false then
			self.DebouncePlayer[Player] = true

			--! TODO Check if they got permission to get the item
			local Data = getItemDataFromName(Id)

			if Data then
				if Knit.GetService("TitleService"):CheckPermission(Player, "CanGetItems", Data.Asset) then
					Knit.GetService("NotificationService"):SendBypass(
						{ Player },
						"Item Given!",
						"You have been given a " .. Data.Name .. "!",
						"rbxassetid://10455632604",
						"Info",
						10
					)
					Knit.GetService("InventoryService"):AddItem(Player, Id, 1)

					local Webhook = WebhookService:CreateWebhook()
					local Embed = WebhookService:CreateEmbed()
					Webhook:SetAvatar("https://i.ibb.co/fxVCgzG/SOL.png")
					Webhook:SetUsername("Dispense Log - Lockridge")
					Embed:SetAuthor("Ingame Log")
					Embed:SetTitle("Dispense Log")
					Embed:SetDescription("A user has dispensed a item from the Armoury.")
					Embed:AddField("Username", Player.Name)
					Embed:AddField("Team", Player.Team.Name)
					Embed:AddField("Date & Time", os.date("%c", os.time()))
					Embed:AddField("Item ID", tostring(Id))
					Embed:AddField("Amount", tostring(1))
					Embed:SetColor(Color3.fromRGB(47, 49, 54))
					Embed:SetTimestamp()
					Webhook:AddEmbed(Embed)

					WebhookService:SendAsync(
						Webhook,
						"https://discord.com/api/webhooks/HAH_U_THOUGHT/ :P "
					)
				end
			end

			task.delay(0.8, function()
				self.DebouncePlayer[Player] = false
			end)
		end
	end
end

function ArmouryService:SaveLoadout(Player, Name)
	self.DebouncePlayer[Player] = self.DebouncePlayer[Player] or false

	if self.DebouncePlayer[Player] == false then
		self.DebouncePlayer[Player] = true
		local Data = Knit.GetService("InventoryService"):GetData(Player)

		if Data and Data.Items then
			local newLoadout = Data.Items
			if not self.Players[Player][Name] then
				self.Players[Player][Name] = newLoadout

				Knit.GetService("NotificationService"):SendBypass(
					{ Player },
					"Loadout Saved",
					"Loadout '" .. Name .. "' successfully saved.",
					"rbxassetid://10415902869",
					"Success",
					10
				)
			else
				Knit.GetService("NotificationService"):SendBypass(
					{ Player },
					"Loadout Error!",
					"A loadout with the same name already exists.",
					"rbxassetid://10415902869",
					"Warning",
					10
				)
			end
		end

		task.delay(0.8, function()
			self.DebouncePlayer[Player] = false
		end)
	end
end

function ArmouryService:GetLoadouts(Player)
	return self.Players[Player]
end

function ArmouryService.Client:GetLoadouts(Player)
	return self.Server:GetLoadouts(Player)
end

function ArmouryService.Client:SaveLoadout(Player, Name)
	return self.Server:SaveLoadout(Player, Name)
end

function ArmouryService:Load(Player, Name)
	self.DebouncePlayer[Player] = self.DebouncePlayer[Player] or false

	if self.DebouncePlayer[Player] == false then
		self.DebouncePlayer[Player] = true
		local Loadouts = self.Players[Player]
		-- TODO: perms

		if Loadouts and Loadouts[Name] then
			local Items = Loadouts[Name]
			Knit.GetService("InventoryService"):Clear(Player)

			for k, v in pairs(Items) do
				Knit.GetService("InventoryService"):AddItem(Player, v.Id, 1, true)
			end

			Knit.GetService("NotificationService"):SendBypass(
				{ Player },
				"Loaded Loadout!",
				"The loadout was successfully loaded.",
				"rbxassetid://10415902869",
				"Success",
				10
			)

			task.delay(0.8, function()
				self.DebouncePlayer[Player] = false
			end)
		end
	end
end

function ArmouryService.Client:Load(Player, Name)
	return self.Server:Load(Player, Name)
end

function ArmouryService.Client:HandleButton(Player, Id)
	return self.Server:GiveItem(Player, Id)
end

function ArmouryService:_onPlayerAdded(Player: Player)
	self.DataService
		:Get("Loadouts", "Global", Player.UserId)
		:andThen(function(data)
			if data then
				self.Players[Player] = data

				self.Client.OnUpdate:Fire(Player)
			else
				self.Client.OnUpdate:Fire(Player)

				self.Players[Player] = {}
			end
		end)
		:catch(warn)
end

function ArmouryService:_onPlayerRemoving(Player: Player)
	self.DataService
		:Set("Loadouts", "Global", Player.UserId, function()
			return self.Players[Player] or {}
		end)
		:finally(function()
			self.Players[Player] = nil
		end)
		:catch(warn)
end

function ArmouryService:KnitStart()
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

return ArmouryService
