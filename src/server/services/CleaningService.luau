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

type Node = {part: BasePart, remaining: number, respawnAt: number, prompt: ProximityPrompt}
type Limits = {cleanAt: number, sellAt: number, tokens: number, updatedAt: number}
local GameConfig = require(config.Game)
local Service = {}
local nodes: {Node} = {}
local limits: {[Player]: Limits} = {}
local connections: {RBXScriptConnection} = {}
local started = false
local running = false
local stationPrompt: ProximityPrompt? = nil

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

local function clean(player: Player, node: Node)
	if not accept(player) or node.remaining <= 0 or not node.part:IsDescendantOf(workspace) then return end
	local data = DataService.Get(player)
	if not data or not data.unlockedPlanets[Cleaning.PlanetId] or data.currentPlanet ~= Cleaning.PlanetId then return end
	local tool = Tools.ById[data.equippedTool]
	if not tool or not data.ownedTools[data.equippedTool] then return end
	if not ToolService.IsEquipped(player, data.equippedTool) then return end
	local entry = getLimits(player)
	local now = os.clock()
	if now < entry.cleanAt or not inRange(player, node.part, tool.range) then return end
	local amount = math.min(tool.power, node.remaining, data.bagCapacity - data.bagContents.amount)
	if amount <= 0 then return end
	-- No yields between checks and mutations: competing prompts cannot double-collect.
	entry.cleanAt = now + tool.speed
	node.remaining -= amount
	data.bagContents.amount += amount
	data.bagContents.baseValue += amount * Planets.ById[Cleaning.PlanetId].dirtValue
	data.totalCleaned += amount
	node.part:SetAttribute("Remaining", node.remaining)
	if node.remaining <= 0 then
		node.respawnAt = now + Planets.ById[Cleaning.PlanetId].respawnSeconds
		node.prompt.Enabled = false
		node.part.Transparency = Cleaning.RespawnTransparency
		node.part.CanQuery = false
	end
	PlayerStateService.Publish(player)
end

local function sell(player: Player, station: BasePart)
	if not accept(player) then return end
	local data = DataService.Get(player)
	if not data or data.currentPlanet ~= Cleaning.PlanetId or not data.unlockedPlanets[Cleaning.PlanetId] then return end
	local entry = getLimits(player)
	local now = os.clock()
	if now < entry.sellAt or not inRange(player, station, Economy.SellRadius) then return end
	if data.bagContents.amount <= 0 then return end
	local value = data.bagContents.baseValue + data.bagContents.coopValue
	if value ~= value or value < 0 or value == math.huge then return end
	if data.money + value == math.huge then return end
	entry.sellAt = now + Cleaning.SellCooldown
	data.money += value
	data.bagContents = {amount = 0, baseValue = 0, coopValue = 0}
	PlayerStateService.Publish(player)
end

function Service.Destroy(): ()
	running = false
	for _, connection in connections do connection:Disconnect() end
	table.clear(connections)
	if stationPrompt then stationPrompt:Destroy(); stationPrompt = nil end
	for _, node in nodes do node.prompt:Destroy() end
	table.clear(nodes)
	table.clear(limits)
end

function Service.Init(): ()
	if started then return end
	started = true
	running = true
	local definition = Planets.ById[Cleaning.PlanetId]
	for _, part in WorldService.GetNodes() do
		local maximumRange = 0
		for _, tool in Tools.ById do maximumRange = math.max(maximumRange, tool.range) end
		local prompt = makePrompt(part, "Clean dust", maximumRange)
		local node: Node = {part = part, remaining = definition.nodeAmount, respawnAt = 0, prompt = prompt}
		part:SetAttribute("Remaining", node.remaining)
		table.insert(nodes, node)
		table.insert(connections, prompt.Triggered:Connect(function(player: Player) clean(player, node) end))
	end
	local station = WorldService.GetSellStation()
	local sellPrompt = makePrompt(station, "Sell bag", Economy.SellRadius)
	stationPrompt = sellPrompt
	table.insert(connections, sellPrompt.Triggered:Connect(function(player: Player) sell(player, station) end))
	table.insert(connections, Players.PlayerRemoving:Connect(function(player: Player) limits[player] = nil end))
	table.insert(connections, station.Destroying:Connect(Service.Destroy))
	game:BindToClose(Service.Destroy)
	task.spawn(function()
		while running do
			task.wait(Cleaning.RespawnPollSeconds)
			if not running then break end
			local now = os.clock()
			for _, node in nodes do
				if node.remaining <= 0 and now >= node.respawnAt then
					node.remaining = definition.nodeAmount
					node.part.Transparency = 0
					node.part.CanQuery = true
					node.part:SetAttribute("Remaining", node.remaining)
					node.prompt.Enabled = true
				end
			end
		end
	end)
end
return Service
