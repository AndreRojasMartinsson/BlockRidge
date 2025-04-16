local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LogService = game:GetService("LogService")

local Knit = require(ReplicatedStorage.Packages.Knit)
local Input = require(ReplicatedStorage.Packages.Input)

local ClientOutput = Knit.CreateController({ Name = "ClientOutput" })

function ClientOutput:Setup()
	LogService.MessageOut:Connect(function(Message, MessageType: Enum.MessageType)
		local frame: TextLabel | nil = nil
		if MessageType == Enum.MessageType.MessageError then
			frame = self.ErrorTemplate:Clone()
		elseif MessageType == Enum.MessageType.MessageWarning then
			frame = self.WarningTemplate:Clone()
		else
			frame = self.NormalTemplate:Clone()
		end

		frame.Name = HttpService:GenerateGUID(false)
		frame.Text = Message
		frame.Parent = self.Gui.Frame.ScrollingFrame
		task.delay(0.1, function()
			frame.Size = UDim2.new(1, 0, 0, frame.TextBounds.Y + 5)
		end)
	end)
end

function ClientOutput:KnitStart()
	local layout: UIListLayout = self.Gui.Frame.ScrollingFrame.UIListLayout
	local absoluteContentSize = layout.AbsoluteContentSize
	self.Gui.Frame.ScrollingFrame.CanvasSize = UDim2.new(0, 0, 0, absoluteContentSize.Y)
	layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		local absoluteContentSize = layout.AbsoluteContentSize
		self.Gui.Frame.ScrollingFrame.CanvasSize = UDim2.new(0, 0, 0, absoluteContentSize.Y + 8)
	end)

	self.Keyboard.KeyDown:Connect(function(key)
		if key == Enum.KeyCode.Y then
			self.Gui.Parent.Visible = not self.Gui.Parent.Visible
		end
	end)

	self:Setup()
end

function ClientOutput:KnitInit()
	self.Gui = Knit.Player.PlayerGui:WaitForChild("Interface", 5):WaitForChild("Outputs"):WaitForChild("Client")
	self.Keyboard = Input.Keyboard.new()

	self.NormalTemplate = ReplicatedStorage.Assets.GUI.Console.Normal
	self.ErrorTemplate = ReplicatedStorage.Assets.GUI.Console.Error
	self.WarningTemplate = ReplicatedStorage.Assets.GUI.Console.Warning
end

return ClientOutput
