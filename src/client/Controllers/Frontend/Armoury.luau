local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")

local Knit = require(ReplicatedStorage.Packages.Knit)
local Input = require(ReplicatedStorage.Packages.Input)
local Trove = require(ReplicatedStorage.Packages.Trove)
local Promise = require(ReplicatedStorage.Packages.Promise)
local BasicState = require(ReplicatedStorage.Packages.BasicState)
local Config = require(ReplicatedStorage.Shared.Modules.Config)

local ArmouryModule = Config("Armoury")
local ItemsModule = Config("Items")

local Armoury = Knit.CreateController({ Name = "Armoury" })

function Armoury:Cleanup()
	self.State:Set("Selected", nil)

	self.Trove:Clean()
	for _, v in ipairs(self.Gui.Categories.Body:GetChildren()) do
		if v:IsA("Frame") or v:IsA("TextButton") then
			v:Destroy()
		end
	end
end

function Armoury:Update(Agency)
	return Promise.new(function(resolve, reject)
		self.Gui.Categories.Header.Agency.Text = Agency:upper()

		-- Setup Categories
		for idx, data in ipairs(ArmouryModule.Categories) do
			if data.Type and data.Type == "Divider" then
				local newDivider = self.Divider:Clone()
				newDivider.Parent = self.Gui.Categories.Body
			else
				local newCategory = self.Button:Clone()
				newCategory.ImageLabel.Image = data.Icon
				newCategory.Name = data.Name
				newCategory.Text = data.Name
				newCategory.Parent = self.Gui.Categories.Body

				local newCategoryFrame = self.Category:Clone()
				newCategoryFrame.Header.Agency.Text = Agency:upper()
				newCategoryFrame.Header.Title.Text = data.Name:upper()
				newCategoryFrame.Name = data.Name
				newCategoryFrame.Parent = self.Gui

				self.Trove:Add(newCategory.MouseButton1Click:Connect(function()
					if self.State:Get("Selected") == nil then
						self.State:Set("Selected", newCategory.Name)
					else
						if self.State:Get("Selected") == newCategory.Name then
							self.State:Set("Selected", nil)
						else
							self.State:Set("Selected", newCategory.Name)
						end
					end
				end))
			end
		end

		resolve()
	end)
end

local function getArmouryDataFromName(Name)
	local ArmouryTable = ArmouryModule.Categories
	local ret = nil

	for k, v in pairs(ArmouryTable) do
		if v.Name == Name then
			ret = v
			break
		end
	end

	return ret
end

local function getItemDataFromName(Asset)
	local ArmouryTable = ItemsModule
	local ret = nil
	local ret2 = nil

	for k, v in pairs(ArmouryTable) do
		if v.Asset == Asset then
			ret = v
			ret2 = k
			break
		end
	end

	return ret, ret2
end

function Armoury:UpdateCategory(New, Old)
	self.CategoryTrove:Clean()

	if Old then
		local OldFrame = self.Gui:FindFirstChild(Old).Body
		for _, v in ipairs(OldFrame:GetDescendants()) do
			if v:IsA("TextButton") then
				v:Destroy()
			end
		end
	end

	if New then
		local NewFrame = self.Gui:FindFirstChild(New)
		if NewFrame then
			for _, v in ipairs(NewFrame:GetDescendants()) do
				if v:IsA("TextButton") or v:IsA("TextBox") then
					v:Destroy()
				end
			end

			NewFrame = NewFrame.Body.ScrollingFrame
			local v = getArmouryDataFromName(New)
			if v then
				if v.Items then
					for _, v in ipairs(v.Items) do
						local DataTable, Id = getItemDataFromName(v)
						if DataTable then
							local new = self.CategoryButton:Clone()
							new.Name = v
							new.Text = DataTable.Name
							new.Parent = NewFrame

							self.CategoryTrove:Add(new.MouseButton1Click:Connect(function()
								Knit.GetService("ArmouryService"):HandleButton(Id)
							end))
						end
					end
				elseif v.Bypass then
					local _, Loadouts = Knit.GetService("ArmouryService"):GetLoadouts():await()
					for k, v in pairs(Loadouts) do
						local new = self.CategoryButton:Clone()
						new.Name = k
						new.Text = k

						self.CategoryTrove:Add(new.MouseButton1Click:Connect(function()
							Knit.GetService("ArmouryService"):Load(k)
						end))

						new.Parent = NewFrame
					end
				else
					local newInput = self.InputBox:Clone()
					local CreateButton = self.CreateButton:Clone()
					newInput.Parent = NewFrame
					CreateButton.Parent = NewFrame

					self.CategoryTrove:Add(CreateButton.MouseButton1Click:Connect(function()
						if string.len(newInput.Text) > 3 then
							Knit.GetService("ArmouryService"):SaveLoadout(newInput.Text)
						end
					end))
				end
			end
		end
	end
end

function Armoury:Setup(Agency)
	if self.Open == false then
		self.Open = true
		self.State = BasicState.new({
			Selected = nil,
		})
		self:Cleanup()

		self.Trove:Add(self.Gui.Categories.Header.Exit.MouseButton1Click:Connect(function()
			self:Cleanup()
			self.Trove:Clean()
			self.CategoryTrove:Clean()

			self.Gui:TweenPosition(UDim2.fromScale(0.2, -1), Enum.EasingDirection.Out, Enum.EasingStyle.Quad, 0.3, true)
			self.Open = false
		end))

		self.State:GetChangedSignal("Selected"):Connect(function(new, old)
			if new then
				self.Gui:FindFirstChild(new).Visible = true
				self:UpdateCategory(new, old)
			end

			if old then
				self:UpdateCategory(new, old)

				self.Gui:FindFirstChild(old).Visible = false
			end
		end)

		self
			:Update(Agency)
			:andThen(function()
				self.Gui:TweenPosition(
					UDim2.fromScale(0.2, 0.025),
					Enum.EasingDirection.Out,
					Enum.EasingStyle.Quad,
					0.3,
					true
				)
			end)
			:catch(function()
				Knit.GetController("NotificationController"):Send(
					"Error Occured!",
					"An error occured while trying to display the armoury gui.",
					"rbxassetid://10345407011",
					"Alert",
					10
				)
			end)
	end
end

function Armoury:KnitStart()
	self.Trove = Trove.new()
	self.CategoryTrove = Trove.new()
	self.Open = false

	ReplicatedStorage.Armoury.OnClientEvent:Connect(function(Agency)
		self:Setup(Agency)
	end)
end

function Armoury:KnitInit()
	self.Gui = Knit.Player.PlayerGui:WaitForChild("Interface", 5):WaitForChild("Armoury")

	self.Keyboard = Input.Keyboard.new()

	self.Category = ReplicatedStorage.Assets.GUI.Armoury.Category
	self.Divider = ReplicatedStorage.Assets.GUI.Armoury.Divider
	self.Button = ReplicatedStorage.Assets.GUI.Armoury.Button
	self.CategoryButton = ReplicatedStorage.Assets.GUI.Armoury.CategoryButton
	self.InputBox = ReplicatedStorage.Assets.GUI.Armoury.InputBox
	self.CreateButton = ReplicatedStorage.Assets.GUI.Armoury.CreateButton
end

return Armoury
