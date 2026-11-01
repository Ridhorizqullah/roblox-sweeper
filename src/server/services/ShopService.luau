--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local config = ReplicatedStorage.Shared.config
local Shop = require(config.Shop)
local Cleaning = require(config.Cleaning)
local Tools = require(config.Tools)
local Bags = require(config.Bags)
local Vehicles = require(config.Vehicles)
local DataService = require(script.Parent.DataService)
local State = require(script.Parent.PlayerStateService)
local ToolService = require(script.Parent.ToolService)
local Service = {}
local lastRequest: {[Player]: number} = {}
local initialized = false
function Service.Init(): ()
	if initialized then return end
	initialized = true
	local station = Instance.new("Part")
	station.Name = "ShopStation"
	station.Anchored = true
	station.Size = Shop.Size
	station.Position = Cleaning.Origin + Shop.Offset
	station.Color = Shop.Color
	station.Parent = workspace:WaitForChild("PlanetSweepersWorld")
	local remote = Instance.new("RemoteEvent")
	remote.Name = "PlanetSweepersShop"
	remote.Parent = ReplicatedStorage
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Open shop"
	prompt.ObjectText = "Tools and bags"
	prompt.MaxActivationDistance = Shop.Radius
	prompt.RequiresLineOfSight = false
	prompt.Parent = station
	local function nearby(player: Player): boolean
		local character = player.Character
		local root = if character then character:FindFirstChild("HumanoidRootPart") else nil
		local humanoid = if character then character:FindFirstChildOfClass("Humanoid") else nil
		return root ~= nil and root:IsA("BasePart") and humanoid ~= nil and humanoid.Health > 0 and (root.Position - station.Position).Magnitude <= Shop.Radius
	end
	local function allowed(player: Player): boolean
		local now = os.clock()
		if now - (lastRequest[player] or -math.huge) < Shop.RequestCooldown then return false end
		lastRequest[player] = now
		return true
	end
	prompt.Triggered:Connect(function(player)
		if allowed(player) and nearby(player) and DataService.Get(player) then remote:FireClient(player, "Open") end
	end)
	remote.OnServerEvent:Connect(function(player: Player, action: any, id: any, expectedCount: any)
		if not allowed(player) then return end
		if type(action) ~= "string" or type(id) ~= "string" or #id > 40 then return end
		if action ~= "Tool" and action ~= "Bag" and action ~= "Robot" then return end
		local data = DataService.Get(player)
		if not data then return end
		if not nearby(player) then remote:FireClient(player, "Result", "Dekati toko dahulu."); return end
		if data.currentPlanet ~= Cleaning.PlanetId or not data.unlockedPlanets[Cleaning.PlanetId] then return end
		-- No yields inside currency transactions. Client supplies intent, never prices.
		if action == "Tool" then
			local definition = Tools.ById[id]
			if not definition then return end
			if not data.ownedTools[id] then
				local previous = Tools.Order[definition.level]
				if previous and not data.ownedTools[previous] then remote:FireClient(player, "Result", "Beli tier sebelumnya."); return end
				local cost = math.ceil(definition.price)
				if cost < 0 or cost ~= cost or cost == math.huge or data.money < cost then return end
				data.money -= cost
				data.ownedTools[id] = true
			end
			data.equippedTool = id
			ToolService.Refresh(player)
		elseif action == "Robot" then
			local definition = Vehicles.ById[id]
			if not definition or type(expectedCount) ~= "number" or expectedCount ~= expectedCount or expectedCount < 0 or expectedCount % 1 ~= 0 then return end
			if definition.price ~= definition.price or definition.price < 0 or definition.price == math.huge then return end
			local count = data.ownedVehicles[id] or 0
			if expectedCount ~= count then return end
			local total = 0
			for _, amount in data.ownedVehicles do total += amount end
			if total >= Vehicles.MaximumRobots or data.money < definition.price then return end
			data.money -= definition.price
			data.ownedVehicles[id] = count + 1
		else
			-- Expected next level prevents duplicate requests from buying twice.
			if id ~= tostring(data.bagLevel + 1) or data.bagLevel >= Bags.MaximumLevel then return end
			local cost = math.ceil(Bags.BaseCost * Bags.CostGrowth ^ data.bagLevel)
			if cost < 0 or cost ~= cost or cost == math.huge or data.money < cost then return end
			data.money -= cost
			data.bagLevel += 1
			data.bagCapacity = Bags.BaseCapacity + Bags.CapacityPerLevel * data.bagLevel
		end
		State.Publish(player)
		remote:FireClient(player, "Result", "Berhasil.")
	end)
	Players.PlayerRemoving:Connect(function(player) lastRequest[player] = nil end)
end
return Service
