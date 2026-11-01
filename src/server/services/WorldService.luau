--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local Config = ReplicatedStorage:WaitForChild("Shared"):WaitForChild("config")
local Cleaning = require(Config:WaitForChild("Cleaning"))
local Game = require(Config:WaitForChild("Game"))
local Planets = require(Config:WaitForChild("Planets"))

local Service = {}
local world: Folder? = nil
local nodes: {BasePart} = {}
local sellStation: BasePart? = nil
local spawnLocation: SpawnLocation? = nil
local WORLD_NAME = "PlanetSweepersWorld"
local spawns: {[string]: SpawnLocation} = {}
local stations: {[string]: BasePart} = {}

local function makePart(name: string, size: Vector3, position: Vector3, color: Color3, parent: Instance): Part
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.Position = position
	part.Color = color
	part.Anchored = true
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Parent = parent
	return part
end

local function addLabel(part: BasePart, text: string): ()
	local billboard = Instance.new("BillboardGui")
	billboard.Name = "Instructions"
	billboard.Size = UDim2.fromOffset(Cleaning.LabelSize.X, Cleaning.LabelSize.Y)
	billboard.StudsOffset = Cleaning.LabelOffset
	billboard.MaxDistance = Cleaning.LabelMaxDistance
	billboard.AlwaysOnTop = true
	billboard.Adornee = part
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Text = text
	label.TextColor3 = Color3.new(1, 1, 1)
	label.TextStrokeTransparency = 0
	label.TextSize = Cleaning.LabelTextSize
	label.TextWrapped = true
	label.Font = Enum.Font.GothamBold
	label.Parent = billboard
	billboard.Parent = part
end

local function getNodePositions(count: number): {Vector3}
	local positions: {Vector3} = {}
	local halfExtent = Game.World.ZoneSize / 2 - Cleaning.EdgeMargin
	local rows = math.floor(halfExtent * 2 / Cleaning.GridSpacing) + 1
	local groundTop = Cleaning.GroundThickness / 2
	for row = 1, rows do
		local z = (row - (rows + 1) / 2) * Cleaning.GridSpacing
		for column = 1, Cleaning.GridColumns do
			local x = (column - (Cleaning.GridColumns + 1) / 2) * Cleaning.GridSpacing
			if math.abs(x) <= halfExtent and Vector2.new(x, z).Magnitude >= Cleaning.ReservedRadius then
				table.insert(positions, Cleaning.Origin + Vector3.new(x, groundTop + Cleaning.NodeSize.Y / 2, z))
				if #positions == count then
					return positions
				end
			end
		end
	end
	error("Cleaning grid cannot fit configured planet dirt density")
end

function Service.Init(): ()
	if world then
		assert(world.Parent == Workspace, "PlanetSweepersWorld was removed after initialization")
		return
	end
	assert(not Workspace:FindFirstChild(WORLD_NAME), "WorldService refuses to overwrite existing Workspace.PlanetSweepersWorld")
	local planet = Planets.ById[Cleaning.PlanetId]
	assert(planet, "Cleaning.PlanetId must reference a configured planet")
	local positions = getNodePositions(planet.dirtDensity)
	local folder = Instance.new("Folder")
	folder.Name = WORLD_NAME
	folder:SetAttribute("PlanetId", Cleaning.PlanetId)

	makePart("Ground", Vector3.new(Game.World.ZoneSize, Cleaning.GroundThickness, Game.World.ZoneSize), Cleaning.Origin, planet.groundColor, folder)
	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "MoonletSpawn"
	spawn.Size = Cleaning.SpawnSize
	spawn.Position = Cleaning.Origin + Cleaning.SpawnOffset
	spawn.Color = Cleaning.SpawnColor
	spawn.Anchored = true
	spawn.Neutral = true
	spawn.Duration = 0
	spawn.TopSurface = Enum.SurfaceType.Smooth
	spawn.BottomSurface = Enum.SurfaceType.Smooth
	spawn.Parent = folder
	addLabel(spawn, planet.name .. "\nApproach dust and hold the Clean dust prompt")

	local station = makePart("SellStation", Cleaning.SellSize, Cleaning.Origin + Cleaning.SellOffset, Cleaning.SellColor, folder)
	addLabel(station, "SELL DIRT\nUse the prompt to empty your bag")
	local dirtFolder = Instance.new("Folder")
	dirtFolder.Name = "DirtNodes"
	dirtFolder.Parent = folder
	local generatedNodes: {BasePart} = {}
	for nodeId, position in ipairs(positions) do
		local node = makePart("Dirt_" .. nodeId, Cleaning.NodeSize, position, planet.dirtColor, dirtFolder)
		node.CanCollide = false
		node.CanTouch = false
		node:SetAttribute("nodeId", nodeId)
		node:SetAttribute("PlanetId", Cleaning.PlanetId)
		table.insert(generatedNodes, node)
	end

	-- Publish only after construction so other services never observe a partial world.
	folder.Parent = Workspace
	world = folder
	nodes = generatedNodes
	sellStation = station
	spawnLocation = spawn
	spawn:SetAttribute("PlanetId", Cleaning.PlanetId)
	station:SetAttribute("PlanetId", Cleaning.PlanetId)
	spawns[Cleaning.PlanetId] = spawn
	stations[Cleaning.PlanetId] = station
	for index, id in Planets.Order do
		if id == Cleaning.PlanetId then continue end
		local definition = Planets.ById[id]
		local offset = Vector3.new((index - 1) * Game.World.ZoneSpacing, 0, 0)
		local zone = Instance.new("Folder")
		zone.Name = id
		zone.Parent = folder
		makePart("Ground", Vector3.new(Game.World.ZoneSize, Cleaning.GroundThickness, Game.World.ZoneSize), Cleaning.Origin + offset, definition.groundColor, zone)
		local destination = spawn:Clone()
		destination.Name = id .. "Spawn"
		destination.Position += offset
		destination:SetAttribute("PlanetId", id)
		destination.Instructions:Destroy()
		addLabel(destination, definition.name)
		destination.Parent = zone
		spawns[id] = destination
		local recycler = makePart("SellStation", Cleaning.SellSize, Cleaning.Origin + offset + Cleaning.SellOffset, Cleaning.SellColor, zone)
		recycler:SetAttribute("PlanetId", id)
		addLabel(recycler, "SELL DIRT")
		stations[id] = recycler
		for nodeId, position in getNodePositions(definition.dirtDensity) do
			local node = makePart(id .. "_Dirt_" .. nodeId, Cleaning.NodeSize, position + offset, definition.dirtColor, dirtFolder)
			node.CanCollide = false
			node.CanTouch = false
			node:SetAttribute("nodeId", nodeId)
			node:SetAttribute("PlanetId", id)
			table.insert(nodes, node)
		end
	end
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
