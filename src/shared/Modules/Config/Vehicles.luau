local Vehicles = {}

Vehicles.DHS20ExpLTBR = {
	Name = "DHS 2020 Explorer",
	Asset = "DHS20ExpLTBR",
	Description = "The 2020 Explorer is a fascinating piece of machine, and is handcrafted by very professional individuals.",
	GasTank = 15,
	InventorySize = 60,
	Acceleration = 11,
	ELS = false,
	LEO = true,
	Health = 100,
	Torque = 180_000,
	Gears = {
		-15,
		0,
		30,
		50,
		70,
		110,
	},
	BrakeAcceleration = 40,
	TurnSpeed = 2.5,
	Height = 2,
	Fuel_Max = 1_200,
	WheelBase = 10.793,
	Price = 300,
	TrackWidth = 5,
	SteeringRatio = 15 / 1,
	SteeringMultiplier = 40,
	StartingAngle = -90,
}

return Vehicles
