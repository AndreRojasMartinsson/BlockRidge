--[=[
TitleService
@date May 03, 2022
@author RootEntry 2022
@description Handle Titles ingame
]=]
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local knit = require(ReplicatedStorage.Packages.Knit)
local promise = require(ReplicatedStorage.Packages.Promise)

local Config = require(ReplicatedStorage.Shared.Modules.Config)
local Titles = Config("Titles")
local Teams = Config("Teams")

local signal = require(ReplicatedStorage.Packages.Signal)

local TitleService = knit.CreateService({
	Name = "TitleService",
	Client = {},
})

local RolesChanged = signal.new()

function TitleService:GetTeamFromColor(brickColor)
	for i, v in ipairs(Teams) do
		if v.TeamColor == brickColor then
			return i
		end
	end
end

function TitleService:GetVerify(Player: Player)
	local PlayerRoles = {}

	if Player:IsInGroup(7325066) then
		PlayerRoles["ILETGroup"] = Titles.ILETGroup
	end

	if Player:IsInGroup(14835809) then
		PlayerRoles["BPDGroup"] = Titles.BPDGroup
	end

	if Player:IsInGroup(12742396) then
		PlayerRoles["CPDGroup"] = Titles.CPDGroup
	end

	if Player:IsInGroup(7220381) then
		PlayerRoles["OFDGroup"] = Titles.OFDGroup
	end

	if Player:IsInGroup(7220348) then
		PlayerRoles["LSPGroup"] = Titles.LSPGroup
	end

	if Player:IsInGroup(7220365) then
		PlayerRoles["SheriffGroup"] = Titles.SheriffGroup
	end

	if Player:GetRankInGroup(7220344) >= 180 then
		PlayerRoles["Resident"] = Titles.Resident
	end

	if Player:GetRankInGroup(7220344) < 180 then
		PlayerRoles["Tourist"] = Titles.Tourist
	end

	for _, v in pairs(Titles) do
		if v.TeamCriteria ~= nil then
			if v.TeamCriteria[1] == self:GetTeamFromColor(Player.Team.TeamColor) then
				PlayerRoles[v.Name] = v
				RolesChanged:Fire(Player, PlayerRoles)
			else
				PlayerRoles[v.Name] = nil
				RolesChanged:Fire(Player, PlayerRoles)
			end
		end
	end

	Player:GetPropertyChangedSignal("Team"):Connect(function()
		local Team = Player.Team
		for _, v in pairs(Titles) do
			if v.TeamCriteria ~= nil then
				if v.TeamCriteria[1] == self:GetTeamFromColor(Team.TeamColor) then
					PlayerRoles[v.Name] = v
					RolesChanged:Fire(Player, PlayerRoles)
				else
					PlayerRoles[v.Name] = nil
					RolesChanged:Fire(Player, PlayerRoles)
				end
			end
		end
	end)

	return PlayerRoles
end

function TitleService:GetPermissionsFromRoles(roles)
	local getTable = {}
	for i, v in pairs(Titles) do
		if roles[i] and v.Permissions then
			for perm, res in pairs(v.Permissions) do
				if typeof(res) == "table" then
					if not getTable[perm] then
						getTable[perm] = {}
					end

					for _, val in pairs(res) do
						getTable[perm][val] = true
					end
				else
					getTable[perm] = true
				end
			end
		end
	end

	local returnTable = {}
	for i, v in pairs(getTable) do
		if typeof(v) == "table" then
			if not returnTable[i] then
				returnTable[i] = {}
			end
			for val in pairs(v) do
				table.insert(returnTable[i], val)
			end
		else
			returnTable[i] = true
		end
	end

	return returnTable
end

function TitleService:CheckPermission(Player, permission, parameter)
	local permissions = self.Players[Player].Permissions or {}
	if permissions[permission] then
		if parameter then
			for _, v in pairs(permissions[permission]) do
				if parameter == v then
					return true
				end
			end
		else
			return true
		end
	end
end

function TitleService:GetRoles(Player)
	if self.Players[Player] then
		return self.Players[Player].Permissions or {}
	end
	return {}
end

function TitleService.Client:GetRoles(Player)
	return self.Server:GetRoles(Player)
end

function TitleService.Client:CheckPermission(Player, permission, parameter)
	return self.Server:CheckPermission(Player, permission, parameter)
end

function TitleService:GetRankInGroup(Player, id)
	local groupData = self.Players[Player].GroupData

	if groupData then
		for i = 1, #groupData do
			if groupData[i].Id == id then
				return groupData[i].Rank
			end
		end
	end
	return 0
end

function TitleService:Yield()
	return promise.new(function(resolve)
		repeat
			task.wait()
		until self.Done
		resolve()
	end)
end

function TitleService:KnitStart()
	for _, v in ipairs(Players:GetPlayers()) do
		task.spawn(function()
			local _PlayerRoles = self:GetVerify(v)
			self.Players[v] = {
				Permissions = self:GetPermissionsFromRoles(_PlayerRoles),
				PlayerRoles = _PlayerRoles,
				GroupData = {},
			}
		end)
	end

	Players.PlayerAdded:Connect(function(v)
		local _PlayerRoles = self:GetVerify(v)
		self.Players[v] = {
			Permissions = self:GetPermissionsFromRoles(_PlayerRoles),
			PlayerRoles = _PlayerRoles,
			GroupData = {},
		}
		self.Done = true
	end)

	Players.PlayerRemoving:Connect(function(v)
		self.Players[v] = nil
	end)

	RolesChanged:Connect(function(Player, Roles, gData)
		self.Players[Player] = self.Players[Player]
			or {
				Permissions = self:GetPermissionsFromRoles(Roles),
				PlayerRoles = Roles,
				GroupData = gData,
			}

		self.Players[Player].PlayerRoles = Roles
		self.Players[Player].GroupData = gData
		self.Players[Player].Permissions = self:GetPermissionsFromRoles(Roles)
		self.OnVerifyUpdate:Fire(Player, Roles)
	end)
end

function TitleService:KnitInit()
	self.Done = false
	self.Players = {}
	self.OnVerifyUpdate = signal.new()
end

return TitleService
