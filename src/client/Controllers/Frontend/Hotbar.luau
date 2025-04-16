local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Knit = require(ReplicatedStorage.Packages.Knit)

local Hotbar = Knit.CreateController({ Name = "Hotbar" })
local BasicState = require(ReplicatedStorage.Packages.BasicState)
local Input = require(ReplicatedStorage.Packages.Input)
local Trove = require(ReplicatedStorage.Packages.Trove)

local Config = require(ReplicatedStorage.Shared.Modules.Config)
local ItemModule = Config("Items")

local TWEENINFO = TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local KEYCODE_CONVERSION = {
	[Enum.KeyCode.One] = 1,
	[Enum.KeyCode.Two] = 2,
	[Enum.KeyCode.Three] = 3,
	[Enum.KeyCode.Four] = 4,
	[Enum.KeyCode.Five] = 5,
	[Enum.KeyCode.Six] = 6,
	[Enum.KeyCode.Seven] = 7,
	[Enum.KeyCode.Eight] = 8,
	[Enum.KeyCode.Nine] = 9,
}

function Hotbar:SelectSlot(UID)
	local Inventory = self.State:Get("Inventory")
	local Equipped = Inventory.Equipped

	if not Equipped[UID] then
		return false
	end

	if self.State:Get("DrawDebounce") == true then
		return false
	end

	Knit.GetService("InventoryService"):SetDrawn(UID)
end

function Hotbar:SetDrawn(Slot)
	if self.State:Get("Drawn") ~= Slot.Name then
		return false
	end

	local Stroke: UIStroke = Slot.UIStroke
	Stroke.Color = Color3.fromRGB(64, 136, 204)
	Slot.BackgroundColor3 = Color3.fromHex("#1f3e6d")

	-- * If has rounds then move it up
	local Item = self:GetItemFromUID(Slot.Name)
	if not Item.Attributes then
		return
	end

	if not Item.Attributes.Rounds then
		return
	end

	Slot.ImageLabel.Position = UDim2.fromScale(0.5, 0.05)
end

function Hotbar:Update()
	local _, Inventory = Knit.GetService("InventoryService"):Get():await()
	local Equipped = Inventory.Equipped

	-- *Remove Slots that have been unequipped

	for _, slot in ipairs(self.Items:GetChildren()) do
		if not slot:IsA("TextButton") then
			continue
		end

		if Equipped[slot.Name] then
			continue
		end

		Knit.GetService("InventoryService"):SetDrawn(slot.Name)
		slot:Destroy()
	end

	-- *Add Slots that was not there before
	for uid, item in pairs(Equipped) do
		if self.Items:FindFirstChild(uid) then
			continue
		end

		local ItemData = ItemModule[item.Id]
		if not ItemData then
			continue
		end

		local NewSlot = self.Template:Clone()
		NewSlot.Name = uid
		NewSlot.ImageLabel.Image = ItemData.Thumbnail
		NewSlot.Mags.Visible = false
		NewSlot.LayoutOrder = tonumber(ItemData.Slot)
		NewSlot.Rounds.TextTransparency = 1
		NewSlot.TextLabel.Text = tostring(ItemData.Slot)

		local IsPrimary = ItemData.Slot == 1 and true or false
		NewSlot.UIAspectRatioConstraint.AspectRatio = IsPrimary and 2 or 1

		-- TODO: Check if Item is drawn, if it is then update accordingly
		self:SetDrawn(NewSlot)

		self.SlotTrove:Add(NewSlot.MouseButton1Click:Connect(function()
			self:SelectSlot(NewSlot.Name)
		end))

		NewSlot.Parent = self.Items
	end
end

function Hotbar:GetItemFromUID(UID)
	local _, Inventory = Knit.GetService("InventoryService"):Get():await()
	local _Items = Inventory.Items
	local Item = nil

	for uid, dat in pairs(_Items) do
		if uid == UID then
			Item = dat
			break
		end
	end

	return Item
end

function Hotbar:GetUIDFromSlot(Slot)
	local UID = nil
	for _, slot in ipairs(self.Items:GetChildren()) do
		if not slot:IsA("TextButton") then
			continue
		end

		if slot.TextLabel.Text == tostring(Slot) then
			UID = slot.Name
			break
		end
	end

	return UID
end

function Hotbar:SetRounds(UID, Text)
	local Items = self.Items
	local Item = Items:FindFirstChild(UID)

	if not Item then
		return
	end

	Item.Rounds.Text = Text
end

function Hotbar:KnitStart()
	self.Gui = Knit.Player.PlayerGui:WaitForChild("Interface"):WaitForChild("Hotbar")
	self.Items = self.Gui.Items

	local Assets = ReplicatedStorage.Assets.GUI.Inventory
	self.Template = Assets:WaitForChild("SlotTemplate")

	-- * Listen to State Changes
	self.State:GetChangedSignal("Inventory"):Connect(function(NewState, OldState)
		if NewState then
			self:Update(NewState, OldState)
		end
	end)

	self.State:GetChangedSignal("Drawn"):Connect(function(NewDrawn, OldDrawn)
		local NewSlot = self.Items:FindFirstChild(NewDrawn)
		local OldSlot = self.Items:FindFirstChild(OldDrawn)

		self.State:Set("DrawDebounce", true)
		task.delay(0.45, function()
			self.State:Set("DrawDebounce", false)
		end)

		if NewSlot then
			local UIStroke: UIStroke = NewSlot.UIStroke
			TweenService:Create(UIStroke, TWEENINFO, {
				Color = Color3.fromRGB(64, 136, 204),
			}):Play()
			TweenService:Create(NewSlot, TWEENINFO, {
				BackgroundColor3 = Color3.fromHex("#1f3e6d"),
			}):Play()

			TweenService:Create(NewSlot.ImageLabel, TWEENINFO, {
				Position = UDim2.fromScale(0.5, 0.05),
			}):Play()

			-- * If has rounds then move it up
			local Item = self:GetItemFromUID(NewSlot.Name)
			if not Item.Attributes then
				return
			end

			if not Item.Attributes.Rounds then
				return
			end

			TweenService:Create(NewSlot.ImageLabel, TWEENINFO, {
				Position = UDim2.fromScale(0.5, 0.05),
			}):Play()
			TweenService:Create(NewSlot.Rounds, TWEENINFO, {
				TextTransparency = 0,
			}):Play()
		end

		if OldSlot then
			local UIStroke: UIStroke = OldSlot.UIStroke
			TweenService:Create(UIStroke, TWEENINFO, {
				Color = Color3.fromRGB(32, 32, 48),
			}):Play()
			TweenService:Create(OldSlot, TWEENINFO, {
				BackgroundColor3 = Color3.fromHex("#202030"),
			}):Play()

			TweenService:Create(OldSlot.ImageLabel, TWEENINFO, {
				Position = UDim2.fromScale(0.5, 0.37),
			}):Play()
			TweenService:Create(OldSlot.Rounds, TWEENINFO, {
				TextTransparency = 1,
			}):Play()
		end
	end)

	-- * Listen to Key Presses
	self.Keyboard.KeyDown:Connect(function(key)
		if not KEYCODE_CONVERSION[key] then
			return
		end

		if not self:GetUIDFromSlot(KEYCODE_CONVERSION[key]) then
			return
		end

		local UID = self:GetUIDFromSlot(KEYCODE_CONVERSION[key])
		self:SelectSlot(UID)
	end)

	-- * Prepare The Hotbar
	Knit.GetService("InventoryService"):Get():andThen(function(Inventory)
		self.State:Set("Inventory", Inventory)
	end)

	-- * Listen to OnUpdate Event
	Knit.GetService("InventoryService").OnUpdate:Connect(function()
		Knit.GetService("InventoryService"):Get():andThen(function(Inventory)
			self.State:Set("Inventory", Inventory)
		end)

		local DrawnUID = self.State:Get("Drawn")
		local _, Rounds = Knit.GetService("InventoryService"):GetChamberRounds(DrawnUID):await()

		local _, Inv = Knit.GetService("InventoryService"):Get():await()
		local Items = Inv.Items

		local Item = Items[DrawnUID]

		if not Item then
			return
		end

		local ItemData = ItemModule[Item.Id]
		if not ItemData then
			return
		end

		local _, TotalRounds = Knit.GetService("InventoryService"):GetTotalRounds(ItemData.Mag[1]):await()
		if Rounds == false then
			return
		end
		self:SetRounds(DrawnUID, Rounds .. '<font color="#bdbdbd">/' .. TotalRounds .. "</font>")
	end)

	Knit.GetService("InventoryService").DrawnUpdate:Connect(function(NewDrawn)
		self.State:Set("Drawn", NewDrawn)

		local _, Rounds = Knit.GetService("InventoryService"):GetChamberRounds(NewDrawn):await()

		local _, Inv = Knit.GetService("InventoryService"):Get():await()
		local Items = Inv.Items

		local Item = Items[NewDrawn]

		if not Item then
			return
		end

		local ItemData = ItemModule[Item.Id]
		if not ItemData then
			return
		end

		local _, TotalRounds = Knit.GetService("InventoryService"):GetTotalRounds(ItemData.Mag[1]):await()
		if Rounds == false then
			return
		end
		self:SetRounds(NewDrawn, Rounds .. '<font color="#bdbdbd">/' .. TotalRounds .. "</font>")
	end)
end

function Hotbar:KnitInit()
	self.SlotTrove = Trove.new()
	self.State = BasicState.new({
		Inventory = nil,
		Drawn = "",
		DrawDebounce = false,
	})
	self.Keyboard = Input.Keyboard.new()
end

return Hotbar
