--!strict
-- First upgrade costs 23; starter income targets approximately one unit per second.
local Economy = require(script.Parent.Economy)
local base = Economy.ToolBaseCost
local growth = Economy.UpgradeCostGrowth
return {
	CostGrowth = growth,
	BaseCost = base,
	Order = {"Toothbrush", "HandBroom", "Vacuum", "LeafBlower", "PlasmaCleaner", "QuantumSweeper"},
	ById = {
		Toothbrush = {name = "Toothbrush", level = 0, power = 1, speed = 0.8, range = 12, price = 0},
		HandBroom = {name = "Hand Broom", level = 1, power = 2, speed = 0.7, range = 13, price = base * growth^1},
		Vacuum = {name = "Vacuum", level = 2, power = 4, speed = 0.6, range = 15, price = base * growth^2},
		LeafBlower = {name = "Leaf Blower", level = 3, power = 7, speed = 0.5, range = 17, price = base * growth^3},
		PlasmaCleaner = {name = "Plasma Cleaner", level = 4, power = 12, speed = 0.4, range = 20, price = base * growth^4},
		QuantumSweeper = {name = "Quantum Sweeper", level = 5, power = 20, speed = 0.3, range = 24, price = base * growth^5},
	},
}
