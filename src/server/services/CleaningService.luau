--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local config = ReplicatedStorage:WaitForChild("Shared"):WaitForChild("config")
local Cleaning = require(config.Cleaning)
local Planets = require(config.Planets)
local Tools = require(config.Tools)
local Economy = require(config.Economy)
local DataService = require(script.Parent.DataService)
local PlayerStateService = require(script.Parent.PlayerStateService)
local WorldService = require(script.Parent.WorldService)
local ToolService = require(script.Parent.ToolService)
local PetService = require(script.Parent.PetService)
local CoopService = require(script.Parent.CoopService)
local Vehicles = require(config.Vehicles)
local RewardService = require(script.Parent.RewardService)
local Monetization = require(script.Parent.MonetizationService)

type Node = {part: BasePart, planetId: string, remaining: number, respawnAt: number, prompt: ProximityPrompt}
type Limits = {cleanAt: number, sellAt: number, tokens: number, updatedAt: number}
local GameConfig = require(config.Game)
local Service = {}
local nodes: {Node} = {}
local limits: {[Player]: Limits} = {}
local connections: {RBXScriptConnection} = {}
local started = false
local running = false
local stationPrompts: {ProximityPrompt} = {}
local cellEvent: RemoteEvent? = nil

local function cellIdOf(node: Node): string
	return node.planetId .. "_" .. tostring(node.part:GetAttribute("nodeId"))
end

local function emitCell(action: string, node: Node, target: Vector3?)
	-- Visual-only broadcast. Gameplay state already mutated before this yields.
	local event = cellEvent
	if not event then return end
	for _, other in Players:GetPlayers() do
		local data = DataService.Get(other)
		if data and data.currentPlanet == node.planetId then
			event:FireClient(other, action, cellIdOf(node), target)
		end
	end
end

local function getLimits(player: Player): Limits
	local existing = limits[player]
	if existing then return existing end
	local entry = {cleanAt = 0, sellAt = 0, tokens = GameConfig.RemoteLimits.Burst, updatedAt = os.clock()}
	limits[player] = entry
	return entry
end

local function accept(player: Player): boolean
	if player.Parent ~= Players then return false end
	local entry = getLimits(player)
	local now = os.clock()
	entry.tokens = math.min(GameConfig.RemoteLimits.Burst, entry.tokens + (now - entry.updatedAt) * GameConfig.RemoteLimits.RequestsPerSecond)
	entry.updatedAt = now
	if entry.tokens < 1 then return false end
	entry.tokens -= 1
	return true
end

local function inRange(player: Player, target: BasePart, range: number): boolean
	local character = player.Character
	local root = if character then character:FindFirstChild("HumanoidRootPart") else nil
	local humanoid = if character then character:FindFirstChildOfClass("Humanoid") else nil
	if not root or not root:IsA("BasePart") or not humanoid or humanoid.Health <= 0 then return false end
	local distance = (root.Position - target.Position).Magnitude
	return distance == distance and distance <= range
end

local function makePrompt(part: BasePart, action: string, distance: number): ProximityPrompt
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = action
	prompt.ObjectText = if action == "Sell bag" then "Recycler" else "Moon dust"
	prompt.MaxActivationDistance = distance
	prompt.HoldDuration = Cleaning.PromptHoldSeconds
	prompt.KeyboardKeyCode = Cleaning.PromptKey
	prompt.RequiresLineOfSight = false
	prompt.Parent = part
	return prompt
end

local function collect(player: Player, node: Node, power: number, range: number): boolean
	if node.remaining <= 0 or not node.part:IsDescendantOf(workspace) then return false end
	local data = DataService.Get(player)
	if not data or not data.unlockedPlanets[node.planetId] or data.currentPlanet ~= node.planetId then return false end
	if not inRange(player, node.part, range) then return false end
	local now = os.clock()
	local amount = math.min(power, node.remaining, Monetization.GetBagCapacity(player, data.bagCapacity) - data.bagContents.amount)
	if amount <= 0 then return false end
	-- No yields between checks and mutations: competing prompts cannot double-collect.
	node.remaining -= amount
	data.bagContents.amount += amount
	local value = amount * Planets.ById[node.planetId].dirtValue
	data.bagContents.baseValue += value
	data.bagContents.coopValue += value * CoopService.Bonus(player)
	data.totalCleaned += amount
	RewardService.Emit(player, "Clean", node.part.Position)
	node.part:SetAttribute("Remaining", node.remaining)
	if node.remaining <= 0 then
		node.respawnAt = now + Planets.ById[node.planetId].respawnSeconds
		node.prompt.Enabled = false
		node.part.Transparency = Cleaning.RespawnTransparency
		node.part.CanQuery = false
		PetService.Discover(player, node.planetId)
		local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
		emitCell("Clean", node, if root and root:IsA("BasePart") then root.Position else node.part.Position)
	end
	PlayerStateService.Publish(player)
	return true
end

local function clean(player: Player, node: Node)
	if not accept(player) then return end
	local data = DataService.Get(player)
	if not data then return end
	local tool = Tools.ById[data.equippedTool]
	if not tool or not data.ownedTools[data.equippedTool] or not ToolService.IsEquipped(player, data.equippedTool) then return end
	local entry = getLimits(player)
	local now = os.clock()
	if now < entry.cleanAt then return end
	if collect(player, node, tool.power, tool.range) then entry.cleanAt = now + tool.speed end
end

-- Internal server API. RobotService owns each robot's independent timer.
function Service.RobotClean(player: Player, id: string): boolean
	local data = DataService.Get(player)
	local definition = Vehicles.ById[id]
	if not data or not definition or (data.ownedVehicles[id] or 0) < 1 then return false end
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	if not root or not root:IsA("BasePart") then return false end
	local nearest: Node? = nil
	local distance = definition.range
	for _, node in nodes do
		if node.remaining <= 0 or node.planetId ~= data.currentPlanet then continue end
		local candidate = (root.Position - node.part.Position).Magnitude
		if candidate <= distance then distance = candidate; nearest = node end
	end
	return if nearest then collect(player, nearest, definition.power, definition.range) else false
end

local function sell(player: Player, station: BasePart)
	if not accept(player) then return end
	local data = DataService.Get(player)
	local planetId = station:GetAttribute("PlanetId")
	if not data or data.currentPlanet ~= planetId or not data.unlockedPlanets[planetId] then return end
	local entry = getLimits(player)
	local now = os.clock()
	if now < entry.sellAt or not inRange(player, station, Economy.SellRadius) then return end
	if data.bagContents.amount <= 0 then return end
	local value = (data.bagContents.baseValue + data.bagContents.coopValue) * PetService.Multiplier(data) * Monetization.GetMoneyMultiplier(player)
	if value ~= value or value < 0 or value == math.huge then return end
	if data.money + value == math.huge then return end
	entry.sellAt = now + Cleaning.SellCooldown
	data.money += value
	RewardService.Emit(player, "Sell", value)
	data.bagContents = {amount = 0, baseValue = 0, coopValue = 0}
	PlayerStateService.Publish(player)
end

function Service.Destroy(): ()
	running = false
	for _, connection in connections do connection:Disconnect() end
	table.clear(connections)
	for _, prompt in stationPrompts do prompt:Destroy() end
	table.clear(stationPrompts)
	for _, node in nodes do node.prompt:Destroy() end
	table.clear(nodes)
	table.clear(limits)
end

function Service.Init(): ()
	if started then return end
	started = true
	running = true
	local event = Instance.new("RemoteEvent")
	event.Name = "PlanetSweepersCells"
	event.Parent = ReplicatedStorage
	cellEvent = event
	for _, part in WorldService.GetNodes() do
		local planetId = part:GetAttribute("PlanetId") :: string
		local definition = Planets.ById[planetId]
		local maximumRange = 0
		for _, tool in Tools.ById do maximumRange = math.max(maximumRange, tool.range) end
		local prompt = makePrompt(part, "Clean dust", maximumRange)
		local node: Node = {part = part, planetId = planetId, remaining = definition.nodeAmount, respawnAt = 0, prompt = prompt}
		part:SetAttribute("Remaining", node.remaining)
		table.insert(nodes, node)
		table.insert(connections, prompt.Triggered:Connect(function(player: Player) clean(player, node) end))
	end
	for _, id in Planets.Order do
	local station = WorldService.GetSellStation(id)
	local sellPrompt = makePrompt(station, "Sell bag", Economy.SellRadius)
	table.insert(stationPrompts, sellPrompt)
	table.insert(connections, sellPrompt.Triggered:Connect(function(player: Player) sell(player, station) end))
	end
	table.insert(connections, Players.PlayerRemoving:Connect(function(player: Player) limits[player] = nil end))
	game:BindToClose(Service.Destroy)
	task.spawn(function()
		while running do
			task.wait(Cleaning.RespawnPollSeconds)
			if not running then break end
			local now = os.clock()
			for _, node in nodes do
				if node.remaining <= 0 and now >= node.respawnAt then
					node.remaining = Planets.ById[node.planetId].nodeAmount
					node.part.Transparency = 0
					node.part.CanQuery = true
					node.part:SetAttribute("Remaining", node.remaining)
					node.prompt.Enabled = true
					emitCell("Respawn", node, nil)
				end
			end
		end
	end)
end
return Service
