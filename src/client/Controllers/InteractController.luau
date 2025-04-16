local CollectionService = game:GetService("CollectionService")
local ReplicatedFirst = game:GetService("ReplicatedFirst")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local knit = require(ReplicatedStorage.Packages.Knit)

local InteractController = knit.CreateController({ Name = "InteractController" })
local input = require(ReplicatedStorage.Packages.Input)
local Keyboard = input.Keyboard.new()
local Trove = require(ReplicatedStorage.Packages.Trove)
local Keybind = ReplicatedStorage.Assets.Keybind

function InteractController:CreateRegion3(pos, size)
	local SizeOffset = size / 2
	local P1 = pos - SizeOffset
	local P2 = pos + SizeOffset
	return Region3.new(P1, P2)
end

function InteractController:GetIgnoreList(InVehicle)
	local def = {
		knit.Character,
		workspace:WaitForChild("Ignore"),
	}

	if InVehicle then
		for _, v in ipairs(CollectionService:GetTagged("ServerCar")) do
			table.insert(def, v)
		end
	end
end

function InteractController:UpdateClosestInteraction()
	local nearby = {}

	knit.Player:WaitForChild("Cuffer", 10)

	if knit.Player.Cuffer.Value ~= nil then
		return {}
	end

	for _, v in ipairs(self.Interactions) do
		if v:IsDescendantOf(knit.Character) then
			continue
		end
		if v:FindFirstChild("Interaction") then
			local r = require(v.Interaction)

			if knit.Player:DistanceFromCharacter(v.Position) < r.Range then
				table.insert(nearby, v)
			end
		end
	end

	local closestDist = nil
	local closest = nil
	for _, v in ipairs(nearby) do
		if closestDist == nil then
			closest = v
			closestDist = (self.Mouse.Hit.Position - v.Position).Magnitude
			continue
		end

		local dist = (self.Mouse.Hit.Position - v.Position).Magnitude
		if dist < closestDist then
			closestDist = dist
			closest = v
		end
	end

	if closest then
		self.Current = closest
	else
		self.Current = nil
	end
end

function InteractController:Render()
	self:UpdateClosestInteraction()
	if self.Current and self.Current:FindFirstChild("Interaction") then
		local r = require(self.Current.Interaction)
		self.InteractService:VerifyInteraction(self.Current, r.Type):andThen(function(valid, returnTable)
			if valid then
				for _, v in ipairs(self.Gui:GetChildren()) do
					if v:IsA("Frame") then
						v:Destroy()
					end
				end
				for k, v in pairs(returnTable) do
					local new = Keybind:Clone()
					new.Key.KeyLabel.Text = k:upper()
					new:SetAttribute("IntType", r.Type)
					new.Label.Text = v
					new.Parent = self.Gui
				end

				self.Gui.Enabled = true
				self.Gui.Adornee = self.Current
			else
				self.Gui.Enabled = false
				for _, v in ipairs(self.Gui:GetChildren()) do
					if v:IsA("Frame") then
						self.InteractService:CloseInteraction(v:GetAttribute("IntType"))
						v:Destroy()
					end
				end
				self.Gui.Adornee = nil
			end
		end)
	else
		self.Gui.Enabled = false
		for _, v in ipairs(self.Gui:GetChildren()) do
			if v:IsA("Frame") then
				self.InteractService:CloseInteraction(v:GetAttribute("IntType"))

				v:Destroy()
			end
		end
		self.Gui.Adornee = nil
	end
end

function InteractController:UpdateInteractions()
	table.clear(self.Interactions)
	for _, v in ipairs(CollectionService:GetTagged("__Interactive__")) do
		table.insert(self.Interactions, v)
	end
end

function InteractController:Cleanup()
	self.Trove:Clean()
	RunService:UnbindFromRenderStep("_InteractController")
end

function InteractController:Setup()
	self:Cleanup()
	-- Update the Interactions Table Accordingly

	self:UpdateInteractions()
	self.Trove:Add(CollectionService:GetInstanceAddedSignal("__Interactive__"):Connect(function()
		self:UpdateInteractions()
	end))

	self.Trove:Add(CollectionService:GetInstanceRemovedSignal("__Interactive__"):Connect(function()
		self:UpdateInteractions()
	end))

	-- Lifecycle Handling
	local start = tick()
	RunService:BindToRenderStep("_InteractController", Enum.RenderPriority.Character.Value, function()
		if tick() - start >= self.Loop_Rate then
			self:Render()
			start = tick()
		end
	end)

	-- Input Handling
	self.Trove:Add(Keyboard.KeyDown:Connect(function(key: Enum.KeyCode)
		if self.Gui and knit.Character and knit.Character:FindFirstChild("Humanoid") then
			for _, v in ipairs(self.Gui:GetChildren()) do
				if v:IsA("Frame") and v.Key.KeyLabel.Text:upper() == key.Name:upper() then
					v.ImageLabel.ImageColor3 = Color3.fromRGB(69, 125, 176)
					v.ImageLabel.ImageTransparency = 0.6
				end
			end
		end
	end))

	self.Trove:Add(Keyboard.KeyUp:Connect(function(key: Enum.KeyCode)
		-- do server handling
		if self.Gui and knit.Character and knit.Character:FindFirstChild("Humanoid") then
			for _, v in ipairs(self.Gui:GetChildren()) do
				--[[if v:IsA("Frame") and v.Key.KeyLabel.Text:upper() == key.Name:upper() then

			end--]]
				if v:IsA("Frame") and v.Key.KeyLabel.Text:lower() == key.Name:lower() then
					v.ImageLabel.ImageColor3 = Color3.fromRGB(37, 37, 37)
					v.ImageLabel.ImageTransparency = 0
				end
			end

			if self.Current then
				self.Current:WaitForChild("Interaction", 4)
				if self.Current and self.Current:FindFirstChild("Interaction") then
					local r = require(self.Current:FindFirstChild("Interaction"))
					self.InteractService:VerifyInteraction(self.Current, r.Type):andThen(function(valid, returnTable)
						if valid then
							for k in pairs(returnTable) do
								if key == Enum.KeyCode[k] then
									self.InteractService:ExecuteInteraction(self.Current, r.Type, key)
								end
							end
						end
					end)
				end
			end
		end
	end))
end

function InteractController:KnitStart()
	local bindable = Instance.new("BindableEvent")
	if ReplicatedFirst:GetAttribute("StreamingFinished") == true then
		bindable:Fire()
	else
		local con = nil
		con = ReplicatedStorage:WaitForChild("StreamingFinished").Event:Connect(function()
			if bindable then
				bindable:Fire()
			end
			con:Disconnect()
		end)
	end

	bindable.Event:Wait()
	bindable:Destroy()

	task.wait(5)
	ReplicatedStorage.IntFinished:Fire()
	ReplicatedStorage:SetAttribute("IntFinished", true)

	self.Gui = knit.Player:WaitForChild("PlayerGui"):WaitForChild("Interact")
	self.Mouse = knit.Player:GetMouse()
	self.Trove = Trove.new()
	self.InteractService = knit.GetService("InteractService")

	knit.Player.CharacterAdded:Connect(function(character)
		character:WaitForChild("Humanoid")
		character:WaitForChild("Torso")
		self:Setup()
	end)

	self:Setup()
end

function InteractController:KnitInit()
	self.Loop = false
	self.Loop_Rate = 0.1
	self.Interactions = {}
	self.Current = nil
end

return InteractController
