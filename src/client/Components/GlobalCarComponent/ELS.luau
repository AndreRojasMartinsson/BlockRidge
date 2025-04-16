local module = {}
module.__index = module
module.Name = "ELS"

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Trove = require(ReplicatedStorage:WaitForChild("Packages").Trove)
local Silo = require(ReplicatedStorage:WaitForChild("Packages").Silo)
local Promise = require(ReplicatedStorage:WaitForChild("Packages").Promise)
local Knit = require(ReplicatedStorage:WaitForChild("Packages").Knit)
local Switch = require(Knit.Shared.Modules.Switch)

function module.new(self)
	local meta = setmetatable({}, module)
	meta.Component = self
	meta.Vehicle = self.Instance

	meta:Setup()

	return meta
end

function module:Setup()
	-- Setup Vehicle Model Constants
	self.Body = self.Vehicle:WaitForChild("Body", 5)
	self.Essentials = self.Vehicle:WaitForChild("Essentials", 5)
	self.Root = self.Essentials:WaitForChild("Root", 5)
	self.ELSModel = self.Body:WaitForChild("Lights", 5):WaitForChild("ELS", 2)
	self.Trove = Trove.new()

	if self.ELSModel then
		for _, v in ipairs(self.ELSModel:GetChildren()) do
			if v:IsA("BasePart") then
				if v and v:FindFirstChild("Point") then
					v.Transparency = 1
					v.Point.Enabled = false
				end
			end
		end
	end

	self.Tasks = {}

	self.State = Silo.new({
		Pattern = 0,
		Takedown = 0,
		Cruise = 0,
		LAlly = 0,
		RAlly = 0,
		Flood = 0,
		TA_Split = 0,
		TA_Left = 0,
		TA_Right = 0,
	}, {
		SetPattern = function(state, data)
			state.Cruise = 0
			if data.toggle then
				state.Pattern = state.Pattern == 0 and 1 or 0
			else
				state.Pattern = data.Pattern
			end
		end,
		SetTakedown = function(state, data)
			if data.toggle then
				state.Takedown = state.Takedown == 0 and 1 or 0
			else
				state.Takedown = data.Takedown
			end
		end,
		SetCruise = function(state, data)
			state.Pattern = 0
			if data.toggle then
				state.Cruise = state.Cruise == 0 and 1 or 0
			else
				state.Cruise = data.Cruise
			end
		end,
		SetLAlly = function(state, data)
			if data.toggle then
				state.LAlly = state.LAlly == 0 and 1 or 0
			else
				state.LAlly = data.LAlly
			end
		end,
		SetRAlly = function(state, data)
			if data.toggle then
				state.RAlly = state.RAlly == 0 and 1 or 0
			else
				state.RAlly = data.RAlly
			end
		end,
		SetFlood = function(state, data)
			if data.toggle then
				state.Flood = state.Flood == 0 and 1 or 0
			else
				state.Flood = data.Flood
			end
		end,
		SetTASplit = function(state, data)
			if data.toggle then
				state.TA_Split = state.TA_Split == 0 and 1 or 0
			else
				state.TA_Split = data.TA_Split
			end
		end,
		SetTALeft = function(state, data)
			if data.toggle then
				state.TA_Left = state.TA_Left == 0 and 1 or 0
			else
				state.TA_Left = data.TA_Left
			end
		end,
		SetTARight = function(state, data)
			if data.toggle then
				state.TA_Right = state.TA_Right == 0 and 1 or 0
			else
				state.TA_Right = data.TA_Right
			end
		end,
	})

	self:SetupProps()
	self:UpdateELS()
end

function module:SetupProps()
	for _, v in ipairs(self.Root:GetChildren()) do
		if v:IsA("IntValue") then
			v:GetPropertyChangedSignal("Value"):Connect(function()
				Switch(v.Name)
					:case("Pattern", function()
						self.State:Dispatch(self.State.Actions.SetPattern({
							Pattern = v.Value,
						}))
						return
					end)
					:case("Takedown", function()
						self.State:Dispatch(self.State.Actions.SetTakedown({
							Takedown = v.Value,
						}))
						return
					end)
					:case("Cruise", function()
						self.State:Dispatch(self.State.Actions.SetCruise({
							Cruise = v.Value,
						}))
						return
					end)
					:case("LAlly", function()
						self.State:Dispatch(self.State.Actions.SetLAlly({
							LAlly = v.Value,
						}))
						return
					end)
					:case("RAlly", function()
						self.State:Dispatch(self.State.Actions.SetRAlly({
							RAlly = v.Value,
						}))
						return
					end)
					:case("Flood", function()
						self.State:Dispatch(self.State.Actions.SetFlood({
							Flood = v.Value,
						}))
						return
					end)
					:case("TASplit", function()
						self.State:Dispatch(self.State.Actions.SetTASplit({
							TA_Split = v.Value,
						}))
						return
					end)
					:case("TALeft", function()
						self.State:Dispatch(self.State.Actions.SetTALeft({
							TA_Left = v.Value,
						}))
						return
					end)
					:case("TARight", function()
						self.State:Dispatch(self.State.Actions.SetTARight({
							TA_Right = v.Value,
						}))
						return
					end)
					:default(function() end)
					:exec()
			end)
		end
	end
end

function module:UpdateLightState(Lights, State, Color)
	task.spawn(function()
		for _, v in ipairs(Lights) do
			local Light = self.ELSModel:FindFirstChild(v)
			Light.Color = Color
			Light.Point.Color = Color
			Light.Transparency = State and 0 or 1
			Light.Point.Enabled = State
		end
	end)
end

local function GetPattern(ModelName, Name)
	return require(ReplicatedStorage.Assets.ELS:FindFirstChild(ModelName):FindFirstChild(Name))
end

function module:UpdateELS()
	self.State:Subscribe(function(State, OldState)
		local Pattern = State.Pattern
		local Takedown = State.Takedown
		local Cruise = State.Cruise
		local LAlly = State.LAlly
		local RAlly = State.RAlly
		local Flood = State.Flood
		local TASplit = State.TA_Split
		local TALeft = State.TA_Left
		local TARight = State.TA_Right

		task.spawn(function()
			-- Pattern Handling
			Switch(Pattern)
				:case(1, function()
					local pattern = GetPattern(self.Vehicle.Name, "Pattern1")
					self.Tasks["Pattern"] = { coroutine.create(pattern.Callback), pattern.Priority, pattern.Off }
					return
				end)
				:case(2, function()
					local pattern = GetPattern(self.Vehicle.Name, "Pattern2")
					self.Tasks["Pattern"] = { coroutine.create(pattern.Callback), pattern.Priority, pattern.Off }
					return
				end)
				:case(3, function()
					local pattern = GetPattern(self.Vehicle.Name, "Pattern3")
					self.Tasks["Pattern"] = { coroutine.create(pattern.Callback), pattern.Priority, pattern.Off }
					return
				end)
				:default(function()
					local prev = self.Root.Pattern.Value
					if prev > 0 then
						local pat = GetPattern(self.Vehicle.Name, "Pattern" .. prev)
						pat.Off(self)
					end

					self.Tasks["Pattern"] = nil
				end)
				:exec()

			if Takedown == 1 then
				local pattern = GetPattern(self.Vehicle.Name, "Takedown")
				self.Tasks["Takedown"] = { coroutine.create(pattern.Callback), pattern.Priority, pattern.Off }
			elseif Takedown == 0 then
				self.Tasks["Takedown"] = nil
			end

			if Flood == 1 then
				local pattern = GetPattern(self.Vehicle.Name, "Flood")
				self.Tasks["Flood"] = { coroutine.create(pattern.Callback), pattern.Priority, pattern.Off }
			elseif Flood == 0 then
				self.Tasks["Flood"] = nil
			end

			if LAlly == 1 then
				local pattern = GetPattern(self.Vehicle.Name, "LAlly")
				self.Tasks["LAlly"] = { coroutine.create(pattern.Callback), pattern.Priority, pattern.Off }
			elseif LAlly == 0 then
				self.Tasks["LAlly"] = nil
			end

			if RAlly == 1 then
				local pattern = GetPattern(self.Vehicle.Name, "RAlly")
				self.Tasks["RAlly"] = { coroutine.create(pattern.Callback), pattern.Priority, pattern.Off }
			elseif RAlly == 0 then
				self.Tasks["RAlly"] = nil
			end

			if TASplit == 1 then
				local pattern = GetPattern(self.Vehicle.Name, "TA_Split")
				self.Tasks["TA_Split"] = { coroutine.create(pattern.Callback), pattern.Priority, pattern.Off }
			elseif TASplit == 0 then
				self.Tasks["TA_Split"] = nil
			end

			if TALeft == 1 then
				local pattern = GetPattern(self.Vehicle.Name, "TA_Left")
				self.Tasks["TA_Left"] = { coroutine.create(pattern.Callback), pattern.Priority, pattern.Off }
			elseif TALeft == 0 then
				self.Tasks["TA_Left"] = nil
			end

			if TARight == 1 then
				local pattern = GetPattern(self.Vehicle.Name, "TA_Right")
				self.Tasks["TA_Right"] = { coroutine.create(pattern.Callback), pattern.Priority, pattern.Off }
			elseif TARight == 0 then
				self.Tasks["TA_Right"] = nil
			end

			if Cruise == 1 then
				local getVal = self.Root.Pattern.Value
				if getVal > 0 then
					local pat = GetPattern(self.Vehicle.Name, "Pattern" .. getVal)
					pat.Off(self)
				end

				local pattern = GetPattern(self.Vehicle.Name, "Cruise")
				self.Tasks["Cruise"] = { coroutine.create(pattern.Callback), pattern.Priority, pattern.Off }
			elseif Cruise == 0 then
				self.Tasks["Cruise"] = nil
			end
		end)

		-- Lifecycle
		local runTable = {}
		for name, data in pairs(self.Tasks) do
			if runTable[data[2]] then
				table.insert(runTable[data[2]], { name, data[1], data[3] })
			else
				runTable[data[2]] = {}
				table.insert(runTable[data[2]], { name, data[1], data[3] })
			end
		end

		for priority, data in pairs(runTable) do
			for _, thread in ipairs(data) do
				coroutine.resume(thread[2], self)
				coroutine.wrap(function()
					Promise.new(function(r)
						repeat
							task.wait()
						until self.Tasks[thread[1]] == nil
						coroutine.close(thread[2])
						r()
					end):andThen(function()
						if thread and thread[3] then
							thread[3](self)
						end
					end)
				end)()
			end
		end
	end)

	for name, thread in pairs(self.Tasks) do
		coroutine.resume(thread, self)

		coroutine.wrap(function()
			repeat
				task.wait()
			until self.Tasks[name] == nil
			coroutine.close(thread)
		end)()
	end
end

function module:Destroy() end

return module
