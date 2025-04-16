local LI = false
local RI = false

return function(self)
	self.Trove:Add(self.Keyboard.KeyDown:Connect(function(input)
		if input == Enum.KeyCode.Q then
			self:SetIndicator("LI", not LI)
			self:SetIndicator("RI", false)

			LI = not LI
			RI = false
		elseif input == Enum.KeyCode.E then
			self:SetIndicator("RI", not RI)
			self:SetIndicator("LI", false)

			RI = not RI
			LI = false
		end
	end))
end
