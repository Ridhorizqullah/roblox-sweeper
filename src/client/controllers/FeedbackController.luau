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
	local button = Instance.new("TextButton")
	button.AnchorPoint = Vector2.new(1, 0)
	button.Position = UDim2.new(1, -16, 0, 72)
	button.Size = UDim2.fromOffset(150, 48)
	button.BackgroundColor3 = Color3.fromRGB(65, 120, 100)
	button.TextColor3 = Color3.new(1, 1, 1)
	button.TextWrapped = true
	button.Parent = gui
	local message = Instance.new("TextLabel")
	message.AnchorPoint = Vector2.new(0.5, 1)
	message.Position = UDim2.fromScale(0.5, 0.85)
	message.Size = UDim2.fromScale(0.8, 0.08)
	message.BackgroundTransparency = 1
	message.TextColor3 = Color3.new(1, 1, 1)
	message.TextSize = 22
	message.Text = ""
	message.Parent = gui
	local effects = Instance.new("Folder")
	effects.Name = "LocalSweeperEffects"
	effects.Parent = workspace
	local sounds: {[string]: Sound} = {}
	for name, id in Config.Sounds do
		local sound = Instance.new("Sound")
		sound.Name = name .. "Placeholder"
		sound.SoundId = id
		sound.Volume = Config.SoundVolume
		sound.Parent = gui
		sounds[name] = sound
	end
	local function sound(name: string)
		local value = sounds[name]
		if value and value.SoundId ~= "" then SoundService:PlayLocalSound(value) end
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
			label.TextColor3 = part.Color
			label.TextStrokeTransparency = 0
			label.TextSize = 26
			label.Text = text
			label.Parent = billboard
		end
		Tween:Create(part, TweenInfo.new(Config.Duration), {Position = position + Vector3.new(0, Config.Rise, 0), Transparency = 1, Size = part.Size * Config.CleanExpansion}):Play()
		task.delay(Config.Duration, function() part:Destroy() end)
	end
	local alive = true
	local connections: {RBXScriptConnection} = {}
	local messageVersion = 0
	table.insert(connections, button.Activated:Connect(function() event:FireServer("ClaimDaily") end))
	table.insert(connections, event.OnClientEvent:Connect(function(action, payload)
		if action == "Clean" and typeof(payload) == "Vector3" then effect(payload, nil); sound("Clean")
		elseif (action == "Sell" or action == "Reward") and type(payload) == "number" then
			local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
			if root and root:IsA("BasePart") then effect(root.Position, "+$" .. Format.Format(payload)) end
			sound(action)
		elseif action == "Message" and type(payload) == "string" then
			messageVersion += 1
			local version = messageVersion
			message.Text = payload
			task.delay(Config.Duration * 3, function() if alive and version == messageVersion then message.Text = "" end end)
		end
	end))
	local petEvent = RS:WaitForChild("PlanetSweepersPets") :: RemoteEvent
	table.insert(connections, petEvent.OnClientEvent:Connect(function(action)
		if action ~= "Found" then return end
		sound("Pet")
		local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
		if root and root:IsA("BasePart") then effect(root.Position, "PET FOUND!") end
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
			button.Text = if remaining <= 0 then "Claim daily $" .. Format.Format(Daily.Money) else string.format("Daily %02d:%02d:%02d", math.floor(remaining / 3600), math.floor(remaining / 60) % 60, math.floor(remaining) % 60)
			button.Active = remaining <= 0
			button.AutoButtonColor = button.Active
			task.wait(1)
		end
	end)
end
return Controller
