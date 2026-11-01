--!strict
-- DirtCellBuilder.luau
-- Builds dust overlay tile + pebble cluster for ONE dirt cell.
-- Server owns gameplay; this module builds visuals only (called on client).
-- Pebbles are decorative: anchored, non-colliding, no query/touch.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = Shared:WaitForChild("config")
local Palette = require(Config:WaitForChild("Palette"))
local Assets = require(Config:WaitForChild("Assets"))
local Visual = require(Config:WaitForChild("DirtVisual"))

local Builder = {}

-- Returns overlay tile (the dusty layer that fades away when cleaned).
function Builder.BuildOverlay(cellId: string, size: Vector3, cframe: CFrame): Part
	local tile = Instance.new("Part")
	tile.Name = "DustOverlay_" .. cellId
	tile.Size = Vector3.new(size.X, Visual.OverlayThickness, size.Z)
	tile.CFrame = cframe * CFrame.new(0, size.Y / 2 + Visual.OverlayLift, 0)
	tile.Color = Palette.Ground
	tile.Transparency = Visual.DustyTransparency
	tile.Material = Enum.Material.Sand
	tile.Anchored = true
	tile.CanCollide = false
	tile.CanTouch = false
	tile.CanQuery = false
	tile.CastShadow = false
	tile.CollisionGroup = "Decor"
	return tile
end

-- Returns pebble cluster model (3-8 irregular stones scattered on the cell).
function Builder.BuildPebbles(cellId: string, size: Vector3, cframe: CFrame, seed: number): Model
	local random = Random.new(seed)
	local cluster = Instance.new("Model")
	cluster.Name = "Pebbles_" .. cellId
	local count = random:NextInteger(Visual.MinPebbles, Visual.MaxPebbles)
	for i = 1, count do
		local entry = if random:NextNumber() < 0.5 then Assets.PebbleLight else Assets.PebbleDark
		local s = random:NextNumber(Visual.PebbleMinSize, Visual.PebbleMaxSize)
		local pebble = Instance.new("Part")
		pebble.Name = "Pebble"
		pebble.Shape = if random:NextNumber() < 0.3 then Enum.PartType.Ball else Enum.PartType.Block
		pebble.Size = Vector3.new(s * random:NextNumber(0.7, 1.4), s * 0.6, s * random:NextNumber(0.7, 1.4))
		local ox = random:NextNumber(-size.X / 2 + s, size.X / 2 - s)
		local oz = random:NextNumber(-size.Z / 2 + s, size.Z / 2 - s)
		pebble.CFrame = cframe
			* CFrame.new(ox, size.Y / 2 + Visual.OverlayLift + s * 0.3, oz)
			* CFrame.Angles(0, random:NextNumber(0, math.pi * 2), 0)
		pebble.Color = entry.Color
		pebble.Material = Enum.Material.Slate
		pebble.Anchored = true
		pebble.CanCollide = false
		pebble.CanTouch = false
		pebble.CanQuery = false
		pebble.CastShadow = false
		pebble.CollisionGroup = "Decor"
		pebble.Parent = cluster
	end
	-- Optional dark footprint/crater mark (flattened disc).
	if random:NextNumber() < Visual.MarkChance then
		local mark = Instance.new("Part")
		mark.Name = "Mark"
		mark.Shape = Enum.PartType.Cylinder
		mark.Size = Vector3.new(Visual.OverlayThickness, Visual.MarkSize, Visual.MarkSize)
		mark.CFrame = cframe
			* CFrame.new(random:NextNumber(-1, 1), size.Y / 2 + Visual.OverlayLift + 0.02, random:NextNumber(-1, 1))
			* CFrame.Angles(0, 0, math.pi / 2)
		mark.Color = Palette.PebbleDark
		mark.Transparency = 0.55
		mark.Material = Enum.Material.SmoothPlastic
		mark.Anchored = true
		mark.CanCollide = false
		mark.CanTouch = false
		mark.CanQuery = false
		mark.CastShadow = false
		mark.CollisionGroup = "Decor"
		mark.Parent = cluster
	end
	return cluster
end

return Builder
