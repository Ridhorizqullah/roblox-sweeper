--!strict
-- Rarity weights are conditional on discovery. Variant rolls are mutually exclusive.
return {
	DiscoveryChance = 0.015,
	EquipSlots = 3,
	MaximumInventory = 200,
	RequestCooldown = 0.25,
	VariantOrder = {"Normal", "Gold", "Rainbow"},
	Visual = {Size = 1.5, Spacing = 2.5, Behind = 4, Height = 0, FollowSpeed = 10, CullDistance = 120, ReconcileSeconds = 0.5, RevealSeconds = 5},
	RarityOrder = {"Common", "Rare", "Epic", "Legendary", "Mythic"},
	Rarities = {
		Common = {weight = 60, incomeBonus = 0.05},
		Rare = {weight = 25, incomeBonus = 0.12},
		Epic = {weight = 10, incomeBonus = 0.25},
		Legendary = {weight = 4, incomeBonus = 0.5},
		Mythic = {weight = 1, incomeBonus = 1},
	},
	Variants = {
		Normal = {chance = 0.975, bonusMultiplier = 1},
		Gold = {chance = 0.02, bonusMultiplier = 2},
		Rainbow = {chance = 0.005, bonusMultiplier = 3},
	},
	Pools = {
		Moonlet = {Common = {"Puff pebble"}, Rare = {"Orbit bun"}, Epic = {"Comet cub"}, Legendary = {"Lunar floof"}, Mythic = {"Starlit sprout"}},
		Desert = {Common = {"Sandy bean"}, Rare = {"Quartz kit"}, Epic = {"Prism pup"}, Legendary = {"Amber puff"}, Mythic = {"Solar noodle"}},
		Swamp = {Common = {"Moss blob"}, Rare = {"Glow tad"}, Epic = {"Neon newt"}, Legendary = {"Aurora slug"}, Mythic = {"Nebula bloom"}},
	},
}
