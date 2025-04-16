local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Packages.Knit)

local Sync = Knit.CreateController({ Name = "Sync" })
local Promise = require(ReplicatedStorage.Packages.Promise)

function Sync:GetMeanLatency()
	return self.MeanLatency
end

function Sync:KnitStart()
	self.LatencyBuffer = {}
	self.MeanLatency = nil
	self.Tick = tick()

	task.spawn(function()
		while true do
			self.Tick = tick()
			Knit.GetService("SyncService"):GetLatency():await()
			local latency = tick() - self.Tick

			if #self.LatencyBuffer > 10 then
				-- * Calculate Mean Latency & Set It
				local meanLatency = 0
				for _, lat in ipairs(self.LatencyBuffer) do
					meanLatency += lat
				end
				meanLatency /= #self.LatencyBuffer
				self.MeanLatency = meanLatency

				table.clear(self.LatencyBuffer)
			else
				table.insert(self.LatencyBuffer, latency)
			end
			task.wait(1)
		end
	end)
end

return Sync
