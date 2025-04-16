local CollectionService = game:GetService("CollectionService")
local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local Knit = require(ReplicatedStorage.Packages.Knit)
local Config = require(ReplicatedStorage.Shared.Modules.Config)

local Items = Config("Items")


local ToolService = Knit.CreateService({
	Name = "ToolService",
	Client = {
		RoundsChanged = Knit.CreateSignal(),
		TotalRoundsChanged = Knit.CreateSignal(),
	},
})

function ToolService:SetMag(Player, Visibility)
	if Player then
		if Player.Character and Player.Character:FindFirstChildOfClass("Model") then
			if Player.Character:FindFirstChildOfClass("Model"):FindFirstChild("Mag") then
				Player.Character:FindFirstChildOfClass("Model").Mag.Transparency = Visibility
			end
		end
	end
end

local function getItemDataFromAsset(Asset)
	local data = nil
	for id, dat in pairs(Items) do
		if dat.Asset == Asset then
			data = dat

			break
		end
	end

	return data
end

function ToolService:PlayTrack(Handle, ItemTable, Name)
	local new = Instance.new("Sound")
	new.Name = Name
	new.SoundId = ItemTable.Sounds[Name]

	if Name == "Fire" then
		new.Volume = 3.2
	end

	new.PlayOnRemove = true
	new.Parent = Handle

	new:Destroy()
end

local RNG = Random.new()
function ToolService:Fire(Player, Mouse, Latency)
	self.Players[Player] = self.Players[Player] or false

	if Player.Character and Player.Character:FindFirstChildOfClass("Model") then
		if Player.Character:FindFirstChildOfClass("Model"):FindFirstChild("Handle") then
			local ItemData = getItemDataFromAsset(Player.Character:FindFirstChildOfClass("Model").Name)
			if ItemData then
				if self.Players[Player] == false then
					self.Players[Player] = true

					local Handle = Player.Character:FindFirstChildOfClass("Model"):FindFirstChild("Handle")
					self.Handle = Handle

					local ChamberedRounds =
						Knit.GetService("InventoryService"):GetChamberRounds(Player, Handle.Parent:GetAttribute("UID"))
					if ChamberedRounds == 0 then
						self:PlayTrack(Handle, ItemData, "Empty")

						local newTime = math.clamp(0.13 - Latency, 0.07, 2)
						task.delay(newTime, function()
							self.Players[Player] = false
						end)
					else
						if ItemData.Type == "Shotgun" then
							self:PlayTrack(Handle, ItemData, "Fire")
							local Origin = Player.Character
								:FindFirstChildOfClass("Model")
								:FindFirstChild("Handle").Smoke.WorldCFrame

							-- * GET UID OF GUN
							local Drawn = Knit.GetService("InventoryService"):GetDrawn(Player)

							-- * Subtract a bullet from the chamber
							local ChamberRounds = Knit.GetService("InventoryService"):GetChamberRounds(Player, Drawn)
							local _totalRounds =
								Knit.GetService("InventoryService"):GetTotalRounds(Player, ItemData.Mag[1])
							local NewChamberRounds = ChamberRounds - 1

							self.Client.RoundsChanged:Fire(Player, NewChamberRounds)
							self.Client.TotalRoundsChanged:Fire(Player, _totalRounds)
							Knit.GetService("InventoryService"):Set(Player, { Drawn }, "Rounds", { NewChamberRounds })

							for _ = 1, 5 do
								local SPREAD = 1000 -- set some value for it
								local spreadPosition = Vector3.new(
									Origin.Position.X + RNG:NextInteger(-SPREAD, SPREAD) / 1000,
									Origin.Position.Y + RNG:NextInteger(-SPREAD, SPREAD) / 1000,
									Origin.Position.Z + RNG:NextInteger(-SPREAD, SPREAD) / 1000
								)

								local Params = RaycastParams.new()
								Params.FilterDescendantsInstances = { Player.Character, workspace.Ignore }
								Params.FilterType = Enum.RaycastFilterType.Blacklist

								local result = workspace:Raycast(
									Origin.Position,
									(Mouse - spreadPosition).Unit * ItemData.Range,
									Params
								)

								if result then
									local _Player = Players:GetPlayerFromCharacter(result.Instance.Parent)
									if not _Player then
										_Player = Players:GetPlayerFromCharacter(result.Instance.Parent.Parent)
									end

									if _Player then
										local humanoid = _Player.Character:FindFirstChild("Humanoid")
										if not humanoid then
											return
										end

										local Damages = ItemData.Damage
										if result.Instance.Name == "Head" then
											humanoid:TakeDamage(Damages[1])
										else
											humanoid:TakeDamage(Damages[2])
										end
									else
										local bulletPart = Instance.new("Part")
										bulletPart.Transparency = 1
										bulletPart.Anchored = true
										bulletPart.CanCollide = false
										bulletPart.Size = Vector3.new(0.35, 0.35, 0.05) -- you might have to change the axis, i didnt test this
										bulletPart.CFrame =
											CFrame.lookAt(result.Position, result.Position + result.Normal)

										local bulletImage = Instance.new("Decal")
										bulletImage.Texture = "rbxassetid://2859765692"
										bulletImage.Parent = bulletPart
										bulletImage.Face = Enum.NormalId.Front

										bulletPart.Parent = workspace.Terrain
										Debris:AddItem(bulletPart, 90)
									end
								end
							end

							local newTime = math.clamp(0.65 - Latency, 0.07, 2)
							task.delay(newTime, function()
								self.Players[Player] = false
							end)
						else
							self:PlayTrack(Handle, ItemData, "Fire")
							local Origin = Player.Character
								:FindFirstChildOfClass("Model")
								:FindFirstChild("Handle").Smoke.WorldPosition
							local Direction = (Mouse - Origin).Unit * ItemData.Range
			
							-- * GET UID OF GUN
							local Drawn = Knit.GetService("InventoryService"):GetDrawn(Player)

							-- * Subtract a bullet from the chamber
							local ChamberRounds = Knit.GetService("InventoryService"):GetChamberRounds(Player, Drawn)
							local _totalRounds =
								Knit.GetService("InventoryService"):GetTotalRounds(Player, ItemData.Mag[1])
							local NewChamberRounds = ChamberRounds - 1

							self.Client.RoundsChanged:Fire(Player, NewChamberRounds)
							self.Client.TotalRoundsChanged:Fire(Player, _totalRounds)
							Knit.GetService("InventoryService"):Set(Player, { Drawn }, "Rounds", { NewChamberRounds })

							local Params = RaycastParams.new()
							Params.FilterDescendantsInstances = { Player.Character, workspace.Ignore }
							Params.FilterType = Enum.RaycastFilterType.Blacklist

							local result = workspace:Raycast(Origin, Direction, Params)

							if result then
								local _Player = Players:GetPlayerFromCharacter(result.Instance.Parent)
								if not _Player then
									_Player = Players:GetPlayerFromCharacter(result.Instance.Parent.Parent)
								end

								if _Player then
									local humanoid = _Player.Character:FindFirstChild("Humanoid")
									if not humanoid then
										return
									end

									local Damages = ItemData.Damage
									if result.Instance.Name == "Head" then
										humanoid:TakeDamage(Damages[1])
									else
										humanoid:TakeDamage(Damages[2])
									end
								else
									local bulletPart = Instance.new("Part")
									bulletPart.Transparency = 1
									bulletPart.Anchored = true
									bulletPart.CanCollide = false
									bulletPart.Size = Vector3.new(0.35, 0.35, 0.05) -- you might have to change the axis, i didnt test this
									bulletPart.CFrame = CFrame.lookAt(result.Position, result.Position + result.Normal)

									local bulletImage = Instance.new("Decal")
									bulletImage.Texture = "rbxassetid://2859765692"
									bulletImage.Parent = bulletPart
									bulletImage.Face = Enum.NormalId.Front

									bulletPart.Parent = workspace.Terrain
									Debris:AddItem(bulletPart, 90)
								end
							end

							local newTime = math.clamp(0.13 - Latency, 0.07, 2)
							task.delay(newTime, function()
								self.Players[Player] = false
							end)
						end
					end
				end
			end
		end
	end

	return false
end

function ToolService:_refillRifleFromFirstMagazineFound(Player, _Items, ItemData, __Item)
	local MagUID = nil

	for uid, dat in pairs(_Items) do
		local _itemDat = Items[dat.Id]
		if _itemDat then
			if _itemDat.Type == "Mag" then
				if dat.Attributes.Rounds > 0 and table.find(ItemData.Mag, _itemDat.Asset) then
					MagUID = uid
					break
				end
			end
		end
	end

	if MagUID then
		if _Items[MagUID] then
			local MaxRounds = ItemData.MaxRounds
			local diff = (MaxRounds - __Item.Attributes.Rounds)
			if _Items[MagUID].Attributes.Rounds - diff == 0 then
				Knit.GetService("InventoryService"):SetAttribute(
					Player,
					Knit.GetService("InventoryService"):GetDrawn(Player),
					"Rounds",
					ItemData.MaxRounds
				)
				Knit.GetService("InventoryService"):SetAttribute(Player, MagUID, "Rounds", 0)
			else
				Knit.GetService("InventoryService"):SetAttribute(
					Player,
					Knit.GetService("InventoryService"):GetDrawn(Player),
					"Rounds",
					__Item.Attributes.Rounds + diff
				)
				Knit.GetService("InventoryService")
					:SetAttribute(Player, MagUID, "Rounds", _Items[MagUID].Attributes.Rounds - diff)
			end
		end

		return true
	end

	return false
end

function ToolService:_canReload(Player, _Items, ItemData, __Item)
	if not self.Handle then
		local char = Player.Character
		local tool = char:FindFirstChildOfClass("Model")

		if not tool then
			return
		end

		if not tool:GetAttribute("UID") then
			return
		end

		self.Handle = tool:FindFirstChild("Handle")
	end

	local ChamberedRounds =
		Knit.GetService("InventoryService"):GetChamberRounds(Player, self.Handle.Parent:GetAttribute("UID"))

	local TotalRounds = Knit.GetService("InventoryService"):GetTotalRounds(Player, ItemData.Mag[1])

	if ChamberedRounds == ItemData.MaxRounds then
		return false
	end

	if TotalRounds == 0 then
		return false
	end

	return true
end

function ToolService:Reload(Player, Latency)
	if not self.Handle or not self.Handle.Parent then
		local char = Player.Character
		local tool = char:FindFirstChildOfClass("Model")

		if not tool then
			return
		end

		if not tool:GetAttribute("UID") then
			return
		end

		self.Handle = tool:FindFirstChild("Handle")
	end

	local Id = self.Handle.Parent:GetAttribute("Id")
	local _UID = self.Handle.Parent:GetAttribute("UID")
	local ItemData = Items[Id]
	if not ItemData then
		return false
	end

	if self.Reloading[Player] == false then
		local MaxRounds = ItemData.MaxRounds
		local Drawn = Knit.GetService("InventoryService"):GetDrawn(Player)
		local Inventory = Knit.GetService("InventoryService"):GetData(Player)
		local _Items = Inventory.Items

		local RoundsInChamber = Knit.GetService("InventoryService"):GetChamberRounds(Player, Drawn)
		if RoundsInChamber == false then
			return false
		end

		local TotalRounds = Knit.GetService("InventoryService"):GetTotalRounds(Player, ItemData.Mag[1])

		if TotalRounds > 0 then
			if RoundsInChamber < MaxRounds then
				self.Reloading[Player] = true

				local newTime = math.clamp(2.3 - Latency, 2, 2.5)

				task.delay(newTime, function()
					self.Reloading[Player] = false
				end)

				if ItemData.Type == "Shotgun" then
					task.delay(2, function()
						self:PlayTrack(self.Handle, ItemData, "Reload")
						local FillAmount = 1
						for uid, dat in pairs(_Items) do
							local _ItemData = Items[dat.Id]
							if not _ItemData then
								continue
							end

							if _ItemData.Asset ~= ItemData.Mag[1] then
								continue
							end

							local RoundsInMagazine = dat.Attributes.Rounds
							if RoundsInMagazine == 0 then
								continue
							end

							if RoundsInMagazine == FillAmount then
								Knit.GetService("InventoryService"):AddItem(Player, dat.Id, 1, {
									Rounds = 0,
								})
								Knit.GetService("InventoryService"):RemoveSpecificItem(Player, uid)
								local _totalRounds =
									Knit.GetService("InventoryService"):GetTotalRounds(Player, ItemData.Mag[1])

								self.Client.TotalRoundsChanged:Fire(Player, _totalRounds)

								local _chamberRounds =
									Knit.GetService("InventoryService"):GetChamberRounds(Player, _UID)
								local _newRounds = _chamberRounds + 1

								self.Client.RoundsChanged:Fire(Player, _newRounds)

								Knit.GetService("InventoryService"):Set(Player, { _UID }, "Rounds", { _newRounds })
								break
							end

							if RoundsInMagazine > FillAmount then
								local NewRoundsInMag = RoundsInMagazine - FillAmount
								Knit.GetService("InventoryService"):AddItem(Player, dat.Id, 1, {
									Rounds = NewRoundsInMag,
								})
								Knit.GetService("InventoryService"):RemoveSpecificItem(Player, uid)

								local _totalRounds =
									Knit.GetService("InventoryService"):GetTotalRounds(Player, ItemData.Mag[1])

								local _chamberRounds =
									Knit.GetService("InventoryService"):GetChamberRounds(Player, _UID)
								local _newRounds = _chamberRounds + 1

								self.Client.TotalRoundsChanged:Fire(Player, _totalRounds)
								self.Client.RoundsChanged:Fire(Player, _newRounds)

								Knit.GetService("InventoryService"):Set(Player, { _UID }, "Rounds", { _newRounds })
								break
							end

							if RoundsInMagazine < FillAmount then
								local NewRoundsInChamber = Knit.GetService("InventoryService")
									:GetChamberRounds(Player, Drawn) + RoundsInMagazine

								Knit.GetService("InventoryService"):AddItem(Player, dat.Id, 1, {
									Rounds = 0,
								})
								Knit.GetService("InventoryService"):RemoveSpecificItem(Player, uid)
								Knit.GetService("InventoryService")
									:Set(Player, { _UID }, "Rounds", { NewRoundsInChamber })

								local _totalRounds =
									Knit.GetService("InventoryService"):GetTotalRounds(Player, ItemData.Mag[1])

								self.Client.TotalRoundsChanged:Fire(Player, _totalRounds)
								self.Client.RoundsChanged:Fire(Player, NewRoundsInChamber)

								TotalRounds =
									Knit.GetService("InventoryService"):GetTotalRounds(Player, ItemData.Mag[1])
								FillAmount = 1
								break
							end
						end
					end)
				else
					self:PlayTrack(self.Handle, ItemData, "Reload")

					task.delay(newTime, function()
						local FillAmount = math.min(MaxRounds - RoundsInChamber, TotalRounds)

						for uid, dat in pairs(_Items) do
							local _ItemData = Items[dat.Id]
							if not _ItemData then
								continue
							end

							if _ItemData.Asset ~= ItemData.Mag[1] then
								continue
							end

							local RoundsInMagazine = dat.Attributes.Rounds
							if RoundsInMagazine == 0 then
								continue
							end

							if RoundsInMagazine == FillAmount then
								Knit.GetService("InventoryService"):AddItem(Player, dat.Id, 1, {
									Rounds = 0,
								})
								Knit.GetService("InventoryService"):RemoveSpecificItem(Player, uid)
								local _totalRounds =
									Knit.GetService("InventoryService"):GetTotalRounds(Player, ItemData.Mag[1])

								self.Client.TotalRoundsChanged:Fire(Player, _totalRounds)

								self.Client.RoundsChanged:Fire(Player, MaxRounds)

								Knit.GetService("InventoryService"):Set(Player, { _UID }, "Rounds", { MaxRounds })
								break
							end

							if RoundsInMagazine > FillAmount then
								local NewRoundsInMag = RoundsInMagazine - FillAmount
								Knit.GetService("InventoryService"):AddItem(Player, dat.Id, 1, {
									Rounds = NewRoundsInMag,
								})
								Knit.GetService("InventoryService"):RemoveSpecificItem(Player, uid)

								local _totalRounds =
									Knit.GetService("InventoryService"):GetTotalRounds(Player, ItemData.Mag[1])

								self.Client.TotalRoundsChanged:Fire(Player, _totalRounds)
								self.Client.RoundsChanged:Fire(Player, MaxRounds)

								Knit.GetService("InventoryService"):Set(Player, { _UID }, "Rounds", { MaxRounds })
								break
							end

							if RoundsInMagazine < FillAmount then
								local NewRoundsInChamber = Knit.GetService("InventoryService")
									:GetChamberRounds(Player, Drawn) + RoundsInMagazine

								Knit.GetService("InventoryService"):AddItem(Player, dat.Id, 1, {
									Rounds = 0,
								})
								Knit.GetService("InventoryService"):RemoveSpecificItem(Player, uid)
								Knit.GetService("InventoryService")
									:Set(Player, { _UID }, "Rounds", { NewRoundsInChamber })

								local _totalRounds =
									Knit.GetService("InventoryService"):GetTotalRounds(Player, ItemData.Mag[1])

								self.Client.TotalRoundsChanged:Fire(Player, _totalRounds)
								self.Client.RoundsChanged:Fire(Player, NewRoundsInChamber)

								TotalRounds =
									Knit.GetService("InventoryService"):GetTotalRounds(Player, ItemData.Mag[1])
								FillAmount = math.min(MaxRounds - NewRoundsInChamber, TotalRounds)
							end
						end
					end)
				end

				-- We can reload
			end
		end
	end
end

function ToolService.Client:Reload(Player, Latency)
	return self.Server:Reload(Player, Latency)
end

function ToolService.Client:Fire(Player, Mouse, Latency)
	return self.Server:Fire(Player, Mouse, Latency)
end

function ToolService.Client:SetMag(Player, Visibility)
	return self.Server:SetMag(Player, Visibility)
end

-- ********************************************************************************************************************************************************
-- * Seperation *******************************************************************************************************************************************
-- ********************************************************************************************************************************************************

function ToolService:Equip(Player, UID)
	if not self.Equipped[Player] then
		return false
	end

	-- If gun already equipped skip.
	if self.Equipped[Player] == UID then
		return false
	end

	-- If another gun is already equipped skip.
	if self.Equipped[Player] ~= "" then
		return false
	end

	local Inventory = Knit.GetService("InventoryService"):GetData(Player)
	local Equipped = Inventory.Equipped

	if not Equipped[UID] then
		return
	end

	local ItemData = Items[Equipped[UID].Id]
	if not ItemData then
		return false
	end

	-- * Equip the Item
	local Character = Player.Character
	local Tool = ServerStorage.Tools:FindFirstChild(ItemData.Asset)
	if not Tool then
		return false
	end

	self.Equipped[Player] = UID
	
	local new = Tool:Clone()
	new:SetAttribute("Type", ItemData.Type)
	new:SetAttribute("UID", UID)
	new:SetAttribute("Id", Equipped[UID].Id)
	new.Parent = Character

	local newMotor6D = Instance.new("Motor6D")
	newMotor6D.Part0 = Character:FindFirstChild("Left Arm")
	newMotor6D.Name = "HandleMotor6"
	newMotor6D.Part1 = new:FindFirstChild("Handle")
	newMotor6D.Parent = Character:FindFirstChild("Torso")

	CollectionService:AddTag(new, "BaseTool")

	local ChamberRounds = Knit.GetService("InventoryService"):GetChamberRounds(Player, UID)
	self.Client.RoundsChanged:Fire(Player, ChamberRounds)

	local _totalRounds = Knit.GetService("InventoryService"):GetTotalRounds(Player, ItemData.Mag[1])

	self.Client.TotalRoundsChanged:Fire(Player, _totalRounds)
end

function ToolService:Unequip(Player, UID)
	if not self.Equipped[Player] then
		return false
	end

	-- If gun isnt equipped skip.
	if self.Equipped[Player] ~= UID then
		return false
	end

	local Character = Player.Character
	if not Character:FindFirstChildOfClass("Model") then
		return false
	end

	local Model = Character:FindFirstChildOfClass("Model")
	if not Model:GetAttribute("UID") then
		return false
	end

	if not Model:GetAttribute("UID") == UID then
		return false
	end

	Model:Destroy()
	Character:FindFirstChild("Torso"):FindFirstChild("HandleMotor6"):Destroy()
	self.Equipped[Player] = ""
end

function ToolService:KnitStart()
	self.Equipped = {}
	self.Players = {}
	self.Reloading = {}
	
	for _, v in ipairs(Players:GetPlayers()) do
		self.Equipped[v] = ""
		self.Reloading[v] = false
	end

	Players.PlayerAdded:Connect(function(v)
		self.Equipped[v] = ""
		self.Reloading[v] = false
	end)

	Players.PlayerRemoving:Connect(function(v)
		self.Equipped[v] = nil
		self.Reloading[v] = nil
	end)
end

function ToolService:KnitInit() end


return ToolService
