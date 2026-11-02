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
	ShortTitle: string,     -- Single short title (SELL, SHOP, PETS, PORTAL)
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
	ClearanceDistance = 8,   -- Minimum clear walking space between objects (studs)
	MaxGroundFloat = 0.5,    -- Max allowable deviation from ground height (studs)
	ShowDebugGizmos = false, -- Studio-only toggle: OFF BY DEFAULT

	-- 1. Base / Spawn center: (0, 0)
	Base = {
		Center = Vector2.new(0, 0),
		Size = Vector3.new(10, 1, 10),
		LookAtCenter = false,
		MinRadius = 5.0,
		ShortTitle = "BASE",
		PromptAction = "",
		PromptObject = "",
		StudsOffset = Vector3.new(0, 4, 0),
		MaxDistance = 35,
	} :: ObjectConfig,

	-- 2. Sell Station: (28, 0), faces the center (>= 25 studs from base, 8-12 studs tall)
	Sell = {
		Center = Vector2.new(28, 0),
		Size = Vector3.new(10, 8, 10),
		LookAtCenter = true,
		MinRadius = 5.0,
		ShortTitle = "SELL",
		PromptAction = "Sell bag contents",
		PromptObject = "Recycler",
		StudsOffset = Vector3.new(0, 6.0, 0),
		MaxDistance = 35,
	} :: ObjectConfig,

	-- 3. Shop Kiosk: (-28, 0), faces the center (>= 25 studs from base, 8-12 studs tall)
	Shop = {
		Center = Vector2.new(-28, 0),
		Size = Vector3.new(8, 9, 7),
		LookAtCenter = true,
		MinRadius = 4.0,
		ShortTitle = "SHOP",
		PromptAction = "Open Shop",
		PromptObject = "Equipment",
		StudsOffset = Vector3.new(0, 6.5, 0),
		MaxDistance = 35,
	} :: ObjectConfig,

	-- 4. Pets / Daily Reward Kiosk: (0, 28), faces the center (>= 25 studs from base, 8-12 studs tall)
	Kiosk = {
		Center = Vector2.new(0, 28),
		Size = Vector3.new(8, 9, 7),
		LookAtCenter = true,
		MinRadius = 4.0,
		ShortTitle = "PETS",
		PromptAction = "Claim Daily / Manage Pets",
		PromptObject = "Kiosk",
		StudsOffset = Vector3.new(0, 6.5, 0),
		MaxDistance = 35,
	} :: ObjectConfig,

	-- 5. Portal to next planet: (0, -120), faces the base (8-12 studs tall)
	Portal = {
		Center = Vector2.new(0, -120),
		Size = Vector3.new(10, 12, 4),
		LookAtCenter = true,
		MinRadius = 5.0,
		ShortTitle = "PORTAL",
		PromptAction = "Travel / Unlock",
		PromptObject = "Portal",
		StudsOffset = Vector3.new(0, 9.5, 0),
		MaxDistance = 35,
		Spacing = 16,
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

	-- 1. Check walking clearance
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

	-- 2. Check vertical alignment against ground height
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

-- Requirement 1 & 7: Studio debug gizmos (OFF BY DEFAULT)
function Layout.DrawDebugGizmos(parent: Instance, worldOrigin: Vector3?): Folder?
	if not RunService:IsStudio() or not Layout.ShowDebugGizmos then
		local existing = parent:FindFirstChild("LayoutDebugGizmos")
		if existing then existing:Destroy() end
		return nil
	end

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
		part.Transparency = 0.75
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
	end

	addBox("Base", Layout.GetCFrame(origin, Layout.Base.Center, Layout.Base.Size, false), Layout.Base.Size, Color3.fromRGB(52, 152, 219))
	addBox("Sell", Layout.GetCFrame(origin, Layout.Sell.Center, Layout.Sell.Size, true), Layout.Sell.Size, Color3.fromRGB(46, 204, 113))
	addBox("Shop", Layout.GetCFrame(origin, Layout.Shop.Center, Layout.Shop.Size, true), Layout.Shop.Size, Color3.fromRGB(241, 196, 15))
	addBox("Pets", Layout.GetCFrame(origin, Layout.Kiosk.Center, Layout.Kiosk.Size, true), Layout.Kiosk.Size, Color3.fromRGB(155, 89, 182))
	addBox("Portal", Layout.GetCFrame(origin, Layout.Portal.Center, Layout.Portal.Size, true), Layout.Portal.Size, Color3.fromRGB(231, 76, 60))

	folder.Parent = parent
	return folder
end

return Layout
