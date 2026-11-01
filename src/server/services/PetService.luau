--!strict
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local Http = game:GetService("HttpService")
local Config = require(RS.Shared.config.Pets)
local Planets = require(RS.Shared.config.Planets)
local Data = require(script.Parent.DataService)
local Types = require(RS.Shared.Types)
type PlayerData = Types.PlayerData
local Service = {}
local random = Random.new()
local remote: RemoteEvent
local last: {[Player]: number} = {}

function Service.Multiplier(data: PlayerData): number
	local multiplier = 1
	local seen: {[string]: boolean} = {}
	for index, id in data.equippedPets do
		if index > Config.EquipSlots then break end
		if seen[id] then continue end
		seen[id] = true
		for _, pet in data.pets do
			if pet.id == id then
				local rarity, variant = Config.Rarities[pet.rarity], Config.Variants[pet.variant]
				if rarity and variant then multiplier += rarity.incomeBonus * variant.bonusMultiplier end
				break
			end
		end
	end
	return multiplier
end

function Service.Publish(player: Player): ()
	local data = Data.Get(player)
	if not data then return end
	-- Public cosmetic summary is bounded to equipped slots. Inventory goes only to its owner.
	local summary = {}
	for _, id in data.equippedPets do
		for _, pet in data.pets do
			if pet.id == id and #summary < Config.EquipSlots then table.insert(summary, pet); break end
		end
	end
	player:SetAttribute("PetFollowers", Http:JSONEncode(summary))
	remote:FireClient(player, "State", {pets = data.pets, equipped = data.equippedPets, index = data.petIndex, multiplier = Service.Multiplier(data)})
end

function Service.Discover(player: Player, planetId: string): ()
	local data = Data.Get(player)
	local planet = Planets.ById[planetId]
	if not data or not planet or #data.pets >= Config.MaximumInventory then return end
	if random:NextNumber() >= Config.DiscoveryChance then return end
	local total = 0
	for _, name in Config.RarityOrder do total += Config.Rarities[name].weight end
	local roll = random:NextNumber() * total
	local rarity = Config.RarityOrder[#Config.RarityOrder]
	for _, name in Config.RarityOrder do
		roll -= Config.Rarities[name].weight
		if roll < 0 then rarity = name; break end
	end
	local variantRoll = random:NextNumber()
	local variant = "Normal"
	for _, name in Config.VariantOrder do
		variantRoll -= Config.Variants[name].chance
		if variantRoll < 0 then variant = name; break end
	end
	local pool = Config.Pools[planet.petPool][rarity]
	local pet = {id = Http:GenerateGUID(false), species = pool[random:NextInteger(1, #pool)], rarity = rarity, variant = variant}
	table.insert(data.pets, pet)
	data.petIndex[pet.species] = true
	Service.Publish(player)
	remote:FireClient(player, "Found", pet)
end

function Service.Init(): ()
	if remote then return end
	remote = Instance.new("RemoteEvent")
	remote.Name = "PlanetSweepersPets"
	remote.Parent = RS
	remote.OnServerEvent:Connect(function(player: Player, action: any, id: any)
		local now = os.clock()
		if now - (last[player] or -math.huge) < Config.RequestCooldown then return end
		last[player] = now
		if type(action) ~= "string" then return end
		local data = Data.Get(player)
		if not data then return end
		if action == "Sync" then Service.Publish(player); return end
		if action ~= "Equip" and action ~= "Unequip" then return end
		if type(id) ~= "string" or #id > 64 then return end
		local owned = false
		for _, pet in data.pets do if pet.id == id then owned = true; break end end
		if not owned then return end
		local position = table.find(data.equippedPets, id)
		if action == "Equip" then
			if position or #data.equippedPets >= Config.EquipSlots then return end
			table.insert(data.equippedPets, id)
		elseif position then table.remove(data.equippedPets, position) end
		Service.Publish(player)
	end)
	Players.PlayerRemoving:Connect(function(player) last[player] = nil end)
end
return Service
