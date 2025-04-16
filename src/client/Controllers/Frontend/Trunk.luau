local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Packages.Knit)

local Config = require(ReplicatedStorage.Shared.Modules.Config)
local Trove = require(ReplicatedStorage.Packages.Trove)
local BasicState = require(ReplicatedStorage.Packages.BasicState)
local Input = require(ReplicatedStorage.Packages.Input)

local ItemModule = Config("Items")

local Trunk = Knit.CreateController({ Name = "Trunk" })

function Trunk:SelectTrunk(Id, UID)
	local curSelected = self.State:Get("Selected_Trunk")
	if curSelected == UID then
		self.State:Set("Selected_Trunk", nil)

		local Actions = self.Trunk.Body.Actions
		Actions.Transfer.TextTransparency = 0.9
		Actions.Transfer.AutoButtonColor = false
	else
		self.State:Set("Selected_Trunk", UID)

		local Actions = self.Trunk.Body.Actions
		Actions.Transfer.TextTransparency = 0
		Actions.Transfer.AutoButtonColor = true
	end
end

function Trunk:SelectPlayer(Id, UID)
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

function Trunk:UpdateTrunk(Data)
	-- * Clear
	local container = self.Trunk.Body.Items.ScrollingFrame
	for _, v in ipairs(container:GetChildren()) do
		if v:IsA("TextButton") then
			v:Destroy()
		end
	end

	-- * Rehydrate
	local DataTable = Data[self.CarUID]
	if DataTable then
		for k, v in pairs(DataTable.Trunk) do
			local ItemData = ItemModule[v.Id]

			if ItemData then
				local newItem = ReplicatedStorage.Assets.GUI.Inventory.ItemTemplate:Clone()
				newItem.Name = k
				newItem.Text = ItemData.Name

				self.SelectTrove:Add(newItem.MouseButton1Click:Connect(function()
					self:SelectTrunk(v.Id, k)
				end))

				newItem.Parent = container
			end
		end
	end
end

function Trunk:UpdatePlayer(Data)
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

function Trunk:_Close()
	self.CarUID = nil
	self.Trove:Clean()
	local containerPlayer = self.Player.Body.Items.ScrollingFrame
	local containerTrunk = self.Trunk.Body.Items.ScrollingFrame

	-- * Clear
	self.SelectTrove:Clean()
	self.State:Set("Selected_Trunk", nil)
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

		for _, v in ipairs(containerTrunk:GetChildren()) do
			if v:IsA("TextButton") then
				v:Destroy()
			end
		end
	end)
end

function Trunk:Setup()
	self.VehicleService:Get():andThen(function(data)
		self:UpdateTrunk(data)
	end)

	self.InventoryService:Get():andThen(function(data)
		self:UpdatePlayer(data.Items)
	end)

	local Actions = self.Trunk.Body.Actions
	self.Trove:Add(Actions.Transfer.MouseButton1Click:Connect(function()
		if self.State:Get("Selected_Trunk") then
			-- TODO: Transfer the Item
			self.VehicleService:Transfer(self.State:Get("Selected_Trunk"), self.CarUID)
		end
	end))

	local PlayerActions = self.Player.Body.Actions
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

	self.Trove:Add(self.Trunk.Header.Close.MouseButton1Click:Connect(function()
		self.CarUID = nil
		self.Trove:Clean()
		local containerPlayer = self.Player.Body.Items.ScrollingFrame
		local containerTrunk = self.Trunk.Body.Items.ScrollingFrame

		-- * Clear
		self.SelectTrove:Clean()
		self.State:Set("Selected_Trunk", nil)
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

			for _, v in ipairs(containerTrunk:GetChildren()) do
				if v:IsA("TextButton") then
					v:Destroy()
				end
			end
		end)
	end))

	self.Trove:Add(self.Player.Header.Close.MouseButton1Click:Connect(function()
		self.CarUID = nil
		self.Trove:Clean()
		local containerPlayer = self.Player.Body.Items.ScrollingFrame
		local containerTrunk = self.Trunk.Body.Items.ScrollingFrame

		-- * Clear
		self.SelectTrove:Clean()
		self.State:Set("Selected_Trunk", nil)
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

			for _, v in ipairs(containerTrunk:GetChildren()) do
				if v:IsA("TextButton") then
					v:Destroy()
				end
			end
		end)
	end))

	self.Trove:Add(PlayerActions.Transfer.MouseButton1Click:Connect(function()
		if self.State:Get("Selected_Player") then
			-- TODO: Transfer the Item
			self.InventoryService
				:UnequipItem(self.State:Get("Selected_Player"))
				:andThen(function()
					self.InventoryService:Transfer(self.State:Get("Selected_Player"), self.CarUID)
					self.State:Set("Selected_Player", nil)
				end)
				:catch(warn)
		end
	end))

	self.Trove:Add(self.State:GetChangedSignal("Selected_Trunk"):Connect(function(New, Old)
		local container = self.Trunk.Body.Items.ScrollingFrame

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

function Trunk:Open()
	if self.State:Get("Open") == false then
		self.Player.Header.Username.Text = Knit.Player.Name
		self:Setup()
		self.Gui:TweenPosition(UDim2.fromScale(0.5, 0.5), Enum.EasingDirection.Out, Enum.EasingStyle.Quad, 0.4)
		Knit.GetController("Inventory"):_Close()

		Knit.GetController("Inventory"):SetLock(true)

		task.delay(0.35, function()
			self.State:Set("Open", true)
		end)
	end
end

function Trunk:KnitStart()
	self.Gui = Knit.Player.PlayerGui:WaitForChild("Interface", 5):WaitForChild("Trunk")
	self.Player = self.Gui:WaitForChild("Player")
	self.Trunk = self.Gui:WaitForChild("Trunk")

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
		local layout: UIListLayout = self.Trunk.Body.Items.ScrollingFrame.UIListLayout
		local absoluteContentSize = layout.AbsoluteContentSize
		self.Trunk.Body.Items.ScrollingFrame.CanvasSize = UDim2.new(0, 0, 0, absoluteContentSize.Y)
		layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
			local absoluteContentSize = layout.AbsoluteContentSize
			self.Trunk.Body.Items.ScrollingFrame.CanvasSize = UDim2.new(0, 0, 0, absoluteContentSize.Y + 8)
		end)
	end

	self.VehicleService = Knit.GetService("VehicleService")
	self.InventoryService = Knit.GetService("InventoryService")

	self.VehicleService.OpenTrunk:Connect(function(UID)
		self.CarUID = UID
		self:Open()
	end)

	self.VehicleService.CloseTrunk:Connect(function()
		self.CarUID = nil
		self.Trove:Clean()
		local containerPlayer = self.Player.Body.Items.ScrollingFrame
		local containerTrunk = self.Trunk.Body.Items.ScrollingFrame

		-- * Clear
		self.SelectTrove:Clean()
		self.State:Set("Selected_Trunk", nil)
		self.State:Set("Selected_Player", nil)
		self.State:Set("Within", nil)

		self.Gui:TweenPosition(UDim2.fromScale(0.5, -1), Enum.EasingDirection.In, Enum.EasingStyle.Quad, 0.45)
		task.delay(0.4, function()
			self.State:Set("Open", false)
			Knit.GetController("Inventory"):SetLock(true)

			for _, v in ipairs(containerPlayer:GetChildren()) do
				if v:IsA("TextButton") then
					v:Destroy()
				end
			end

			for _, v in ipairs(containerTrunk:GetChildren()) do
				if v:IsA("TextButton") then
					v:Destroy()
				end
			end
		end)
	end)

	self.VehicleService.OnUpdate:Connect(function()
		local success, data = self.VehicleService:Get():await()
		if success then
			self:UpdateTrunk(data)
		end
	end)

	self.InventoryService.OnUpdate:Connect(function()
		local success, data = self.InventoryService:Get():await()
		if success then
			self:UpdatePlayer(data.Items)
		end
	end)
end

function Trunk:KnitInit()
	self.Mouse = Input.Mouse.new()
	self.Keyboard = Input.Keyboard.new()

	self.SelectTrove = Trove.new()
	self.Trove = Trove.new()
	self.CarUID = nil
	self.State = BasicState.new({
		Selected_Trunk = nil,
		Selected_Player = nil,
		Open = false,
		Within = false,
	})
	self.ItemTemplate = ReplicatedStorage.Assets.GUI.Inventory.ItemTemplate
end

return Trunk
