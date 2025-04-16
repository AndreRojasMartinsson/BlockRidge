local LockerInt = {}
LockerInt.Type = "LockerInt"

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

function LockerInt.Verify(Player, Part)
	local bool = knit.GetService("TitleService"):CheckPermission(Player, "CanGetItems", "Radio")

	if Part and bool and Part:FindFirstChild("Agency") then
		return true, { ["F"] = "Access Locker" }
	else
		return false, {}
	end
end

function LockerInt.Init() end

function LockerInt.Close(Player) end

function LockerInt.Execute(Player, Part, Key)
	if Key == Enum.KeyCode.F then
		ReplicatedStorage.Locker:FireClient(Player, Part:FindFirstChild("Agency").Value)
	end
end

return LockerInt
