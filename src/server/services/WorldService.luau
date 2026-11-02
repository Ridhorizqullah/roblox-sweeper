--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Config = ReplicatedStorage:WaitForChild("Shared"):WaitForChild("config")
local Layout = require(Config:WaitForChild("Layout"))
local Cleaning = require(Config:WaitForChild("Cleaning"))
local Game = require(Config:WaitForChild("Game"))
local Planets = require(Config:WaitForChild("Planets"))
local Palette = require(Config:WaitForChild("Palette"))
local WorldLook = require(ReplicatedStorage.Shared.art.WorldLookBuilder)
local OutpostBuilder = require(ReplicatedStorage.Shared.art.OutpostBuilder)

local Service = {}
local world: Folder? = nil
local nodes: {BasePart} = {}
local sellStation: BasePart? = nil
local spawnLocation: SpawnLocation? = nil
local WORLD_NAME = "PlanetSweepersWorld"
local spawns: {[string]: SpawnLocation} = {}
local stations: {[string]: BasePart} = {}

local function makePart(name: string, size: Vector3, cf: CFrame, color: Color3, parent: Instance): Part
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.CFrame = cf
	part.Color = color
	part.Anchored = true
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Parent = parent
	return part
end

local function addLabel(part: BasePart, text: string, studsOffset: Vector3?, maxDistance: number?): ()
	local billboard = Instance.new("BillboardGui")
	billboard.Name = "Instructions"
	billboard.Size = UDim2.fromOffset(180, 40)
	billboard.StudsOffset = studsOffset or Vector3.new(0, 5.5, 0)
	billboard.MaxDistance = maxDistance or 35
	billboard.AlwaysOnTop = true
	billboard.Adornee = part

	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Text = text
	label.TextColor3 = Color3.fromRGB(255, 255, 255)
	label.TextStrokeTransparency = 0.15
	label.TextStrokeColor3 = Color3.fromRGB(20, 25, 35)
	label.TextSize = 18
	label.TextWrapped = false
	label.Font = Enum.Font.GothamBlack
	label.Parent = billboard

	billboard.Parent = part
end

-- Builds yellow painted floor guide lines between origins and destinations
local function buildGuideLines(parent: Instance, origin: Vector3)
	local linesFolder = Instance.new("Folder")
	linesFolder.Name = "GuideLines"
	linesFolder.Parent = parent

	local cfg = Layout.GuideLines
	for _, conn in ipairs(cfg.Connections) do
		local fromPos = Vector2.new(origin.X + conn.From.X, origin.Z + conn.From.Y)
		local toPos = Vector2.new(origin.X + conn.To.X, origin.Z + conn.To.Y)

		local fromY = Layout.GetGroundY(fromPos.X, fromPos.Y, origin.Y + 2)
		local toY = Layout.GetGroundY(toPos.X, toPos.Y, origin.Y + 2)

		local start = Vector3.new(fromPos.X, fromY + cfg.LineHeight / 2 + 0.05, fromPos.Y)
		local finish = Vector3.new(toPos.X, toY + cfg.LineHeight / 2 + 0.05, toPos.Y)

		local length = (finish - start).Magnitude
		local center = (start + finish) / 2
		local lineCF = CFrame.lookAt(center, finish)

		local line = Instance.new("Part")
		line.Name = "GuideLine_" .. conn.Label
		line.Size = Vector3.new(cfg.LineWidth, cfg.LineHeight, length)
		line.CFrame = lineCF
		line.Color = Palette.RoadYellow or Color3.fromRGB(250, 205, 50)
		line.Material = Enum.Material.SmoothPlastic
		line.Anchored = true
		line.CanCollide = false
		line.CanTouch = false
		line.CanQuery = false
		line.CastShadow = false
		line.CollisionGroup = "Decor"
		line.Parent = linesFolder
	end
end

function Service.Init(): ()
	if world then
		assert(world.Parent == Workspace, "PlanetSweepersWorld was removed after initialization")
		return
	end
	assert(not Workspace:FindFirstChild(WORLD_NAME), "WorldService refuses to overwrite existing Workspace.PlanetSweepersWorld")

	local planet = Planets.ById[Cleaning.PlanetId]
	assert(planet, "Cleaning.PlanetId must reference a configured planet")

	local folder = Instance.new("Folder")
	folder.Name = WORLD_NAME
	folder:SetAttribute("PlanetId", Cleaning.PlanetId)

	-- 1. Base terrain ground foundation
	local groundCF = CFrame.new(Cleaning.Origin.X, Cleaning.Origin.Y - Cleaning.GroundThickness / 2, Cleaning.Origin.Z)
	makePart("Ground", Vector3.new(Game.World.ZoneSize, Cleaning.GroundThickness, Game.World.ZoneSize), groundCF, planet.groundColor, folder)

	-- 2. Spawn platform at (0, 0)
	local spawnCF = Layout.GetCFrame(Cleaning.Origin, Layout.Base.Center, Layout.Base.Size, false)
	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "MoonletSpawn"
	spawn.Size = Layout.Base.Size
	spawn.CFrame = spawnCF
	spawn.Color = Cleaning.SpawnColor
	spawn.Anchored = true
	spawn.Neutral = true
	spawn.Duration = 0
	spawn.TopSurface = Enum.SurfaceType.Smooth
	spawn.BottomSurface = Enum.SurfaceType.Smooth
	spawn.Parent = folder
	addLabel(spawn, Layout.Base.ShortTitle, Layout.Base.StudsOffset, Layout.Base.MaxDistance)

	-- 3. Sell Station at (28, 0), facing center (0, 0)
	local sellCF = Layout.GetCFrame(Cleaning.Origin, Layout.Sell.Center, Layout.Sell.Size, true)
	local stationModel = OutpostBuilder.BuildSellStation(folder, sellCF)
	local station = stationModel.PrimaryPart :: BasePart
	station.Name = "SellStation"
	addLabel(station, Layout.Sell.ShortTitle, Layout.Sell.StudsOffset, Layout.Sell.MaxDistance)

	-- 4. Pets & Daily Reward Kiosk at (0, 28), facing center (0, 0)
	local kioskCF = Layout.GetCFrame(Cleaning.Origin, Layout.Kiosk.Center, Layout.Kiosk.Size, true)
	local kioskModel = OutpostBuilder.BuildPetsKiosk(folder, kioskCF)
	local kiosk = kioskModel.PrimaryPart :: BasePart
	kiosk.Name = "PetsDailyKiosk"
	addLabel(kiosk, Layout.Kiosk.ShortTitle, Layout.Kiosk.StudsOffset, Layout.Kiosk.MaxDistance)

	-- ProximityPrompt for Kiosk: opens Pets/Daily UI on interaction
	local kioskPrompt = Instance.new("ProximityPrompt")
	kioskPrompt.ActionText = Layout.Kiosk.PromptAction
	kioskPrompt.ObjectText = ""
	kioskPrompt.MaxActivationDistance = Layout.Kiosk.MaxDistance
	kioskPrompt.RequiresLineOfSight = false
	kioskPrompt.Parent = kiosk

	kioskPrompt.Triggered:Connect(function(player)
		local petRemote = ReplicatedStorage:FindFirstChild("PlanetSweepersPets")
		if petRemote and petRemote:IsA("RemoteEvent") then
			petRemote:FireClient(player, "OpenUI")
		end
	end)

	-- 5. Yellow guide lines
	buildGuideLines(folder, Cleaning.Origin)

	-- 6. Dust Nodes laid out on clean grid inside Zone A, Zone B, and Zone C
	local dirtFolder = Instance.new("Folder")
	dirtFolder.Name = "DirtNodes"
	dirtFolder.Parent = folder

	local gridPositions = Layout.GetZoneGridPositions(Cleaning.Origin, planet.dirtDensity)
	local generatedNodes: {BasePart} = {}

	for nodeId, position in ipairs(gridPositions) do
		local nodeCF = CFrame.new(position)
		local node = makePart("Dirt_" .. nodeId, Layout.DustZones.A.CellSize, nodeCF, planet.dirtColor, dirtFolder)
		node.CanCollide = false
		node.CanTouch = false
		node:SetAttribute("nodeId", nodeId)
		node:SetAttribute("PlanetId", Cleaning.PlanetId)
		table.insert(generatedNodes, node)
	end

	-- 7. Validate layout clearances and vertical alignment
	Layout.Validate(Cleaning.Origin)

	-- 8. Draw Studio visual debug gizmos
	Layout.DrawDebugGizmos(folder, Cleaning.Origin)

	-- Publish to Workspace
	folder.Parent = Workspace
	world = folder
	nodes = generatedNodes
	sellStation = station
	spawnLocation = spawn
	spawn:SetAttribute("PlanetId", Cleaning.PlanetId)
	station:SetAttribute("PlanetId", Cleaning.PlanetId)
	spawns[Cleaning.PlanetId] = spawn
	stations[Cleaning.PlanetId] = station

	-- Initialize other planets with their respective zones and offsets
	for index, id in ipairs(Planets.Order) do
		if id == Cleaning.PlanetId then continue end
		local definition = Planets.ById[id]
		local offset = Vector3.new((index - 1) * Game.World.ZoneSpacing, 0, 0)
		local zone = Instance.new("Folder")
		zone.Name = id
		zone.Parent = folder

		local zoneGroundCF = CFrame.new(Cleaning.Origin.X + offset.X, Cleaning.Origin.Y - Cleaning.GroundThickness / 2, Cleaning.Origin.Z + offset.Z)
		makePart("Ground", Vector3.new(Game.World.ZoneSize, Cleaning.GroundThickness, Game.World.ZoneSize), zoneGroundCF, definition.groundColor, zone)

		local destination = spawn:Clone()
		destination.Name = id .. "Spawn"
		destination.CFrame = Layout.GetCFrame(Cleaning.Origin + offset, Layout.Base.Center, Layout.Base.Size, false)
		destination:SetAttribute("PlanetId", id)
		local oldInstructions = destination:FindFirstChild("Instructions")
		if oldInstructions then oldInstructions:Destroy() end
		addLabel(destination, definition.name:upper(), Layout.Base.StudsOffset, Layout.Base.MaxDistance)
		destination.Parent = zone
		spawns[id] = destination

		local recyclerCF = Layout.GetCFrame(Cleaning.Origin + offset, Layout.Sell.Center, Layout.Sell.Size, true)
		local recyclerModel = OutpostBuilder.BuildSellStation(zone, recyclerCF)
		local recycler = recyclerModel.PrimaryPart :: BasePart
		recycler.Name = "SellStation"
		recycler:SetAttribute("PlanetId", id)
		addLabel(recycler, Layout.Sell.ShortTitle, Layout.Sell.StudsOffset, Layout.Sell.MaxDistance)
		stations[id] = recycler

		buildGuideLines(zone, Cleaning.Origin + offset)

		for nodeId, position in ipairs(Layout.GetZoneGridPositions(Cleaning.Origin + offset, definition.dirtDensity)) do
			local node = makePart(id .. "_Dirt_" .. nodeId, Layout.DustZones.A.CellSize, CFrame.new(position), definition.dirtColor, dirtFolder)
			node.CanCollide = false
			node.CanTouch = false
			node:SetAttribute("nodeId", nodeId)
			node:SetAttribute("PlanetId", id)
			table.insert(nodes, node)
		end
	end
end

function Service.ApplyLook(): ()
	assert(world, "World must exist before art generation")
	WorldLook.Build(world)
end

function Service.GetNodes(): {BasePart}
	assert(world, "WorldService.Init must be called before GetNodes")
	return table.clone(nodes)
end

function Service.GetSellStation(id: string?): BasePart
	local station = stations[id or Cleaning.PlanetId]
	assert(station, "WorldService.Init must be called before GetSellStation")
	return station
end

function Service.GetSpawn(id: string?): SpawnLocation
	local spawn = spawns[id or Cleaning.PlanetId]
	assert(spawn, "WorldService.Init must be called before GetSpawn")
	return spawn
end

return Service
