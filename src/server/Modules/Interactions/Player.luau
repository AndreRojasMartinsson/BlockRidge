local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Int = {}
Int.Type = "Player"
Int.Anims = {}

local knit = require(ReplicatedStorage.Packages.Knit)
local Config = require(ReplicatedStorage.Shared.Modules.Config)
local Teams = Config("Teams")

local function GetTeamFromColor(bC)
	for _, v in pairs(Teams) do
		if v.TeamColor == bC then
			return v
		end
	end
end

function Int.getAnims()
	return Int.Anims
end

local function Cuff(Player, Target)
	if Player.Cuffing.Value == nil then
		if Target.Cuffer.Value == nil then
			Player.Cuffing.Value = Target
			Target.Cuffer.Value = Player

			local cuffs = ReplicatedStorage.Assets.Interactions.Cuffs:Clone()
			cuffs.Parent = Target.Character

			local weld = Instance.new("Weld")
			weld.Name = "CuffWeld"
			weld.Part0 = cuffs
			weld.Part1 = Target.Character.HumanoidRootPart
			weld.C1 = CFrame.new(0, -0.7, 1.1) * CFrame.Angles(0, math.rad(0), 0)
			weld.Parent = cuffs

			cuffs.SFX:Play()

			Target.Character.Humanoid.WalkSpeed = 9
		end
	end
end

local function Uncuff(Player, Target)
	if Target.Cuffer.Value == Player and Player.Cuffing.Value == Target then
		Target.Cuffer.Value = nil
		Player.Cuffing.Value = nil
		Target.Character.Cuffs.SFX:Play()
		Target.Character.Cuffs.SFX.PlayOnRemove = true
		Target.Character.Cuffs:Destroy()
		Target.Character.Humanoid.WalkSpeed = 13
	end
end

local function Release(Player, Target)
	if Target.Grabber.Value == Player and Player.Grabbing.Value == Target then
		Target.Grabber.Value = nil
		Player.Grabbing.Value = nil

		for _, v in ipairs(Target.Character:GetDescendants()) do
			if v:IsA("BasePart") then
				v.Massless = false
				v:SetNetworkOwnershipAuto()
			end
		end

		Target.Character.HumanoidRootPart.GrabWeld:Destroy()
		Target.Character.Humanoid.JumpPower = 50
		Target.Character.Humanoid.PlatformStand = false
	end
end

local function Grab(Player, Target)
	if
		Target.Grabber.Value == nil
		and Player.Grabbing.Value == nil
		and Player.Cuffing.Value == Target
		and Target.Cuffer.Value == Player
	then
		Target.Grabber.Value = Player
		Player.Grabbing.Value = Target

		local GrabWeld = Instance.new("Weld")
		GrabWeld.Name = "GrabWeld"
		GrabWeld.Part0 = Player.Character.HumanoidRootPart
		GrabWeld.Part1 = Target.Character.HumanoidRootPart
		GrabWeld.C1 = CFrame.new(0, 0, 2.5)
		GrabWeld.Parent = Target.Character.HumanoidRootPart

		Target.Character.Humanoid.JumpPower = 0
		Target.Character.Humanoid.PlatformStand = true

		for _, v in ipairs(Target.Character:GetDescendants()) do
			if v:IsA("BasePart") then
				v.Massless = true
				v:SetNetworkOwner(Player)
			end
		end
	end
end

function Int.Verify(Player, Part)
	if Part and Part.Parent then
		local TargetPlayer = Players:GetPlayerFromCharacter(Part.Parent)
		if TargetPlayer then
			if TargetPlayer:FindFirstChild("CurrentVehicle") and Player:FindFirstChild("CurrentVehicle") then
				if Player.CurrentVehicle.Value ~= nil then
					return false, {}
				end

				if TargetPlayer.CurrentVehicle.Value ~= nil then
					return false, {}
				end

				if not knit.GetService("InventoryService"):HasItem(Player, 9) then
					return false, {}
				end

				if TargetPlayer then
					if TargetPlayer.Team then
						local PlayerTeam = GetTeamFromColor(TargetPlayer.Team.TeamColor)
						if PlayerTeam.LEO then
							return false, {}
						end

						if Player.Team then
							local OwnTeam = GetTeamFromColor(Player.Team.TeamColor)
							if OwnTeam then
								if OwnTeam.LEO then
									if Player.Cuffing.Value == TargetPlayer then
										if TargetPlayer.Pinner.Value == Player then
											return true, {
												["P"] = "Unpin Suspect",
											}
										end

										if Player.Grabbing.Value == TargetPlayer then
											return true, {
												["Z"] = "Release Suspect",
											}
										else
											return true,
												{
													["Z"] = "Grab Suspect",
													["C"] = "Uncuff Suspect",
													["P"] = "Pin Suspect",
												}
										end
									else
										return true,
											{
												["C"] = "Cuff Suspect",
												["X"] = "Issue Citation",
												["H"] = "Search Suspect",
											}
									end
								end
							end
						end
					end
				end
			end
		end
	end

	return false, {}
end

local DebouncePlayer = {}
local SearchDebounce = {}
function Int.Init()
	Players.PlayerRemoving:Connect(function(player)
		DebouncePlayer[player] = nil
		SearchDebounce[player] = nil
	end)
end

function Int.Execute(Player, Part, Key)
	local TargetPlayer = Players:GetPlayerFromCharacter(Part.Parent)

	DebouncePlayer[Player] = DebouncePlayer[Player] or false
	SearchDebounce[Player] = SearchDebounce[Player] or false

	if TargetPlayer then
		-- *
		if DebouncePlayer[Player] == false then
			DebouncePlayer[Player] = true
			if Key == Enum.KeyCode.H then
				if SearchDebounce[Player] == false then
					SearchDebounce[Player] = true
					local Data = knit.GetService("InventoryService"):GetData(TargetPlayer)
					if Data then
						knit.GetService("NotificationService"):SendBypass(
							{ TargetPlayer },
							"Search Request",
							Player.Name .. " wants to search your person.",
							"rbxassetid://10342716476",
							"Alert",
							8
						)

						knit.GetService("NotificationService"):SendBypass(
							{ Player },
							"Search Request",
							"A request has been sent to the suspect.",
							"rbxassetid://10342716476",
							"Misc",
							10
						)

						local ret = ReplicatedStorage.Consent:InvokeClient(TargetPlayer, Player)
						if ret == true then
							knit.GetService("NotificationService"):SendBypass(
								{ Player },
								"Consent Status",
								TargetPlayer.Name .. " accepted to get searched.",
								"rbxassetid://10342716476",
								"Success",
								30
							)
							ReplicatedStorage.Search:FireClient(Player, TargetPlayer, Data)
							knit.GetService("NotificationService"):SendBypass(
								{ TargetPlayer },
								"Search",
								Player.Name .. " has searched you.",
								"rbxassetid://10342716476",
								"Info",
								10
							)
						else
							knit.GetService("OverrideService"):Override(Player, TargetPlayer)
							knit.GetService("NotificationService"):SendBypass(
								{ Player },
								"Consent Status",
								TargetPlayer.Name .. " declined to get searched.",
								"rbxassetid://10342716476",
								"Alert",
								30
							)
						end
					end

					task.delay(30, function()
						SearchDebounce[Player] = false
					end)
				end
			elseif Key == Enum.KeyCode.G then
				if Player.Cuffing.Value == TargetPlayer then
					if Player.Grabbing.Value == TargetPlayer then
						--! TODO: REMOVE GRABBING
						Release(Player, TargetPlayer)
					else
						--! TODO: ADD GRABBING
						Grab(Player, TargetPlayer)
					end
				end
			elseif Key == Enum.KeyCode.C then
				if Player.Cuffing.Value == TargetPlayer then
					--! TODO: REMOVE CUFFING & GRABBING

					knit.GetService("NotificationService"):SendBypass(
						{ Player },
						"Uncuffed a Suspect!",
						"You have uncuffed " .. TargetPlayer.Name,
						"rbxassetid://10342716476",
						"Success",
						20
					)

					knit.GetService("NotificationService"):SendBypass(
						{ TargetPlayer },
						"Released!",
						"You have been released by " .. Player.Name .. ".",
						"rbxassetid://10342716476",
						"Info",
						10
					)

					Release(Player, TargetPlayer)
					Uncuff(Player, TargetPlayer)
					knit.GetService("InventoryService"):AddItem(Player, 9, 1)
				else
					knit.GetService("NotificationService"):SendBypass(
						{ TargetPlayer },
						"Cuffed!",
						"You have been cuffed by "
							.. Player.Name
							.. ". Do not leave or you may face administrative actions.",
						"rbxassetid://10342716476",
						"Alert",
						60
					)

					knit.GetService("NotificationService"):SendBypass(
						{ Player },
						"Cuffed a Suspect!",
						"You have cuffed " .. TargetPlayer.Name,
						"rbxassetid://10342716476",
						"Success",
						20
					)
					Cuff(Player, TargetPlayer)

					--* Remove one handcuff
					knit.GetService("InventoryService"):RemoveItem(Player, 9)
				end
			elseif Key == Enum.KeyCode.P then
				if Player.Cuffing.Value == TargetPlayer then
					if TargetPlayer.Pinner.Value == Player then
						--! REMOVE PIN
						TargetPlayer.Pinner.Value = nil

						local TargetChar = TargetPlayer.Character
						local TargetHumanoid = TargetChar:WaitForChild("Humanoid", 8)
						local cuffWeld = TargetChar:WaitForChild("Cuffs"):WaitForChild("CuffWeld")

						cuffWeld.C1 = CFrame.new(0, -0.7, 1.1) * CFrame.Angles(0, math.rad(0), 0)

						local animTable = Int.getAnims()[TargetPlayer]
						animTable.Pin[1]:Stop()
						animTable.Pin[1]:Destroy()
						animTable.Pin[2]:Destroy()

						TargetHumanoid.WalkSpeed = 0
						TargetHumanoid.JumpPower = 0
					else
						--! PIN
						TargetPlayer.Pinner.Value = Player

						local TargetChar = TargetPlayer.Character
						local TargetHumanoid = TargetChar:WaitForChild("Humanoid", 8)
						local cuffWeld = TargetChar:WaitForChild("Cuffs"):WaitForChild("CuffWeld")
						local animObj = Instance.new("Animation")
						animObj.AnimationId = "rbxassetid://10007999079"
						animObj.Parent = script

						Int.getAnims()[TargetPlayer] = {
							Pin = { TargetHumanoid:LoadAnimation(animObj), animObj },
						}

						Int.getAnims()[TargetPlayer].Pin[1]:Play()
						TargetHumanoid.WalkSpeed = 0
						TargetHumanoid.JumpPower = 0

						cuffWeld.C1 = CFrame.new(0, -1.8, 1.1) * CFrame.Angles(0, math.rad(0), 0)
					end
				end
			end

			task.delay(0.8, function()
				DebouncePlayer[Player] = false
			end)
		end
	end

	return true
end

return Int
