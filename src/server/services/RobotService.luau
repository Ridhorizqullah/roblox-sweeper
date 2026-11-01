--!strict
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local Config = require(RS.Shared.config.Vehicles)
local Data = require(script.Parent.DataService)
local Cleaning = require(script.Parent.CleaningService)
local SweeperVehicleBuilder = require(RS.Shared.art.SweeperVehicleBuilder)

local Service = {}
type Robot = {model: Model, nextAction: number}
local robots: {[Player]: {[string]: Robot}} = {}
local running = false

local function clear(player: Player)
	local owned = robots[player]
	if owned then
		for _, robot in owned do
			robot.model:Destroy()
		end
	end
	robots[player] = nil
end

function Service.Init(): ()
	if running then return end
	running = true
	local leaving = Players.PlayerRemoving:Connect(clear)
	game:BindToClose(function()
		running = false
		leaving:Disconnect()
		for player in robots do clear(player) end
	end)

	task.spawn(function()
		while running do
			task.wait(Config.TickSeconds)
			if not running then break end
			for _, player in Players:GetPlayers() do
				local data = Data.Get(player)
				local character = player.Character
				local root = character and character:FindFirstChild("HumanoidRootPart")
				local humanoid = character and character:FindFirstChildOfClass("Humanoid")
				if not data or not root or not root:IsA("BasePart") or not humanoid or humanoid.Health <= 0 then
					clear(player)
					continue
				end
				local owned = robots[player] or {}
				robots[player] = owned
				local active: {[string]: boolean} = {}
				local slot = 0
				for _, id in Config.Order do
					local count = math.min(data.ownedVehicles[id] or 0, Config.MaximumRobots - slot)
					for index = 1, count do
						slot += 1
						local key = id .. index
						active[key] = true
						local robot = owned[key]
						local targetCF = root.CFrame * CFrame.new(slot * Config.VisualSpacing, -0.6, Config.VisualBehind)
						if not robot then
							local model = SweeperVehicleBuilder.BuildSweeperBot(player.Name .. "_" .. key, workspace, targetCF)
							robot = {model = model, nextAction = os.clock() + Config.ById[id].speed}
							owned[key] = robot
						end
						robot.model:PivotTo(targetCF)
						if os.clock() >= robot.nextAction then
							robot.nextAction = os.clock() + Config.ById[id].speed
							Cleaning.RobotClean(player, id)
						end
					end
				end
				for key, robot in owned do
					if not active[key] then
						robot.model:Destroy()
						owned[key] = nil
					end
				end
			end
		end
	end)
end

return Service
