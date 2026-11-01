--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local DataConfig = require(Shared:WaitForChild("config"):WaitForChild("Data"))
local Types = require(Shared:WaitForChild("Types"))
type PlayerData = Types.PlayerData
type DataService = { Get: (Player) -> PlayerData? }

local Service = {}
local dataService: DataService? = nil

function Service.Init(service: DataService): ()
	dataService = service
end

function Service.Publish(player: Player): ()
	local service = dataService
	assert(service, "PlayerStateService.Init must be called before Publish")
	local data = service.Get(player)
	local existing = player:FindFirstChild("PlanetSweepersState")
	if existing and not existing:IsA("Folder") then
		warn("PlanetSweepersState must be a Folder")
		return
	end
	local folder = existing or Instance.new("Folder")
	folder.Name = "PlanetSweepersState"
	folder:SetAttribute("DataReady", false)
	folder:SetAttribute("Money", if data then data.money else 0)
	folder:SetAttribute("BagLevel", if data then data.bagLevel else 0)
	folder:SetAttribute("EquippedTool", if data then data.equippedTool else "")
	if data then
		for id, count in data.ownedVehicles do folder:SetAttribute("Robot_" .. id, count) end
		for id, owned in data.ownedTools do folder:SetAttribute("Owned_" .. id, owned) end
	end
	folder:SetAttribute("BagAmount", if data then data.bagContents.amount else 0)
	folder:SetAttribute("BagCapacity", if data then data.bagCapacity else 0)
	folder:SetAttribute("Planet", if data then data.currentPlanet else "")
	folder:SetAttribute("StorageMode", if RunService:IsStudio() and not DataConfig.UseStudioDataStore then "Temporary" else "Persistent")
	if not existing then
		folder.Parent = player
	end
	folder:SetAttribute("DataReady", data ~= nil)
end

return Service
