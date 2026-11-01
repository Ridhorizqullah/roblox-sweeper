--!strict
local Players = game:GetService("Players")
local PhysicsService = game:GetService("PhysicsService")
local RS = game:GetService("ReplicatedStorage")
local Config = require(RS.Shared.config.Costume)
local Builder = require(RS.Shared.art.AstronautBuilder)
local Service = {}
type Visual = BasePart | Decal
type State = {
	character: Model,
	connections: {RBXScriptConnection},
	original: {[Visual]: number},
	suit: Model?,
	alive: boolean,
	queued: boolean,
}
local states: {[Player]: State} = {}
local playerConnections: {[Player]: {RBXScriptConnection}} = {}
local started = false

local function cleanup(player: Player)
	local state = states[player]
	if not state then return end
	states[player] = nil
	state.alive = false
	for _, connection in state.connections do connection:Disconnect() end
	if state.suit then state.suit:Destroy() end
	for visual, transparency in state.original do
		if visual.Parent then visual.Transparency = transparency end
	end
	table.clear(state.original)
end

local function hide(state: State, item: Instance)
	if state.suit and item:IsDescendantOf(state.suit) then return end
	if not item:IsA("BasePart") and not item:IsA("Decal") then return end
	if item:FindFirstAncestorOfClass("Tool") then return end
	local rigPart = item:IsA("BasePart") and item.Parent == state.character and item.Name ~= "HumanoidRootPart"
	local accessory = item:FindFirstAncestorOfClass("Accessory")
	local face = item:IsA("Decal") and item.Parent == state.character:FindFirstChild("Head")
	if rigPart or accessory or face then
		if state.original[item] == nil then state.original[item] = item.Transparency end
		item.Transparency = 1
	end
end

local function dress(player: Player, character: Model)
	cleanup(player)
	local state: State = {character = character, connections = {}, original = {}, suit = nil, alive = true, queued = false}
	states[player] = state
	local function valid(): boolean
		return state.alive and states[player] == state and player.Character == character and character.Parent ~= nil
	end
	local function rebuild()
		if not valid() then return end
		if state.suit then state.suit:Destroy(); state.suit = nil end
		state.suit = Builder.Build(character)
		if state.suit then
			for _, item in character:GetDescendants() do hide(state, item) end
		end
	end
	local function queue()
		if state.queued then return end
		state.queued = true
		task.delay(Config.RebuildDelay, function()
			state.queued = false
			if valid() then rebuild() end
		end)
	end
	table.insert(state.connections, character.Destroying:Connect(function()
		if states[player] == state then cleanup(player) end
	end))
	table.insert(state.connections, character.DescendantAdded:Connect(function(item)
		if state.suit then hide(state, item) end
		if item:IsA("BasePart") and item.Parent == character and item.Name ~= "HumanoidRootPart" then
			table.insert(state.connections, item:GetPropertyChangedSignal("Size"):Connect(queue))
			queue()
		end
	end))
	table.insert(state.connections, character.DescendantRemoving:Connect(function(item)
		if item:IsA("BasePart") or item:IsA("Decal") then state.original[item] = nil end
	end))
	table.insert(state.connections, player.CharacterAppearanceLoaded:Connect(function(loaded)
		if loaded == character then queue() end
	end))
	for _, item in character:GetChildren() do
		if item:IsA("BasePart") then
			table.insert(state.connections, item:GetPropertyChangedSignal("Size"):Connect(queue))
		end
	end
	task.spawn(function()
		local humanoid = character:WaitForChild("Humanoid", Config.RigWaitSeconds)
		local head = character:WaitForChild("Head", Config.RigWaitSeconds)
		if humanoid and head and valid() then rebuild() end
	end)
end

function Service.Init()
	if started then return end
	started = true
	if not PhysicsService:IsCollisionGroupRegistered("Decor") then PhysicsService:RegisterCollisionGroup("Decor") end
	PhysicsService:CollisionGroupSetCollidable("Decor", "Default", false)
	local function added(player: Player)
		if playerConnections[player] then return end
		playerConnections[player] = {
			player.CharacterAdded:Connect(function(character) dress(player, character) end),
			player.CharacterRemoving:Connect(function(character)
				if states[player] and states[player].character == character then cleanup(player) end
			end),
		}
		if player.Character then dress(player, player.Character) end
	end
	Players.PlayerAdded:Connect(added)
	Players.PlayerRemoving:Connect(function(player)
		cleanup(player)
		for _, connection in playerConnections[player] or {} do connection:Disconnect() end
		playerConnections[player] = nil
	end)
	for _, player in Players:GetPlayers() do added(player) end
end
return Service
