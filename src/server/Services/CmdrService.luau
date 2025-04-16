local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Knit = require(ReplicatedStorage.Packages.Knit)
local Cmdr = require(ServerScriptService.ServerPackages.Cmdr)

local WebhookService = require(ReplicatedStorage.Shared.Modules.WebhookService)

local CmdrService = Knit.CreateService({
	Name = "CmdrService",
	Client = {},
})

function CmdrService:KnitStart()
	
	Cmdr:RegisterCommandsIn(script.Parent.Parent.Modules.Commands)
	Cmdr:RegisterHooksIn(script.Parent.Parent.Modules.Hooks)
	Cmdr:RegisterTypesIn(script.Parent.Parent.Modules.Types)

	Cmdr.Registry:RegisterHook("AfterRun", function(context)
		-- Send Webhook Log
		local Webhook = WebhookService:CreateWebhook()
		local Embed = WebhookService:CreateEmbed()
		Webhook:SetAvatar("https://i.ibb.co/fxVCgzG/SOL.png")
		Webhook:SetUsername("Command Log - Lockridge")
		Embed:SetAuthor("Ingame Log")
		Embed:SetTitle("Command Log")
		Embed:SetDescription("A staff just ran a command within Cmdr.")
		Embed:AddField("Username", context.Executor.Name)
		Embed:AddField("Team", context.Executor.Team.Name)
		Embed:AddField("Date & Time", os.date("%c", os.time()))
		Embed:AddField("Group", context.Group)
		Embed:AddField("Command Name", context.Name)
		Embed:AddField("Full Command", context.RawText)
		Embed:SetColor(Color3.fromRGB(47, 49, 54))
		Embed:SetTimestamp()
		Webhook:AddEmbed(Embed)

		WebhookService:SendAsync(
			Webhook,
			"https://discord.com/api/webhooks/[HAH_PARK_THOUGHT_ID_INCLUDE_MY_TOKENS]/[HAH_PARK_THOUGHT_ID_INCLUDE_MY_TOKENS]"
		)
	
	end)

end

function CmdrService:KnitInit() end

return CmdrService
