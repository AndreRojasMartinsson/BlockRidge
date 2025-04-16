local Players = game:GetService("Players")
local TextService = game:GetService("TextService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Packages.Knit)

local RateLimitPlayers = {}
local function RateLimit(Player: Player, Args: { any })
	-- Rate Limit to 5 requests per secondper player
	if RateLimitPlayers[Player] == nil then
		RateLimitPlayers[Player] = {
			Requests = 0,
			LastRequest = 0,
		}
	end
	local RateLimit = RateLimitPlayers[Player]
	local Time = tick()
	if Time - RateLimit.LastRequest < 0.2 then
		RateLimit.Requests = RateLimit.Requests + 1
		if RateLimit.Requests > 5 then
			return false, "You are sending too many requests. Please try again later."
		end
	else
		RateLimit.Requests = 0
	end
	RateLimit.LastRequest = Time

	return true
end

local NotificationService = Knit.CreateService({
	Name = "NotificationService",
	Client = {
		SendNotification = Knit.CreateSignal(),
	},
	Middleware = {
		Inbound = {
			RateLimit,
		},
	},
})

export type NotificationButton = {}

function NotificationService:SendBypass(
	Recipients: { Player },
	Title: string,
	Text: string,
	Icon: string,
	Type: string,
	Duration: number
)
	if Recipients then
		self.Client.SendNotification:FireFor(Recipients, Title, Text, Icon, Type, Duration)
	end
end

function NotificationService:Send(
	Player: Player,
	Recipients: { Player },
	Title: string,
	Text: string,
	Icon: string,
	Type: string,
	Duration: number
)
	if Player and Recipients then
		local FilteredResult: TextFilterResult =
			TextService:FilterStringAsync(Title, Player.UserId, Enum.TextFilterContext.PublicChat)
		local NewTitle = FilteredResult:GetNonChatStringForBroadcastAsync()

		FilteredResult = TextService:FilterStringAsync(Text, Player.UserId, Enum.TextFilterContext.PublicChat)
		local NewBody = FilteredResult:GetNonChatStringForBroadcastAsync()

		local idx = table.find(Recipients, Player)

		if Player == nil then
			if idx then
				table.remove(Recipients, idx)
			end
		end

		self.Client.SendNotification:FireFor(Recipients, NewTitle, NewBody, Icon, Type, Duration)
	end
end

function NotificationService.Client:Send(
	Player: Player,
	Recipients: { Player },
	Title: string,
	Text: string,
	Icon: string,
	Type: string,
	Duration: number
)
	return self.Server:Send(Player, Recipients, Title, Text, Icon, Type, Duration)
end

function NotificationService:KnitStart()
	Players.PlayerRemoving:Connect(function(player)
		if RateLimitPlayers[player] then
			RateLimitPlayers[player] = nil
		end
	end)
end

return NotificationService
