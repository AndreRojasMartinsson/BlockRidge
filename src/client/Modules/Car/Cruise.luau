local on = false

return function(self)
	self.Trove:Add(self.Keyboard.KeyDown:Connect(function(input)
		if input == Enum.KeyCode.V then
			self:SetCruise(not on)
			on = not on
		end
	end))
end
