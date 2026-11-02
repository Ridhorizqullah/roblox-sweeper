--!strict
-- OutpostBuilder.luau
-- Procedurally constructs lunar outpost buildings, stations, and kiosks
-- compliant with AGENTS.md art pass rules and part budgets (all <= 40 parts).

local RS = game:GetService("ReplicatedStorage")
local Palette = require(RS.Shared.config.Palette)

local Builder = {}

local function createPart(
	name: string,
	parent: Instance,
	size: Vector3,
	cf: CFrame,
	color: Color3,
	shape: Enum.PartType?,
	material: Enum.Material?
): Part
	local part = Instance.new("Part")
	part.Name = name
	part.Shape = shape or Enum.PartType.Block
	part.Size = size
	part.CFrame = cf
	part.Color = color
	part.Material = material or Enum.Material.SmoothPlastic
	part.Anchored = true
	part.CanCollide = false
	part.CanTouch = false
	part.CanQuery = false
	part.CastShadow = true
	part.CollisionGroup = "Decor"
	part.Parent = parent
	return part
end

-- =========================================================================
-- STATIONS (Requirement 6: Under 40 parts each, 8-12 studs tall max)
-- =========================================================================

-- 1. Sell Station: White base, teal trim, orange glowing pad, floating "SELL" sign
function Builder.BuildSellStation(parent: Instance, cf: CFrame): Model
	local model = Instance.new("Model")
	model.Name = "SellStation"

	-- Main interactive Root Part (invisible or matches bounding box)
	local root = Instance.new("Part")
	root.Name = "StationRoot"
	root.Size = Vector3.new(10, 8, 10)
	root.CFrame = cf
	root.Transparency = 1
	root.Anchored = true
	root.CanCollide = false
	root.CanTouch = true
	root.CanQuery = true
	root.Parent = model
	model.PrimaryPart = root

	-- Foundation: Clean White Base
	createPart("BaseWhite", model, Vector3.new(10, 1.2, 10), cf * CFrame.new(0, -3.4, 0), Palette.StationWhite)

	-- Teal Trim Borders around the base
	createPart("TrimL", model, Vector3.new(0.6, 1.3, 10.2), cf * CFrame.new(-4.8, -3.35, 0), Palette.StationTeal)
	createPart("TrimR", model, Vector3.new(0.6, 1.3, 10.2), cf * CFrame.new(4.8, -3.35, 0), Palette.StationTeal)
	createPart("TrimF", model, Vector3.new(9.6, 1.3, 0.6), cf * CFrame.new(0, -3.35, 4.8), Palette.StationTeal)
	createPart("TrimB", model, Vector3.new(9.6, 1.3, 0.6), cf * CFrame.new(0, -3.35, -4.8), Palette.StationTeal)

	-- Center: Orange Glowing Recycling Pad
	local pad = createPart("GlowingPad", model, Vector3.new(6.5, 0.4, 6.5), cf * CFrame.new(0, -2.7, 0), Palette.AccentOrange, nil, Enum.Material.Neon)

	-- Hopper Chute back wall
	createPart("HopperWall", model, Vector3.new(8, 4.5, 1.5), cf * CFrame.new(0, -0.6, -3.8), Palette.StationWhite)
	createPart("HopperStripe", model, Vector3.new(8.2, 0.8, 1.6), cf * CFrame.new(0, 1.2, -3.8), Palette.StationTeal)

	-- Four Corner Lighting Pylons
	for _, xSign in {-1, 1} do
		for _, zSign in {-1, 1} do
			local pylonCF = cf * CFrame.new(xSign * 4.4, -1.5, zSign * 4.4)
			createPart("Pylon", model, Vector3.new(0.8, 4.5, 0.8), pylonCF, Palette.StationDark)
			createPart("PylonBeacon", model, Vector3.new(0.9, 0.6, 0.9), pylonCF * CFrame.new(0, 2.4, 0), Palette.BeaconAmber, Enum.PartType.Ball, Enum.Material.Neon)
		end
	end

	model.Parent = parent
	return model
end

-- 2. Shop Kiosk: White booth with teal screen, floating "SHOP" sign
function Builder.BuildShopKiosk(parent: Instance, cf: CFrame): Model
	local model = Instance.new("Model")
	model.Name = "ShopStation"

	local root = Instance.new("Part")
	root.Name = "ShopRoot"
	root.Size = Vector3.new(8, 9, 7)
	root.CFrame = cf
	root.Transparency = 1
	root.Anchored = true
	root.CanCollide = false
	root.CanTouch = true
	root.CanQuery = true
	root.Parent = model
	model.PrimaryPart = root

	-- Booth Body: Clean White
	createPart("BasePlinth", model, Vector3.new(8, 0.8, 7), cf * CFrame.new(0, -4.1, 0), Palette.StationDark)
	createPart("BackWall", model, Vector3.new(8, 7.5, 1.2), cf * CFrame.new(0, 0, -2.6), Palette.StationWhite)
	createPart("SideL", model, Vector3.new(1.2, 7.5, 5.5), cf * CFrame.new(-3.4, 0, -0.4), Palette.StationWhite)
	createPart("SideR", model, Vector3.new(1.2, 7.5, 5.5), cf * CFrame.new(3.4, 0, -0.4), Palette.StationWhite)

	-- Counter Desk & Trim
	createPart("CounterDesk", model, Vector3.new(6, 2.8, 1.6), cf * CFrame.new(0, -2.4, 1.6), Palette.StationWhite)
	createPart("DeskTop", model, Vector3.new(6.4, 0.4, 2.0), cf * CFrame.new(0, -0.8, 1.6), Palette.StationTeal)

	-- Overhead Canopy
	createPart("Canopy", model, Vector3.new(8.4, 0.8, 7.4), cf * CFrame.new(0, 3.8, 0.2), Palette.StationWhite)
	createPart("CanopyTrim", model, Vector3.new(8.6, 0.4, 7.6), cf * CFrame.new(0, 3.6, 0.2), Palette.StationTeal)

	-- Glowing Teal Digital Screen
	createPart("MonitorFrame", model, Vector3.new(5, 3.2, 0.4), cf * CFrame.new(0, 0.8, -1.8), Palette.StationDark)
	createPart("TealScreen", model, Vector3.new(4.6, 2.8, 0.2), cf * CFrame.new(0, 0.8, -1.5), Palette.AccentTeal, nil, Enum.Material.Neon)

	model.Parent = parent
	return model
end

-- 3. Pets Kiosk: White booth with purple-pink screen, floating "PETS" sign
function Builder.BuildPetsKiosk(parent: Instance, cf: CFrame): Model
	local model = Instance.new("Model")
	model.Name = "PetsDailyKiosk"

	local root = Instance.new("Part")
	root.Name = "KioskRoot"
	root.Size = Vector3.new(8, 9, 7)
	root.CFrame = cf
	root.Transparency = 1
	root.Anchored = true
	root.CanCollide = false
	root.CanTouch = true
	root.CanQuery = true
	root.Parent = model
	model.PrimaryPart = root

	-- Booth Body: Clean White
	createPart("BasePlinth", model, Vector3.new(8, 0.8, 7), cf * CFrame.new(0, -4.1, 0), Palette.StationDark)
	createPart("BackWall", model, Vector3.new(8, 7.5, 1.2), cf * CFrame.new(0, 0, -2.6), Palette.StationWhite)
	createPart("SideL", model, Vector3.new(1.2, 7.5, 5.5), cf * CFrame.new(-3.4, 0, -0.4), Palette.StationWhite)
	createPart("SideR", model, Vector3.new(1.2, 7.5, 5.5), cf * CFrame.new(3.4, 0, -0.4), Palette.StationWhite)

	-- Counter Desk & Purple Trim
	createPart("CounterDesk", model, Vector3.new(6, 2.8, 1.6), cf * CFrame.new(0, -2.4, 1.6), Palette.StationWhite)
	createPart("DeskTop", model, Vector3.new(6.4, 0.4, 2.0), cf * CFrame.new(0, -0.8, 1.6), Palette.StationPurple)

	-- Overhead Canopy with cute arch
	createPart("Canopy", model, Vector3.new(8.4, 0.8, 7.4), cf * CFrame.new(0, 3.8, 0.2), Palette.StationWhite)
	createPart("CanopyTrim", model, Vector3.new(8.6, 0.4, 7.6), cf * CFrame.new(0, 3.6, 0.2), Palette.StationPurple)

	-- Glowing Purple-Pink Digital Screen
	createPart("MonitorFrame", model, Vector3.new(5, 3.2, 0.4), cf * CFrame.new(0, 0.8, -1.8), Palette.StationDark)
	createPart("PurpleScreen", model, Vector3.new(4.6, 2.8, 0.2), cf * CFrame.new(0, 0.8, -1.5), Palette.StationPurple, nil, Enum.Material.Neon)

	-- Cute Antenna Spheres
	createPart("AntennaL", model, Vector3.new(0.6, 1.8, 0.6), cf * CFrame.new(-2.5, 4.8, 0.2), Palette.MetalPipes, Enum.PartType.Cylinder)
	createPart("AntennaR", model, Vector3.new(0.6, 1.8, 0.6), cf * CFrame.new(2.5, 4.8, 0.2), Palette.MetalPipes, Enum.PartType.Cylinder)
	createPart("AntennaSphereL", model, Vector3.new(1.2, 1.2, 1.2), cf * CFrame.new(-2.5, 5.8, 0.2), Palette.StationPurple, Enum.PartType.Ball, Enum.Material.Neon)
	createPart("AntennaSphereR", model, Vector3.new(1.2, 1.2, 1.2), cf * CFrame.new(2.5, 5.8, 0.2), Palette.StationPurple, Enum.PartType.Ball, Enum.Material.Neon)

	model.Parent = parent
	return model
end

-- =========================================================================
-- OUTPOST DECOR & BACKGROUND
-- =========================================================================

-- Builds small decorative gray lunar rocks under 6 studs (Requirement 5)
function Builder.BuildLunarRocks(parent: Instance, center: Vector3): Model
	local model = Instance.new("Model")
	model.Name = "DecorativeRocks"

	local rockOffsets = {
		Vector3.new(-46, 0, -22),
		Vector3.new(-50, 0, -26),
		Vector3.new(-43, 0, -30),
		Vector3.new(-53, 0, -18),
	}

	for i, offset in ipairs(rockOffsets) do
		local size = Vector3.new(3.8 - (i * 0.4), 2.2 - (i * 0.2), 3.4 - (i * 0.3)) -- All < 6 studs
		local cf = CFrame.new(center + offset + Vector3.new(0, size.Y / 2, 0)) * CFrame.Angles(0.2 * i, 0.5 * i, 0)
		createPart("Rock_" .. i, model, size, cf, Palette.PebbleDark, Enum.PartType.Block, Enum.Material.Slate)
	end

	model.Parent = parent
	return model
end

-- Solar Panel Array (background decor, far out)
function Builder.BuildSolarArray(parent: Instance, center: Vector3): Model
	local model = Instance.new("Model")
	model.Name = "SolarPanelArray"

	local basePos = center + Vector3.new(58, 0, -32)
	local tilt = CFrame.Angles(-math.rad(28), math.rad(15), 0)

	createPart("SolarPlatform", model, Vector3.new(14, 0.8, 14), CFrame.new(basePos + Vector3.new(0, 0.4, 0)), Palette.StationDark)
	createPart("Pylon", model, Vector3.new(2, 5.5, 2), CFrame.new(basePos + Vector3.new(0, 3.5, 0)), Palette.StationWhite)

	local panelCenter = basePos + Vector3.new(0, 6.8, 0)
	local frame = createPart("PanelFrame", model, Vector3.new(14, 0.6, 9), CFrame.new(panelCenter) * tilt, Palette.StationDark)
	createPart("SolarCells", model, Vector3.new(13.2, 0.2, 8.2), frame.CFrame * CFrame.new(0, 0.35, 0), Palette.SolarBlue)

	model.Parent = parent
	return model
end

-- Main Central Modular Habitat (background decor, far out)
function Builder.BuildCentralHabitat(parent: Instance, center: Vector3): Model
	local model = Instance.new("Model")
	model.Name = "CentralHabitatStation"

	local hubPos = center + Vector3.new(0, 0, -65)

	createPart("Foundation", model, Vector3.new(34, 1.5, 28), CFrame.new(hubPos + Vector3.new(0, 0.75, 0)), Palette.StationDark)
	createPart("MainBodyCenter", model, Vector3.new(30, 14, 24), CFrame.new(hubPos + Vector3.new(0, 8.5, 0)), Palette.StationWhite)
	createPart("StripeTop", model, Vector3.new(30.4, 1.0, 24.4), CFrame.new(hubPos + Vector3.new(0, 13.5, 0)), Palette.AccentOrange)

	for i = -2, 2 do
		if i ~= 0 then
			createPart("Window_" .. i, model, Vector3.new(2, 6, 0.4), CFrame.new(hubPos + Vector3.new(i * 6, 8.5, 12.2)), Palette.AccentTeal, nil, Enum.Material.Neon)
		end
	end

	createPart("AirlockDoor", model, Vector3.new(4.5, 6, 0.8), CFrame.new(hubPos + Vector3.new(0, 4, 12.5)), Palette.AirlockDoor or Color3.fromRGB(75, 80, 95))

	model.Parent = parent
	return model
end

function Builder.BuildOutpost(parent: Instance, center: Vector3): ()
	local container = Instance.new("Folder")
	container.Name = "OutpostStructures"
	container.Parent = parent

	Builder.BuildCentralHabitat(container, center)
	Builder.BuildSolarArray(container, center)
	Builder.BuildLunarRocks(container, center)
end

return Builder
