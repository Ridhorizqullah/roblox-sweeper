--!strict
return {
	Order = {"SweepBot", "OrbitBot"},
	TickSeconds = 0.25,
	VisualSize = Vector3.new(1.5, 1, 1.5),
	VisualSpacing = 2,
	VisualBehind = 3,
	MaximumRobots = 3,
	ById = {
		SweepBot = {name = "Sweep Bot", speed = 2, range = 16, power = 2, price = 250},
		OrbitBot = {name = "Orbit Bot", speed = 1.2, range = 24, power = 5, price = 1200},
	},
}
