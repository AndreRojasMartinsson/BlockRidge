local on = false

return function(self)
	self.Trove:Add(self.Keyboard.KeyDown:Connect(function(input)
		if input == Enum.KeyCode.L then
			self:SetHeadlight(not on)
			on = not on
		end
	end))
end
