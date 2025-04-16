local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Packages.Knit)
local Cmdr = require(ReplicatedStorage:WaitForChild("CmdrClient"))
local TableUtil = require(ReplicatedStorage.Packages.TableUtil)

local Config = require(ReplicatedStorage.Shared.Modules.Config)
local Environment = Config("Environment")

local CmdrController = Knit.CreateController({ Name = "CmdrController" })

function CmdrController:KnitStart()
	Cmdr:SetActivationKeys({ Enum.KeyCode.F2 })
	Cmdr:SetActivationUnlocksMouse(true)
	Cmdr:SetHideOnLostFocus(true)
	Cmdr:SetPlaceName("Lockridge_Testing")

	local AuthorisedUsers = TableUtil.Assign(Environment.Moderators, Environment.Admins, Environment.Root)
	if table.find(AuthorisedUsers, Knit.Player.UserId) then
		Cmdr:SetEnabled(true)
	else
		Cmdr:SetEnabled(false)
	end
end

return CmdrController
