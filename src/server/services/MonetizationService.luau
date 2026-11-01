--!strict
local Config = require(game:GetService("ReplicatedStorage").Shared.config.Monetization)
local Service = {}

-- TODO LIVE: implement a server-only entitlement cache populated by
-- MarketplaceService:UserOwnsGamePassAsync inside pcall with bounded retries.
-- On failure keep benefits unverified; never accept ownership from client attributes.
-- Recheck on purchase completion, publish updated HUD state, and clean cache on leave.
-- Deliberately false even when IDs/Enabled are changed: this phase cannot sell passes.
local function ownsPass(_player: Player, _passId: number): boolean
	return false
end

function Service.GetMoneyMultiplier(player: Player): number
	if Config.Enabled and ownsPass(player, Config.DoubleMoneyPassId) then
		return Config.MoneyMultiplier
	end
	return 1
end

function Service.GetBagCapacity(player: Player, baseCapacity: number): number
	if Config.Enabled and ownsPass(player, Config.BiggerBagPassId) then
		return math.floor(baseCapacity * Config.BagMultiplier)
	end
	return baseCapacity
end

function Service.RequestPurchase(_player: Player, pass: string): (boolean, string)
	if pass ~= "DoubleMoney" and pass ~= "BiggerBag" then return false, "INVALID_PASS" end
	-- TODO LIVE: add a rate-limited, allowlisted server request and official purchase prompt.
	-- A prompt-close notification alone must never grant benefits without server revalidation.
	return false, "NOT_IMPLEMENTED"
end

return Service
