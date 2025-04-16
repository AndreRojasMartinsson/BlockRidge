local Debris = game:GetService("Debris")
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Packages.Knit)

local NotificationController = Knit.CreateController({
	Name = "NotificationController",
})

local types = {
	Alert = Color3.fromRGB(170, 90, 90),
	Moderation = Color3.fromRGB(107, 90, 170),
	Success = Color3.fromRGB(90, 170, 101),
	Warning = Color3.fromRGB(204, 139, 55),
	Info = Color3.fromRGB(90, 135, 170),
	Misc = Color3.fromRGB(82, 85, 87),
}

function NotificationController:_IsAtBottom()
	local ScrollFrame = self.Gui.Content
	if ScrollFrame.CanvasPosition.Y == ScrollFrame.CanvasSize.Y.Offset - ScrollFrame.AbsoluteSize.Y then
		return true
	else
		return false
	end
end

function NotificationController:Send(Title, Text, Icon, Type, Duration)
	local new = self.Template:Clone()
	new.Name = HttpService:GenerateGUID(false)

	new.UIStroke.Color = types[Type] or types.Alert
	new.Header.Title.TextColor3 = types[Type] or types.Alert
	new.Header.Icon.ImageColor3 = types[Type] or types.Alert
	new.Header.Icon.Image = Icon or ""

	new.Header.Title.Text = Title or ""
	new.Label.Text = Text or ""
	new.Parent = self.Gui.Content

	task.delay(0.01, function()
		local Label: TextLabel = new.Label
		new.Label.Size = UDim2.new(1, 0, 0, Label.TextBounds.Y + 5)
		task.delay(0.01, function()
			new.Size = UDim2.new(1, 0, 0, new.UIListLayout.AbsoluteContentSize.Y + 5)
		end)
	end)

	-- TODO: Play sound
	local sound = Instance.new("Sound")
	if Type == "Alert" then
		sound.SoundId = "rbxassetid://10191652411"
	else
		sound.SoundId = "rbxassetid://10191636259"
	end

	sound.PlayOnRemove = true
	sound.Volume = 1
	sound.Parent = workspace
	sound:Destroy()

	Debris:AddItem(new, Duration or 8)
end

function NotificationController:KnitStart()
	self.Gui = Knit.Player.PlayerGui:WaitForChild("Interface", 5):WaitForChild("Notifications")
	self.Template = ReplicatedStorage.Assets.GUI.Notifications.Notification
	self.Service = Knit.GetService("NotificationService")

	self.Gui.Content.ChildAdded:Connect(function(child)
		task.wait(0.05)
		self.Gui.Content.CanvasPosition = Vector2.new(0, 9999999999)
	end)

	self:Send(
		"Test Title",
		"thotgrkh torkfhokp trkpoh koptrkopht opkrh pokhtrpokh kpo hrtdfzghbfgdthtrokph ko+trkoh trkophkpotrpokhpko",
		"rbxassetid://10191652411",
		"Alert",
		30
	)

	local layout: UIListLayout = self.Gui.Content.UIListLayout
	local absoluteContentSize = layout.AbsoluteContentSize
	self.Gui.Content.CanvasSize = UDim2.new(0, 0, 0, absoluteContentSize.Y)
	layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		local absoluteContentSize = layout.AbsoluteContentSize
		self.Gui.Content.CanvasSize = UDim2.new(0, 0, 0, absoluteContentSize.Y + 8)
	end)

	self.Service.SendNotification:Connect(function(...)
		self:Send(...)
	end)
end

function NotificationController:KnitInit() end

return NotificationController
