--!strict
-- Palette.luau
-- Single source of truth for all visual colors inspired by the lunar space sweeper reference art.

return {
	-- Lighting & Skybox (Bright Lunar Daylight)
	Ambient = Color3.fromRGB(115, 110, 130),         -- Mid gray-lavender ambient for high readability
	OutdoorAmbient = Color3.fromRGB(95, 90, 112),    -- Diffuse lunar bounce light
	Space = Color3.fromRGB(6, 6, 12),                -- Void of space (pitch black)
	Tint = Color3.fromRGB(250, 248, 255),            -- Crisp neutral lunar sunlight
	Stars = Color3.fromRGB(255, 255, 255),
	Sun = Color3.fromRGB(255, 248, 220),             -- Strong warm solar glare

	-- Celestial bodies
	Earth = Color3.fromRGB(40, 120, 220),
	EarthLand = Color3.fromRGB(55, 150, 80),
	EarthCloud = Color3.fromRGB(245, 245, 255),

	-- World & Environment (Bright pale gray-lavender ground)
	Ground = Color3.fromRGB(212, 208, 222),          -- Pale gray-lavender lunar regolith
	GroundClean = Color3.fromRGB(245, 244, 252),     -- Smooth polished ground revealed after cleaning
	PebbleDark = Color3.fromRGB(130, 128, 140),       -- Small gray regolith rocks
	PebbleLight = Color3.fromRGB(175, 172, 185),      -- Fine surface dust pebbles
	RoadYellow = Color3.fromRGB(250, 205, 50),        -- Yellow painted guidance seam lines

	-- Sci-Fi Lunar Outpost Architecture (Clean White, Teal & Orange accents)
	StationWhite = Color3.fromRGB(245, 247, 252),     -- Clean white modular booth & base panels
	StationDark = Color3.fromRGB(55, 60, 72),         -- Foundation trims & bases
	StationTeal = Color3.fromRGB(36, 170, 190),       -- Teal trim & kiosk highlights
	StationPurple = Color3.fromRGB(180, 100, 240),     -- Purple-pink screen & trim for Pets
	AccentOrange = Color3.fromRGB(255, 115, 20),      -- Orange glowing sell pad & warning stripes
	AccentTeal = Color3.fromRGB(45, 215, 240),        -- Glowing digital screens & lights
	MetalPipes = Color3.fromRGB(140, 145, 155),       -- Utility conduits & poles
	SolarBlue = Color3.fromRGB(25, 45, 80),           -- Solar cells
	AirlockDoor = Color3.fromRGB(75, 80, 95),         -- Reinforced airlock door panels

	-- Character & Space Suits
	SuitWhite = Color3.fromRGB(245, 245, 250),
	SuitRed = Color3.fromRGB(225, 45, 45),            -- Stripe bands on arms/legs
	SuitBackpack = Color3.fromRGB(160, 165, 175),
	SuitVisor = Color3.fromRGB(22, 25, 32),           -- Glossy dark helmet visor

	-- Vehicles & Sweeper Bots
	CartBody = Color3.fromRGB(245, 243, 238),        -- Off-white / cream body
	CartTeal = Color3.fromRGB(38, 70, 82),            -- Dark teal chassis skirt
	CartOrange = Color3.fromRGB(245, 115, 20),        -- Racing & warning stripes
	BrushOrange = Color3.fromRGB(255, 130, 15),       -- Heavy-duty sweeping bristle discs
	BeaconAmber = Color3.fromRGB(255, 170, 0),        -- Flashing amber warning beacon
	TireRubber = Color3.fromRGB(30, 32, 36),          -- Rugged rover wheel rubber

	-- Pet Rarity Tiers
	Rarity = {
		Common = Color3.fromRGB(149, 165, 166),
		Rare = Color3.fromRGB(52, 152, 219),
		Epic = Color3.fromRGB(155, 89, 182),
		Legendary = Color3.fromRGB(241, 196, 15),
		Mythic = Color3.fromRGB(231, 76, 60),
	},
}
