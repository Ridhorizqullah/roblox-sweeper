--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local StarterGui = game:GetService("StarterGui")

-- Requirement 7: Disable default Roblox backpack to prevent duplicate tool hotbar slots
task.spawn(function()
	local tries = 0
	while tries < 15 do
		local ok = pcall(function()
			StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)
		end)
		if ok then break end
		tries += 1
		task.wait(0.2)
	end
end)

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = Shared:WaitForChild("config")
local Planets = require(Config:WaitForChild("Planets"))
local Tools = require(Config:WaitForChild("Tools"))
local GameConfig = require(Config:WaitForChild("Game"))
local FormatNumber = require(Shared:WaitForChild("Util"):WaitForChild("FormatNumber"))

local Controller = {}
local activeGui: ScreenGui? = nil

local function disconnectAll(connections: {RBXScriptConnection})
	for _, connection in connections do
		connection:Disconnect()
	end
	table.clear(connections)
end

local function nonnegative(value: any): number?
	if typeof(value) == "number" and value == value and value >= 0 and value < math.huge then
		return value
	end
	return nil
end

function Controller.Start(): ()
	if activeGui then return end
	local player = Players.LocalPlayer
	local playerGui = player:WaitForChild("PlayerGui")
	if activeGui then return end

	local gui = Instance.new("ScreenGui")
	gui.Name = "PlanetSweepersHud"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = false
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	activeGui = gui

	local connections: {RBXScriptConnection} = {}
	local stateConnections: {RBXScriptConnection} = {}
	local state: Folder? = nil
	local destroyed = false

	-- =========================================================================
	-- 1. TOP-LEFT: Money + Planet Name (Compact panel, no wasted space)
	-- Positioned safely below the Roblox core topbar icons (Y = 52)
	-- =========================================================================
	local topLeftPanel = Instance.new("Frame")
	topLeftPanel.Name = "TopLeftCompactPanel"
	topLeftPanel.Position = UDim2.new(0, 14, 0, 52)
	topLeftPanel.Size = UDim2.fromOffset(190, 64)
	topLeftPanel.BackgroundColor3 = Color3.fromRGB(15, 20, 32)
	topLeftPanel.BackgroundTransparency = 0.15
	topLeftPanel.BorderSizePixel = 0
	topLeftPanel.Parent = gui

	local tlCorner = Instance.new("UICorner")
	tlCorner.CornerRadius = UDim.new(0, 10)
	tlCorner.Parent = topLeftPanel

	local tlStroke = Instance.new("UIStroke")
	tlStroke.Color = Color3.fromRGB(255, 255, 255)
	tlStroke.Transparency = 0.85
	tlStroke.Thickness = 1.2
	tlStroke.Parent = topLeftPanel

	local tlPad = Instance.new("UIPadding")
	tlPad.PaddingTop = UDim.new(0, 6)
	tlPad.PaddingBottom = UDim.new(0, 6)
	tlPad.PaddingLeft = UDim.new(0, 10)
	tlPad.PaddingRight = UDim.new(0, 10)
	tlPad.Parent = topLeftPanel

	local tlLayout = Instance.new("UIListLayout")
	tlLayout.SortOrder = Enum.SortOrder.LayoutOrder
	tlLayout.Padding = UDim.new(0, 4)
	tlLayout.Parent = topLeftPanel

	-- Row 1: Money
	local moneyRow = Instance.new("Frame")
	moneyRow.Name = "MoneyRow"
	moneyRow.LayoutOrder = 1
	moneyRow.Size = UDim2.new(1, 0, 0, 24)
	moneyRow.BackgroundTransparency = 1
	moneyRow.Parent = topLeftPanel

	local moneyIcon = Instance.new("TextLabel")
	moneyIcon.Size = UDim2.fromOffset(20, 24)
	moneyIcon.BackgroundTransparency = 1
	moneyIcon.Font = Enum.Font.GothamBold
	moneyIcon.Text = "$"
	moneyIcon.TextColor3 = Color3.fromRGB(255, 215, 0)
	moneyIcon.TextSize = 18
	moneyIcon.TextXAlignment = Enum.TextXAlignment.Left
	moneyIcon.Parent = moneyRow

	local moneyLabel = Instance.new("TextLabel")
	moneyLabel.Name = "MoneyLabel"
	moneyLabel.Position = UDim2.new(0, 22, 0, 0)
	moneyLabel.Size = UDim2.new(1, -22, 1, 0)
	moneyLabel.BackgroundTransparency = 1
	moneyLabel.Font = Enum.Font.GothamBold
	moneyLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	moneyLabel.TextSize = 16
	moneyLabel.TextXAlignment = Enum.TextXAlignment.Left
	moneyLabel.TextTruncate = Enum.TextTruncate.AtEnd
	moneyLabel.Text = "$ 0"
	moneyLabel.Parent = moneyRow

	-- Row 2: Planet
	local planetRow = Instance.new("Frame")
	planetRow.Name = "PlanetRow"
	planetRow.LayoutOrder = 2
	planetRow.Size = UDim2.new(1, 0, 0, 22)
	planetRow.BackgroundTransparency = 1
	planetRow.Parent = topLeftPanel

	local planetIcon = Instance.new("TextLabel")
	planetIcon.Size = UDim2.fromOffset(20, 22)
	planetIcon.BackgroundTransparency = 1
	planetIcon.Font = Enum.Font.GothamMedium
	planetIcon.Text = "🪐"
	planetIcon.TextSize = 14
	planetIcon.TextXAlignment = Enum.TextXAlignment.Left
	planetIcon.Parent = planetRow

	local planetLabel = Instance.new("TextLabel")
	planetLabel.Name = "PlanetLabel"
	planetLabel.Position = UDim2.new(0, 22, 0, 0)
	planetLabel.Size = UDim2.new(1, -22, 1, 0)
	planetLabel.BackgroundTransparency = 1
	planetLabel.Font = Enum.Font.GothamMedium
	planetLabel.TextColor3 = Color3.fromRGB(80, 227, 194)
	planetLabel.TextSize = 13
	planetLabel.TextXAlignment = Enum.TextXAlignment.Left
	planetLabel.TextTruncate = Enum.TextTruncate.AtEnd
	planetLabel.Text = "Dusty Moonlet"
	planetLabel.Parent = planetRow

	-- =========================================================================
	-- 2. TOP-CENTER: Bag Bar (Scale based with min/max constraint)
	-- =========================================================================
	local bagBarPanel = Instance.new("Frame")
	bagBarPanel.Name = "TopCenterBagBar"
	bagBarPanel.AnchorPoint = Vector2.new(0.5, 0)
	bagBarPanel.Position = UDim2.new(0.5, 0, 0, 52)
	bagBarPanel.Size = UDim2.new(0.32, 0, 0, 52)
	bagBarPanel.BackgroundColor3 = Color3.fromRGB(15, 20, 32)
	bagBarPanel.BackgroundTransparency = 0.15
	bagBarPanel.BorderSizePixel = 0
	bagBarPanel.Parent = gui

	local bagConstraint = Instance.new("UISizeConstraint")
	bagConstraint.MinSize = Vector2.new(200, 52)
	bagConstraint.MaxSize = Vector2.new(340, 52)
	bagConstraint.Parent = bagBarPanel

	local bbCorner = Instance.new("UICorner")
	bbCorner.CornerRadius = UDim.new(0, 10)
	bbCorner.Parent = bagBarPanel

	local bbStroke = Instance.new("UIStroke")
	bbStroke.Color = Color3.fromRGB(255, 255, 255)
	bbStroke.Transparency = 0.85
	bbStroke.Thickness = 1.2
	bbStroke.Parent = bagBarPanel

	local bbPad = Instance.new("UIPadding")
	bbPad.PaddingTop = UDim.new(0, 6)
	bbPad.PaddingBottom = UDim.new(0, 8)
	bbPad.PaddingLeft = UDim.new(0, 12)
	bbPad.PaddingRight = UDim.new(0, 12)
	bbPad.Parent = bagBarPanel

	local bagTitle = Instance.new("TextLabel")
	bagTitle.Name = "Title"
	bagTitle.Size = UDim2.new(0.65, 0, 0, 18)
	bagTitle.BackgroundTransparency = 1
	bagTitle.Font = Enum.Font.GothamBold
	bagTitle.TextColor3 = Color3.fromRGB(235, 242, 255)
	bagTitle.TextSize = 13
	bagTitle.TextXAlignment = Enum.TextXAlignment.Left
	bagTitle.Text = "🎒 Bag: 0 / 25"
	bagTitle.Parent = bagBarPanel

	local bagPercentTag = Instance.new("TextLabel")
	bagPercentTag.Name = "PercentTag"
	bagPercentTag.Size = UDim2.new(0.35, 0, 0, 18)
	bagPercentTag.Position = UDim2.new(0.65, 0, 0, 0)
	bagPercentTag.BackgroundTransparency = 1
	bagPercentTag.Font = Enum.Font.GothamBold
	bagPercentTag.TextColor3 = Color3.fromRGB(46, 213, 115)
	bagPercentTag.TextSize = 12
	bagPercentTag.TextXAlignment = Enum.TextXAlignment.Right
	bagPercentTag.Text = "0%"
	bagPercentTag.Parent = bagBarPanel

	local track = Instance.new("Frame")
	track.Name = "Track"
	track.Position = UDim2.new(0, 0, 0, 22)
	track.Size = UDim2.new(1, 0, 0, 12)
	track.BackgroundColor3 = Color3.fromRGB(28, 36, 54)
	track.BorderSizePixel = 0
	track.ClipsDescendants = true
	track.Parent = bagBarPanel

	local trackCorner = Instance.new("UICorner")
	trackCorner.CornerRadius = UDim.new(1, 0)
	trackCorner.Parent = track

	local fill = Instance.new("Frame")
	fill.Name = "Fill"
	fill.Size = UDim2.fromScale(0, 1)
	fill.BackgroundColor3 = Color3.fromRGB(46, 213, 115)
	fill.BorderSizePixel = 0
	fill.Parent = track

	local fillCorner = Instance.new("UICorner")
	fillCorner.CornerRadius = UDim.new(1, 0)
	fillCorner.Parent = fill

	-- =========================================================================
	-- 3. RIGHT SIDE: Vertical stack of buttons (Shop, Pets, Daily)
	-- Equal spacing, large mobile tap targets (>= 44px)
	-- =========================================================================
	local rightStack = Instance.new("Frame")
	rightStack.Name = "RightButtonStack"
	rightStack.AnchorPoint = Vector2.new(1, 0.5)
	rightStack.Position = UDim2.new(1, -16, 0.5, 0)
	rightStack.Size = UDim2.fromOffset(116, 168)
	rightStack.BackgroundTransparency = 1
	rightStack.Parent = gui

	local stackLayout = Instance.new("UIListLayout")
	stackLayout.FillDirection = Enum.FillDirection.Vertical
	stackLayout.SortOrder = Enum.SortOrder.LayoutOrder
	stackLayout.Padding = UDim.new(0, 12)
	stackLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
	stackLayout.Parent = rightStack

	local function makeStackButton(name: string, text: string, order: number, bgCol: Color3, strokeCol: Color3): TextButton
		local btn = Instance.new("TextButton")
		btn.Name = name
		btn.LayoutOrder = order
		btn.Size = UDim2.fromOffset(114, 46)
		btn.BackgroundColor3 = bgCol
		btn.BorderSizePixel = 0
		btn.Font = Enum.Font.GothamBold
		btn.TextSize = 13
		btn.TextColor3 = Color3.fromRGB(245, 250, 255)
		btn.Text = text
		btn.AutoButtonColor = true
		btn.Parent = rightStack

		local bCorner = Instance.new("UICorner")
		bCorner.CornerRadius = UDim.new(0, 10)
		bCorner.Parent = btn

		local bStroke = Instance.new("UIStroke")
		bStroke.Color = strokeCol
		bStroke.Transparency = 0.5
		bStroke.Thickness = 1.2
		bStroke.Parent = btn

		return btn
	end

	local shopButton = makeStackButton("ShopButton", "🛒 SHOP", 1, Color3.fromRGB(24, 34, 56), Color3.fromRGB(80, 130, 220))
	local petsButton = makeStackButton("PetsButton", "🐾 PETS", 2, Color3.fromRGB(36, 26, 54), Color3.fromRGB(165, 94, 234))
	local dailyButton = makeStackButton("DailyButton", "🎁 DAILY", 3, Color3.fromRGB(24, 48, 42), Color3.fromRGB(46, 213, 115))

	-- Button interactions
	table.insert(connections, shopButton.Activated:Connect(function()
		local shopGui = playerGui:FindFirstChild("PlanetSweepersShopUI")
		if shopGui and shopGui:IsA("ScreenGui") then
			shopGui.Enabled = not shopGui.Enabled
		else
			local remote = ReplicatedStorage:FindFirstChild("PlanetSweepersShop")
			if remote and remote:IsA("RemoteEvent") then remote:FireServer("Open") end
		end
	end))

	table.insert(connections, petsButton.Activated:Connect(function()
		local petGui = playerGui:FindFirstChild("PetInventory")
		if petGui and petGui:IsA("ScreenGui") then
			local panel = petGui:FindFirstChild("PetPanel")
			local backdrop = petGui:FindFirstChild("Backdrop")
			if panel and panel:IsA("GuiObject") then
				panel.Visible = not panel.Visible
				if backdrop and backdrop:IsA("GuiObject") then
					backdrop.Visible = panel.Visible
				end
			end
		end
	end))

	table.insert(connections, dailyButton.Activated:Connect(function()
		local remote = ReplicatedStorage:FindFirstChild("PlanetSweepersFeedback")
		if remote and remote:IsA("RemoteEvent") then
			remote:FireServer("ClaimDaily")
		end
	end))

	-- =========================================================================
	-- 4. BOTTOM-CENTER: Hotbar (Equipped tool specs badge)
	-- =========================================================================
	local hotbarPanel = Instance.new("Frame")
	hotbarPanel.Name = "BottomCenterHotbar"
	hotbarPanel.AnchorPoint = Vector2.new(0.5, 1)
	hotbarPanel.Position = UDim2.new(0.5, 0, 1, -14)
	hotbarPanel.Size = UDim2.new(0.34, 0, 0, 48)
	hotbarPanel.BackgroundColor3 = Color3.fromRGB(15, 20, 32)
	hotbarPanel.BackgroundTransparency = 0.15
	hotbarPanel.BorderSizePixel = 0
	hotbarPanel.Parent = gui

	local hbConstraint = Instance.new("UISizeConstraint")
	hbConstraint.MinSize = Vector2.new(220, 48)
	hbConstraint.MaxSize = Vector2.new(340, 48)
	hbConstraint.Parent = hotbarPanel

	local hbCorner = Instance.new("UICorner")
	hbCorner.CornerRadius = UDim.new(0, 10)
	hbCorner.Parent = hotbarPanel

	local hbStroke = Instance.new("UIStroke")
	hbStroke.Color = Color3.fromRGB(255, 255, 255)
	hbStroke.Transparency = 0.88
	hbStroke.Thickness = 1.2
	hbStroke.Parent = hotbarPanel

	local hbPad = Instance.new("UIPadding")
	hbPad.PaddingTop = UDim.new(0, 6)
	hbPad.PaddingBottom = UDim.new(0, 6)
	hbPad.PaddingLeft = UDim.new(0, 12)
	hbPad.PaddingRight = UDim.new(0, 12)
	hbPad.Parent = hotbarPanel

	local toolNameLabel = Instance.new("TextLabel")
	toolNameLabel.Name = "ToolName"
	toolNameLabel.Size = UDim2.new(1, 0, 0, 18)
	toolNameLabel.BackgroundTransparency = 1
	toolNameLabel.Font = Enum.Font.GothamBold
	toolNameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	toolNameLabel.TextSize = 13
	toolNameLabel.TextXAlignment = Enum.TextXAlignment.Center
	toolNameLabel.Text = "🧹 Toothbrush"
	toolNameLabel.Parent = hotbarPanel

	local toolStatsLabel = Instance.new("TextLabel")
	toolStatsLabel.Name = "ToolStats"
	toolStatsLabel.Position = UDim2.new(0, 0, 0, 18)
	toolStatsLabel.Size = UDim2.new(1, 0, 0, 16)
	toolStatsLabel.BackgroundTransparency = 1
	toolStatsLabel.Font = Enum.Font.Gotham
	toolStatsLabel.TextColor3 = Color3.fromRGB(140, 175, 210)
	toolStatsLabel.TextSize = 11
	toolStatsLabel.TextXAlignment = Enum.TextXAlignment.Center
	toolStatsLabel.Text = "Power 1  ·  0.8s  ·  Range 12"
	toolStatsLabel.Parent = hotbarPanel

	-- =========================================================================
	-- Render & State Binding
	-- =========================================================================
	local function render()
		local current = state
		local ready = current ~= nil and current:GetAttribute("DataReady") == true
		local amount = if current then nonnegative(current:GetAttribute("BagAmount")) else nil
		local capacity = if current then nonnegative(current:GetAttribute("BagCapacity")) else nil
		local balance = if current then nonnegative(current:GetAttribute("Money")) else nil
		local planetId = if current then current:GetAttribute("Planet") else nil
		local definition = if typeof(planetId) == "string" then Planets.ById[planetId] else nil
		local equippedToolId = if current then current:GetAttribute("EquippedTool") else "Toothbrush"
		local toolDef = if typeof(equippedToolId) == "string" then Tools.ById[equippedToolId] else nil

		if ready and amount and capacity and balance and definition then
			moneyLabel.Text = "$" .. FormatNumber.Format(balance)
			planetLabel.Text = definition.name
			bagTitle.Text = "🎒 Bag: " .. FormatNumber.Format(amount) .. " / " .. FormatNumber.Format(capacity)

			local fraction = if capacity > 0 then math.clamp(amount / capacity, 0, 1) else 0
			local percent = math.floor(fraction * 100)

			TweenService:Create(fill, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				Size = UDim2.fromScale(fraction, 1),
			}):Play()

			if fraction >= 1 then
				fill.BackgroundColor3 = Color3.fromRGB(255, 71, 87)
				bagPercentTag.TextColor3 = Color3.fromRGB(255, 71, 87)
				bagPercentTag.Text = "FULL! SELL"
			elseif fraction >= 0.8 then
				fill.BackgroundColor3 = Color3.fromRGB(255, 171, 0)
				bagPercentTag.TextColor3 = Color3.fromRGB(255, 171, 0)
				bagPercentTag.Text = percent .. "%"
			else
				fill.BackgroundColor3 = Color3.fromRGB(46, 213, 115)
				bagPercentTag.TextColor3 = Color3.fromRGB(46, 213, 115)
				bagPercentTag.Text = percent .. "%"
			end
		else
			moneyLabel.Text = "$ —"
			planetLabel.Text = "Loading..."
			bagTitle.Text = "🎒 Bag: — / —"
			bagPercentTag.Text = "0%"
			fill.Size = UDim2.fromScale(0, 1)
		end

		if toolDef then
			toolNameLabel.Text = "🧹 " .. toolDef.name
			toolStatsLabel.Text = string.format("Power %d  ·  %.1fs  ·  Range %d", toolDef.power, toolDef.speed, toolDef.range)
		end
	end

	local function bind(folder: Folder?)
		disconnectAll(stateConnections)
		state = folder
		if folder then
			table.insert(stateConnections, folder.AttributeChanged:Connect(render))
		end
		render()
	end

	table.insert(connections, gui.Destroying:Connect(function()
		destroyed = true
		disconnectAll(stateConnections)
		disconnectAll(connections)
		state = nil
		if activeGui == gui then activeGui = nil end
	end))

	table.insert(connections, player.ChildAdded:Connect(function(child)
		if child.Name == "PlanetSweepersState" and child:IsA("Folder") then
			bind(child)
		end
	end))

	table.insert(connections, player.ChildRemoved:Connect(function(child)
		if child == state then
			local replacement = player:FindFirstChild("PlanetSweepersState")
			bind(if replacement and replacement:IsA("Folder") then replacement else nil)
		end
	end))

	local existing = player:FindFirstChild("PlanetSweepersState")
	bind(if existing and existing:IsA("Folder") then existing else nil)

	if not destroyed then gui.Parent = playerGui end

	-- Countdown timer loop for Daily Reward button
	task.spawn(function()
		local dailyCfg = GameConfig.DailyReward
		while not destroyed do
			if state then
				local last = state:GetAttribute("LastDailyReward") or 0
				local remaining = if last == 0 then 0 else math.max(0, last + dailyCfg.CooldownSeconds - workspace:GetServerTimeNow())
				if remaining <= 0 then
					dailyButton.Text = "🎁 DAILY"
					dailyButton.BackgroundColor3 = Color3.fromRGB(24, 48, 42)
				else
					local m = math.floor(remaining / 60) % 60
					local s = math.floor(remaining) % 60
					dailyButton.Text = string.format("⏳ %02d:%02d", m, s)
					dailyButton.BackgroundColor3 = Color3.fromRGB(30, 36, 48)
				end
			end
			task.wait(1)
		end
	end)
end

return Controller
