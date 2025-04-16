local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local knit = require(ReplicatedStorage.Packages.Knit)

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

local InteractService = knit.CreateService({
	Name = "InteractService",
	Client = {},
	Middleware = {
		RateLimit,
	},
})

function InteractService:VerifyInteraction(Player, Part, IntType)
	if self.Interactions[IntType] then
		local valid, response = self.Interactions[IntType].Verify(Player, Part)
		return valid, response
	end

	return false, {}
end

function InteractService.Client:VerifyInteraction(Player, Part, IntType)
	if Player.Cuffer.Value ~= nil then
		return false, {}
	end

	local valid, response = self.Server:VerifyInteraction(Player, Part, IntType)
	return valid, response
end

function InteractService:ExecuteInteraction(Player, Part, IntType, Key)
	local valid = self:VerifyInteraction(Player, Part, IntType)

	if Player.Cuffer.Value ~= nil then
		return false
	end

	if valid == true then
		if self.Interactions[IntType] then
			local _valid = self.Interactions[IntType].Execute(Player, Part, Key)
			return _valid
		end

		return false
	end

	return false
end

function InteractService:CloseInteraction(Player, IntType)
	if self.Interactions[IntType] then
		if self.Interactions[IntType].Close then
			self.Interactions[IntType].Close(Player)
		end
	end
end

function InteractService.Client:ExecuteInteraction(Player, Part, IntType, Key)
	local valid = self.Server:ExecuteInteraction(Player, Part, IntType, Key)
	return valid
end

function InteractService.Client:CloseInteraction(Player, IntType)
	self.Server:CloseInteraction(Player, IntType)
end

function InteractService:KnitStart()
	task.wait(8)
	for _, v in ipairs(script.Parent.Parent.Modules.Interactions:GetChildren()) do
		if v:IsA("ModuleScript") then
			local r = require(v)
			if r.Init then
				r.Init()
			end

			self.Interactions[r.Type] = r
		end
	end

	Players.PlayerRemoving:Connect(function(player)
		if RateLimitPlayers[player] then
			RateLimitPlayers[player] = nil
		end
	end)

	for _, v in ipairs(workspace:WaitForChild("StaticStreaming").Doors:GetDescendants()) do
		if v:IsA("BasePart") then
			if v.Anchored == false then
				v:SetNetworkOwner(nil)
			end
		end
	end
end

function InteractService:KnitInit()
	self.Interactions = {}
end

return InteractService
