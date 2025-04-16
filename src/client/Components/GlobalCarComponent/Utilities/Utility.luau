local module = {}

function module.IsInRange(Player: Player, Vehicle)
	local dist = Player:DistanceFromCharacter(Vehicle.Essentials.Root.Position)
	if dist <= 256 then
		return true
	end

	return false
end

return module
