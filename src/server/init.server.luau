--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Cleaning = require(ReplicatedStorage.Shared.config.Cleaning)
local DataService = require(script.services.DataService)
local PlayerStateService = require(script.services.PlayerStateService)
local WorldService = require(script.services.WorldService)
local CleaningService = require(script.services.CleaningService)
local ToolService = require(script.services.ToolService)
local ShopService = require(script.services.ShopService)
local PetService = require(script.services.PetService)
local characterConnections: {[Player]: RBXScriptConnection} = {}

DataService.Init()
PlayerStateService.Init(DataService)
WorldService.Init()
PetService.Init()
CleaningService.Init()
ShopService.Init()

local function moveToSpawn(player: Player, character: Model)
	local root = character:WaitForChild("HumanoidRootPart", Cleaning.SpawnWaitSeconds)
	if root and player.Parent == Players and player.Character == character and DataService.Get(player) then
		character:PivotTo(WorldService.GetSpawn().CFrame + Vector3.new(0, Cleaning.SpawnLift, 0))
		ToolService.Refresh(player)
	end
end

local function onPlayerAdded(player: Player)
	if not DataService.Load(player) then return end
	if player.Parent ~= Players then return end
	PlayerStateService.Publish(player)
	PetService.Publish(player)
	player.RespawnLocation = WorldService.GetSpawn()
	if characterConnections[player] then return end
	characterConnections[player] = player.CharacterAdded:Connect(function(character)
		task.spawn(moveToSpawn, player, character)
	end)
	if player.Character then task.spawn(moveToSpawn, player, player.Character) end
end

Players.PlayerRemoving:Connect(function(player)
	local connection = characterConnections[player]
	if connection then connection:Disconnect(); characterConnections[player] = nil end
end)
Players.PlayerAdded:Connect(onPlayerAdded)
for _, player in Players:GetPlayers() do task.spawn(onPlayerAdded, player) end
