--!strict
-- Assets.luau
-- Asset slot overrides. Empty strings fall back to procedural code models.
-- When replacing with custom 3D meshes/sounds from Roblox Studio, paste asset IDs here.

export type AssetEntry = {
	MeshId: string,
	TextureId: string,
	ModelId: string?,
	SoundId: string?,
	Scale: Vector3?,
	Color: Color3?,
}

return {
	-- World & Sky Elements
	Earth = {MeshId = "", TextureId = "", ModelId = "", SoundId = ""},
	EarthDetail = {MeshId = "", TextureId = "", ModelId = "", SoundId = ""},
	Sun = {MeshId = "", TextureId = "", ModelId = "", SoundId = ""},
	SpaceWall = {MeshId = "", TextureId = "", ModelId = "", SoundId = ""},
	Star = {MeshId = "", TextureId = "", ModelId = "", SoundId = ""},
	GuideLine = {MeshId = "", TextureId = "", ModelId = "", SoundId = ""},

	-- Dust cells & pebbles (Color fallback used when no mesh override).
	PebbleDark = {MeshId = "", TextureId = "", ModelId = nil, SoundId = nil, Scale = nil, Color = Color3.fromRGB(120, 118, 130)},
	PebbleLight = {MeshId = "", TextureId = "", ModelId = nil, SoundId = nil, Scale = nil, Color = Color3.fromRGB(160, 158, 170)},

	-- Tools
	Tools = {
		Toothbrush = {MeshId = "", TextureId = ""},
		HandBroom = {MeshId = "", TextureId = ""},
		Vacuum = {MeshId = "", TextureId = ""},
		LeafBlower = {MeshId = "", TextureId = ""},
		PlasmaCleaner = {MeshId = "", TextureId = ""},
		QuantumSweeper = {MeshId = "", TextureId = ""},
	},

	-- Vehicles & Robots
	Vehicles = {
		SweepBot = {MeshId = "", TextureId = ""},
		OrbitBot = {MeshId = "", TextureId = ""},
		LunarSweeperTruck = {MeshId = "", TextureId = ""},
	},

	-- Player Character
	Costumes = {
		AstronautSuit = {MeshId = "", TextureId = ""},
		Helmet = {MeshId = "", TextureId = ""},
		Backpack = {MeshId = "", TextureId = ""},
	},

	-- Outpost Stations & Props
	Stations = {
		CentralHabitat = {MeshId = "", TextureId = ""},
		SellStation = {MeshId = "", TextureId = ""},
		SolarArray = {MeshId = "", TextureId = ""},
		StorageTank = {MeshId = "", TextureId = ""},
	},
}
