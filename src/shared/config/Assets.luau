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

local Palette = require(script.Parent.Palette)

return {
	-- Inactive local integration slots; gameplay builders opt in in their own phases.
	ImportedModels = {
		Toothbrush = {
			LocalModel = "Toothbrush", Kind = "Tool", Category = "Tool", MaxParts = 15,
			DefaultColor = Palette.SuitWhite,
			Colors = {HandleGrip = Palette.AccentTeal, Neck = Palette.MetalPipes,
				Bristle0 = Palette.AccentTeal, Bristle1 = Palette.AccentTeal,
				Bristle2 = Palette.AccentTeal, Bristle3 = Palette.AccentTeal,
				Bristle4 = Palette.AccentTeal, Tip = Palette.AccentOrange},
		},
		CleaningRobot = {
			LocalModel = "CleaningRobot", Kind = "Model", Category = "Vehicle", MaxParts = 40,
			DefaultColor = Palette.CartBody,
			Colors = {Face = Palette.SuitVisor, EyeStrip = Palette.AccentTeal,
				Ring = Palette.CartTeal, Base = Palette.CartTeal, BrushR = Palette.BrushOrange,
				Antenna = Palette.MetalPipes, AntennaTip = Palette.BeaconAmber, Stripe = Palette.CartOrange},
		},
		SweeperCart = {
			LocalModel = "SweeperCart", Kind = "Model", Category = "Vehicle", MaxParts = 40,
			DefaultColor = Palette.CartBody,
			Colors = {Chassis = Palette.CartTeal, Dash = Palette.SuitVisor,
				StripeL = Palette.CartOrange, StripeR = Palette.CartOrange,
				Wheel0 = Palette.TireRubber, Wheel1 = Palette.TireRubber,
				Wheel2 = Palette.TireRubber, Wheel3 = Palette.TireRubber,
				Hub0 = Palette.CartOrange, Hub1 = Palette.CartOrange,
				Hub2 = Palette.CartOrange, Hub3 = Palette.CartOrange,
				Brush = Palette.BrushOrange, BrushGuard = Palette.CartTeal,
				HandlePole = Palette.MetalPipes, HandleGrip = Palette.TireRubber,
				LightL = Palette.AccentTeal, LightR = Palette.AccentTeal},
		},
		MoonBunny = {
			LocalModel = "MoonBunny", Kind = "Model", Category = "Pet", MaxParts = 25,
			DefaultColor = Palette.SuitWhite,
			Colors = {EyeL = Palette.SuitVisor, EyeR = Palette.SuitVisor,
				EarInL = Palette.AccentOrange, EarInR = Palette.AccentOrange,
				Nose = Palette.CartTeal, Belly = Palette.CartBody,
				["Blush L"] = Palette.AccentOrange, ["Blush R"] = Palette.AccentOrange,
				Antenna = Palette.MetalPipes, AntennaTip = Palette.AccentTeal},
		},
	},

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
		Toothbrush = {MeshId = "", TextureId = "", ModelId = "Toothbrush"},
		HandBroom = {MeshId = "", TextureId = ""},
		Vacuum = {MeshId = "", TextureId = ""},
		LeafBlower = {MeshId = "", TextureId = ""},
		PlasmaCleaner = {MeshId = "", TextureId = ""},
		QuantumSweeper = {MeshId = "", TextureId = ""},
	},

	-- Vehicles & Robots
	Vehicles = {
		SweepBot = {MeshId = "", TextureId = "", ModelId = "CleaningRobot"},
		SweeperCart = {MeshId = "", TextureId = "", ModelId = "SweeperCart"},
		OrbitBot = {MeshId = "", TextureId = ""},
		LunarSweeperTruck = {MeshId = "", TextureId = ""},
	},

	-- Visual slot only; MoonBunny is not a new species in the gameplay pet pool.
	Pets = {
		MoonBunny = {MeshId = "", TextureId = "", ModelId = "MoonBunny"},
	},

	-- Player Character
	Costumes = {
		AstronautSuit = {MeshId = "", TextureId = "", ModelId = ""},
		Helmet = {MeshId = "", TextureId = "", ModelId = ""},
		Backpack = {MeshId = "", TextureId = "", ModelId = ""},
	},

	-- Outpost Stations & Props
	Stations = {
		CentralHabitat = {MeshId = "", TextureId = ""},
		SellStation = {MeshId = "", TextureId = ""},
		SolarArray = {MeshId = "", TextureId = ""},
		StorageTank = {MeshId = "", TextureId = ""},
	},
}
