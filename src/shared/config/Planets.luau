--!strict
return {
	Portal = {Radius = 14, Cooldown = 1, HoldSeconds = 1, Size = Vector3.new(5, 6, 2), Offset = Vector3.new(-16, 3, 0), Spacing = 12},
	Order = {"DustyMoonlet", "CrystalDesert", "NeonSwamp"},
	ById = {
		DustyMoonlet = {name = "Dusty Moonlet", dirtColor = Color3.fromRGB(175, 160, 140), groundColor = Color3.fromRGB(87, 84, 110), dirtValue = 1, dirtDensity = 60, nodeAmount = 5, respawnSeconds = 8, unlockPrice = 0, petPool = "Moonlet"},
		CrystalDesert = {name = "Crystal Desert", dirtColor = Color3.fromRGB(220, 160, 240), groundColor = Color3.fromRGB(194, 154, 110), dirtValue = 3, dirtDensity = 80, nodeAmount = 15, respawnSeconds = 10, unlockPrice = 1000, petPool = "Desert"},
		NeonSwamp = {name = "Neon Swamp", dirtColor = Color3.fromRGB(130, 255, 110), groundColor = Color3.fromRGB(35, 70, 64), dirtValue = 8, dirtDensity = 100, nodeAmount = 30, respawnSeconds = 12, unlockPrice = 5000, petPool = "Swamp"},
	},
}
