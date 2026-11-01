--!strict
local Players = game:GetService("Players")
local Config = require(game:GetService("ReplicatedStorage").Shared.config.Vehicles)
local Data = require(script.Parent.DataService)
local Cleaning = require(script.Parent.CleaningService)
local Service = {}
type Robot = {part: Part, nextAction: number}
local robots: {[Player]: {[string]: Robot}} = {}
local running = false
local function clear(player: Player)
	local owned = robots[player]
	if owned then for _, robot in owned do robot.part:Destroy() end end
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
				if not data or not root or not root:IsA("BasePart") or not humanoid or humanoid.Health <= 0 then clear(player); continue end
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
						if not robot then
							local part = Instance.new("Part")
							part.Name = player.Name .. "_" .. key
							part.Size = Config.VisualSize
							part.Anchored = true
							part.CanCollide = false
							part.CanTouch = false
							part.CanQuery = false
							part.Color = Color3.fromRGB(90, 180, 220)
							part.Parent = workspace
							robot = {part = part, nextAction = os.clock() + Config.ById[id].speed}
							owned[key] = robot
						end
						robot.part.CFrame = root.CFrame * CFrame.new(slot * Config.VisualSpacing, -1, Config.VisualBehind)
						if os.clock() >= robot.nextAction then
							robot.nextAction = os.clock() + Config.ById[id].speed
							Cleaning.RobotClean(player, id)
						end
					end
				end
				for key, robot in owned do if not active[key] then robot.part:Destroy(); owned[key] = nil end end
			end
		end
	end)
end
return Service
