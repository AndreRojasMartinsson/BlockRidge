local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Packages.Knit)

local Config = require(ReplicatedStorage.Shared.Modules.Config)
local Trove = require(ReplicatedStorage.Packages.Trove)
local BasicState = require(ReplicatedStorage.Packages.BasicState)
local Input = require(ReplicatedStorage.Packages.Input)
local Promise = require(ReplicatedStorage.Packages.Promise)

local ItemModule = Config("Items")

local Search = Knit.CreateController({ Name = "Search" })

function Search:SelectTarget(Id, UID)
	local curSelected = self.State:Get("Selected_Target")
	if curSelected == UID then
		self.State:Set("Selected_Target", nil)

		local Actions = self.Target.Body.Actions
		Actions.Transfer.TextTransparency = 0.9
		Actions.Transfer.AutoButtonColor = false
	else
		self.State:Set("Selected_Target", UID)

		local Actions = self.Target.Body.Actions
		Actions.Transfer.TextTransparency = 0
		Actions.Transfer.AutoButtonColor = true
	end
end

function Search:SelectPlayer(Id, UID)
	local curSelected = self.State:Get("Selected_Player")
	if curSelected == UID then
		self.State:Set("Selected_Player", nil)

		local Actions = self.Player.Body.Actions
		Actions.Transfer.TextTransparency = 0.9
		Actions.Transfer.AutoButtonColor = false

		Actions.Equip.TextTransparency = 0.9
		Actions.Equip.AutoButtonColor = false
	else
		self.State:Set("Selected_Player", UID)

		local Actions = self.Player.Body.Actions
		Actions.Transfer.TextTransparency = 0
		Actions.Transfer.AutoButtonColor = true

		Actions.Equip.TextTransparency = 0
		Actions.Equip.AutoButtonColor = true
	end
end

function Search:UpdateTarget(Data)
	Data = Data or {}
	-- * Clear
	local container = self.Target.Body.Items.ScrollingFrame
	for _, v in ipairs(container:GetChildren()) do
		if v:IsA("TextButton") then
			v:Destroy()
		end
	end

	-- * Rehydrate
	for k, v in pairs(Data) do
		local ItemData = ItemModule[v.Id]

		if ItemData then
			local newItem = ReplicatedStorage.Assets.GUI.Inventory.ItemTemplate:Clone()
			newItem.Name = k
			newItem.Text = ItemData.Name

			self.SelectTrove:Add(newItem.MouseButton1Click:Connect(function()
				self:SelectTarget(v.Id, k)
			end))

			newItem.Parent = container
		end
	end
end

function Search:UpdatePlayer(Data)
	Data = Data or {}
	-- * Clear
	local container = self.Player.Body.Items.ScrollingFrame
	local _, DataTable = self.InventoryService:Get():await()
	local EquippedTable = DataTable.Equipped

	for _, v in ipairs(container:GetChildren()) do
		if v:IsA("TextButton") then
			v:Destroy()
		end
	end

	-- * Rehydrate
	for k, v in pairs(Data) do
		local ItemData = ItemModule[v.Id]
		if ItemData then
			local newItem = ReplicatedStorage.Assets.GUI.Inventory.ItemTemplate:Clone()
			newItem.Name = k
			newItem.Text = ItemData.Name

			if EquippedTable[k] then
				newItem.UIStroke.Color = Color3.fromRGB(56, 117, 170)
				newItem.BackgroundColor3 = Color3.fromHex("#1c2235")
			end

			self.SelectTrove:Add(newItem.MouseButton1Click:Connect(function()
				self:SelectPlayer(v.Id, k)
			end))

			newItem.Parent = container
		end
	end
end

function Search:_Close()
	self.TargetPlayer = nil
	self.Trove:Clean()
	local containerPlayer = self.Player.Body.Items.ScrollingFrame
	local containerTarget = self.Target.Body.Items.ScrollingFrame

	-- * Clear
	self.SelectTrove:Clean()
	self.State:Set("Selected_Target", nil)
	self.State:Set("Selected_Player", nil)
	self.State:Set("Within", nil)

	self.Gui:TweenPosition(UDim2.fromScale(0.5, -1), Enum.EasingDirection.In, Enum.EasingStyle.Quad, 0.45)
	task.delay(0.4, function()
		Knit.GetController("Inventory"):SetLock(false)

		for _, v in ipairs(containerPlayer:GetChildren()) do
			if v:IsA("TextButton") then
				v:Destroy()
			end
		end

		for _, v in ipairs(containerTarget:GetChildren()) do
			if v:IsA("TextButton") then
				v:Destroy()
			end
		end
	end)
end

function Search:Setup()
	self.InventoryService:Get():andThen(function(data)
		self:UpdatePlayer(data.Items)
	end)

	local Actions = self.Target.Body.Actions
	local PlayerActions = self.Player.Body.Actions

	self.Trove:Add(Actions.Transfer.MouseButton1Click:Connect(function()
		self.InventoryService:TransferFrom(self.TargetPlayer, self.State:Get("Selected_Target"))
	end))

	self.Trove:Add(PlayerActions.Transfer.MouseButton1Click:Connect(function()
		self.InventoryService:TransferTo(self.TargetPlayer, self.State:Get("Selected_Player"))
	end))

	self.Trove:Add(PlayerActions.Equip.MouseButton1Click:Connect(function()
		local selected = self.State:Get("Selected_Player")
		if selected then
			if PlayerActions.Equip.Text == "EQUIP" then
				self.InventoryService:EquipItem(selected)
				self.State:Set("Selected_Player", nil)
			elseif PlayerActions.Equip.Text == "UNEQUIP" then
				self.InventoryService:UnequipItem(selected)

				self.State:Set("Selected_Player", nil)
			end
		end
	end))

	self.Trove:Add(self.Target.Header.Close.MouseButton1Click:Connect(function()
		self.TargetPlayer = nil
		self.Trove:Clean()
		local containerPlayer = self.Player.Body.Items.ScrollingFrame
		local containerTarget = self.Target.Body.Items.ScrollingFrame

		-- * Clear
		self.SelectTrove:Clean()
		self.State:Set("Selected_Target", nil)
		self.State:Set("Selected_Player", nil)
		self.State:Set("Within", nil)

		self.Gui:TweenPosition(UDim2.fromScale(0.5, -1), Enum.EasingDirection.In, Enum.EasingStyle.Quad, 0.45)
		task.delay(0.4, function()
			self.State:Set("Open", false)
			Knit.GetController("Inventory"):SetLock(false)
			Knit.GetController("Inventory"):_Close()

			for _, v in ipairs(containerPlayer:GetChildren()) do
				if v:IsA("TextButton") then
					v:Destroy()
				end
			end

			for _, v in ipairs(containerTarget:GetChildren()) do
				if v:IsA("TextButton") then
					v:Destroy()
				end
			end
		end)
	end))

	self.Trove:Add(self.Player.Header.Close.MouseButton1Click:Connect(function()
		self.TargetPlayer = nil
		self.Trove:Clean()
		local containerPlayer = self.Player.Body.Items.ScrollingFrame
		local containerTarget = self.Target.Body.Items.ScrollingFrame

		-- * Clear
		self.SelectTrove:Clean()
		self.State:Set("Selected_Target", nil)
		self.State:Set("Selected_Player", nil)
		self.State:Set("Within", nil)

		self.Gui:TweenPosition(UDim2.fromScale(0.5, -1), Enum.EasingDirection.In, Enum.EasingStyle.Quad, 0.45)
		task.delay(0.4, function()
			self.State:Set("Open", false)
			Knit.GetController("Inventory"):SetLock(false)

			for _, v in ipairs(containerPlayer:GetChildren()) do
				if v:IsA("TextButton") then
					v:Destroy()
				end
			end

			for _, v in ipairs(containerTarget:GetChildren()) do
				if v:IsA("TextButton") then
					v:Destroy()
				end
			end
		end)
	end))

	self.Trove:Add(self.State:GetChangedSignal("Selected_Target"):Connect(function(New, Old)
		local container = self.Target.Body.Items.ScrollingFrame

		if New then
			local newFrame = container:FindFirstChild(New)
			if newFrame then
				newFrame.BackgroundTransparency = 0
			end
		end

		if Old then
			local oldFrame = container:FindFirstChild(Old)
			if oldFrame then
				oldFrame.BackgroundTransparency = 0.8
			end
		end
	end))

	self.Trove:Add(self.State:GetChangedSignal("Selected_Player"):Connect(function(New, Old)
		local container = self.Player.Body.Items.ScrollingFrame

		if New then
			local _, DataTable = self.InventoryService:Get():await()
			local EquippedTable = DataTable.Equipped

			if EquippedTable[New] then
				self.Player.Body.Actions.Equip.Text = "UNEQUIP"
			else
				self.Player.Body.Actions.Equip.Text = "EQUIP"
			end

			local newFrame = container:FindFirstChild(New)
			if newFrame then
				newFrame.BackgroundTransparency = 0
			end
		end

		if Old then
			local oldFrame = container:FindFirstChild(Old)
			if oldFrame then
				oldFrame.BackgroundTransparency = 0.8
			end
		end
	end))
end

function Search:Open()
	if self.State:Get("Open") == false then
		self:Setup()
		self.Player.Header.Username.Text = Knit.Player.Name
		Knit.GetController("Inventory"):SetLock(true)

		Knit.GetController("Inventory"):_Close()
		self.Gui:TweenPosition(UDim2.fromScale(0.5, 0.5), Enum.EasingDirection.Out, Enum.EasingStyle.Quad, 0.4)
		task.delay(0.35, function()
			self.State:Set("Open", true)
		end)
	end
end

function Search:KnitStart()
	self.Gui = Knit.Player.PlayerGui:WaitForChild("Interface", 5):WaitForChild("Search")
	self.OverrideGui = Knit.Player.PlayerGui:WaitForChild("Interface", 5):WaitForChild("ConsentOverride")
	self.Player = self.Gui:WaitForChild("Player")
	self.Target = self.Gui:WaitForChild("Target")

	ReplicatedStorage.Search.OnClientEvent:Connect(function(Target, Data)
		local success, data = self.InventoryService:Get():await()
		if success then
			self.Target.Header.Username.Text = Target.Name
			self:UpdatePlayer(data.Items)
			self:UpdateTarget(Data.Items)
			self:Open()
			self.TargetPlayer = Target
		end
	end)

	do
		local layout: UIListLayout = self.Player.Body.Items.ScrollingFrame.UIListLayout
		local absoluteContentSize = layout.AbsoluteContentSize
		self.Player.Body.Items.ScrollingFrame.CanvasSize = UDim2.new(0, 0, 0, absoluteContentSize.Y)
		layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
			local absoluteContentSize = layout.AbsoluteContentSize
			self.Player.Body.Items.ScrollingFrame.CanvasSize = UDim2.new(0, 0, 0, absoluteContentSize.Y + 8)
		end)
	end

	do
		local layout: UIListLayout = self.Target.Body.Items.ScrollingFrame.UIListLayout
		local absoluteContentSize = layout.AbsoluteContentSize
		self.Target.Body.Items.ScrollingFrame.CanvasSize = UDim2.new(0, 0, 0, absoluteContentSize.Y)
		layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
			local absoluteContentSize = layout.AbsoluteContentSize
			self.Target.Body.Items.ScrollingFrame.CanvasSize = UDim2.new(0, 0, 0, absoluteContentSize.Y + 8)
		end)
	end

	local ConsentGui = Knit.Player.PlayerGui:WaitForChild("Interface", 5):WaitForChild("Consent")
	local ConsentTrove = Trove.new()
	local OverrideTrove = Trove.new()

	ReplicatedStorage.ConsentOverride.OnClientInvoke = function(Target)
		local consentStatus = nil
		local UID = HttpService:GenerateGUID(false)
		local newBindable = Instance.new("BindableEvent")

		self.OverrideGui.Body.Desc.Text = (
			'<b>%s</b> has declined your search. <font color="#adadad">Do you want to override the decision?</font>'
		):format(Target.Name)
		self.OverrideGui:TweenPosition(UDim2.fromScale(0.5, 0.5), Enum.EasingDirection.Out, Enum.EasingStyle.Quad, 0.35)

		OverrideTrove:Add(self.OverrideGui.Body.No.MouseButton1Click:Connect(function()
			self.OverrideGui:TweenPosition(
				UDim2.fromScale(0.5, -1),
				Enum.EasingDirection.Out,
				Enum.EasingStyle.Quad,
				0.35
			)
			consentStatus = false
			newBindable:Fire()
			OverrideTrove:Clean()
		end))

		OverrideTrove:Add(self.OverrideGui.Body.Yes.MouseButton1Click:Connect(function()
			self.OverrideGui:TweenPosition(
				UDim2.fromScale(0.5, -1),
				Enum.EasingDirection.Out,
				Enum.EasingStyle.Quad,
				0.35
			)
			consentStatus = true
			newBindable:Fire()
			OverrideTrove:Clean()
		end))

		-- * Timeout
		task.delay(30, function()
			if newBindable and consentStatus == nil then
				consentStatus = false

				newBindable:Fire()
			end
		end)

		newBindable.Event:Wait()
		newBindable:Destroy()

		self.OverrideGui:TweenPosition(UDim2.fromScale(0.5, -1), Enum.EasingDirection.Out, Enum.EasingStyle.Quad, 0.35)

		return consentStatus
	end

	ReplicatedStorage.Consent.OnClientInvoke = function(Officer)
		local consentStatus = nil
		local UID = HttpService:GenerateGUID(false)
		local newBindable = Instance.new("BindableEvent")
		ConsentGui.Body.Desc.Text = (
			'<b>%s</b> wants to search your person. <font color="#adadad">Do you consent?</font>'
		):format(Officer.Name)
		ConsentGui:TweenPosition(UDim2.fromScale(0.5, 0.5), Enum.EasingDirection.Out, Enum.EasingStyle.Quad, 0.35)

		ConsentTrove:Add(ConsentGui.Body.Yes.MouseButton1Click:Connect(function()
			ConsentGui:TweenPosition(UDim2.fromScale(0.5, -1), Enum.EasingDirection.Out, Enum.EasingStyle.Quad, 0.35)
			consentStatus = true
			newBindable:Fire()
			ConsentTrove:Clean()
		end))

		ConsentTrove:Add(ConsentGui.Body.No.MouseButton1Click:Connect(function()
			ConsentGui:TweenPosition(UDim2.fromScale(0.5, -1), Enum.EasingDirection.Out, Enum.EasingStyle.Quad, 0.35)
			consentStatus = false
			newBindable:Fire()
			ConsentTrove:Clean()
		end))

		-- * Timeout
		task.delay(30, function()
			if newBindable and consentStatus == nil then
				consentStatus = false

				newBindable:Fire()
			end
		end)

		newBindable.Event:Wait()
		newBindable:Destroy()

		ConsentGui:TweenPosition(UDim2.fromScale(0.5, -1), Enum.EasingDirection.Out, Enum.EasingStyle.Quad, 0.35)

		return consentStatus
	end

	self.InventoryService = Knit.GetService("InventoryService")

	self.InventoryService.OnUpdate:Connect(function()
		local success, data = self.InventoryService:Get():await()
		if success then
			self:UpdatePlayer(data.Items)
		end
	end)
end

function Search:KnitInit()
	self.Mouse = Input.Mouse.new()
	self.Keyboard = Input.Keyboard.new()

	self.SelectTrove = Trove.new()
	self.Trove = Trove.new()
	self.CarUID = nil
	self.State = BasicState.new({
		Selected_Target = nil,
		Selected_Player = nil,
		Open = false,
		Within = false,
	})
	self.ItemTemplate = ReplicatedStorage.Assets.GUI.Inventory.ItemTemplate
end

return Search
