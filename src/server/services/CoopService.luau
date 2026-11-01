--!strict
local Players = game:GetService("Players")
local Config = require(game:GetService("ReplicatedStorage").Shared.config.Game).Coop
local Data = require(script.Parent.DataService)
local Service = {}
function Service.Bonus(player: Player): number
	local data = Data.Get(player)
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	if not data or not root or not root:IsA("BasePart") then return 0 end
	local count = 0
	for _, other in Players:GetPlayers() do
		if other == player then continue end
		local otherData = Data.Get(other)
		local character = other.Character
		local otherRoot = character and character:FindFirstChild("HumanoidRootPart")
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		if otherData and otherData.currentPlanet == data.currentPlanet and otherRoot and otherRoot:IsA("BasePart") and humanoid and humanoid.Health > 0
			and (root.Position - otherRoot.Position).Magnitude <= Config.Radius then count += 1 end
	end
	return math.min(Config.MaximumBonus, count * Config.BonusPerPlayer)
end
return Service
