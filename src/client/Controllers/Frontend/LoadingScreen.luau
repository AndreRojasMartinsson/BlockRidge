local ContentProvider = game:GetService("ContentProvider")
local ReplicatedFirst = game:GetService("ReplicatedFirst")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Knit = require(ReplicatedStorage.Packages.Knit)

local Config = require(ReplicatedStorage.Shared.Modules.Config)
local Trove = require(ReplicatedStorage.Packages.Trove)
local BasicState = require(ReplicatedStorage.Packages.BasicState)
local Input = require(ReplicatedStorage.Packages.Input)
local Promise = require(ReplicatedStorage.Packages.Promise)

local Config = require(ReplicatedStorage.Shared.Modules.Config)
local Assets = Config("Assets")

local LoadingScreen = Knit.CreateController({ Name = "LoadingScreen" })

local _tweenInf = TweenInfo.new(3, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut)
function LoadingScreen:KnitStart()
	self.Gui = Knit.Player.PlayerGui:WaitForChild("Interface", 5):WaitForChild("Loading")
	self.Gui.Visible = true
	task.spawn(function()
		while not self.State:Get("Finished") do
			TweenService:Create(self.Gui.Logo.UIStroke, _tweenInf, { Color = Color3.fromRGB(101, 170, 68) }):Play()
			task.wait(3)
			if self.State:Get("Finished") then
				break
			end
			TweenService:Create(self.Gui.Logo.UIStroke, _tweenInf, { Color = Color3.fromRGB(170, 139, 67) }):Play()
			task.wait(3)
			if self.State:Get("Finished") then
				break
			end
			TweenService:Create(self.Gui.Logo.UIStroke, _tweenInf, { Color = Color3.fromRGB(170, 64, 64) }):Play()
			task.wait(3)
			if self.State:Get("Finished") then
				break
			end
			TweenService:Create(self.Gui.Logo.UIStroke, _tweenInf, { Color = Color3.fromRGB(59, 135, 170) }):Play()
			task.wait(3)
			if self.State:Get("Finished") then
				break
			end
		end
	end)

	self.State:GetChangedSignal("UpperText"):Connect(function(new)
		self.Gui.Label.Text = new
	end)

	self.State:GetChangedSignal("LowerText"):Connect(function(new)
		self.Gui.Hint.Text = new
	end)

	self.State:Set("UpperText", "YEILDING ...")
	self.State:Set("LowerText", "The system is currently yielding for the Chunk system to finish.")

	task.spawn(function()
		local char = Knit.Player.Character or Knit.Player.CharacterAdded:Wait()
		char:WaitForChild("Humanoid")
		char.Humanoid.WalkSpeed = 0
	end)

	-- Loading Procedure
	self.Trove:Add(function()
		self.State:Set("Finished", true)
		self.State:Set("UpperText", "LOADING FINISHED!")
		self.State:Set("LowerText", "Have fun.")
		task.wait(1)

		self.Gui:TweenPosition(UDim2.fromScale(0, -1), Enum.EasingDirection.In, Enum.EasingStyle.Quad, 0.5)
		task.wait(0.5)
		self.Gui:Destroy()
	end)

	--task.wait(1)

	-- Make Sure Streaming is DOne

	Promise.new(function(resolve)
		if ReplicatedFirst:GetAttribute("StreamingFinished") == true then
			resolve()
		else
			local con = nil
			con = ReplicatedStorage:WaitForChild("StreamingFinished").Event:Connect(function()
				resolve()
				con:Disconnect()
			end)
		end

		task.spawn(function()
			while true do
				if ReplicatedFirst:GetAttribute("StreamingFinished") == true then
					resolve()
					break
				end
				task.wait(0.05)
			end
		end)
	end):andThen(function()
		self.State:Set("UpperText", "PRELOADING NECESSARY ASSETS ...")
		self.Gui.Bottom.Loading.Bar:TweenSize(
			UDim2.fromScale(1 / 3, 1),
			Enum.EasingDirection.InOut,
			Enum.EasingStyle.Quad,
			0.6
		)

		local Total = #Assets
		local Current = 1
		for _, v in ipairs(Assets) do
			self.State:Set("LowerText", ("%s <font size='14'><b>  ( %d / %d )</b></font>"):format(v, Current, Total))
		--	ContentProvider:PreloadAsync({ v })
			Current += 1
			task.wait(0.0015)
		end

		self.State:Set("UpperText", "YIELDING ...")
		self.State:Set("LowerText", "WAITING FOR THE INTERACTION SYSTEM TO FINISH ...")

		Promise.new(function(resolve)
			if ReplicatedStorage:GetAttribute("IntFinished") == true then
				resolve()
			else
				local con = nil
				con = ReplicatedStorage:WaitForChild("IntFinished").Event:Connect(function()
					con:Disconnect()
					resolve()
				end)
			end

			while true do
				if ReplicatedStorage:GetAttribute("IntFinished") == true then
					resolve()
					break
				end
				task.wait(0.05)
			end
		end):andThen(function()
			self.Gui.Bottom.Loading.Bar:TweenSize(
				UDim2.fromScale(2 / 3, 1),
				Enum.EasingDirection.InOut,
				Enum.EasingStyle.Quad,
				0.6
			)

			local char = Knit.Player.Character or Knit.Player.CharacterAdded:Wait()
			char:WaitForChild("Humanoid")
			char.Humanoid.WalkSpeed = 12

			self.State:Set("UpperText", "FINALIZING ...")
			self.State:Set("LowerText", "Finalizing and cleaning up connections.")

			task.wait(1.3)
			self.Gui.Bottom.Loading.Bar:TweenSize(
				UDim2.fromScale(1, 1),
				Enum.EasingDirection.InOut,
				Enum.EasingStyle.Quad,
				0.6
			)
			task.wait(1)
			self.Trove:Destroy()
		end)
	end)

	-- Load Assets
end

function LoadingScreen:KnitInit()
	self.Trove = Trove.new()
	self.State = BasicState.new({
		UpperText = "",
		Finished = false,
		LowerText = "",
	})
end

return LoadingScreen
