--!strict
local Layout = require(script.Parent.Layout)

return {
	PlanetId = "DustyMoonlet",
	Origin = Layout.Origin,
	GroundThickness = 4,

	-- Offsets and sizes sourced from Layout (Single Source of Truth)
	SpawnOffset = Vector3.new(Layout.Base.Center.X, 0, Layout.Base.Center.Y),
	SpawnSize = Layout.Base.Size,
	SellOffset = Vector3.new(Layout.Sell.Center.X, 0, Layout.Sell.Center.Y),
	SellSize = Layout.Sell.Size,
	NodeSize = Layout.DustZones.A.CellSize,

	RespawnPollSeconds = 0.5,
	SellCooldown = 0.5,
	PromptHoldSeconds = 0.25,
	PromptKey = Enum.KeyCode.E,
	SpawnWaitSeconds = 10,
	SpawnLift = 4,
	RespawnTransparency = 1,
	SpawnColor = Color3.fromRGB(125, 190, 235),
	SellColor = Color3.fromRGB(105, 215, 155),

	-- Billboard & Prompt configs
	LabelSize = Vector2.new(240, 60),
	LabelOffset = Layout.Sell.StudsOffset,
	LabelMaxDistance = 40,
	LabelTextSize = 16,
}
