--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Tools = require(Shared.config.Tools)
local Bags = require(Shared.config.Bags)
local Vehicles = require(Shared.config.Vehicles)
local Shop = require(Shared.config.Shop)
local Format = require(Shared.Util.FormatNumber)

local Controller = {}
local started = false

function Controller.Start(): ()
	if started then return end
	started = true

	local player = Players.LocalPlayer
	local remote = ReplicatedStorage:WaitForChild("PlanetSweepersShop") :: RemoteEvent
	local state = player:WaitForChild("PlanetSweepersState")

	local gui = Instance.new("ScreenGui")
	gui.Name = "PlanetSweepersShopUI"
	gui.ResetOnSpawn = false
	gui.Enabled = false
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

	-- Modal Background Dim
	local backdrop = Instance.new("TextButton")
	backdrop.Name = "Backdrop"
	backdrop.Size = UDim2.fromScale(1, 1)
	backdrop.BackgroundColor3 = Color3.new(0, 0, 0)
	backdrop.BackgroundTransparency = 0.5
	backdrop.Text = ""
	backdrop.AutoButtonColor = false
	backdrop.Parent = gui

	-- Main Shop Panel
	local panel = Instance.new("Frame")
	panel.Name = "ShopPanel"
	panel.AnchorPoint = Vector2.new(0.5, 0.5)
	panel.Position = UDim2.fromScale(0.5, 0.5)
	panel.Size = UDim2.fromScale(0.92, 0.85)
	panel.BackgroundColor3 = Color3.fromRGB(15, 20, 32)
	panel.BorderSizePixel = 0
	panel.Parent = gui

	local panelCorner = Instance.new("UICorner")
	panelCorner.CornerRadius = UDim.new(0, 14)
	panelCorner.Parent = panel

	local panelStroke = Instance.new("UIStroke")
	panelStroke.Color = Color3.fromRGB(80, 130, 220)
	panelStroke.Transparency = 0.7
	panelStroke.Thickness = 1.5
	panelStroke.Parent = panel

	local limit = Instance.new("UISizeConstraint")
	limit.MaxSize = Vector2.new(Shop.PanelWidth + 60, Shop.PanelHeight + 40)
	limit.MinSize = Vector2.new(320, 420)
	limit.Parent = panel

	-- Header Section
	local header = Instance.new("Frame")
	header.Name = "Header"
	header.Size = UDim2.new(1, 0, 0, 60)
	header.BackgroundTransparency = 1
	header.Parent = panel

	local headerPadding = Instance.new("UIPadding")
	headerPadding.PaddingLeft = UDim.new(0, 18)
	headerPadding.PaddingRight = UDim.new(0, 14)
	headerPadding.PaddingTop = UDim.new(0, 10)
	headerPadding.Parent = header

	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.Text = "EQUIPMENT SHOP"
	title.Size = UDim2.new(1, -60, 0, 26)
	title.TextColor3 = Color3.fromRGB(255, 255, 255)
	title.Font = Enum.Font.GothamBold
	title.TextSize = 20
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.BackgroundTransparency = 1
	title.Parent = header

	local subtitle = Instance.new("TextLabel")
	subtitle.Name = "Subtitle"
	subtitle.Text = "Upgrade tools, bag capacity, and automated robots"
	subtitle.Size = UDim2.new(1, -60, 0, 18)
	subtitle.Position = UDim2.new(0, 0, 0, 26)
	subtitle.TextColor3 = Color3.fromRGB(140, 160, 190)
	subtitle.Font = Enum.Font.Gotham
	subtitle.TextSize = 12
	subtitle.TextXAlignment = Enum.TextXAlignment.Left
	subtitle.BackgroundTransparency = 1
	subtitle.Parent = header

	-- Close Button
	local close = Instance.new("TextButton")
	close.Name = "CloseButton"
	close.Text = "✕"
	close.Font = Enum.Font.GothamBold
	close.TextSize = 18
	close.TextColor3 = Color3.fromRGB(220, 230, 245)
	close.Size = UDim2.fromOffset(36, 36)
	close.Position = UDim2.new(1, -40, 0, 10)
	close.BackgroundColor3 = Color3.fromRGB(35, 45, 65)
	close.BorderSizePixel = 0
	close.Parent = panel

	local closeCorner = Instance.new("UICorner")
	closeCorner.CornerRadius = UDim.new(1, 0)
	closeCorner.Parent = close

	local closeStroke = Instance.new("UIStroke")
	closeStroke.Color = Color3.fromRGB(255, 255, 255)
	closeStroke.Transparency = 0.85
	closeStroke.Parent = close

	-- Status Bar (Feedback message)
	local status = Instance.new("TextLabel")
	status.Name = "Status"
	status.Size = UDim2.new(1, -32, 0, 24)
	status.Position = UDim2.fromOffset(16, 62)
	status.BackgroundColor3 = Color3.fromRGB(25, 33, 50)
	status.TextColor3 = Color3.fromRGB(255, 210, 128)
	status.Font = Enum.Font.GothamMedium
	status.Text = "Pembelian hanya dapat dilakukan di dekat toko."
	status.TextSize = 12
	status.BorderSizePixel = 0
	status.Parent = panel

	local statusCorner = Instance.new("UICorner")
	statusCorner.CornerRadius = UDim.new(0, 6)
	statusCorner.Parent = status

	-- Items Scroll List
	local list = Instance.new("ScrollingFrame")
	list.Position = UDim2.fromOffset(14, 94)
	list.Size = UDim2.new(1, -28, 1, -106)
	list.BackgroundTransparency = 1
	list.AutomaticCanvasSize = Enum.AutomaticSize.Y
	list.CanvasSize = UDim2.new()
	list.ScrollBarThickness = 6
	list.ScrollBarImageColor3 = Color3.fromRGB(80, 130, 220)
	list.Parent = panel

	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 8)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = list

	local listPadding = Instance.new("UIPadding")
	listPadding.PaddingRight = UDim.new(0, 6)
	listPadding.PaddingBottom = UDim.new(0, 10)
	listPadding.Parent = list

	local connections: {RBXScriptConnection} = {}
	type RowControls = {
		card: Frame,
		nameLabel: TextLabel,
		statLabel: TextLabel,
		actionButton: TextButton,
		actionStroke: UIStroke,
	}
	local rows: {[string]: RowControls} = {}

	local function createSectionHeader(titleText: string, order: number)
		local section = Instance.new("Frame")
		section.Name = "Header_" .. titleText
		section.Size = UDim2.new(1, 0, 0, 28)
		section.BackgroundTransparency = 1
		section.LayoutOrder = order
		section.Parent = list

		local label = Instance.new("TextLabel")
		label.Text = titleText
		label.Size = UDim2.new(1, 0, 1, 0)
		label.BackgroundTransparency = 1
		label.Font = Enum.Font.GothamBold
		label.TextColor3 = Color3.fromRGB(80, 227, 194)
		label.TextSize = 13
		label.TextXAlignment = Enum.TextXAlignment.Left
		label.Parent = section
	end

	local function createCard(id: string, order: number): RowControls
		local card = Instance.new("Frame")
		card.Name = "Card_" .. id
		card.Size = UDim2.new(1, 0, 0, 64)
		card.LayoutOrder = order
		card.BackgroundColor3 = Color3.fromRGB(24, 32, 50)
		card.BorderSizePixel = 0
		card.Parent = list

		local cardCorner = Instance.new("UICorner")
		cardCorner.CornerRadius = UDim.new(0, 10)
		cardCorner.Parent = card

		local cardStroke = Instance.new("UIStroke")
		cardStroke.Color = Color3.fromRGB(255, 255, 255)
		cardStroke.Transparency = 0.92
		cardStroke.Thickness = 1
		cardStroke.Parent = card

		local cardPad = Instance.new("UIPadding")
		cardPad.PaddingLeft = UDim.new(0, 14)
		cardPad.PaddingRight = UDim.new(0, 12)
		cardPad.Parent = card

		local nameLabel = Instance.new("TextLabel")
		nameLabel.Name = "Name"
		nameLabel.Size = UDim2.new(1, -125, 0, 24)
		nameLabel.Position = UDim2.new(0, 0, 0, 10)
		nameLabel.BackgroundTransparency = 1
		nameLabel.Font = Enum.Font.GothamBold
		nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
		nameLabel.TextSize = 15
		nameLabel.TextXAlignment = Enum.TextXAlignment.Left
		nameLabel.TextTruncate = Enum.TextTruncate.AtEnd
		nameLabel.Parent = card

		local statLabel = Instance.new("TextLabel")
		statLabel.Name = "Stats"
		statLabel.Size = UDim2.new(1, -125, 0, 20)
		statLabel.Position = UDim2.new(0, 0, 0, 32)
		statLabel.BackgroundTransparency = 1
		statLabel.Font = Enum.Font.Gotham
		statLabel.TextColor3 = Color3.fromRGB(150, 170, 200)
		statLabel.TextSize = 12
		statLabel.TextXAlignment = Enum.TextXAlignment.Left
		statLabel.TextTruncate = Enum.TextTruncate.AtEnd
		statLabel.Parent = card

		local actionButton = Instance.new("TextButton")
		actionButton.Name = "ActionButton"
		actionButton.Size = UDim2.new(0, 115, 0, 40)
		actionButton.Position = UDim2.new(1, -115, 0.5, -20)
		actionButton.BackgroundColor3 = Color3.fromRGB(50, 60, 80)
		actionButton.BorderSizePixel = 0
		actionButton.Font = Enum.Font.GothamBold
		actionButton.TextSize = 13
		actionButton.TextColor3 = Color3.fromRGB(255, 255, 255)
		actionButton.Parent = card

		local btnCorner = Instance.new("UICorner")
		btnCorner.CornerRadius = UDim.new(0, 8)
		btnCorner.Parent = actionButton

		local actionStroke = Instance.new("UIStroke")
		actionStroke.Transparency = 0.8
		actionStroke.Thickness = 1
		actionStroke.Parent = actionButton

		local controls: RowControls = {
			card = card,
			nameLabel = nameLabel,
			statLabel = statLabel,
			actionButton = actionButton,
			actionStroke = actionStroke,
		}
		rows[id] = controls
		return controls
	end

	-- Build Tools
	createSectionHeader("CLEANING TOOLS", 10)
	for index, id in Tools.Order do
		local row = createCard(id, 10 + index)
		table.insert(connections, row.actionButton.Activated:Connect(function()
			if row.actionButton.Active then remote:FireServer("Tool", id) end
		end))
	end

	-- Build Bag
	createSectionHeader("STORAGE CAPACITY", 100)
	local bagRow = createCard("Bag", 101)
	table.insert(connections, bagRow.actionButton.Activated:Connect(function()
		if bagRow.actionButton.Active then
			remote:FireServer("Bag", tostring((state:GetAttribute("BagLevel") or 0) + 1))
		end
	end))

	-- Build Robots
	createSectionHeader("AUTONOMOUS ROBOTS", 200)
	for index, id in Vehicles.Order do
		local row = createCard("Robot_" .. id, 200 + index)
		table.insert(connections, row.actionButton.Activated:Connect(function()
			if row.actionButton.Active then
				remote:FireServer("Robot", id, state:GetAttribute("Robot_" .. id) or 0)
			end
		end))
	end

	local function render()
		local ready = state:GetAttribute("DataReady") == true
		local money = state:GetAttribute("Money") or 0

		-- Render Robots
		local robotTotal = 0
		for _, id in Vehicles.Order do robotTotal += state:GetAttribute("Robot_" .. id) or 0 end
		for _, id in Vehicles.Order do
			local definition = Vehicles.ById[id]
			local row = rows["Robot_" .. id]
			local count = state:GetAttribute("Robot_" .. id) or 0
			local canBuy = ready and robotTotal < Vehicles.MaximumRobots and money >= definition.price

			row.nameLabel.Text = definition.name
			row.statLabel.Text = "Owned: " .. count .. "  ·  Total: " .. robotTotal .. "/" .. Vehicles.MaximumRobots

			row.actionButton.Active = canBuy
			row.actionButton.AutoButtonColor = canBuy
			if canBuy then
				row.actionButton.BackgroundColor3 = Color3.fromRGB(46, 213, 115)
				row.actionButton.TextColor3 = Color3.fromRGB(15, 25, 20)
				row.actionButton.Text = "$ " .. Format.Format(definition.price)
			else
				row.actionButton.BackgroundColor3 = Color3.fromRGB(45, 55, 75)
				row.actionButton.TextColor3 = Color3.fromRGB(140, 150, 170)
				row.actionButton.Text = if robotTotal >= Vehicles.MaximumRobots then "MAX" else "$ " .. Format.Format(definition.price)
			end
		end

		-- Adjust proximity range for currently equipped tool
		local equippedDefinition = Tools.ById[state:GetAttribute("EquippedTool") or "Toothbrush"]
		local world = workspace:FindFirstChild("PlanetSweepersWorld")
		local dirt = if world then world:FindFirstChild("DirtNodes") else nil
		if dirt and equippedDefinition then
			for _, node in dirt:GetChildren() do
				local prompt = node:FindFirstChildOfClass("ProximityPrompt")
				if prompt then prompt.MaxActivationDistance = equippedDefinition.range end
			end
		end

		-- Render Tools
		for _, id in Tools.Order do
			local definition = Tools.ById[id]
			local row = rows[id]
			local owned = state:GetAttribute("Owned_" .. id) == true
			local equipped = state:GetAttribute("EquippedTool") == id
			local previous = Tools.Order[definition.level]
			local unlocked = previous == nil or state:GetAttribute("Owned_" .. previous) == true
			local cost = math.ceil(definition.price)

			row.nameLabel.Text = definition.name
			row.statLabel.Text = "Power " .. definition.power .. "  ·  " .. definition.speed .. "s  ·  Range " .. definition.range

			local canBuy = ready and not equipped and (owned or (unlocked and money >= cost))
			row.actionButton.Active = canBuy
			row.actionButton.AutoButtonColor = canBuy

			if equipped then
				row.actionButton.BackgroundColor3 = Color3.fromRGB(35, 70, 55)
				row.actionButton.TextColor3 = Color3.fromRGB(80, 227, 194)
				row.actionButton.Text = "EQUIPPED"
			elseif owned then
				row.actionButton.BackgroundColor3 = Color3.fromRGB(54, 120, 220)
				row.actionButton.TextColor3 = Color3.fromRGB(255, 255, 255)
				row.actionButton.Text = "EQUIP"
			elseif not unlocked then
				row.actionButton.BackgroundColor3 = Color3.fromRGB(40, 48, 65)
				row.actionButton.TextColor3 = Color3.fromRGB(120, 130, 150)
				row.actionButton.Text = "LOCKED"
			else
				row.actionButton.BackgroundColor3 = if money >= cost then Color3.fromRGB(255, 195, 18) else Color3.fromRGB(50, 60, 80)
				row.actionButton.TextColor3 = if money >= cost then Color3.fromRGB(25, 20, 10) else Color3.fromRGB(150, 160, 180)
				row.actionButton.Text = "$ " .. Format.Format(cost)
			end
		end

		-- Render Bag
		local level = state:GetAttribute("BagLevel") or 0
		local cost = math.ceil(Bags.BaseCost * Bags.CostGrowth ^ level)
		local nextCapacity = Bags.BaseCapacity + Bags.CapacityPerLevel * (level + 1)
		local canBuyBag = ready and level < Bags.MaximumLevel and money >= cost

		bagRow.nameLabel.Text = if level >= Bags.MaximumLevel then "Bag (Max Level)" else "Bag Tier " .. (level + 1)
		bagRow.statLabel.Text = "New Capacity: " .. nextCapacity .. " units"
		bagRow.actionButton.Active = canBuyBag
		bagRow.actionButton.AutoButtonColor = canBuyBag

		if level >= Bags.MaximumLevel then
			bagRow.actionButton.BackgroundColor3 = Color3.fromRGB(40, 48, 65)
			bagRow.actionButton.TextColor3 = Color3.fromRGB(120, 130, 150)
			bagRow.actionButton.Text = "MAX"
		else
			bagRow.actionButton.BackgroundColor3 = if canBuyBag then Color3.fromRGB(255, 195, 18) else Color3.fromRGB(50, 60, 80)
			bagRow.actionButton.TextColor3 = if canBuyBag then Color3.fromRGB(25, 20, 10) else Color3.fromRGB(150, 160, 180)
			bagRow.actionButton.Text = "$ " .. Format.Format(cost)
		end
	end

	table.insert(connections, state.AttributeChanged:Connect(render))
	table.insert(connections, close.Activated:Connect(function() gui.Enabled = false end))
	table.insert(connections, backdrop.Activated:Connect(function() gui.Enabled = false end))

	table.insert(connections, remote.OnClientEvent:Connect(function(action, message)
		if action == "Open" then
			gui.Enabled = true
			render()
		elseif action == "Result" and type(message) == "string" then
			status.Text = message
		end
	end))

	table.insert(connections, gui.Destroying:Connect(function()
		for _, connection in connections do connection:Disconnect() end
		table.clear(connections)
		started = false
	end))

	render()
	gui.Parent = player:WaitForChild("PlayerGui")
end

return Controller
