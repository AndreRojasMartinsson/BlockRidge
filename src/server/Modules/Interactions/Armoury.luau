local Armoury = {}
Armoury.Type = "Armoury"

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local knit = require(ReplicatedStorage.Packages.Knit)

local Config = require(ReplicatedStorage.Shared.Modules.Config)
local Teams = Config("Teams")

function GetTeamFromColor(brickColor)
	for _, v in ipairs(Teams) do
		if v.TeamColor == brickColor then
			return v
		end
	end
end

function Armoury.Verify(Player, Part)
	local bool = knit.GetService("TitleService"):CheckPermission(Player, "CanGetItems", "Radio")

	if Part and bool and Part:FindFirstChild("Agency") then
		return true, { ["F"] = "Access Armoury" }
	else
		return false, {}
	end
end

function Armoury.Init() end

function Armoury.Close(Player) end

function Armoury.Execute(Player, Part, Key)
	if Key == Enum.KeyCode.F then
		ReplicatedStorage.Armoury:FireClient(Player, Part:FindFirstChild("Agency").Value)
	end
end

return Armoury
