--!strict
local Economy = require(script.Parent.Economy)
local Data = require(script.Parent.Data)
return {BaseCapacity = Data.Default.bagCapacity, CapacityPerLevel = 15, BaseCost = Economy.BagBaseCost, CostGrowth = Economy.UpgradeCostGrowth, MaximumLevel = 100}
