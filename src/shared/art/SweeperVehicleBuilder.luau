--!strict
-- SweeperVehicleBuilder.luau
-- Procedurally builds the authentic Lunar Sweeper Cart / Bot
-- directly inspired by REFERENSI ASET (Screenshots 4 & 6).

local RS = game:GetService("ReplicatedStorage")
local Palette = require(RS.Shared.config.Palette)

local Builder = {}

local function createSubPart(
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

-- Builds a complete Sweeper Bot model matching the reference screenshots
function Builder.BuildSweeperBot(name: string, parent: Instance, cf: CFrame): Model
	local model = Instance.new("Model")
	model.Name = name

	-- Main Chassis / Lower Skirt (Dark Teal - Screenshot 4 & 6)
	local chassis = createSubPart("Chassis", model, Vector3.new(2.4, 0.8, 3.2), cf * CFrame.new(0, 0.4, 0), Palette.CartTeal)

	-- Upper Cabin / Body (Cream / White - Screenshot 4 & 6)
	local cabin = createSubPart("Cabin", model, Vector3.new(2.2, 1.4, 2.6), cf * CFrame.new(0, 1.4, -0.2), Palette.CartBody)

	-- Side Orange Accent Stripe Panels (Screenshot 4 & 6)
	createSubPart("StripeL", model, Vector3.new(0.1, 0.35, 2.4), cf * CFrame.new(-1.12, 1.5, -0.2), Palette.CartOrange)
	createSubPart("StripeR", model, Vector3.new(0.1, 0.35, 2.4), cf * CFrame.new(1.12, 1.5, -0.2), Palette.CartOrange)

	-- Front Windshield / Dark Visor Section
	createSubPart("Visor", model, Vector3.new(1.8, 0.8, 0.2), cf * CFrame.new(0, 1.5, -1.45), Palette.GlassVisor)

	-- Top Amber Flashing Beacon Light (Screenshot 4)
	local beacon = createSubPart("Beacon", model, Vector3.new(0.5, 0.4, 0.5), cf * CFrame.new(0, 2.3, -0.2), Palette.BeaconAmber, Enum.PartType.Cylinder, Enum.Material.Neon)

	-- 4 Black Rubber Rover Wheels with Orange Hubs
	local wheelZ = {0.9, -0.9}
	for i, z in ipairs(wheelZ) do
		-- Left Wheel
		local wL = createSubPart("WheelL_" .. i, model, Vector3.new(0.4, 0.9, 0.9), cf * CFrame.new(-1.3, 0.45, z) * CFrame.Angles(0, 0, math.rad(90)), Palette.TireRubber, Enum.PartType.Cylinder)
		createSubPart("HubL_" .. i, model, Vector3.new(0.42, 0.4, 0.4), wL.CFrame, Palette.CartOrange, Enum.PartType.Cylinder)

		-- Right Wheel
		local wR = createSubPart("WheelR_" .. i, model, Vector3.new(0.4, 0.9, 0.9), cf * CFrame.new(1.3, 0.45, z) * CFrame.Angles(0, 0, math.rad(90)), Palette.TireRubber, Enum.PartType.Cylinder)
		createSubPart("HubR_" .. i, model, Vector3.new(0.42, 0.4, 0.4), wR.CFrame, Palette.CartOrange, Enum.PartType.Cylinder)
	end

	-- Front Sweeping Mechanism (Screenshots 4 & 6)
	-- Mounting bracket in front
	createSubPart("BrushBracket", model, Vector3.new(2.6, 0.3, 0.6), cf * CFrame.new(0, 0.35, -1.8), Palette.StationDark)

	-- Dual Rotating Orange Sweeping Brush Discs
	local brushL = createSubPart("BrushL", model, Vector3.new(1.2, 0.35, 1.2), cf * CFrame.new(-0.8, 0.2, -2.1), Palette.BrushOrange, Enum.PartType.Cylinder)
	brushL.Material = Enum.Material.Fabric

	local brushR = createSubPart("BrushR", model, Vector3.new(1.2, 0.35, 1.2), cf * CFrame.new(0.8, 0.2, -2.1), Palette.BrushOrange, Enum.PartType.Cylinder)
	brushR.Material = Enum.Material.Fabric

	-- Push Handlebar (Behind - Screenshot 6)
	createSubPart("HandleBarL", model, Vector3.new(0.15, 1.2, 0.15), cf * CFrame.new(-0.8, 1.6, 1.5) * CFrame.Angles(-math.rad(25), 0, 0), Palette.MetalPipes)
	createSubPart("HandleBarR", model, Vector3.new(0.15, 1.2, 0.15), cf * CFrame.new(0.8, 1.6, 1.5) * CFrame.Angles(-math.rad(25), 0, 0), Palette.MetalPipes)
	createSubPart("HandleCross", model, Vector3.new(1.75, 0.18, 0.18), cf * CFrame.new(0, 2.1, 1.8), Palette.StationDark)

	model.PrimaryPart = chassis
	model.Parent = parent
	return model
end

return Builder
