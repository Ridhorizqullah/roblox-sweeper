--!strict
-- OutpostBuilder.luau
-- Procedurally constructs lunar outpost buildings (Central Habitat, Solar Arrays, Tanks, Conduits)
-- exactly reflecting the visual style in REFERENSI ASET (Screenshots 2, 3, 7).

local RS = game:GetService("ReplicatedStorage")
local Palette = require(RS.Shared.config.Palette)
local Assets = require(RS.Shared.config.Assets)

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

-- Builds the central modular habitat station (Screenshots 2 & 7)
function Builder.BuildCentralHabitat(parent: Instance, center: Vector3): Model
	local model = Instance.new("Model")
	model.Name = "CentralHabitatStation"

	local groundY = center.Y
	local hubPos = center + Vector3.new(0, 0, -50)

	-- Base Foundation
	createPart("Foundation", model, Vector3.new(38, 1.5, 32), CFrame.new(hubPos + Vector3.new(0, 0.75, 0)), Palette.StationDark)

	-- Main Body (Rounded/chamfered modular building)
	createPart("MainBodyCenter", model, Vector3.new(34, 16, 26), CFrame.new(hubPos + Vector3.new(0, 9.5, 0)), Palette.StationWhite)
	createPart("MainBodyWingL", model, Vector3.new(10, 14, 20), CFrame.new(hubPos + Vector3.new(-18, 8.5, 0)), Palette.StationWhite)
	createPart("MainBodyWingR", model, Vector3.new(10, 14, 20), CFrame.new(hubPos + Vector3.new(18, 8.5, 0)), Palette.StationWhite)

	-- Signature Orange Accent Warning Stripes (Screenshots 2, 4, 7)
	createPart("StripeTop", model, Vector3.new(34.4, 1.2, 26.4), CFrame.new(hubPos + Vector3.new(0, 15, 0)), Palette.AccentOrange)
	createPart("StripeMid", model, Vector3.new(34.4, 0.8, 26.4), CFrame.new(hubPos + Vector3.new(0, 5, 0)), Palette.AccentOrange)

	-- Vertical Cyan Observation Windows (Screenshots 2 & 7)
	for i = -2, 2 do
		if i ~= 0 then
			createPart("WindowF_" .. i, model, Vector3.new(2.4, 7, 0.4), CFrame.new(hubPos + Vector3.new(i * 6.5, 9.5, 13.2)), Palette.AccentTeal, nil, Enum.Material.Neon)
		end
	end

	-- Airlock Entrance (Center Front)
	createPart("AirlockFrame", model, Vector3.new(7, 8, 2), CFrame.new(hubPos + Vector3.new(0, 5, 13.5)), Palette.StationDark)
	createPart("AirlockDoor", model, Vector3.new(5, 6.5, 0.8), CFrame.new(hubPos + Vector3.new(0, 4.5, 14)), Palette.AirlockDoor)
	createPart("AirlockStripe", model, Vector3.new(5.2, 0.6, 1), CFrame.new(hubPos + Vector3.new(0, 8.2, 13.6)), Palette.AccentOrange)
	createPart("AirlockLight", model, Vector3.new(1.2, 0.4, 0.4), CFrame.new(hubPos + Vector3.new(0, 9.2, 14.2)), Palette.AccentTeal, nil, Enum.Material.Neon)

	-- Roof Comms Antenna & Radar Dish
	createPart("RoofMast", model, Vector3.new(1, 8, 1), CFrame.new(hubPos + Vector3.new(0, 21.5, 0)), Palette.MetalPipes)
	createPart("RoofDish", model, Vector3.new(5, 1, 5), CFrame.new(hubPos + Vector3.new(0, 25.5, 0)) * CFrame.Angles(0.3, 0.4, 0), Palette.StationWhite, Enum.PartType.Cylinder)
	createPart("RoofBeacon", model, Vector3.new(0.8, 0.8, 0.8), CFrame.new(hubPos + Vector3.new(0, 26.5, 0)), Palette.BeaconAmber, Enum.PartType.Ball, Enum.Material.Neon)

	model.Parent = parent
	return model
end

-- Builds angled solar panel arrays on mounts (Screenshots 2 & 3)
function Builder.BuildSolarArray(parent: Instance, center: Vector3): Model
	local model = Instance.new("Model")
	model.Name = "SolarPanelArray"

	local basePos = center + Vector3.new(52, 0, -28)
	local tilt = CFrame.Angles(-math.rad(28), math.rad(15), 0)

	-- Hexagonal Foundation Platform
	createPart("SolarPlatform", model, Vector3.new(16, 0.8, 16), CFrame.new(basePos + Vector3.new(0, 0.4, 0)), Palette.StationDark)
	createPart("PlatformStripe", model, Vector3.new(16.4, 0.2, 16.4), CFrame.new(basePos + Vector3.new(0, 0.8, 0)), Palette.AccentOrange)

	-- Central Mounting Pylon
	createPart("Pylon", model, Vector3.new(2.4, 6, 2.4), CFrame.new(basePos + Vector3.new(0, 3.8, 0)), Palette.StationWhite)
	createPart("StatusLight", model, Vector3.new(0.6, 1.2, 2.5), CFrame.new(basePos + Vector3.new(0, 3.8, 0)), Palette.AccentTeal, nil, Enum.Material.Neon)

	-- Solar Panel Frame & Photovoltaic Grid
	local panelCenter = basePos + Vector3.new(0, 7.5, 0)
	local frame = createPart("PanelFrame", model, Vector3.new(15, 0.6, 10), CFrame.new(panelCenter) * tilt, Palette.StationDark)
	local cells = createPart("SolarCells", model, Vector3.new(14.2, 0.2, 9.2), frame.CFrame * CFrame.new(0, 0.35, 0), Palette.SolarBlue, nil, Enum.Material.SmoothPlastic)

	-- Grid Lines on Solar Array
	createPart("SolarDividerH", model, Vector3.new(14.3, 0.25, 0.3), cells.CFrame, Palette.MetalPipes)
	createPart("SolarDividerV", model, Vector3.new(0.3, 0.25, 9.3), cells.CFrame, Palette.MetalPipes)

	model.Parent = parent
	return model
end

-- Builds the pressurized life-support / storage tank with dial & conduits (Screenshots 2 & 3)
function Builder.BuildStorageTank(parent: Instance, center: Vector3): Model
	local model = Instance.new("Model")
	model.Name = "OutpostStorageTank"

	local tankPos = center + Vector3.new(-50, 0, -28)

	-- Cradle Supports
	createPart("CradleL", model, Vector3.new(3, 4, 8), CFrame.new(tankPos + Vector3.new(-7, 2, 0)), Palette.StationDark)
	createPart("CradleR", model, Vector3.new(3, 4, 8), CFrame.new(tankPos + Vector3.new(7, 2, 0)), Palette.StationDark)

	-- Main Tank Cylinder
	local tankBody = createPart("TankBody", model, Vector3.new(18, 7, 7), CFrame.new(tankPos + Vector3.new(0, 5.5, 0)) * CFrame.Angles(0, 0, math.rad(90)), Palette.StationWhite, Enum.PartType.Cylinder)

	-- End Caps
	createPart("EndCapL", model, Vector3.new(7, 7, 7), CFrame.new(tankPos + Vector3.new(-9, 5.5, 0)), Palette.StationWhite, Enum.PartType.Ball)
	createPart("EndCapR", model, Vector3.new(7, 7, 7), CFrame.new(tankPos + Vector3.new(9, 5.5, 0)), Palette.StationWhite, Enum.PartType.Ball)

	-- Orange Warning Ring Bands
	createPart("RingL", model, Vector3.new(1, 7.3, 7.3), CFrame.new(tankPos + Vector3.new(-4, 5.5, 0)) * CFrame.Angles(0, 0, math.rad(90)), Palette.AccentOrange, Enum.PartType.Cylinder)
	createPart("RingR", model, Vector3.new(1, 7.3, 7.3), CFrame.new(tankPos + Vector3.new(4, 5.5, 0)) * CFrame.Angles(0, 0, math.rad(90)), Palette.AccentOrange, Enum.PartType.Cylinder)

	-- Pressure Gauge Dial (Screenshot 3)
	local dial = createPart("PressureGauge", model, Vector3.new(2.4, 0.4, 2.4), CFrame.new(tankPos + Vector3.new(-7, 7.5, 3.6)) * CFrame.Angles(math.rad(90), 0, 0), Palette.StationWhite, Enum.PartType.Cylinder)
	createPart("GaugeNeedle", model, Vector3.new(0.2, 0.45, 1.2), dial.CFrame * CFrame.new(0, 0.05, 0), Palette.AccentOrange)

	-- Supply Pipe Conduit running toward the Central Habitat
	createPart("PipeSegment1", model, Vector3.new(1.2, 1.2, 22), CFrame.new(tankPos + Vector3.new(0, 1.2, -11)), Palette.MetalPipes, Enum.PartType.Cylinder)

	model.Parent = parent
	return model
end

-- Builds all outpost structures for the starter moonlet
function Builder.BuildOutpost(parent: Instance, center: Vector3): ()
	local container = Instance.new("Folder")
	container.Name = "OutpostStructures"
	container.Parent = parent

	Builder.BuildCentralHabitat(container, center)
	Builder.BuildSolarArray(container, center)
	Builder.BuildStorageTank(container, center)
end

return Builder
