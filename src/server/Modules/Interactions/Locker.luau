local Locker = {}
Locker.Type = "Locker"

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

function Locker.Verify(Player, Part)
	if Part:GetAttribute("Cooldown") == true then
		return false, {}
	end

	if Part.Parent:FindFirstChild("Permission") then
		local vals = Part.Parent.Permission.Value:split(",")
		local can = false
		for _, v in ipairs(vals) do
			local bool = Locker.TitleService:CheckPermission(Player, "CanOpen", v)
			if bool == true then
				can = true
				break
			end
		end

		if can then
			return true, { ["F"] = "Access Locker" }
		else
			return false, {}
		end
	end
end

function Locker.Init()
	Locker.TitleService = knit.GetService("TitleService")
end

function Locker.Close(Player)
	knit.GetService("Locker"):Close(Player)
end

function Locker.Execute(Player, _, Key)
	if Key == Enum.KeyCode.F then
		knit.GetService("Locker"):Open(Player)
	end
end

return Locker
