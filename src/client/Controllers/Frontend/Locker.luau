local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Knit = require(ReplicatedStorage.Packages.Knit)
local BasicState = require(ReplicatedStorage.Packages.BasicState)
local Trove = require(ReplicatedStorage.Packages.Trove)
local Promise = require(ReplicatedStorage.Packages.Promise)
local Input = require(ReplicatedStorage.Packages.Input)
local Component = require(ReplicatedStorage.Packages.Component)

local Locker = Knit.CreateController({ Name = "Locker" })
local Config = require(ReplicatedStorage.Shared.Modules.Config)

local Uniforms = Config("Uniforms")

function Locker:Select(idx)
	if idx == "Clear" or idx == "Loadouts" or idx == "Save" then
		--* Manually Setup buttons
		return
	end

	if self.State:Get("Selected") == nil then
		self.State:Set("Selected", idx)
	else
		if self.State:Get("Selected") == idx then
			self.State:Set("Selected", nil)
		else
			self.State:Set("Selected", idx)
		end
	end
end

function weldAttachments(attach1, attach2)
	local weld = Instance.new("Weld")
	weld.Part0 = attach1.Parent
	weld.Part1 = attach2.Parent
	weld.C0 = attach1.CFrame
	weld.C1 = attach2.CFrame
	weld.Parent = attach1.Parent
	return weld
end

local function buildWeld(weldName, parent, part0, part1, c0, c1)
	local weld = Instance.new("Weld")
	weld.Name = weldName
	weld.Part0 = part0
	weld.Part1 = part1
	weld.C0 = c0
	weld.C1 = c1
	weld.Parent = parent
	return weld
end

local function findFirstMatchingAttachment(model, name)
	for _, child in pairs(model:GetChildren()) do
		if child:IsA("Attachment") and child.Name == name then
			return child
		elseif not child:IsA("Accoutrement") and not child:IsA("Tool") then -- Don't look in hats or tools in the character
			local foundAttachment = findFirstMatchingAttachment(child, name)
			if foundAttachment then
				return foundAttachment
			end
		end
	end
end

function addAccoutrement(character, accoutrement)
	accoutrement.Parent = character
	local handle = accoutrement:FindFirstChild("Handle")
	if handle then
		local accoutrementAttachment = handle:FindFirstChildOfClass("Attachment")
		if accoutrementAttachment then
			local characterAttachment = findFirstMatchingAttachment(character, accoutrementAttachment.Name)
			if characterAttachment then
				weldAttachments(characterAttachment, accoutrementAttachment)
			end
		else
			local head = character:FindFirstChild("Head")
			if head then
				local attachmentCFrame = CFrame.new(0, 0.5, 0)
				local hatCFrame = accoutrement.AttachmentPoint
				buildWeld("HeadWeld", head, head, handle, attachmentCFrame, hatCFrame)
			end
		end
	end
end

function Locker:UpdateContainer(New)
	-- Clear out
	for _, v in ipairs(self.Items:GetChildren()) do
		if v:IsA("TextButton") then
			v:Destroy()
		end
	end

	local Dummy = self.Component.Dummy

	if New then
		if Uniforms[self.State:Get("Agency")] then
			local Button = ReplicatedStorage.Assets.GUI.Locker.Button
			for _, data in pairs(Uniforms[self.State:Get("Agency")]) do
				if data.Name == self.State:Get("Selected") then
					for name, dat in pairs(data.Items) do
						local newButton = Button:Clone()
						newButton.Name = name
						newButton.Text = name
						newButton.Parent = self.Items

						self.ButtonTrove:Add(newButton.MouseButton1Click:Connect(function()
							if data.Name == "Uniforms" then
								local GroupRank = Knit.Player:GetRankInGroup(data.Id)
								local shirtId = nil
								for rank, id in pairs(dat) do
									local MinRank, MaxRank = unpack(rank:split("-"))
									print(MinRank, MaxRank, GroupRank)

									if MaxRank then
										if GroupRank >= tonumber(MinRank) and GroupRank <= tonumber(MaxRank) then
											shirtId = id
											break
										end
									else
										if GroupRank == tonumber(MinRank) then
											shirtId = id
											break
										end
									end
								end

								if shirtId then
									Dummy.Shirt.ShirtTemplate = shirtId
									Dummy.Pants.PantsTemplate = data.Pants
								end
							elseif data.Name == "Accessories" then
								local Accessory = ReplicatedStorage.Accessories:FindFirstChild(dat[1])
								if Accessory then
									if Accessory.Name == "PoliceBelt" then
										if Dummy:FindFirstChild("StaffPoliceBelt") then
											return
										end
									elseif Accessory.Name == "StaffPoliceBelt" then
										if Dummy:FindFirstChild("PoliceBelt") then
											return
										end
									end

									if Dummy:FindFirstChild(Accessory.Name) then
										local as = ReplicatedStorage.Buffer:FindFirstChild(Accessory.Name)
										if as then
											as:Destroy()
										end
										Dummy:FindFirstChild(Accessory.Name):Destroy()

										return
									else
										local new = Accessory:Clone()
										addAccoutrement(Dummy, new)

										if not ReplicatedStorage.Buffer:FindFirstChild(new.Name) then
											local newB = Instance.new("BoolValue")
											newB.Name = new.Name
											newB.Parent = ReplicatedStorage.Buffer
										end
									end
								end
							elseif data.Name == "Hairstyles" then
								local Accessory = ReplicatedStorage.Accessories:FindFirstChild(dat[1])
								if Accessory then
									if Accessory.Name == "Bun" then
										if Dummy:FindFirstChild("Trecky") then
											return
										end
									elseif Accessory.Name == "Trecky" then
										if Dummy:FindFirstChild("Bun") then
											return
										end
									end

									if Dummy:FindFirstChild(Accessory.Name) then
										local as = ReplicatedStorage.Buffer:FindFirstChild(Accessory.Name)
										if as then
											as:Destroy()
										end
										Dummy:FindFirstChild(Accessory.Name):Destroy()

										return
									else
										local new = Accessory:Clone()
										addAccoutrement(Dummy, new)

										if not ReplicatedStorage.Buffer:FindFirstChild(new.Name) then
											local newB = Instance.new("BoolValue")
											newB.Name = new.Name
											newB.Parent = ReplicatedStorage.Buffer
										end
									end
								end
							end
						end))
					end
				end
			end
		end
	end
end

function Locker:_awaitSetup()
	return Promise.new(function(resolve)
		-- Setup Buttons
		self.Finish.Visible = true
		self.Main.Header.Agency.Text = self.State:Get("Agency") or "NULL"

		local Dummy = self.Component.Dummy

		self.Trove:Add(self.Buttons.Clear.MouseButton1Click:Connect(function()
			if self.State:Get("Remove") == true then
				self.State:Set("Remove", false)

				local ShirtId = Dummy.Shirt.ShirtTemplate
				local PantsId = Dummy.Pants.PantsTemplate

				local newDesc = Players:GetHumanoidDescriptionFromUserId(Knit.Player.UserId)

				-- local newDummy = ReplicatedStorage.Assets.Models.PreviewDummy:Clone()
				-- newDummy.Parent = workspace
				-- newDummy.Humanoid:ApplyDescriptionReset()

				Dummy.Humanoid:ApplyDescriptionReset(newDesc)
				Dummy.Shirt.ShirtTemplate = ShirtId
				Dummy.Pants.PantsTemplate = PantsId
				newDesc:Destroy()

				self.Buttons.Clear.Text = "CLEAR"

				-- -- * TODO: LOAD ALL GAME ACCESSORIES
				local GameAccessories = ReplicatedStorage.Buffer:GetChildren()
				for _, v in ipairs(GameAccessories) do
					local new = ReplicatedStorage.Accessories:FindFirstChild(v.Name)
					if new then
						local newAcc = new:Clone()
						addAccoutrement(Dummy, newAcc)
						v:Destroy()
					end
				end
			else
				-- * Save Accessories to buffer

				for _, v in ipairs(Dummy:GetChildren()) do
					if v:IsA("Accessory") and v:GetAttribute("Game") == nil then
						v:Destroy()
					end

					if v:IsA("Accessory") and v:GetAttribute("Game") == true then
						if not ReplicatedStorage.Buffer:FindFirstChild(v.Name) then
							local new = Instance.new("BoolValue")
							new.Name = v.Name
							new.Parent = ReplicatedStorage.Buffer
						end
					end
				end

				self.State:Set("Remove", true)
				self.Buttons.Clear.Text = "RETRIEVE"
			end
		end))

		self.Trove:Add(self.Buttons.Save.MouseButton1Click:Connect(function()
			self.Items.Visible = false
			self.State:Set("Selected", nil)
			self.Save.Visible = not self.Save.Visible
			self.Loadouts.Visible = false
		end))

		self.Trove:Add(self.Buttons.Loadouts.MouseButton1Click:Connect(function()
			self.Items.Visible = false
			self.State:Set("Selected", nil)
			self.Save.Visible = false
			self.Loadouts.Visible = not self.Loadouts.Visible

			for _, v in ipairs(self.Loadouts:GetChildren()) do
				if v:IsA("TextButton") then
					v:Destroy()
				end
			end

			if self.Loadouts.Visible == true then
				local Button = ReplicatedStorage.Assets.GUI.Locker.Button

				local _, data = Knit.GetService("LockerService"):GetData():await()
				if data then
					for name, dat in pairs(data) do
						local newButton = Button:Clone()
						newButton.Text = name
						newButton.Name = name
						newButton.Parent = self.Loadouts

						self.Trove:Add(newButton.MouseButton1Click:Connect(function()
							-- Load Thingy
							self.Buttons.Clear.Text = "CLEAR"
							self.State:Set("Selected", nil)
							self.State:Set("Remove", false)
							ReplicatedStorage.Buffer:ClearAllChildren()
							Dummy.Humanoid:RemoveAccessories()
							Dummy.Shirt.ShirtTemplate = dat.Shirt
							Dummy.Pants.PantsTemplate = dat.Pants

							for _, acc in ipairs(dat.Accessories) do
								local _Accessory = ReplicatedStorage.Accessories:FindFirstChild(acc)
								if _Accessory then
									local newAc = _Accessory:Clone()
									addAccoutrement(Dummy, newAc)
								end
							end

							Knit.GetController("NotificationController"):Send(
								"Success!",
								"You have successfully equipped the following loadout: " .. name .. ".",
								"rbxassetid://10415898158",
								"Success",
								10
							)
						end))
					end
				end
			end
		end))

		self.Trove:Add(self.Save.Save.MouseButton1Click:Connect(function()
			if string.len(self.Save.Input.Text) < 3 then
				return
			end

			local accessories = {}

			for _, v in ipairs(Dummy.Humanoid:GetAccessories()) do
				table.insert(accessories, v.Name)
			end

			local dataTable = {
				Shirt = Dummy.Shirt.ShirtTemplate,
				Pants = Dummy.Pants.PantsTemplate,
				Accessories = accessories,
			}

			Knit.GetService("LockerService"):Save(self.Save.Input.Text, dataTable):andThen(function(success)
				if success then
					self.Save.Visible = false
					Knit.GetController("NotificationController"):Send(
						"Success!",
						"You successfully saved a new loadout called: " .. self.Save.Input.Text .. ".",
						"rbxassetid://10415902869",
						"Success",
						8
					)
				else
					Knit.GetController("NotificationController"):Send(
						"Error!",
						"An error occured while trying to save the loadout.",
						"rbxassetid://10345407011",
						"Alert",
						10
					)
				end
			end)
		end))

		for _, btn: TextButton in ipairs(self.Buttons:GetChildren()) do
			if btn:IsA("TextButton") then
				if btn.Name == "Save" then
					continue
				end

				if btn.Name == "Loadouts" then
					continue
				end

				if btn.Name == "Clear" then
					continue
				end

				self.Trove:Add(btn.MouseButton1Click:Connect(function()
					self:Select(btn.Name)
				end))
			end
		end

		self.Trove:Add(self.Finish.Finish.MouseButton1Click:Connect(function()
			local accessories = {}

			for _, v in ipairs(Dummy.Humanoid:GetAccessories()) do
				table.insert(accessories, v.Name)
			end

			local dataTable = {
				Shirt = Dummy.Shirt.ShirtTemplate,
				Pants = Dummy.Pants.PantsTemplate,
				Accessories = accessories,
			}

			Knit.GetController("TransitionController"):In():await()
			Knit.GetService("LockerService"):ApplyToPlayer(dataTable):await()
			task.delay(0.3, function()
				self.Gui.Visible = false
				self.ButtonTrove:Clean()
				self.Trove:Clean()
				self.Keyboard:Destroy()
				self.Buttons.Clear.Text = "CLEAR"
				self.Items.Visible = false
				self.Save.Visible = false
				self.Loadouts.Visible = false
				ReplicatedStorage.Buffer:ClearAllChildren()
				self.State:Set("Open", false)
				task.delay(0.05, function()
					CollectionService:RemoveTag(workspace.StaticStreaming.Locker, "PreviewDummy")
				end)
				Knit.GetController("TransitionController"):Out():await()
			end)
		end))

		self.Trove:Add(self.State:GetChangedSignal("Selected"):Connect(function(new, old)
			self.ButtonTrove:Clean()

			self.Save.Visible = false
			self.Loadouts.Visible = false

			if new then
				self.Main.Items.Visible = true
			else
				self.Main.Items.Visible = false
			end

			self:UpdateContainer(new)
		end))

		self.Gui.Visible = true
		resolve()
	end)
end

function Locker:Setup(Agency)
	self.Keyboard = Input.Keyboard.new()
	self.Trove = Trove.new()
	self.ButtonTrove = Trove.new()

	self.State:Set("Agency", Agency)

	-- Setup Transition
	self.State:Set("Open", true)
	Knit.GetController("TransitionController"):In():await()

	-- Setup Stuff
	self.Component =
		require(script.Parent.Parent.Parent.Components.PreviewDummy):FromInstance(workspace.StaticStreaming.Locker)

	self:_awaitSetup():andThen(function()
		task.wait(0.2)
		Knit.GetController("TransitionController"):Out():await()
	end)
end

function Locker:Open(Agency)
	self.State = BasicState.new({
		Open = false,
		Remove = false,
		Selected = nil,
		Agency = nil,
		AccessoryBuffer = {},
	})
	if self.State:Get("Open") == true then
		return
	end

	self:Setup(Agency)
end

function Locker:KnitStart()
	self.Gui = Knit.Player.PlayerGui:WaitForChild("Interface").Locker
	self.Finish = self.Gui.Finish
	self.Main = self.Gui.Main
	self.Buttons = self.Gui.Main.Main
	self.Items = self.Gui.Main.Items
	self.Save = self.Gui.Main.Save
	self.Loadouts = self.Gui.Main.Loadouts

	ReplicatedStorage.Locker.OnClientEvent:Connect(function(Agency)
		if self.State then
			if self.State:Get("Open") == false then
				workspace.StaticStreaming.Locker:SetAttribute("Agency", Agency)
				CollectionService:AddTag(workspace.StaticStreaming.Locker, "PreviewDummy")
			end
		else
			workspace.StaticStreaming.Locker:SetAttribute("Agency", Agency)
			CollectionService:AddTag(workspace.StaticStreaming.Locker, "PreviewDummy")
		end
	end)
end

function Locker:KnitInit() end

return Locker
