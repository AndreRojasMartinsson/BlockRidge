local TeamChanger = {}
TeamChanger.Type = "TeamChanger"

local Players = game:GetService("Players")
local Teams = game:GetService("Teams")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local knit = require(ReplicatedStorage.Packages.Knit)

local Config = require(ReplicatedStorage.Shared.Modules.Config)
local Streamable = require(ReplicatedStorage.Packages.Streamable)
local TeamsModule = Config("Teams")

function GetTeamFromColor(brickColor)
	for i, v in ipairs(TeamsModule) do
		if v.TeamColor == brickColor then
			return v
		end
	end
end

local function getTeamFromIdx(Idx)
	local team = nil
	for _, v in ipairs(TeamsModule) do
		if v.Idx == Idx then
			team = v
			break
		end
	end

	return team
end
function TeamChanger.Verify(Player: Player, Part)
	local char = Player.Character
	local humanoid = char and char.Humanoid

	if char and humanoid then
		if humanoid.Health > 0 then
			if Part and Part:FindFirstChild("Team") then
				if
					TeamChanger.TitleService:CheckPermission(Player, "CanChangeTeam", Part:FindFirstChild("Team").Value)
				then
					local _team = GetTeamFromColor(Player.TeamColor)
					if _team.Idx == Part.Team.Value then
						return true, { ["F"] = "Go Off Team" }
					else
						local NewTeam = getTeamFromIdx(Part.Team.Value)
						if NewTeam then
							return true, { ["F"] = "Go On Team: " .. NewTeam.Name }
						end
					end
				end
			end
		end
	end

	return false, {}
end

local DebouncePlayer = {}
function TeamChanger.Init()
	TeamChanger.TitleService = knit.GetService("TitleService")
	Players.PlayerRemoving:Connect(function(player)
		DebouncePlayer[player] = nil
	end)
end

function TeamChanger.Execute(Player, Part, Key)
	if Key == Enum.KeyCode.F then
		-- * Rate Limit
		DebouncePlayer[Player] = DebouncePlayer[Player] or false

		if DebouncePlayer[Player] == false then
			DebouncePlayer[Player] = true

			local _team = GetTeamFromColor(Player.TeamColor)
			if _team.Idx == Part.Team.Value then
				Player.Team = Teams:FindFirstChild("Resident")
				knit.GetService("NotificationService"):SendBypass(
					{ Player },
					"Changed Team!",
					"You have changed your team to: " .. Player.Team.Name .. ".",
					"rbxassetid://10345606534",
					"Success",
					8
				)
			else
				local NewTeam = getTeamFromIdx(Part.Team.Value)
				if NewTeam then
					Player.Team = Teams:FindFirstChild(NewTeam.Name)
					knit.GetService("NotificationService"):SendBypass(
						{ Player },
						"Changed Team!",
						"You have changed your team to: " .. NewTeam.Name .. ".",
						"rbxassetid://10345606534",
						"Success",
						8
					)
				end
			end

			task.delay(5, function()
				DebouncePlayer[Player] = false
			end)
		end
	end
end

return TeamChanger
