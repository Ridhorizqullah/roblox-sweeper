--!strict
-- Assets.luau
-- Asset slot overrides. Empty strings fall back to procedural code models.
-- When replacing with custom 3D meshes/sounds from Roblox Studio, paste asset IDs here.

export type AssetEntry = {
	MeshId: string?,
	TextureId: string?,
	SoundId: string?,
	Scale: Vector3?,
}

return {
	Earth = {MeshId = "", ModelId = "", TextureId = "", SoundId = ""},
	EarthDetail = {MeshId = "", ModelId = "", TextureId = "", SoundId = ""},
	Sun = {MeshId = "", ModelId = "", TextureId = "", SoundId = ""},
	Star = {MeshId = "", ModelId = "", TextureId = "", SoundId = ""},
	SpaceWall = {MeshId = "", ModelId = "", TextureId = "", SoundId = ""},
	GuideLine = {MeshId = "", ModelId = "", TextureId = "", SoundId = ""},
	Tools = {
		Toothbrush = {MeshId = "", TextureId = ""},
		HandBroom = {MeshId = "", TextureId = ""},
		Vacuum = {MeshId = "", TextureId = ""},
		LeafBlower = {MeshId = "", TextureId = ""},
		PlasmaCleaner = {MeshId = "", TextureId = ""},
		QuantumSweeper = {MeshId = "", TextureId = ""},
	},
	Vehicles = {
		SweepBot = {MeshId = "", TextureId = ""},
		OrbitBot = {MeshId = "", TextureId = ""},
		LunarSweeperTruck = {MeshId = "", TextureId = ""},
	},
	Costumes = {
		AstronautSuit = {MeshId = "", TextureId = ""},
		Helmet = {MeshId = "", TextureId = ""},
		Backpack = {MeshId = "", TextureId = ""},
	},
	Stations = {
		CentralHabitat = {MeshId = "", TextureId = ""},
		SellStation = {MeshId = "", TextureId = ""},
		SolarArray = {MeshId = "", TextureId = ""},
		StorageTank = {MeshId = "", TextureId = ""},
	},
}
