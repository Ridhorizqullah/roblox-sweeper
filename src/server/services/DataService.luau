--!strict
local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("config"):WaitForChild("Data"))
local Types = require(Shared:WaitForChild("Types"))
type PlayerData = Types.PlayerData

type Record = {
	data: PlayerData?,
	token: string,
	expiresAt: number,
	busy: boolean,
	loading: boolean,
	invalid: boolean,
}
local Service = {}
local records: {[Player]: Record} = {}
local initialized = false
local closing = false
local shutdownDeadline = math.huge
local store: any = nil
local ephemeral: {[string]: any} = {}

local function clone(value: any): any
	if type(value) ~= "table" then return value end
	local result = {}
	for key, item in pairs(value) do result[key] = clone(item) end
	return result
end

local function defaults(): any
	local data = clone(Config.Default)
	data.dataVersion = Config.Version
	return data
end

local function number(value: any): boolean
	return type(value) == "number" and value == value and value >= 0 and value < math.huge
end
local function stringMap(value: any, kind: string): boolean
	if type(value) ~= "table" then return false end
	for key, item in pairs(value) do
		if type(key) ~= "string" then return false end
		if kind == "number" then
			if not number(item) then return false end
		elseif type(item) ~= kind then return false end
	end
	return true
end
local function array(value: any, check: (any) -> boolean): boolean
	if type(value) ~= "table" then return false end
	local count = 0
	for key, item in pairs(value) do
		if type(key) ~= "number" or key % 1 ~= 0 or key < 1 or not check(item) then return false end
		count += 1
	end
	return count == #value
end

-- Conservative structural checks reject malformed known fields and unknown versions.
-- Pet contents remain opaque to this service, but must be finite, serializable tables.
local function serializable(value: any, depth: number): boolean
	if depth > 20 then return false end
	local kind = type(value)
	if kind == "number" then return value == value and math.abs(value) < math.huge end
	if kind == "string" or kind == "boolean" then return true end
	if kind ~= "table" then return false end
	for key, item in pairs(value) do
		if type(key) ~= "string" and type(key) ~= "number" then return false end
		if not serializable(key, depth + 1) or not serializable(item, depth + 1) then return false end
	end
	return true
end
local function decode(raw: any): PlayerData?
	if type(raw) ~= "table" or not serializable(raw, 0) then return nil end
	if raw.dataVersion ~= 0 and raw.dataVersion ~= Config.Version then return nil end
	local data = clone(raw)
	if data.dataVersion == 0 then
		for key, value in pairs(defaults()) do
			if data[key] == nil then data[key] = clone(value) end
		end
		data.dataVersion = Config.Version
	end
	for _, key in ipairs({"money", "gems", "bagCapacity", "totalCleaned", "rebirths", "lastSeen", "bagLevel", "lastDailyReward"}) do
		if not number(data[key]) then return nil end
	end
	if type(data.bagContents) ~= "table" then return nil end
	for _, key in ipairs({"amount", "baseValue", "coopValue"}) do
		if not number(data.bagContents[key]) then return nil end
	end
	if type(data.equippedTool) ~= "string" or type(data.currentPlanet) ~= "string" then return nil end
	for _, key in ipairs({"ownedTools", "unlockedPlanets", "petIndex"}) do
		if not stringMap(data[key], "boolean") then return nil end
	end
	if not stringMap(data.ownedVehicles, "number") then return nil end
	if not array(data.equippedPets, function(item) return type(item) == "string" end) then return nil end
	if not array(data.pets, function(item) return type(item) == "table" and serializable(item, 0) end) then return nil end
	return data :: PlayerData
end

local function update(key: string, transform: (any) -> any): (boolean, any)
	for attempt = 1, Config.RetryAttempts do
		if os.clock() >= shutdownDeadline then break end
		local ok, result = pcall(function()
			if store then return store:UpdateAsync(key, transform) end
			local value = transform(clone(ephemeral[key]))
			if value ~= nil then ephemeral[key] = clone(value) end
			return clone(value)
		end)
		if ok then return true, result end
		warn("[DataService] UpdateAsync failed:", result)
		if attempt < Config.RetryAttempts then
			local delay = math.min(Config.RetryDelaySeconds * 2 ^ (attempt - 1), math.max(0, shutdownDeadline - os.clock()))
			task.wait(delay)
		end
	end
	return false, nil
end

local function invalidate(player: Player, record: Record, reason: string)
	record.invalid = true
	record.data = nil
	if player.Parent == Players then player:Kick(reason) end
end
local function acquire(record: Record): boolean
	local deadline = math.min(os.clock() + Config.ShutdownSeconds, shutdownDeadline)
	while record.busy do
		if os.clock() >= deadline then return false end
		task.wait(0.05)
	end
	record.busy = true
	return true
end

function Service.IsClosing(): boolean
	return closing
end
function Service.Get(player: Player): PlayerData?
	local record = records[player]
	if closing or not record or record.invalid or record.loading then return nil end
	if os.time() >= record.expiresAt - Config.LockSafetySeconds then
		invalidate(player, record, "Your data session expired. Please rejoin.")
		return nil
	end
	return record.data
end

function Service.Save(player: Player, release: boolean?): boolean
	local record = records[player]
	if not record or not acquire(record) then return false end
	if record.invalid or record.loading or not record.data then record.busy = false; return false end
	if os.time() >= record.expiresAt - Config.LockSafetySeconds then
		invalidate(player, record, "Your data session expired. Please rejoin.")
		record.busy = false
		return false
	end
	-- Snapshot only after obtaining the per-player save mutex.
	local snapshot = decode(record.data)
	if not snapshot then
		invalidate(player, record, "Your data could not be saved safely. Please rejoin.")
		record.busy = false
		return false
	end
	snapshot.lastSeen = os.time()
	local denied = false
	local ok, result = update("Player_" .. player.UserId, function(old)
		denied = false
		if type(old) ~= "table" or type(old.session) ~= "table"
			or old.session.id ~= record.token or not number(old.session.expiresAt)
			or old.session.expiresAt <= os.time() + Config.LockSafetySeconds then
			denied = true
			return nil
		end
		return {data = snapshot, session = if release then nil else {id = record.token, expiresAt = os.time() + Config.LockSeconds}}
	end)
	local saved = ok and result ~= nil and not denied
	if saved then
		if release then
			record.invalid = true
			record.data = nil
			if records[player] == record then records[player] = nil end
		else
			record.expiresAt = result.session.expiresAt
		end
	elseif denied or os.time() >= record.expiresAt - Config.LockSafetySeconds then
		invalidate(player, record, "Your data session was lost. Please rejoin.")
	end
	record.busy = false
	return saved
end

function Service.Release(player: Player)
	Service.Save(player, true)
	local record = records[player]
	if record and not record.loading and not record.busy then
		-- Failed releases leave the stored lease to expire, never clear another owner.
		record.invalid = true
		record.data = nil
		records[player] = nil
	end
end

function Service.Load(player: Player): PlayerData?
	if not initialized then Service.Init() end
	if closing then player:Kick("Server is shutting down. Please rejoin."); return nil end
	if records[player] then return Service.Get(player) end
	local record: Record = {data = nil, token = HttpService:GenerateGUID(false), expiresAt = 0, busy = true, loading = true, invalid = false}
	records[player] = record
	local ok, result = update("Player_" .. player.UserId, function(old)
		local data: PlayerData?
		if old == nil then
			data = defaults()
		elseif type(old) == "table" then
			data = decode(old.data)
			if old.session ~= nil then
				local session = old.session
				if type(session) ~= "table" or type(session.id) ~= "string" or not number(session.expiresAt) then return nil end
				if session.id ~= record.token and session.expiresAt > os.time() then return nil end
			end
		end
		if not data then return nil end
		return {data = data, session = {id = record.token, expiresAt = os.time() + Config.LockSeconds}}
	end)
	record.loading = false
	record.busy = false
	if not ok or not result or result.session.id ~= record.token then
		invalidate(player, record, "Your data could not be loaded safely. Please rejoin shortly.")
		return nil
	end
	record.data = result.data
	record.expiresAt = result.session.expiresAt
	if player.Parent ~= Players or closing then Service.Release(player); return nil end
	return Service.Get(player)
end

function Service.Init()
	if initialized then return end
	initialized = true
	if RunService:IsStudio() and not Config.UseStudioDataStore then
		warn("[DataService] Studio memory mode: data is EPHEMERAL and will not persist between sessions.")
	else
		local ok, result = pcall(function()
			return DataStoreService:GetDataStore(if RunService:IsStudio() then Config.StudioStoreName else Config.StoreName)
		end)
		if not ok then
			closing = true
			warn("[DataService] Persistent storage initialization failed:", result)
		else
			store = result
		end
	end
	Players.PlayerRemoving:Connect(function(player) Service.Release(player) end)
	task.spawn(function()
		local nextSave = os.clock() + Config.AutosaveSeconds
		while not closing do
			task.wait(1)
			for player in pairs(records) do Service.Get(player) end
			if os.clock() >= nextSave then
				nextSave = os.clock() + Config.AutosaveSeconds
				for player in pairs(records) do task.spawn(Service.Save, player, false) end
			end
		end
	end)
	game:BindToClose(function()
		closing = true
		shutdownDeadline = os.clock() + Config.ShutdownSeconds
		local pending = 0
		for player in pairs(records) do
			pending += 1
			task.spawn(function()
				Service.Release(player)
				pending -= 1
			end)
		end
		while pending > 0 and os.clock() < shutdownDeadline do task.wait(0.05) end
	end)
end

return Service
