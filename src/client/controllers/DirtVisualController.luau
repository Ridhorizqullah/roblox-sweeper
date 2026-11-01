--!strict
-- DirtVisualController.luau (client)
-- Renders dust overlay tiles + pebble clusters for every dirt node.
-- Listens to server CellState events: overlay fade + pebble fly arc on clean,
-- fade-in back on respawn. All effects are cosmetic; server stays authoritative.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = Shared:WaitForChild("config")
local Visual = require(Config:WaitForChild("DirtVisual"))
local Builder = require(Shared:WaitForChild("art"):WaitForChild("DirtCellBuilder"))

local Controller = {}
local started = false

type CellVisual = {
	overlay: Part,
	cluster: Model,
	cleaned: boolean,
	cullAt: number,
}

function Controller.Start(): ()
	if started then return end
	started = true

	local player = Players.LocalPlayer
	local event = ReplicatedStorage:WaitForChild("PlanetSweepersCells") :: RemoteEvent
	local world = workspace:WaitForChild("PlanetSweepersWorld")
	local dirtFolder = world:WaitForChild("DirtNodes")

	local cells: {[string]: CellVisual} = {}
	local pebblePool: {Part} = {}
	local connections: {RBXScriptConnection} = {}
	local alive = true

	-- Build visuals for one node part (server part stays, we add overlay + pebbles).
	local function buildCell(node: BasePart)
		local cellId = node:GetAttribute("PlanetId") .. "_" .. tostring(node:GetAttribute("nodeId"))
		if cells[cellId] then return end
		local overlay = Builder.BuildOverlay(cellId, node.Size, node.CFrame)
		overlay.Parent = world
		local seed = 0
		for i = 1, #cellId do
			seed += string.byte(cellId, i) * i
		end
		local cluster = Builder.BuildPebbles(cellId, node.Size, node.CFrame, seed)
		cluster.Parent = world
		cells[cellId] = {overlay = overlay, cluster = cluster, cleaned = false, cullAt = 0}
	end

	-- Reuse pooled pebbles for the fly-to-player arc (no create/destroy spam).
	local function flyPebble(from: Vector3, to: Vector3)
		local pebble: Part? = table.remove(pebblePool)
		if not pebble then
			if #pebblePool >= Visual.PebblePoolSize then return end
			pebble = Instance.new("Part")
			pebble.Shape = Enum.PartType.Ball
			pebble.Size = Vector3.one * 0.4
			pebble.Color = Color3.fromRGB(150, 148, 160)
			pebble.Material = Enum.Material.Slate
			pebble.Anchored = true
			pebble.CanCollide = false
			pebble.CanTouch = false
			pebble.CanQuery = false
			pebble.CastShadow = false
			pebble.CollisionGroup = "Decor"
			pebble.Parent = world
		end
		local active = pebble :: Part
		active.Position = from
		active.Transparency = 0
		active.Parent = world
		local mid = (from + to) / 2 + Vector3.new(0, Visual.PebbleFlyHeight, 0)
		local t1 = TweenService:Create(active, TweenInfo.new(Visual.PebbleFlyTime / 2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Position = mid})
		t1:Play()
		t1.Completed:Once(function()
			if not alive then return end
			local t2 = TweenService:Create(active, TweenInfo.new(Visual.PebbleFlyTime / 2, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {Position = to, Transparency = 1})
			t2:Play()
			t2.Completed:Once(function()
				active.Parent = nil
				if #pebblePool < Visual.PebblePoolSize then
					table.insert(pebblePool, active)
				else
					active:Destroy()
				end
			end)
		end)
	end

	-- Server event: "Clean", cellId, playerPosition | "Respawn", cellId
	table.insert(connections, event.OnClientEvent:Connect(function(action: any, cellId: any, target: any)
		if type(action) ~= "string" or type(cellId) ~= "string" then return end
		local cell = cells[cellId]
		if not cell then return end
		if action == "Clean" then
			cell.cleaned = true
			TweenService:Create(cell.overlay, TweenInfo.new(Visual.FadeTime), {Transparency = Visual.CleanTransparency}):Play()
			-- Hide cluster, spawn fly arcs toward the cleaner.
			for _, pebble in cell.cluster:GetChildren() do
				if pebble:IsA("BasePart") and typeof(target) == "Vector3" then
					for _ = 1, 2 do
						flyPebble(pebble.Position, target)
					end
				end
			end
			cell.cluster.Parent = nil
		elseif action == "Respawn" then
			cell.overlay.Transparency = Visual.CleanTransparency
			cell.cluster.Parent = world
			cell.cleaned = false
			TweenService:Create(cell.overlay, TweenInfo.new(Visual.RespawnFadeTime), {Transparency = Visual.DustyTransparency}):Play()
		end
	end))

	-- Build for existing nodes, then watch for late-added ones.
	for _, node in dirtFolder:GetChildren() do
		if node:IsA("BasePart") then buildCell(node) end
	end
	table.insert(connections, dirtFolder.ChildAdded:Connect(function(child)
		if child:IsA("BasePart") then buildCell(child) end
	end))

	-- Distance culling on a slow timer (not per-frame).
	task.spawn(function()
		while alive do
			task.wait(Visual.CullCheckSeconds)
			if not alive then break end
			local camera = workspace.CurrentCamera
			if not camera then continue end
			local focus = camera.CFrame.Position
			for _, cell in cells do
				if cell.cleaned then continue end
				local dist = (cell.overlay.Position - focus).Magnitude
				local visible = dist <= Visual.CullDistance
				local inWorld = cell.cluster.Parent == world
				if visible and not inWorld then
					cell.cluster.Parent = world
				elseif not visible and inWorld then
					cell.cluster.Parent = nil
				end
			end
		end
	end)

	table.insert(connections, dirtFolder.Destroying:Connect(function()
		alive = false
		for _, connection in connections do connection:Disconnect() end
		for _, cell in cells do
			cell.overlay:Destroy()
			cell.cluster:Destroy()
		end
		table.clear(cells)
		for _, pebble in pebblePool do pebble:Destroy() end
		table.clear(pebblePool)
		started = false
	end))

	player:WaitForChild("PlayerGui") -- ensure GUI ready before returning
end

return Controller
