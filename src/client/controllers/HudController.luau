--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = Shared:WaitForChild("config")
local Hud = require(Config:WaitForChild("Game")).Hud
local Planets = require(Config:WaitForChild("Planets"))
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

	-- Main Floating Card Container
	local panel = Instance.new("Frame")
	panel.Name = "Panel"
	panel.Position = UDim2.fromOffset(Hud.Margin, Hud.Margin)
	panel.Size = UDim2.new(1, -Hud.Margin * 2, 0, 168)
	panel.BackgroundColor3 = Color3.fromRGB(15, 20, 32)
	panel.BackgroundTransparency = 0.12
	panel.BorderSizePixel = 0
	panel.Parent = gui

	local panelCorner = Instance.new("UICorner")
	panelCorner.CornerRadius = UDim.new(0, 12)
	panelCorner.Parent = panel

	local panelStroke = Instance.new("UIStroke")
	panelStroke.Color = Color3.fromRGB(255, 255, 255)
	panelStroke.Transparency = 0.85
	panelStroke.Thickness = 1.2
	panelStroke.Parent = panel

	local constraint = Instance.new("UISizeConstraint")
	constraint.MaxSize = Vector2.new(Hud.Width + 20, 175)
	constraint.Parent = panel

	local padding = Instance.new("UIPadding")
	padding.PaddingTop = UDim.new(0, 12)
	padding.PaddingBottom = UDim.new(0, 12)
	padding.PaddingLeft = UDim.new(0, 14)
	padding.PaddingRight = UDim.new(0, 14)
	padding.Parent = panel

	local content = Instance.new("Frame")
	content.BackgroundTransparency = 1
	content.Size = UDim2.fromScale(1, 1)
	content.Parent = panel

	local layout = Instance.new("UIListLayout")
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Padding = UDim.new(0, 8)
	layout.Parent = content

	-- Row 1: Badges for Money and Planet
	local topRow = Instance.new("Frame")
	topRow.Name = "TopRow"
	topRow.LayoutOrder = 1
	topRow.Size = UDim2.new(1, 0, 0, 36)
	topRow.BackgroundTransparency = 1
	topRow.Parent = content

	local topLayout = Instance.new("UIListLayout")
	topLayout.FillDirection = Enum.FillDirection.Horizontal
	topLayout.SortOrder = Enum.SortOrder.LayoutOrder
	topLayout.Padding = UDim.new(0, 8)
	topLayout.Parent = topRow

	-- Money Chip
	local moneyBadge = Instance.new("Frame")
	moneyBadge.Name = "MoneyBadge"
	moneyBadge.LayoutOrder = 1
	moneyBadge.Size = UDim2.new(0.55, -4, 1, 0)
	moneyBadge.BackgroundColor3 = Color3.fromRGB(25, 33, 50)
	moneyBadge.BorderSizePixel = 0
	moneyBadge.Parent = topRow

	local moneyCorner = Instance.new("UICorner")
	moneyCorner.CornerRadius = UDim.new(0, 8)
	moneyCorner.Parent = moneyBadge

	local moneyStroke = Instance.new("UIStroke")
	moneyStroke.Color = Color3.fromRGB(255, 215, 0)
	moneyStroke.Transparency = 0.7
	moneyStroke.Thickness = 1
	moneyStroke.Parent = moneyBadge

	local moneyPadding = Instance.new("UIPadding")
	moneyPadding.PaddingLeft = UDim.new(0, 8)
	moneyPadding.PaddingRight = UDim.new(0, 8)
	moneyPadding.Parent = moneyBadge

	local moneyIcon = Instance.new("TextLabel")
	moneyIcon.Name = "Icon"
	moneyIcon.Size = UDim2.new(0, 20, 1, 0)
	moneyIcon.BackgroundTransparency = 1
	moneyIcon.Font = Enum.Font.GothamBold
	moneyIcon.Text = "$"
	moneyIcon.TextColor3 = Color3.fromRGB(255, 215, 0)
	moneyIcon.TextSize = 18
	moneyIcon.TextXAlignment = Enum.TextXAlignment.Left
	moneyIcon.Parent = moneyBadge

	local moneyLabel = Instance.new("TextLabel")
	moneyLabel.Name = "Amount"
	moneyLabel.Position = UDim2.new(0, 22, 0, 0)
	moneyLabel.Size = UDim2.new(1, -22, 1, 0)
	moneyLabel.BackgroundTransparency = 1
	moneyLabel.Font = Enum.Font.GothamBold
	moneyLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	moneyLabel.TextSize = 16
	moneyLabel.TextXAlignment = Enum.TextXAlignment.Left
	moneyLabel.TextTruncate = Enum.TextTruncate.AtEnd
	moneyLabel.Text = "$ 0"
	moneyLabel.Parent = moneyBadge

	-- Planet Chip
	local planetBadge = Instance.new("Frame")
	planetBadge.Name = "PlanetBadge"
	planetBadge.LayoutOrder = 2
	planetBadge.Size = UDim2.new(0.45, -4, 1, 0)
	planetBadge.BackgroundColor3 = Color3.fromRGB(25, 33, 50)
	planetBadge.BorderSizePixel = 0
	planetBadge.Parent = topRow

	local planetCorner = Instance.new("UICorner")
	planetCorner.CornerRadius = UDim.new(0, 8)
	planetCorner.Parent = planetBadge

	local planetStroke = Instance.new("UIStroke")
	planetStroke.Color = Color3.fromRGB(80, 227, 194)
	planetStroke.Transparency = 0.75
	planetStroke.Thickness = 1
	planetStroke.Parent = planetBadge

	local planetPadding = Instance.new("UIPadding")
	planetPadding.PaddingLeft = UDim.new(0, 8)
	planetPadding.PaddingRight = UDim.new(0, 8)
	planetPadding.Parent = planetBadge

	local planetLabel = Instance.new("TextLabel")
	planetLabel.Name = "Planet"
	planetLabel.Size = UDim2.new(1, 0, 1, 0)
	planetLabel.BackgroundTransparency = 1
	planetLabel.Font = Enum.Font.GothamMedium
	planetLabel.TextColor3 = Color3.fromRGB(80, 227, 194)
	planetLabel.TextSize = 13
	planetLabel.TextTruncate = Enum.TextTruncate.AtEnd
	planetLabel.TextXAlignment = Enum.TextXAlignment.Center
	planetLabel.Text = "Planet: ..."
	planetLabel.Parent = planetBadge

	-- Row 2: Bag Capacity Header
	local bagHeader = Instance.new("Frame")
	bagHeader.Name = "BagHeader"
	bagHeader.LayoutOrder = 2
	bagHeader.Size = UDim2.new(1, 0, 0, 22)
	bagHeader.BackgroundTransparency = 1
	bagHeader.Parent = content

	local bagTitle = Instance.new("TextLabel")
	bagTitle.Name = "Title"
	bagTitle.Size = UDim2.new(0.65, 0, 1, 0)
	bagTitle.BackgroundTransparency = 1
	bagTitle.Font = Enum.Font.GothamBold
	bagTitle.TextColor3 = Color3.fromRGB(230, 238, 248)
	bagTitle.TextSize = 14
	bagTitle.TextXAlignment = Enum.TextXAlignment.Left
	bagTitle.Text = "Bag: 0 / 25"
	bagTitle.Parent = bagHeader

	local bagPercentTag = Instance.new("TextLabel")
	bagPercentTag.Name = "PercentTag"
	bagPercentTag.Size = UDim2.new(0.35, 0, 1, 0)
	bagPercentTag.Position = UDim2.new(0.65, 0, 0, 0)
	bagPercentTag.BackgroundTransparency = 1
	bagPercentTag.Font = Enum.Font.GothamBold
	bagPercentTag.TextColor3 = Color3.fromRGB(46, 213, 115)
	bagPercentTag.TextSize = 13
	bagPercentTag.TextXAlignment = Enum.TextXAlignment.Right
	bagPercentTag.Text = "0%"
	bagPercentTag.Parent = bagHeader

	-- Row 3: Progress Bar Track & Fill
	local track = Instance.new("Frame")
	track.Name = "BagProgress"
	track.LayoutOrder = 3
	track.Size = UDim2.new(1, 0, 0, 14)
	track.BackgroundColor3 = Color3.fromRGB(28, 37, 56)
	track.BorderSizePixel = 0
	track.ClipsDescendants = true
	track.Parent = content

	local trackCorner = Instance.new("UICorner")
	trackCorner.CornerRadius = UDim.new(1, 0)
	trackCorner.Parent = track

	local trackStroke = Instance.new("UIStroke")
	trackStroke.Color = Color3.fromRGB(255, 255, 255)
	trackStroke.Transparency = 0.9
	trackStroke.Thickness = 1
	trackStroke.Parent = track

	local fill = Instance.new("Frame")
	fill.Name = "Fill"
	fill.Size = UDim2.fromScale(0, 1)
	fill.BackgroundColor3 = Color3.fromRGB(46, 213, 115)
	fill.BorderSizePixel = 0
	fill.Parent = track

	local fillCorner = Instance.new("UICorner")
	fillCorner.CornerRadius = UDim.new(1, 0)
	fillCorner.Parent = fill

	-- Row 4: Status / Footer
	local status = Instance.new("TextLabel")
	status.Name = "Status"
	status.LayoutOrder = 4
	status.Size = UDim2.new(1, 0, 0, 18)
	status.BackgroundTransparency = 1
	status.Font = Enum.Font.Gotham
	status.TextColor3 = Color3.fromRGB(160, 175, 200)
	status.TextSize = 12
	status.TextXAlignment = Enum.TextXAlignment.Left
	status.Text = "Memuat data..."
	status.Parent = content

	local connections: {RBXScriptConnection} = {}
	local stateConnections: {RBXScriptConnection} = {}
	local state: Folder? = nil
	local destroyed = false

	local function render()
		local current = state
		local ready = current ~= nil and current:GetAttribute("DataReady") == true
		local amount = if current then nonnegative(current:GetAttribute("BagAmount")) else nil
		local capacity = if current then nonnegative(current:GetAttribute("BagCapacity")) else nil
		local balance = if current then nonnegative(current:GetAttribute("Money")) else nil
		local planetId = if current then current:GetAttribute("Planet") else nil
		local definition = if typeof(planetId) == "string" then Planets.ById[planetId] else nil
		local valid = ready and amount ~= nil and capacity ~= nil and balance ~= nil and definition ~= nil
		local temporary = current ~= nil and current:GetAttribute("StorageMode") == "Temporary"

		if valid and amount and capacity and balance and definition then
			moneyLabel.Text = FormatNumber.Format(balance)
			bagTitle.Text = "Bag: " .. FormatNumber.Format(amount) .. " / " .. FormatNumber.Format(capacity)

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

			planetLabel.Text = definition.name
			status.Text = if temporary then "● Studio (Mode Data Sementara)" else "● Tersinkronisasi"
			status.TextColor3 = if temporary then Color3.fromRGB(255, 195, 18) else Color3.fromRGB(123, 237, 159)
		else
			moneyLabel.Text = "—"
			bagTitle.Text = "Bag: — / —"
			bagPercentTag.Text = "0%"
			fill.Size = UDim2.fromScale(0, 1)
			planetLabel.Text = "Planet: —"
			status.Text = if ready then "● Data tidak tersedia" else "● Memuat data..."
			status.TextColor3 = Color3.fromRGB(255, 171, 0)
		end
	end

	local function bind(folder: Folder?)
		disconnectAll(stateConnections)
		state = folder
		if folder then
			table.insert(stateConnections, folder.AttributeChanged:Connect(function()
				render()
			end))
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
end

return Controller
