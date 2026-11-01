--!strict
local Players = game:GetService("Players")
local DataService = require(script.services.DataService)
local PlayerStateService = require(script.services.PlayerStateService)

DataService.Init()
PlayerStateService.Init(DataService)

local function onPlayerAdded(player: Player)
	if DataService.Load(player) then
		PlayerStateService.Publish(player)
	end
end

Players.PlayerAdded:Connect(onPlayerAdded)
for _, player in Players:GetPlayers() do
	task.spawn(onPlayerAdded, player)
end
