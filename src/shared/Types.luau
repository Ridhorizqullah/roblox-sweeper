--!strict
export type Pet = {id: string, species: string, rarity: string, variant: string}
export type PlayerData = {
	money: number, gems: number, bagCapacity: number,
	bagContents: {amount: number, baseValue: number, coopValue: number},
	equippedTool: string, ownedTools: {[string]: boolean},
	unlockedPlanets: {[string]: boolean}, ownedVehicles: {[string]: number},
	pets: {Pet}, equippedPets: {string}, totalCleaned: number,
	rebirths: number, lastSeen: number, dataVersion: number, bagLevel: number,
	currentPlanet: string, petIndex: {[string]: boolean}, lastDailyReward: number,
}
return {}
