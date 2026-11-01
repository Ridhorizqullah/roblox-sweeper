--!strict
return {
	Version = 1,
	StoreName = "PlanetSweepers_v1",
	StudioStoreName = "PlanetSweepers_TEST_v1",
	UseStudioDataStore = false,
	AutosaveSeconds = 60,
	LockSeconds = 180,
	LockSafetySeconds = 30,
	RetryAttempts = 3,
	RetryDelaySeconds = 2,
	ShutdownSeconds = 25,
	Default = {
		money = 0, gems = 0, bagCapacity = 25,
		bagContents = {amount = 0, baseValue = 0, coopValue = 0},
		equippedTool = "Toothbrush", ownedTools = {Toothbrush = true},
		unlockedPlanets = {DustyMoonlet = true}, ownedVehicles = {},
		pets = {}, equippedPets = {}, totalCleaned = 0, rebirths = 0,
		lastSeen = 0, dataVersion = 1, bagLevel = 0,
		currentPlanet = "DustyMoonlet", petIndex = {}, lastDailyReward = 0,
	},
}
