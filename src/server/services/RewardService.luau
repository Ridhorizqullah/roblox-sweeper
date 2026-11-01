--!strict
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local Config = require(RS.Shared.config.Game).DailyReward
local Feedback = require(RS.Shared.config.Feedback)
local Data = require(script.Parent.DataService)
local State = require(script.Parent.PlayerStateService)
local Service = {}
local last: {[Player]: number} = {}
local remote: RemoteEvent? = nil
function Service.Init(): ()
	if remote then return end
	local event = Instance.new("RemoteEvent")
	event.Name = "PlanetSweepersFeedback"
	event.Parent = RS
	remote = event
	local request = event.OnServerEvent:Connect(function(player: Player, action: any)
		local now = os.clock()
		if now - (last[player] or -math.huge) < Feedback.RequestCooldown then return end
		last[player] = now
		if action ~= "ClaimDaily" then return end
		local data = Data.Get(player)
		if not data then return end
		local timestamp = os.time()
		if data.lastDailyReward > 0 and timestamp - data.lastDailyReward < Config.CooldownSeconds then
			event:FireClient(player, "Message", "Daily reward belum tersedia.")
			return
		end
		-- Timestamp and money mutate together without yielding. Repeated requests cannot double-award.
		data.lastDailyReward = timestamp
		data.money += Config.Money
		State.Publish(player)
		event:FireClient(player, "Reward", Config.Money)
		task.spawn(function() Data.Save(player) end)
	end)
	local leaving = Players.PlayerRemoving:Connect(function(player) last[player] = nil end)
	game:BindToClose(function() request:Disconnect(); leaving:Disconnect(); table.clear(last) end)
end
function Service.Emit(player: Player, action: string, payload: any): ()
	if remote and player.Parent == Players then remote:FireClient(player, action, payload) end
end
return Service
