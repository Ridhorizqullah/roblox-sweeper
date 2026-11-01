--!strict
-- Palette.luau
-- Single source of truth for all visual colors inspired by the lunar space sweeper reference art.

return {
	Earth = Color3.fromRGB(40, 120, 220), EarthLand = Color3.fromRGB(55, 150, 80),
	Sun = Color3.fromRGB(255, 248, 220), Space = Color3.new(0, 0, 0),
	Stars = Color3.fromRGB(219, 229, 255), Ambient = Color3.fromRGB(34, 32, 45),
	OutdoorAmbient = Color3.fromRGB(78, 75, 91), Tint = Color3.fromRGB(239, 235, 255),
	-- World & Environment
	Ground = Color3.fromRGB(195, 192, 205),          -- Pale gray-lavender lunar regolith
	GroundClean = Color3.fromRGB(235, 235, 245),     -- Smooth polished ground revealed after cleaning
	PebbleDark = Color3.fromRGB(120, 118, 130),       -- Coarse regolith pebbles
	PebbleLight = Color3.fromRGB(160, 158, 170),      -- Fine surface dust pebbles
	RoadYellow = Color3.fromRGB(250, 205, 50),        -- Yellow painted runway / guidance seam lines
	SpaceSky = Color3.fromRGB(6, 6, 12),              -- Void of space
	SunGlow = Color3.fromRGB(255, 248, 220),          -- Distant bright solar glare
	EarthBlue = Color3.fromRGB(40, 120, 220),         -- Earth ocean
	EarthGreen = Color3.fromRGB(55, 150, 80),         -- Earth landmass
	EarthCloud = Color3.fromRGB(240, 245, 255),       -- Earth atmosphere & clouds

	-- Sci-Fi Lunar Outpost Architecture (Modular Base, Solar, Tanks)
	StationWhite = Color3.fromRGB(242, 244, 248),     -- Modular composite habitat panels
	StationDark = Color3.fromRGB(50, 54, 64),         -- Industrial base trims & foundations
	AccentOrange = Color3.fromRGB(245, 120, 25),      -- High-visibility safety orange trim
	AccentTeal = Color3.fromRGB(45, 195, 225),        -- High-tech illuminated glass & monitors
	MetalPipes = Color3.fromRGB(140, 145, 155),       -- Utility conduits & pipes
	SolarBlue = Color3.fromRGB(25, 42, 75),           -- Photovoltaic crystalline solar cells
	AirlockDoor = Color3.fromRGB(70, 75, 88),         -- Pressurized hatch door

	-- Character & Space Suits
	SuitWhite = Color3.fromRGB(245, 245, 250),
	SuitRed = Color3.fromRGB(225, 45, 45),            -- Stripe bands on arms/legs
	SuitBackpack = Color3.fromRGB(160, 165, 175),
	SuitVisor = Color3.fromRGB(22, 25, 32),           -- Glossy dark helmet visor

	-- Vehicles & Sweeper Bots (Ref: Lunar Sweeper Cart & Truck)
	CartBody = Color3.fromRGB(245, 243, 238),        -- Off-white / cream body
	CartTeal = Color3.fromRGB(38, 70, 82),            -- Dark teal chassis skirt
	CartOrange = Color3.fromRGB(245, 115, 20),        -- Racing & warning stripes
	BrushOrange = Color3.fromRGB(255, 130, 15),       -- Heavy-duty sweeping bristle discs
	BeaconAmber = Color3.fromRGB(255, 170, 0),        -- Flashing amber warning beacon
	TireRubber = Color3.fromRGB(30, 32, 36),          -- Rugged rover wheel rubber

	-- Pet Rarity Tiers
	Rarity = {
		Common = Color3.fromRGB(180, 185, 195),
		Rare = Color3.fromRGB(60, 160, 255),
		Epic = Color3.fromRGB(185, 75, 255),
		Legendary = Color3.fromRGB(255, 180, 30),
		Mythic = Color3.fromRGB(255, 55, 95),
	},

	-- User Interface
	UiBackground = Color3.fromRGB(28, 32, 42),
	UiPanel = Color3.fromRGB(38, 44, 58),
	UiBorder = Color3.fromRGB(65, 75, 95),
	UiTextPrimary = Color3.fromRGB(255, 255, 255),
	UiTextMuted = Color3.fromRGB(175, 182, 198),
	UiSuccess = Color3.fromRGB(75, 215, 130),
	UiWarning = Color3.fromRGB(255, 170, 40),
}
