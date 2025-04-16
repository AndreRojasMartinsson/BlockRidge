return function(self)
	self.Trove:Add(self.Keyboard.KeyDown:Connect(function(input)
		if input == Enum.KeyCode.R then
			self:ChangeGear(true)
		elseif input == Enum.KeyCode.F then
			self:ChangeGear(false)
		end
	end))
end
