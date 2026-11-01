--!strict
-- DirtVisual.luau
-- ALL visual tuning for dust cells and pebbles. No gameplay values here.
-- Server never reads this module; client reads it for effects only.

return {
	-- Dust overlay tile (thin layer on top of the ground per cell).
	OverlayThickness = 0.15,
	OverlayLift = 0.12, -- sits above the node part surface
	DustyTransparency = 0.25, -- dusty cell overlay opacity
	CleanTransparency = 1, -- fully revealed smooth ground when clean
	FadeTime = 0.45,

	-- Pebble cluster per cell (client-side decoration only).
	MinPebbles = 3,
	MaxPebbles = 7,
	PebbleMinSize = 0.25,
	PebbleMaxSize = 0.7,
	PebbleFlyTime = 0.5, -- arc toward player on clean
	PebbleFlyHeight = 3,

	-- Footprint / crater marks (flattened dark discs scattered in dusty cells).
	MarkChance = 0.35, -- chance a cell gets a mark
	MarkSize = 1.6,

	-- Performance caps (per planet area).
	MaxPebblesPerPlanet = 400,
	CullDistance = 120, -- hide pebbles beyond this from camera
	CullCheckSeconds = 1,
	PebblePoolSize = 60, -- reused flying pebbles, no create/destroy spam

	-- Respawn: dusty fade-in back to dusty look.
	RespawnFadeTime = 1.2,
}
