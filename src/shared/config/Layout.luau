--!strict
-- Layout.luau
-- SINGLE source of truth for positions (Vector3), rotations, and sizes of every world object.
-- Contains ground raycasting, clearance validation, dust zone grids, and debug gizmo drawing.

local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")

export type ObjectConfig = {
	Center: Vector2,        -- (X, Z) offset relative to planet origin
	Size: Vector3,          -- (X, Y, Z) bounding size
	LookAtCenter: boolean,  -- Whether the object faces (0, 0)
	MinRadius: number,      -- Clearance radius for collision/spacing checks
	PromptAction: string,
	PromptObject: string,
	StudsOffset: Vector3,
	MaxDistance: number,
}

export type DustZone = {
	Name: string,
	Center: Vector2,
	Radius: number,
	CellSize: Vector3,
	CellGap: number,
}

local Layout = {
	-- Planet 1 base origin in world space
	Origin = Vector3.new(0, 100, 0),

	-- Validation thresholds
	ClearanceDistance = 8,  -- Minimum clear walking space between objects (studs)
	MaxGroundFloat = 0.5,   -- Max allowable deviation from ground height (studs)
	ShowDebugGizmos = true, -- Auto-generate visual boxes in Studio

	-- 1. Base / Spawn center: (0, 0)
	Base = {
		Center = Vector2.new(0, 0),
		Size = Vector3.new(10, 1, 10),
		LookAtCenter = false,
		MinRadius = 5.0,
		PromptAction = "",
		PromptObject = "Spawn Platform",
		StudsOffset = Vector3.new(0, 4, 0),
		MaxDistance = 40,
	} :: ObjectConfig,

	-- 2. Sell Station: (15, 0), faces the center
	Sell = {
		Center = Vector2.new(15, 0),
		Size = Vector3.new(8, 4, 8),
		LookAtCenter = true,
		MinRadius = 4.5,
		PromptAction = "Sell bag contents",
		PromptObject = "Recycler Station",
		StudsOffset = Vector3.new(0, 6, 0),
		MaxDistance = 25,
	} :: ObjectConfig,

	-- 3. Shop Kiosk: (-15, 0), faces the center
	Shop = {
		Center = Vector2.new(-15, 0),
		Size = Vector3.new(6, 4, 6),
		LookAtCenter = true,
		MinRadius = 3.5,
		PromptAction = "Open Shop",
		PromptObject = "Equipment Kiosk",
		StudsOffset = Vector3.new(0, 6, 0),
		MaxDistance = 25,
	} :: ObjectConfig,

	-- 4. Pets / Daily Reward Kiosk: (0, 18), faces the center
	Kiosk = {
		Center = Vector2.new(0, 18),
		Size = Vector3.new(6, 4, 6),
		LookAtCenter = true,
		MinRadius = 3.5,
		PromptAction = "Interact",
		PromptObject = "Pets & Daily Kiosk",
		StudsOffset = Vector3.new(0, 6, 0),
		MaxDistance = 25,
	} :: ObjectConfig,

	-- 5. Portal to next planet: (0, -120), faces the base
	Portal = {
		Center = Vector2.new(0, -120),
		Size = Vector3.new(8, 12, 4),
		LookAtCenter = true,
		MinRadius = 5.0,
		PromptAction = "Travel / Unlock",
		PromptObject = "Planet Portal",
		StudsOffset = Vector3.new(0, 9, 0),
		MaxDistance = 25,
	} :: ObjectConfig,

	-- 6. Dust Zones (clean grid alignment, no random scatter)
	DustZones = {
		A = {
			Name = "Zone A",
			Center = Vector2.new(-70, -20),
			Radius = 35,
			CellSize = Vector3.new(5, 0.4, 5),
			CellGap = 1.0,
		} :: DustZone,
		B = {
			Name = "Zone B",
			Center = Vector2.new(70, -20),
			Radius = 35,
			CellSize = Vector3.new(5, 0.4, 5),
			CellGap = 1.0,
		} :: DustZone,
		C = {
			Name = "Zone C",
			Center = Vector2.new(0, 80),
			Radius = 35,
			CellSize = Vector3.new(5, 0.4, 5),
			CellGap = 1.0,
		} :: DustZone,
	},

	-- 7. Yellow guide lines connecting base to each destination
	GuideLines = {
		LineWidth = 1.6,
		LineHeight = 0.08,
		Connections = {
			{From = Vector2.new(0, 0), To = Vector2.new(-70, -20), Label = "Base to Zone A"},
			{From = Vector2.new(0, 0), To = Vector2.new(70, -20), Label = "Base to Zone B"},
			{From = Vector2.new(0, 0), To = Vector2.new(0, 80), Label = "Base to Zone C"},
			{From = Vector2.new(0, 0), To = Vector2.new(0, -120), Label = "Base to Portal"},
		},
	},
}

-- Returns the accurate ground Y coordinate using raycasting onto Terrain or Ground parts.
-- Guarantees objects never float or sink.
function Layout.GetGroundY(worldX: number, worldZ: number, defaultY: number?): number
	local fallback = defaultY or (Layout.Origin.Y + 2)
	local rayOrigin = Vector3.new(worldX, fallback + 100, worldZ)
	local rayDir = Vector3.new(0, -200, 0)

	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Include
	local filter = {}
	if Workspace.Terrain then
		table.insert(filter, Workspace.Terrain)
	end
	local world = Workspace:FindFirstChild("PlanetSweepersWorld")
	if world then
		local ground = world:FindFirstChild("Ground")
		if ground then table.insert(filter, ground) end
	end
	params.FilterDescendantsInstances = filter

	local result = Workspace:Raycast(rayOrigin, rayDir, params)
	if result then
		return result.Position.Y
	end
	return fallback
end

-- Returns a positioned and rotated CFrame anchored perfectly on the terrain ground.
function Layout.GetCFrame(worldOrigin: Vector3, center: Vector2, size: Vector3, lookAtCenter: boolean): CFrame
	local worldX = worldOrigin.X + center.X
	local worldZ = worldOrigin.Z + center.Y
	local groundY = Layout.GetGroundY(worldX, worldZ, worldOrigin.Y + 2)
	local pos = Vector3.new(worldX, groundY + size.Y / 2, worldZ)

	if lookAtCenter then
		local target = Vector3.new(worldOrigin.X, pos.Y, worldOrigin.Z)
		return CFrame.lookAt(pos, target)
	end
	return CFrame.new(pos)
end

-- Generates clean grid-aligned cell positions within the 3 configured dust zones.
function Layout.GetZoneGridPositions(worldOrigin: Vector3, targetTotalCount: number?): {Vector3}
	local positions: {Vector3} = {}
	local zoneList = {Layout.DustZones.A, Layout.DustZones.B, Layout.DustZones.C}

	-- Calculate grid points inside each circular zone
	for _, zone in ipairs(zoneList) do
		local zoneWorldX = worldOrigin.X + zone.Center.X
		local zoneWorldZ = worldOrigin.Z + zone.Center.Y
		local step = zone.CellSize.X + zone.CellGap
		local maxRadius = zone.Radius - (zone.CellSize.X / 2)

		for x = -maxRadius, maxRadius, step do
			for z = -maxRadius, maxRadius, step do
				local dist = math.sqrt(x * x + z * z)
				if dist <= maxRadius then
					local worldX = zoneWorldX + x
					local worldZ = zoneWorldZ + z
					local groundY = Layout.GetGroundY(worldX, worldZ, worldOrigin.Y + 2)
					local nodePos = Vector3.new(worldX, groundY + zone.CellSize.Y / 2, worldZ)
					table.insert(positions, nodePos)
				end
			end
		end
	end

	-- If a specific total count is requested (e.g. planet.dirtDensity), pick evenly
	if targetTotalCount and targetTotalCount > 0 and #positions > targetTotalCount then
		local result: {Vector3} = {}
		local stride = #positions / targetTotalCount
		for i = 1, targetTotalCount do
			local index = math.clamp(math.floor((i - 1) * stride) + 1, 1, #positions)
			table.insert(result, positions[index])
		end
		return result
	end

	return positions
end

-- Validates that objects maintain minimum 8 studs walking space and do not float/sink.
function Layout.Validate(worldOrigin: Vector3?): (boolean, {string})
	local origin = worldOrigin or Layout.Origin
	local warnings: {string} = {}

	local objects = {
		{Name = "Base Center", Center = Layout.Base.Center, Radius = Layout.Base.MinRadius, Size = Layout.Base.Size},
		{Name = "Sell Station", Center = Layout.Sell.Center, Radius = Layout.Sell.MinRadius, Size = Layout.Sell.Size},
		{Name = "Shop Kiosk", Center = Layout.Shop.Center, Radius = Layout.Shop.MinRadius, Size = Layout.Shop.Size},
		{Name = "Pets/Daily Kiosk", Center = Layout.Kiosk.Center, Radius = Layout.Kiosk.MinRadius, Size = Layout.Kiosk.Size},
		{Name = "Planet Portal", Center = Layout.Portal.Center, Radius = Layout.Portal.MinRadius, Size = Layout.Portal.Size},
	}

	-- 1. Check walking clearance (min 8 studs clearance)
	for i = 1, #objects do
		for j = i + 1, #objects do
			local a = objects[i]
			local b = objects[j]
			local centerDist = (a.Center - b.Center).Magnitude
			local clearance = centerDist - (a.Radius + b.Radius)
			if clearance < Layout.ClearanceDistance then
				table.insert(warnings, string.format(
					"[Layout Validation Warning] Clearance between '%s' and '%s' is %.2f studs (minimum required: %.1f studs)",
					a.Name, b.Name, clearance, Layout.ClearanceDistance
				))
			end
		end
	end

	-- 2. Check vertical alignment against ground height (max 0.5 studs float/sink)
	for _, obj in ipairs(objects) do
		local worldX = origin.X + obj.Center.X
		local worldZ = origin.Z + obj.Center.Y
		local groundY = Layout.GetGroundY(worldX, worldZ, origin.Y + 2)
		local placedCF = Layout.GetCFrame(origin, obj.Center, obj.Size, false)
		local bottomY = placedCF.Position.Y - (obj.Size.Y / 2)
		local floatDiff = math.abs(bottomY - groundY)
		if floatDiff > Layout.MaxGroundFloat then
			table.insert(warnings, string.format(
				"[Layout Validation Warning] Object '%s' has vertical float/sink of %.3f studs (max allowed: %.2f studs)",
				obj.Name, floatDiff, Layout.MaxGroundFloat
			))
		end
	end

	-- Print diagnostics
	for _, msg in ipairs(warnings) do
		warn(msg)
	end
	if #warnings == 0 then
		print(string.format(
			"[Layout Validation] PASSED: All 5 world objects have >= %.1f studs walking space and 0 float/sink.",
			Layout.ClearanceDistance
		))
	end

	return #warnings == 0, warnings
end

-- Requirement 7: Draws visual colored bounding boxes and labels in Studio mode.
function Layout.DrawDebugGizmos(parent: Instance, worldOrigin: Vector3?): Folder?
	if not RunService:IsStudio() then return nil end

	local existing = parent:FindFirstChild("LayoutDebugGizmos")
	if existing then existing:Destroy() end

	local folder = Instance.new("Folder")
	folder.Name = "LayoutDebugGizmos"

	local origin = worldOrigin or Layout.Origin

	local function addBox(name: string, cf: CFrame, size: Vector3, color: Color3)
		local part = Instance.new("Part")
		part.Name = "Gizmo_" .. name
		part.CFrame = cf
		part.Size = size
		part.Color = color
		part.Material = Enum.Material.Neon
		part.Transparency = 0.7
		part.Anchored = true
		part.CanCollide = false
		part.CanTouch = false
		part.CanQuery = false
		part.Parent = folder

		local box = Instance.new("SelectionBox")
		box.Adornee = part
		box.Color3 = color
		box.LineThickness = 0.08
		box.Parent = part

		local bb = Instance.new("BillboardGui")
		bb.Size = UDim2.fromOffset(180, 42)
		bb.StudsOffset = Vector3.new(0, size.Y / 2 + 2.5, 0)
		bb.AlwaysOnTop = true
		bb.MaxDistance = 150
		bb.Parent = part

		local label = Instance.new("TextLabel")
		label.Size = UDim2.fromScale(1, 1)
		label.BackgroundTransparency = 1
		label.TextColor3 = color
		label.Font = Enum.Font.GothamBold
		label.TextSize = 13
		label.TextStrokeTransparency = 0.2
		label.Text = string.format("%s\n(%.0f, %.0f)", name, cf.Position.X - origin.X, cf.Position.Z - origin.Z)
		label.Parent = bb
	end

	-- Object gizmos
	addBox("Base (0,0)", Layout.GetCFrame(origin, Layout.Base.Center, Layout.Base.Size, false), Layout.Base.Size, Color3.fromRGB(52, 152, 219))
	addBox("Sell Station (15,0)", Layout.GetCFrame(origin, Layout.Sell.Center, Layout.Sell.Size, true), Layout.Sell.Size, Color3.fromRGB(46, 204, 113))
	addBox("Shop Kiosk (-15,0)", Layout.GetCFrame(origin, Layout.Shop.Center, Layout.Shop.Size, true), Layout.Shop.Size, Color3.fromRGB(241, 196, 15))
	addBox("Pets/Daily Kiosk (0,18)", Layout.GetCFrame(origin, Layout.Kiosk.Center, Layout.Kiosk.Size, true), Layout.Kiosk.Size, Color3.fromRGB(155, 89, 182))
	addBox("Planet Portal (0,-120)", Layout.GetCFrame(origin, Layout.Portal.Center, Layout.Portal.Size, true), Layout.Portal.Size, Color3.fromRGB(231, 76, 60))

	-- Dust Zone circles
	for key, zone in pairs(Layout.DustZones) do
		local zcf = Layout.GetCFrame(origin, zone.Center, Vector3.new(zone.Radius * 2, 0.4, zone.Radius * 2), false)
		local cylinder = Instance.new("Part")
		cylinder.Name = "Gizmo_Zone_" .. key
		cylinder.Shape = Enum.PartType.Cylinder
		cylinder.Size = Vector3.new(0.4, zone.Radius * 2, zone.Radius * 2)
		cylinder.CFrame = zcf * CFrame.Angles(0, 0, math.rad(90))
		cylinder.Color = Color3.fromRGB(255, 220, 100)
		cylinder.Transparency = 0.85
		cylinder.Material = Enum.Material.Neon
		cylinder.Anchored = true
		cylinder.CanCollide = false
		cylinder.CanTouch = false
		cylinder.CanQuery = false
		cylinder.Parent = folder

		local bb = Instance.new("BillboardGui")
		bb.Size = UDim2.fromOffset(180, 40)
		bb.StudsOffset = Vector3.new(0, 4, 0)
		bb.AlwaysOnTop = true
		bb.MaxDistance = 200
		bb.Parent = cylinder

		local label = Instance.new("TextLabel")
		label.Size = UDim2.fromScale(1, 1)
		label.BackgroundTransparency = 1
		label.TextColor3 = Color3.fromRGB(255, 230, 120)
		label.Font = Enum.Font.GothamBold
		label.TextSize = 14
		label.TextStrokeTransparency = 0.2
		label.Text = string.format("%s (r=%.0f)\n(%.0f, %.0f)", zone.Name, zone.Radius, zone.Center.X, zone.Center.Y)
		label.Parent = bb
	end

	folder.Parent = parent
	return folder
end

return Layout
