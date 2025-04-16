local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Knit = require(ReplicatedStorage.Packages.Knit)
local Promise = require(ReplicatedStorage.Packages.Promise)

local TransitionController = Knit.CreateController({ Name = "TransitionController" })

local tweenIn = TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local tweenOut = TweenInfo.new(0.45, Enum.EasingStyle.Quad, Enum.EasingDirection.In)

function TransitionController:In()
	return Promise.new(function(resolve)
		local newTween = TweenService:Create(self.Gui, tweenIn, {
			Size = UDim2.fromScale(1, 1),
		})
		local conn = nil
		conn = newTween.Completed:Connect(function()
			conn:Disconnect()
			conn = nil
			resolve()
		end)

		newTween:Play()
	end)
end

function TransitionController:Out()
	return Promise.new(function(resolve)
		local newTween = TweenService:Create(self.Gui, tweenOut, {
			Size = UDim2.fromScale(1, 0),
		})

		local conn = nil
		conn = newTween.Completed:Connect(function()
			conn:Disconnect()
			conn = nil
			resolve()
		end)

		newTween:Play()
	end)
end

function TransitionController:KnitStart()
	self.Gui = Knit.Player.PlayerGui:WaitForChild("Interface").Transition
end

return TransitionController
