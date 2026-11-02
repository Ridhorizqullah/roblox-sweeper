--!strict
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local Tween = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")
local Config = require(RS.Shared.config.Feedback)
local Daily = require(RS.Shared.config.Game).DailyReward
local Format = require(RS.Shared.Util.FormatNumber)

local Controller = {}
local started = false

function Controller.Start(): ()
	if started then return end
	started = true

	local player = Players.LocalPlayer
	local event = RS:WaitForChild("PlanetSweepersFeedback") :: RemoteEvent
	local state = player:WaitForChild("PlanetSweepersState")

	local gui = Instance.new("ScreenGui")
	gui.Name = "SweeperFeedback"
	gui.ResetOnSpawn = false
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

	-- Floating Daily Reward Button (Managed by HudController RightButtonStack)
	local button = Instance.new("TextButton")
	button.Name = "DailyRewardButton"
	button.AnchorPoint = Vector2.new(1, 0)
	button.Position = UDim2.new(1, -16, 0, 68)
	button.Size = UDim2.fromOffset(150, 42)
	button.BackgroundColor3 = Color3.fromRGB(24, 48, 42)
	button.TextColor3 = Color3.fromRGB(240, 255, 248)
	button.Font = Enum.Font.GothamBold
	button.TextSize = 13
	button.BorderSizePixel = 0
	button.TextWrapped = true
	button.Visible = false -- Unified in HudController right stack
	button.Parent = gui

	local btnCorner = Instance.new("UICorner")
	btnCorner.CornerRadius = UDim.new(0, 10)
	btnCorner.Parent = button

	local btnStroke = Instance.new("UIStroke")
	btnStroke.Color = Color3.fromRGB(46, 213, 115)
	btnStroke.Transparency = 0.5
	btnStroke.Thickness = 1.2
	btnStroke.Parent = button

	-- System Announcement Pill
	local messageCard = Instance.new("Frame")
	messageCard.Name = "MessageCard"
	messageCard.AnchorPoint = Vector2.new(0.5, 1)
	messageCard.Position = UDim2.fromScale(0.5, 0.86)
	messageCard.Size = UDim2.fromOffset(420, 44)
	messageCard.BackgroundColor3 = Color3.fromRGB(15, 20, 32)
	messageCard.BackgroundTransparency = 0.15
	messageCard.BorderSizePixel = 0
	messageCard.Visible = false
	messageCard.Parent = gui

	local msgCorner = Instance.new("UICorner")
	msgCorner.CornerRadius = UDim.new(0, 10)
	msgCorner.Parent = messageCard

	local msgStroke = Instance.new("UIStroke")
	msgStroke.Color = Color3.fromRGB(255, 255, 255)
	msgStroke.Transparency = 0.85
	msgStroke.Parent = messageCard

	local message = Instance.new("TextLabel")
	message.Name = "Text"
	message.Size = UDim2.fromScale(1, 1)
	message.BackgroundTransparency = 1
	message.TextColor3 = Color3.fromRGB(255, 235, 175)
	message.Font = Enum.Font.GothamMedium
	message.TextSize = 14
	message.Text = ""
	message.Parent = messageCard

	local effects = Instance.new("Folder")
	effects.Name = "LocalSweeperEffects"
	effects.Parent = workspace

	local sounds: {[string]: Sound} = {}
	for name, id in Config.Sounds do
		local cfg = Config.SoundConfigs and Config.SoundConfigs[name]
		local soundId = if cfg and cfg.Id ~= "" then cfg.Id else id
		if soundId and soundId ~= "" then
			local s = Instance.new("Sound")
			s.Name = name .. "Effect"
			s.SoundId = soundId
			s.Volume = (if cfg and cfg.Volume then cfg.Volume else 0.3) * (Config.SoundVolume or 1)
			s.Parent = gui
			sounds[name] = s
		end
	end

	local lastSoundTime: {[string]: number} = {}

	local function sound(name: string)
		local cfg = Config.SoundConfigs and Config.SoundConfigs[name]
		local baseSound = sounds[name]
		if not baseSound then return end

		-- Throttle rapid sound spam (especially when sweeping multiple dirt nodes)
		local now = os.clock()
		local lastTime = lastSoundTime[name] or 0
		local minInterval = if name == "Clean" then 0.08 else 0.05
		if now - lastTime < minInterval then
			return
		end
		lastSoundTime[name] = now

		local pMin = if cfg and cfg.PitchMin then cfg.PitchMin else 1
		local pMax = if cfg and cfg.PitchMax then cfg.PitchMax else 1
		local pitch = if pMin == pMax then pMin else (pMin + math.random() * (pMax - pMin))

		local volume = if cfg and cfg.Volume then cfg.Volume else 0.3
		baseSound.PlaybackSpeed = pitch
		baseSound.Volume = volume * (Config.SoundVolume or 1)
		SoundService:PlayLocalSound(baseSound)
	end

	local function effect(position: Vector3, text: string?)
		if #effects:GetChildren() >= Config.MaximumEffects then return end

		local part = Instance.new("Part")
		part.Anchored = true
		part.CanCollide = false
		part.CanQuery = false
		part.CanTouch = false
		part.Shape = Enum.PartType.Ball
		part.Size = Vector3.one * Config.CleanSize
		part.Position = position
		part.Material = Enum.Material.Neon
		part.Color = Color3.fromRGB(110, 255, 175)
		part.Transparency = if text then 1 else 0
		part.Parent = effects

		if text then
			local billboard = Instance.new("BillboardGui")
			billboard.Size = UDim2.fromOffset(200, 48)
			billboard.AlwaysOnTop = true
			billboard.Parent = part

			local label = Instance.new("TextLabel")
			label.Size = UDim2.fromScale(1, 1)
			label.BackgroundTransparency = 1
			label.TextColor3 = Color3.fromRGB(80, 255, 160)
			label.TextStrokeTransparency = 0.3
			label.TextStrokeColor3 = Color3.fromRGB(10, 30, 20)
			label.Font = Enum.Font.GothamBold
			label.TextSize = 24
			label.Text = text
			label.Parent = billboard
		end

		Tween:Create(part, TweenInfo.new(Config.Duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Position = position + Vector3.new(0, Config.Rise, 0),
			Transparency = 1,
			Size = part.Size * Config.CleanExpansion,
		}):Play()

		task.delay(Config.Duration, function()
			part:Destroy()
		end)
	end

	local alive = true
	local connections: {RBXScriptConnection} = {}
	local messageVersion = 0

	table.insert(connections, button.Activated:Connect(function()
		event:FireServer("ClaimDaily")
	end))

	table.insert(connections, event.OnClientEvent:Connect(function(action, payload)
		if action == "Clean" and typeof(payload) == "Vector3" then
			effect(payload, nil)
			sound("Clean")
		elseif (action == "Sell" or action == "Reward") and type(payload) == "number" then
			local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
			if root and root:IsA("BasePart") then
				effect(root.Position, "+$" .. Format.Format(payload))
			end
			sound(action)
		elseif action == "Message" and type(payload) == "string" then
			messageVersion += 1
			local version = messageVersion
			message.Text = payload
			messageCard.Visible = true
			task.delay(Config.Duration * 3, function()
				if alive and version == messageVersion then
					messageCard.Visible = false
					message.Text = ""
				end
			end)
		end
	end))

	local petEvent = RS:WaitForChild("PlanetSweepersPets") :: RemoteEvent
	table.insert(connections, petEvent.OnClientEvent:Connect(function(action)
		if action ~= "Found" then return end
		sound("Pet")
		local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
		if root and root:IsA("BasePart") then
			effect(root.Position, "PET FOUND!")
		end
	end))

	table.insert(connections, gui.Destroying:Connect(function()
		alive = false
		for _, connection in connections do connection:Disconnect() end
		effects:Destroy()
		started = false
	end))

	gui.Parent = player:WaitForChild("PlayerGui")

	task.spawn(function()
		while alive do
			local last = state:GetAttribute("LastDailyReward") or 0
			local remaining = if last == 0 then 0 else math.max(0, last + Daily.CooldownSeconds - workspace:GetServerTimeNow())
			if remaining <= 0 then
				button.Text = "🎁 Claim $" .. Format.Format(Daily.Money)
				button.BackgroundColor3 = Color3.fromRGB(24, 56, 44)
				btnStroke.Color = Color3.fromRGB(46, 213, 115)
				btnStroke.Transparency = 0.3
				button.Active = true
			else
				local h = math.floor(remaining / 3600)
				local m = math.floor(remaining / 60) % 60
				local s = math.floor(remaining) % 60
				button.Text = string.format("⏳ %02d:%02d:%02d", h, m, s)
				button.BackgroundColor3 = Color3.fromRGB(30, 36, 48)
				btnStroke.Color = Color3.fromRGB(100, 115, 140)
				btnStroke.Transparency = 0.7
				button.Active = false
			end
			button.AutoButtonColor = button.Active
			task.wait(1)
		end
	end)
end

return Controller
