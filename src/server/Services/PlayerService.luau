local CollectionService = game:GetService("CollectionService")
local DataStoreService = game:GetService("DataStoreService")
local PhysicsService = game:GetService("PhysicsService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local _WhitelistedPlayers = {
	"CityProsecutor",
	"ieatmeatandloveit",
	"oCqtrux",
	"kyledward",
	"Aerolifts",
	"localrejects",
	"EffortlessBrit",
	"theburnerphone",
	"JamesVanchetti",
	"Creator20204",
	"TwitVanchetti",
	"RootEntry",
	"-1",
	"-2",
	"Player",
	"Player1",
	"Player2",
	"Player3",
	"EffortlessPugsy",
	"SwiperCraft",
	"h_eadquarters",
	"gowisely"
}

local Knit = require(ReplicatedStorage.Packages.Knit)
local Promise = require(ReplicatedStorage.Packages.Promise)

local PlayerService = Knit.CreateService({
	Name = "PlayerService",
	Client = {},
})

--[=[
	Utility wrapper function to create a value instance (String, Number, or Object) and parents it to the specified instance.
	@param Type - The type of value instance to create ("String", "Number", or "Object")
	@param Name - The name of the value instance.
	@param Value - The initial value of the instance (optional)
	@param parent - The parent instance to which the value will be added to (optional).
]=]
local function createValue(Type: "String" | "Number" | "Object", Name: string, Value: string | number | ObjectValue, Parent: Instance)
	local inst = Instance.new(`{Type}Value`)
	
	inst.Name = Name
	inst.Value = Value
	inst.Parent = Parent
end

function PlayerService:isPlayerWhitelisted(player: Player)
	local username = player.Name
	--local encodedWhitelist = '
end

function PlayerService:_onPlayerAdded(Player: Player)
	if table.find(_WhitelistedPlayers, Player.Name) then
	else
		Knit.GetService("NotificationService"):SendBypass(
			Players:GetPlayers(),
			"Player Kicked!",
			Player.Name .. " has been kicked for not being whitelisted.",
			"rbxassetid://10191778113",
			"Moderation",
			12
		)
		Player:Kick()
	end

	Player.CharacterAdded:Connect(function(character)
		CollectionService:AddTag(character.HumanoidRootPart, "__Interactive__")

		local newModule = ReplicatedStorage.Assets.Interactions.Player.Interaction:Clone()
		newModule.Parent = character.HumanoidRootPart

		for _, v in ipairs(character:GetDescendants()) do
			if v:IsA("BasePart") then
				v.CollisionGroup = "Character"
			end
		end
	end)

	pcall(function()
		local bans = DataStoreService:GetDataStore("Bans"):GetAsync("Global")
		print(bans)
		if bans and bans[tostring(Player.UserId)] then
			Knit.GetService("NotificationService"):SendBypass(
				Players:GetPlayers(),
				"Player Banned!",
				Player.Name .. " tried to join while being banned.",
				"rbxassetid://10191778113",
				"Moderation",
				20
			)
			Player:Kick("You are banned from the game.")
		end
	end)

	createValue("Object", "Cuffer", nil, Player)
	createValue("Object", "Cuffing", nil, Player)
	createValue("Object", "Grabber", nil, Player)
	createValue("Object", "Grabbing", nil, Player)
	createValue("Object", "CurrentVehicle", nil, Player)
	createValue("Object", "Pinner", nil, Player)

	Knit.GetService("NotificationService"):SendBypass(
		Players:GetPlayers(),
		"Player Connected!",
		Player.Name .. " has joined the server.",
		"rbxassetid://10191778113",
		"Info",
		10
	)
end

function PlayerService:KnitStart()
	-- Init Players
	for _, Player in pairs(Players:GetPlayers()) do
		self:_onPlayerAdded(Player)
	end

	Players.PlayerAdded:Connect(function(Player)
		self:_onPlayerAdded(Player)
	end)

	Players.PlayerRemoving:Connect(function(player)
		Knit.GetService("NotificationService"):SendBypass(
			Players:GetPlayers(),
			"Player Disconnected!",
			player.Name .. " has left the server.",
			"rbxassetid://10191794588",
			"Alert",
			30
		)
	end)
end

return PlayerService
