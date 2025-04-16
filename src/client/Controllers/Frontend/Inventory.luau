local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Packages.Knit)

local Config = require(ReplicatedStorage.Shared.Modules.Config)
local Trove = require(ReplicatedStorage.Packages.Trove)
local BasicState = require(ReplicatedStorage.Packages.BasicState)
local Input = require(ReplicatedStorage.Packages.Input)

local ItemModule = Config("Items")

local Inventory = Knit.CreateController({ Name = "Inventory" })

function Inventory:Select(Id, UID)
	local curSelected = self.State:Get("Selected")
	if curSelected == UID then
		self.State:Set("Selected", nil)
	else
		self.State:Set("Selected", UID)
	end
end

function Inventory:UpdateContainer(Data)
	local container = self.Body.Items.ScrollingFrame
	local _, DataTable = self.InventoryService:Get():await()
	local EquippedTable = DataTable.Equipped

	-- * Clear
	self.SelectTrove:Clean()
	for _, v in ipairs(container:GetChildren()) do
		if v:IsA("TextButton") then
			v:Destroy()
		end
	end

	-- * Rehydrate
	for uid, data in pairs(Data) do
		local ItemData = ItemModule[tonumber(data.Id)]
		if ItemData then
			local Item = self.ItemTemplate:Clone()
			Item.Text = ItemData.Name
			Item.Name = uid

			-- * Check if Equipped
			if EquippedTable[uid] then
				Item.UIStroke.Color = Color3.fromRGB(56, 117, 170)
				Item.BackgroundColor3 = Color3.fromHex("#1c2235")
			end

			self.SelectTrove:Add(Item.MouseButton1Click:Connect(function()
				if Knit.Player.CurrentVehicle.Value ~= nil then
					return
				end
				self:Select(data.Id, uid)
			end))

			Item.Parent = container
		end
	end
end

function Inventory:Setup()
	self.InventoryService:Get():andThen(function(data)
		local Items = data.Items
		self:UpdateContainer(Items)
	end)

	local DropBtn = self.Actions.Drop
	local EquipBtn = self.Actions.Equip

	self.Trove:Add(EquipBtn.MouseButton1Click:Connect(function()
		if Knit.Player.CurrentVehicle.Value ~= nil then
			return
		end
		if Knit.Player.Cuffer.Value ~= nil then
			return
		end
		local selected = self.State:Get("Selected")
		if selected then
			if EquipBtn.Text == "EQUIP" then
				-- * Check if it can be equipped
				local _, DataTable = self.InventoryService:Get():await()
				if DataTable and DataTable.Items then
					local ItemDataTable = DataTable.Items[selected]
					if ItemDataTable then
						local Dat = ItemModule[ItemDataTable.Id]
						if Dat and Dat.Slot ~= -1 then
							self.InventoryService:EquipItem(selected)
							self.State:Set("Selected", nil)
						end
					end
				end
			elseif EquipBtn.Text == "UNEQUIP" then
				local _, DataTable = self.InventoryService:Get():await()
				if DataTable and DataTable.Items then
					local ItemDataTable = DataTable.Items[selected]
					if ItemDataTable then
						local Dat = ItemModule[ItemDataTable.Id]
						if Dat and Dat.Slot ~= -1 then
							self.InventoryService:UnequipItem(selected)
							self.State:Set("Selected", nil)
						end
					end
				end
			end
		end
	end))

	self.Trove:Add(DropBtn.MouseButton1Click:Connect(function()
		if Knit.Player.CurrentVehicle.Value ~= nil then
			return
		end
		if Knit.Player.Cuffer.Value ~= nil then
			return
		end
		local selected = self.State:Get("Selected")
		if selected then
			self.InventoryService:DropItem(selected)
			self.State:Set("Selected", nil)
		end
	end))

	-- Setup Within State
	self.Trove:Add(self.Gui.MouseEnter:Connect(function()
		self.State:Set("Within", true)
	end))

	self.Trove:Add(self.Gui.MouseLeave:Connect(function()
		self.State:Set("Within", false)
	end))

	self.Trove:Add(self.Mouse.LeftDown:Connect(function()
		if self.State:Get("Within") == false then
			self:Select(-1, self.State:Get("Selected"))
		end
	end))

	-- * Fix Exit Button
	self.Trove:Add(self.Gui.Header.Close.MouseButton1Click:Connect(function()
		if Knit.Player.CurrentVehicle.Value ~= nil then
			return
		end
		if Knit.Player.Cuffer.Value ~= nil then
			return
		end
		self.Trove:Clean()
		local container = self.Body.Items.ScrollingFrame

		-- * Clear
		self.SelectTrove:Clean()
		self.State:Set("Selected", nil)
		self.State:Set("Within", nil)

		self.Gui:TweenPosition(UDim2.fromScale(0.5, -1), Enum.EasingDirection.In, Enum.EasingStyle.Quad, 0.45)
		task.delay(0.4, function()
			self.State:Set("Open", false)

			for _, v in ipairs(container:GetChildren()) do
				if v:IsA("TextButton") then
					v:Destroy()
				end
			end
		end)
	end))

	self.Trove:Add(self.State:GetChangedSignal("Selected"):Connect(function(NewValue, OldValue)
		if NewValue then
			local _, DataTable = self.InventoryService:Get():await()
			local EquippedTable = DataTable.Equipped

			local container = self.Body.Items.ScrollingFrame
			container:FindFirstChild(NewValue).BackgroundTransparency = 0

			if OldValue then
				container:FindFirstChild(OldValue).BackgroundTransparency = 0.8
			end

			EquipBtn.TextTransparency = 0.9
			EquipBtn.AutoButtonColor = false

			local _ItemID = DataTable.Items[NewValue].Id
			if _ItemID then
				local _ItemData = ItemModule[_ItemID].Slot
				if _ItemData ~= -1 then
					EquipBtn.TextTransparency = 0
					EquipBtn.AutoButtonColor = true
				end
			end

			DropBtn.TextTransparency = 0

			DropBtn.AutoButtonColor = true

			if EquippedTable[NewValue] then
				EquipBtn.Text = "UNEQUIP"
			else
				EquipBtn.Text = "EQUIP"
			end
		else
			local container = self.Body.Items.ScrollingFrame
			if OldValue then
				container:FindFirstChild(OldValue).BackgroundTransparency = 0.8
			end

			EquipBtn.TextTransparency = 0.9
			DropBtn.TextTransparency = 0.9

			EquipBtn.AutoButtonColor = false
			DropBtn.AutoButtonColor = false
		end
	end))
end

function Inventory:Open()
	self.Gui.Header.Username.Text = Knit.Player.Name

	if self.State:Get("Open") == false then
		self:Setup()
		self.Gui:TweenPosition(UDim2.fromScale(0.5, 0.5), Enum.EasingDirection.Out, Enum.EasingStyle.Quad, 0.4)
		task.delay(0.35, function()
			self.State:Set("Open", true)
		end)
	end
end

function Inventory:SetLock(boolean)
	self.Locked = boolean
end

function Inventory:_Close()
	self.Trove:Clean()
	local container = self.Body.Items.ScrollingFrame

	-- * Clear
	self.SelectTrove:Clean()
	self.State:Set("Selected", nil)
	self.State:Set("Within", nil)

	self.Gui:TweenPosition(UDim2.fromScale(0.5, -1), Enum.EasingDirection.In, Enum.EasingStyle.Quad, 0.45)
	task.delay(0.4, function()
		self.State:Set("Open", false)

		for _, v in ipairs(container:GetChildren()) do
			if v:IsA("TextButton") then
				v:Destroy()
			end
		end
	end)
end

function Inventory:KnitStart()
	self.Gui = Knit.Player.PlayerGui:WaitForChild("Interface", 5):WaitForChild("Inventory")
	self.Body = self.Gui:WaitForChild("Body")
	self.Locked = false
	self.Actions = self.Body.Actions

	local layout: UIListLayout = self.Body.Items.ScrollingFrame.UIListLayout
	local absoluteContentSize = layout.AbsoluteContentSize
	self.Body.Items.ScrollingFrame.CanvasSize = UDim2.new(0, 0, 0, absoluteContentSize.Y)
	layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		local absoluteContentSize = layout.AbsoluteContentSize
		self.Body.Items.ScrollingFrame.CanvasSize = UDim2.new(0, 0, 0, absoluteContentSize.Y + 8)
	end)

	self.InventoryService = Knit.GetService("InventoryService")
	self.Keyboard.KeyDown:Connect(function(key)
		if key == Enum.KeyCode.G then
			if self.Locked then
				return
			end

			if Knit.Player.CurrentVehicle.Value ~= nil then
				return
			end

			if Knit.Player.Cuffer.Value ~= nil then
				return
			end

			Knit.GetController("Trunk"):_Close()
			Knit.GetController("Search"):_Close()

			self:Open()
		end
	end)

	self.InventoryService.OnUpdate:Connect(function()
		local success, data = self.InventoryService:Get():await()
		if success then
			local Items = data.Items
			self:UpdateContainer(Items)
		end
	end)
end

function Inventory:KnitInit()
	self.Mouse = Input.Mouse.new()
	self.Keyboard = Input.Keyboard.new()

	self.SelectTrove = Trove.new()
	self.Trove = Trove.new()
	self.State = BasicState.new({
		Selected = nil,
		Open = false,
		Within = false,
	})
	self.ItemTemplate = ReplicatedStorage.Assets.GUI.Inventory.ItemTemplate
end

return Inventory
