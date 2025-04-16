return function(self)
	self.Trove:Add(self.Keyboard.KeyDown:Connect(function(input)
		if input == Enum.KeyCode.H then
			self:ToggleHorn(true)
		end
	end))

	self.Trove:Add(self.Keyboard.KeyUp:Connect(function(input)
		if input == Enum.KeyCode.H then
			self:ToggleHorn(false)
		end
	end))
end
