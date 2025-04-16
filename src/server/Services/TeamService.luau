local TeamsService = game:GetService("Teams")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Packages.Knit)
local Config = require(ReplicatedStorage.Shared.Modules.Config)
local Teams = Config("Teams")

local TeamService = Knit.CreateService({
	Name = "TeamService",
	Client = {},
})

function TeamService:KnitStart()
	for _, v in ipairs(Teams) do
		local new = Instance.new("Team")
		new.Name = v.Name
		new.AutoAssignable = v.Default and true or false
		new.TeamColor = v.TeamColor
		new.Parent = TeamsService
	end
end

return TeamService
