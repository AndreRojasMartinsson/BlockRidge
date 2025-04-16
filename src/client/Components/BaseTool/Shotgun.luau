local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Shotgun = {}
Shotgun.__index = Shotgun

local Component = require(ReplicatedStorage.Packages.Component)
local BasicState = require(ReplicatedStorage.Packages.BasicState)
local Knit = require(ReplicatedStorage.Packages.Knit)
local Config = require(ReplicatedStorage.Shared.Modules.Config)

local CameraShaker = require(ReplicatedStorage.Assets.CameraShaker)

local BaseToolComponent = require(script.Parent)
local Items = Config("Items")

local IdleCrosshair = "rbxassetid://10052760275"
local HitCrosshair = "rbxassetid://10052735538"

local function GetItemDataFromAsset(Asset)
	local data = nil
	for idx, _dat in pairs(Items) do
		if _dat.Asset == Asset then
			data = _dat
			break
		end
	end

	return data
end

local function CreateTrack(Name, Id)
	local new = Instance.new("Animation")
	new.Name = Name
	new.AnimationId = Id

	return new
end

local CamShake = CameraShaker.new(Enum.RenderPriority.Camera.Value, function(shakeCFrame)
	workspace.CurrentCamera.CFrame *= shakeCFrame
end)

local function isFirstPerson()
	local camera = workspace.CurrentCamera
	local character = Knit.Character
	if (character.Head.CFrame.Position - camera.CFrame.Position).magnitude < 1 then
		return true
	else
		return false
	end
end

function lerp(a, b, t) -- Gets a number between two points using an alpha
	return a * (1 - t) + (b * t)
end

function Shotgun:FireGun()
	if self.State:Get("Reloading") == true then
		return
	end

	if self.State:Get("FireDebounce") == false then
		self.State:Set("FireDebounce", true)

		task.delay(0.65, function()
			self.State:Set("FireDebounce", false)
		end)

		task.spawn(function()
			Knit.GetService("ToolService")
				:Fire(self.Component.PlayerMouse.Hit.Position, Knit.GetController("Sync"):GetMeanLatency() or 0)
		end)

		if self.State:Get("ChamberRounds") > 0 then
			local Handle = self.Instance:FindFirstChild("Handle")
			local curShot = self.State:Get("CurShot")
			local LastClick = self.State:Get("LastClick")
			local RecoilReset = self.State:Get("RecoilReset")
			self.State:Set("CurShot", (tick() - LastClick > RecoilReset and 1 or curShot + 1))
			self.State:Set("LastClick", tick())

			CamShake:ShakeOnce(2.5, 16.5, 0.18, 0.4)

			if self.State:Get("Aiming") then
				self.AimFireTrack:Play()
			else
				self.FireTrack:Play()
			end

			local Camera = workspace.CurrentCamera
			for _, v in pairs(self.ItemTable.RecoilPattern) do
				if self.State:Get("CurShot") <= v[1] then -- Found the current recoil we're at
					task.spawn(function()
						local num = 0
						while math.abs(num - v[2]) > 0.01 do
							num = lerp(num, v[2], v[4])
							local rec = num / 10
							Camera.CFrame = Camera.CFrame * CFrame.Angles(math.rad(rec), math.rad(rec * v[5]), 0)
							RunService.RenderStepped:Wait()
						end
						while math.abs(num - v[3]) > 0.01 do
							num = lerp(num, v[3], v[4])
							local rec = num / 10
							Camera.CFrame = Camera.CFrame * CFrame.Angles(math.rad(rec), math.rad(rec * v[5]), 0)
							RunService.RenderStepped:Wait()
						end
					end)
					break
				end
			end

			local RootAttachment = Handle.RootAttachment
			RootAttachment.Beam.Enabled = true
			RootAttachment.ParticleEmitter:Emit(25)
			RootAttachment.PointLight.Enabled = true

			task.delay(0.02, function()
				if RootAttachment and RootAttachment:FindFirstChild("Beam") then
					RootAttachment.Beam.Enabled = false
					RootAttachment.PointLight.Enabled = false
					Handle.Smoke.Smoke.Enabled = true
				end

				task.delay(1.5, function()
					if self and self.Instance and Handle and Handle:FindFirstChild("Smoke") then
						Handle.Smoke.Smoke.Enabled = false
					end
				end)
			end)
		end
	end
end

function Shotgun:Init()
	self.Char = Knit.Character
	self.Humanoid = self.Char:WaitForChild("Humanoid")
	self.Animator = self.Humanoid:WaitForChild("CharAnimator")

	RunService:BindToRenderStep("ShotgunUpdate", Enum.RenderPriority.Character.Value, function()
		if isFirstPerson() == true then
			UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
		else
			UserInputService.MouseBehavior = Enum.MouseBehavior.Default
		end

		if isFirstPerson() == false and self.State:Get("Aiming") == true then
			self.State:Set("Aiming", false)
			UserInputService.MouseIconEnabled = true
			TweenService
				:Create(workspace.CurrentCamera, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
					FieldOfView = 70,
				})
				:Play()

			UserInputService.MouseDeltaSensitivity = 1

			self.AimTrack:Stop()
			self.IdleTrack:Play()
		end
	end)

	self.Component.Trove:Add(Knit.GetService("ToolService").RoundsChanged:Connect(function(newRounds)
		self.State:Set("ChamberRounds", newRounds)
	end))

	self.Component.Trove:Add(Knit.GetService("ToolService").TotalRoundsChanged:Connect(function(newRounds)
		self.State:Set("TotalRounds", newRounds)
	end))

	if GetItemDataFromAsset(self.Instance.Name) then
		local ItemTable = GetItemDataFromAsset(self.Instance.Name)
		local AnimTable = ItemTable.Animations

		self.ItemTable = ItemTable

		self.Idle = CreateTrack("Idle", AnimTable.Idle)
		self.Reload = CreateTrack("Reload", AnimTable.Reload)
		self.Aim = CreateTrack("Aim", AnimTable.Aim)
		self.Fire = CreateTrack("Fire", AnimTable.Fire)
		self.AimFire = CreateTrack("AimFire", AnimTable.AimFire)
		self.Pump = CreateTrack("Pump", AnimTable.Pump)
		self.AimPump = CreateTrack("AimPump", AnimTable.AimPump)

		self.IdleTrack = self.Animator:LoadAnimation(self.Idle)
		self.AimTrack = self.Animator:LoadAnimation(self.Aim)
		self.FireTrack = self.Animator:LoadAnimation(self.Fire)
		self.ReloadTrack = self.Animator:LoadAnimation(self.Reload)
		self.AimFireTrack = self.Animator:LoadAnimation(self.AimFire)

		self.PumpTrack = self.Animator:LoadAnimation(self.Pump)
		self.AimPumpTrack = self.Animator:LoadAnimation(self.AimPump)

		self.Component.Trove:Add(self.ReloadTrack:GetMarkerReachedSignal("HideMag"):Connect(function()
			Knit.GetService("ToolService"):SetMag(1)
		end))

		self.Component.Trove:Add(self.FireTrack:GetMarkerReachedSignal("Pump"):Connect(function()
			task.delay(0.15, function()
				if self.State:Get("Aiming") then
					self.AimPumpTrack:Play()
				else
					self.PumpTrack:Play()
				end
			end)
		end))

		self.Component.Trove:Add(self.ReloadTrack:GetMarkerReachedSignal("ShowMag"):Connect(function()
			Knit.GetService("ToolService"):SetMag(0)
		end))

		self.Component.PlayerMouse.Icon = IdleCrosshair
		self.IdleTrack:Play()

		self.Component.Trove:Add(self.Component.Mouse.RightDown:Connect(function()
			if self.State:Get("Reloading") == true then
				return
			end

			if self.State:Get("Aiming") == false and isFirstPerson() == true then
				self.State:Set("Aiming", true)
				UserInputService.MouseIconEnabled = false
				TweenService
					:Create(
						workspace.CurrentCamera,
						TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
						{
							FieldOfView = 50,
						}
					)
					:Play()

				UserInputService.MouseDeltaSensitivity = 0.2

				self.IdleTrack:Stop()
				self.AimTrack:Play()
			end
		end))

		self.Component.Trove:Add(self.Component.Mouse.LeftUp:Connect(function()
			self.State:Set("MouseDown", false)
		end))

		self.Component.Trove:Add(self.Component.Mouse.LeftDown:Connect(function()
			local thisTick = tick()
			self.State:Set("MouseDown", ItemTable.Automatic and thisTick)
			repeat
				RunService.Heartbeat:Wait()
				self:FireGun()
			until self.State:Get("MouseDown") ~= thisTick
		end))

		self.Component.Trove:Add(self.State:GetChangedSignal("Reloading"):Connect(function(new)
			if new == true then
				local ChamberRounds = self.State:Get("ChamberRounds")
				local TotalRounds = self.State:Get("TotalRounds")
				if ChamberRounds < ItemTable.MaxRounds then
					if TotalRounds == 0 then
						self.State:Set("Reloading", false)
						return
					end

					local ChamberRounds = self.State:Get("ChamberRounds")
					if ChamberRounds == 8 then
						self.State:Set("Reloading", false)
					end

					self.State:Set("Reloading", true)

					local FillAmount = math.min(ItemTable.MaxRounds - ChamberRounds, TotalRounds)
					for _ = 1, FillAmount do
						Knit.GetService("ToolService"):Reload(Knit.GetController("Sync"):GetMeanLatency() or 0):await()
						self.ReloadTrack:AdjustSpeed(0.4)
						self.ReloadTrack:Play(0.4)
						task.wait(2.5)
					end

					if self.State then
						self.State:Set("Reloading", false)
					end
				end
			end
		end))

		self.Component.Trove:Add(self.Component.Keyboard.KeyDown:Connect(function(key)
			if key == Enum.KeyCode.R then
				if self.State:Get("Reloading") == true then
					return
				end

				self.State:Set("Reloading", true)
			end
		end))

		self.Component.Trove:Add(self.Component.Mouse.RightUp:Connect(function()
			if self.State:Get("Aiming") == true then
				self.State:Set("Aiming", false)
				UserInputService.MouseIconEnabled = true
				TweenService
					:Create(
						workspace.CurrentCamera,
						TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
						{
							FieldOfView = 70,
						}
					)
					:Play()
				UserInputService.MouseDeltaSensitivity = 1

				self.AimTrack:Stop()
				self.IdleTrack:Play()
			end
		end))
	end
end

function Shotgun.new(Model)
	local self = setmetatable({}, Shotgun)

	self.Instance = Model
	self.Component = BaseToolComponent:FromInstance(Model)

	CamShake:Start()

	-- TODO: CamShaker
	self.State = BasicState.new({
		LastClick = tick(),
		Reloading = false,
		CurShot = 0,
		RecoilReset = 0.5,
		ThisTick = tick(),
		MouseDown = false,
		ChamberRounds = 0,
		TotalRounds = 0,
		FireDebounce = false,
		Auto = false,
		Aiming = false,
	})

	self:Init()

	return self
end

function Shotgun:Destroy()
	if self.Component then
		self.Component.Trove:Clean()
	end
	self.IdleTrack:Stop()
	self.AimTrack:Stop()
	self.ReloadTrack:Stop()
	self.AimFireTrack:Stop()
	self.State:Set("Reloading", false)
	self.FireTrack:Stop()
	self.PumpTrack:Stop()
	self.AimPumpTrack:Stop()

	self.Idle:Destroy()
	self.Reload:Destroy()
	self.Aim:Destroy()
	self.Fire:Destroy()
	self.AimFire:Destroy()
	self.Pump:Destroy()
	self.AimPump:Destroy()

	CamShake:Stop()
	RunService:UnbindFromRenderStep("ShotgunUpdate")
	Knit.Player:GetMouse().Icon = ""
	UserInputService.MouseBehavior = Enum.MouseBehavior.Default
	self.State = nil
	self = nil
end

return Shotgun
