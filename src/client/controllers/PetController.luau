--!strict
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Config = require(RS.Shared.config.Pets)

local Controller = {}
local started = false

local RARITY_COLORS: {[string]: Color3} = {
	Common = Color3.fromRGB(149, 165, 166),
	Rare = Color3.fromRGB(52, 152, 219),
	Epic = Color3.fromRGB(155, 89, 182),
	Legendary = Color3.fromRGB(241, 196, 15),
	Mythic = Color3.fromRGB(231, 76, 60),
}

function Controller.Start(): ()
	if started then return end
	started = true

	local remote = RS:WaitForChild("PlanetSweepersPets") :: RemoteEvent
	local gui = Instance.new("ScreenGui")
	gui.Name = "PetInventory"
	gui.ResetOnSpawn = false
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

	local connections: {RBXScriptConnection} = {}
	local rowConnections: {RBXScriptConnection} = {}
	local snapshot: any = {pets = {}, equipped = {}, index = {}, multiplier = 1}
	local currentTab: "Inventory" | "Index" = "Inventory"

	-- Floating HUD Open Button (Managed by HudController RightButtonStack)
	local open = Instance.new("TextButton")
	open.Name = "OpenPetsButton"
	open.Text = "🐾 PETS"
	open.Font = Enum.Font.GothamBold
	open.TextSize = 14
	open.TextColor3 = Color3.fromRGB(240, 230, 255)
	open.BackgroundColor3 = Color3.fromRGB(36, 26, 54)
	open.BorderSizePixel = 0
	open.Size = UDim2.fromOffset(110, 42)
	open.AnchorPoint = Vector2.new(1, 0)
	open.Position = UDim2.new(1, -16, 0, 16)
	open.Visible = false -- Unified in HudController right stack
	open.Parent = gui

	local openCorner = Instance.new("UICorner")
	openCorner.CornerRadius = UDim.new(0, 10)
	openCorner.Parent = open

	local openStroke = Instance.new("UIStroke")
	openStroke.Color = Color3.fromRGB(165, 94, 234)
	openStroke.Transparency = 0.5
	openStroke.Thickness = 1.2
	openStroke.Parent = open

	-- Modal Backdrop
	local backdrop = Instance.new("TextButton")
	backdrop.Name = "Backdrop"
	backdrop.Size = UDim2.fromScale(1, 1)
	backdrop.BackgroundColor3 = Color3.new(0, 0, 0)
	backdrop.BackgroundTransparency = 0.5
	backdrop.Text = ""
	backdrop.Visible = false
	backdrop.AutoButtonColor = false
	backdrop.Parent = gui

	-- Modal Panel
	local panel = Instance.new("Frame")
	panel.Name = "PetPanel"
	panel.Size = UDim2.fromScale(0.92, 0.82)
	panel.Position = UDim2.fromScale(0.5, 0.5)
	panel.AnchorPoint = Vector2.new(0.5, 0.5)
	panel.BackgroundColor3 = Color3.fromRGB(16, 20, 32)
	panel.BorderSizePixel = 0
	panel.Visible = false
	panel.Parent = gui

	local panelCorner = Instance.new("UICorner")
	panelCorner.CornerRadius = UDim.new(0, 14)
	panelCorner.Parent = panel

	local panelStroke = Instance.new("UIStroke")
	panelStroke.Color = Color3.fromRGB(165, 94, 234)
	panelStroke.Transparency = 0.65
	panelStroke.Thickness = 1.5
	panelStroke.Parent = panel

	local constraint = Instance.new("UISizeConstraint")
	constraint.MaxSize = Vector2.new(580, 640)
	constraint.MinSize = Vector2.new(320, 420)
	constraint.Parent = panel

	-- Header
	local header = Instance.new("Frame")
	header.Name = "Header"
	header.Size = UDim2.new(1, 0, 0, 56)
	header.BackgroundTransparency = 1
	header.Parent = panel

	local headerPad = Instance.new("UIPadding")
	headerPad.PaddingLeft = UDim.new(0, 18)
	headerPad.PaddingRight = UDim.new(0, 14)
	headerPad.PaddingTop = UDim.new(0, 10)
	headerPad.Parent = header

	local title = Instance.new("TextLabel")
	title.Text = "PET COMPANIONS"
	title.Font = Enum.Font.GothamBold
	title.TextSize = 20
	title.TextColor3 = Color3.fromRGB(240, 230, 255)
	title.Size = UDim2.new(1, -50, 0, 24)
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.BackgroundTransparency = 1
	title.Parent = header

	local subtitle = Instance.new("TextLabel")
	subtitle.Name = "StatsSummary"
	subtitle.Text = "Multiplier x1.00  ·  Equipped 0/3  ·  Inventory 0/20"
	subtitle.Font = Enum.Font.GothamMedium
	subtitle.TextSize = 12
	subtitle.TextColor3 = Color3.fromRGB(180, 190, 215)
	subtitle.Position = UDim2.new(0, 0, 0, 26)
	subtitle.Size = UDim2.new(1, -50, 0, 18)
	subtitle.TextXAlignment = Enum.TextXAlignment.Left
	subtitle.BackgroundTransparency = 1
	subtitle.Parent = header

	-- Close Button
	local close = Instance.new("TextButton")
	close.Name = "CloseButton"
	close.Text = "✕"
	close.Font = Enum.Font.GothamBold
	close.TextSize = 18
	close.TextColor3 = Color3.fromRGB(230, 235, 245)
	close.Size = UDim2.fromOffset(36, 36)
	close.Position = UDim2.new(1, -40, 0, 10)
	close.BackgroundColor3 = Color3.fromRGB(35, 45, 65)
	close.BorderSizePixel = 0
	close.Parent = panel

	local closeCorner = Instance.new("UICorner")
	closeCorner.CornerRadius = UDim.new(1, 0)
	closeCorner.Parent = close

	-- Tab Switcher Bar
	local tabContainer = Instance.new("Frame")
	tabContainer.Name = "TabContainer"
	tabContainer.Position = UDim2.fromOffset(16, 60)
	tabContainer.Size = UDim2.new(1, -32, 0, 36)
	tabContainer.BackgroundTransparency = 1
	tabContainer.Parent = panel

	local tabLayout = Instance.new("UIListLayout")
	tabLayout.FillDirection = Enum.FillDirection.Horizontal
	tabLayout.Padding = UDim.new(0, 8)
	tabLayout.Parent = tabContainer

	local function createTabButton(name: string, label: string): TextButton
		local btn = Instance.new("TextButton")
		btn.Name = "Tab_" .. name
		btn.Text = label
		btn.Font = Enum.Font.GothamBold
		btn.TextSize = 13
		btn.Size = UDim2.new(0.5, -4, 1, 0)
		btn.BorderSizePixel = 0
		btn.Parent = tabContainer

		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, 8)
		corner.Parent = btn
		return btn
	end

	local invTabBtn = createTabButton("Inventory", "🎒 MY PETS")
	local indexTabBtn = createTabButton("Index", "📖 PET INDEX & RATES")

	-- Scrolling List
	local list = Instance.new("ScrollingFrame")
	list.Position = UDim2.fromOffset(14, 104)
	list.Size = UDim2.new(1, -28, 1, -114)
	list.BackgroundTransparency = 1
	list.AutomaticCanvasSize = Enum.AutomaticSize.Y
	list.CanvasSize = UDim2.new()
	list.ScrollBarThickness = 6
	list.ScrollBarImageColor3 = Color3.fromRGB(165, 94, 234)
	list.Parent = panel

	local layout = Instance.new("UIListLayout")
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Padding = UDim.new(0, 8)
	layout.Parent = list

	local listPad = Instance.new("UIPadding")
	listPad.PaddingRight = UDim.new(0, 6)
	listPad.PaddingBottom = UDim.new(0, 10)
	listPad.Parent = list

	local function setTabVisuals()
		if currentTab == "Inventory" then
			invTabBtn.BackgroundColor3 = Color3.fromRGB(165, 94, 234)
			invTabBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
			indexTabBtn.BackgroundColor3 = Color3.fromRGB(28, 35, 52)
			indexTabBtn.TextColor3 = Color3.fromRGB(160, 175, 205)
		else
			indexTabBtn.BackgroundColor3 = Color3.fromRGB(165, 94, 234)
			indexTabBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
			invTabBtn.BackgroundColor3 = Color3.fromRGB(28, 35, 52)
			invTabBtn.TextColor3 = Color3.fromRGB(160, 175, 205)
		end
	end

	local function render()
		for _, connection in rowConnections do connection:Disconnect() end
		table.clear(rowConnections)
		for _, child in list:GetChildren() do
			if child:IsA("GuiObject") then child:Destroy() end
		end

		setTabVisuals()
		subtitle.Text = string.format("Multiplier x%.2f  ·  Equipped %d/%d  ·  Inventory %d/%d",
			snapshot.multiplier or 1,
			#snapshot.equipped, Config.EquipSlots,
			#snapshot.pets, Config.MaximumInventory
		)

		local totalRarityWeight = 0
		for _, rarity in Config.RarityOrder do totalRarityWeight += Config.Rarities[rarity].weight end

		if currentTab == "Inventory" then
			if #snapshot.pets == 0 then
				local emptyLabel = Instance.new("TextLabel")
				emptyLabel.Size = UDim2.new(1, 0, 0, 100)
				emptyLabel.BackgroundTransparency = 1
				emptyLabel.Font = Enum.Font.GothamMedium
				emptyLabel.TextSize = 14
				emptyLabel.TextColor3 = Color3.fromRGB(140, 155, 185)
				emptyLabel.Text = "No pets yet!\nClean dirt nodes on any planet for a chance to discover cute pets."
				emptyLabel.Parent = list
				return
			end

			for order, pet in ipairs(snapshot.pets) do
				local equipped = table.find(snapshot.equipped, pet.id) ~= nil
				local rarityColor = RARITY_COLORS[pet.rarity] or Color3.fromRGB(200, 200, 200)

				local card = Instance.new("Frame")
				card.Name = "PetCard_" .. pet.id
				card.Size = UDim2.new(1, 0, 0, 60)
				card.LayoutOrder = order
				card.BackgroundColor3 = Color3.fromRGB(24, 30, 48)
				card.BorderSizePixel = 0
				card.Parent = list

				local cardCorner = Instance.new("UICorner")
				cardCorner.CornerRadius = UDim.new(0, 10)
				cardCorner.Parent = card

				local cardStroke = Instance.new("UIStroke")
				cardStroke.Color = rarityColor
				cardStroke.Transparency = if equipped then 0.3 else 0.75
				cardStroke.Thickness = if equipped then 1.5 else 1
				cardStroke.Parent = card

				local cardPad = Instance.new("UIPadding")
				cardPad.PaddingLeft = UDim.new(0, 14)
				cardPad.PaddingRight = UDim.new(0, 12)
				cardPad.Parent = card

				local nameText = pet.species
				if pet.variant and pet.variant ~= "Standard" then
					nameText = "[" .. pet.variant .. "] " .. nameText
				end

				local nameLabel = Instance.new("TextLabel")
				nameLabel.Name = "Species"
				nameLabel.Text = nameText
				nameLabel.Font = Enum.Font.GothamBold
				nameLabel.TextSize = 15
				nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
				nameLabel.TextXAlignment = Enum.TextXAlignment.Left
				nameLabel.Size = UDim2.new(1, -120, 0, 22)
				nameLabel.Position = UDim2.new(0, 0, 0, 8)
				nameLabel.BackgroundTransparency = 1
				nameLabel.Parent = card

				local rarityBadge = Instance.new("TextLabel")
				rarityBadge.Name = "Rarity"
				rarityBadge.Text = pet.rarity:upper()
				rarityBadge.Font = Enum.Font.GothamBold
				rarityBadge.TextSize = 11
				rarityBadge.TextColor3 = rarityColor
				rarityBadge.TextXAlignment = Enum.TextXAlignment.Left
				rarityBadge.Size = UDim2.new(1, -120, 0, 18)
				rarityBadge.Position = UDim2.new(0, 0, 0, 30)
				rarityBadge.BackgroundTransparency = 1
				rarityBadge.Parent = card

				local actionBtn = Instance.new("TextButton")
				actionBtn.Name = "Action"
				actionBtn.Size = UDim2.new(0, 105, 0, 38)
				actionBtn.Position = UDim2.new(1, -105, 0.5, -19)
				actionBtn.BorderSizePixel = 0
				actionBtn.Font = Enum.Font.GothamBold
				actionBtn.TextSize = 13
				actionBtn.Parent = card

				local btnCorner = Instance.new("UICorner")
				btnCorner.CornerRadius = UDim.new(0, 8)
				btnCorner.Parent = actionBtn

				local canEquip = equipped or #snapshot.equipped < Config.EquipSlots
				actionBtn.Active = canEquip
				actionBtn.AutoButtonColor = canEquip

				if equipped then
					actionBtn.BackgroundColor3 = Color3.fromRGB(231, 76, 60)
					actionBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
					actionBtn.Text = "UNEQUIP"
				elseif canEquip then
					actionBtn.BackgroundColor3 = Color3.fromRGB(46, 213, 115)
					actionBtn.TextColor3 = Color3.fromRGB(15, 25, 20)
					actionBtn.Text = "EQUIP"
				else
					actionBtn.BackgroundColor3 = Color3.fromRGB(45, 55, 75)
					actionBtn.TextColor3 = Color3.fromRGB(140, 150, 170)
					actionBtn.Text = "FULL (3/3)"
				end

				table.insert(rowConnections, actionBtn.Activated:Connect(function()
					if actionBtn.Active then
						remote:FireServer(if equipped then "Unequip" else "Equip", pet.id)
					end
				end))
			end
		else
			-- Tab: Index & Drop Rates
			local rateBanner = Instance.new("Frame")
			rateBanner.Size = UDim2.new(1, 0, 0, 64)
			rateBanner.BackgroundColor3 = Color3.fromRGB(28, 35, 54)
			rateBanner.BorderSizePixel = 0
			rateBanner.Parent = list

			local bannerCorner = Instance.new("UICorner")
			bannerCorner.CornerRadius = UDim.new(0, 8)
			bannerCorner.Parent = rateBanner

			local bannerText = Instance.new("TextLabel")
			bannerText.Size = UDim2.new(1, -20, 1, 0)
			bannerText.Position = UDim2.new(0, 10, 0, 0)
			bannerText.BackgroundTransparency = 1
			bannerText.Font = Enum.Font.GothamMedium
			bannerText.TextSize = 12
			bannerText.TextColor3 = Color3.fromRGB(240, 245, 255)
			bannerText.TextWrapped = true
			bannerText.Text = string.format("Discovery Chance: %.2f%% per depleted node.\nRarities roll after discovery. Equipped pets boost income multipliers.", Config.DiscoveryChance * 100)
			bannerText.Parent = rateBanner

			-- Rarity Rates
			for _, rarity in Config.RarityOrder do
				local chance = Config.Rarities[rarity].weight / totalRarityWeight
				local perNode = chance * Config.DiscoveryChance * 100
				local rarityColor = RARITY_COLORS[rarity] or Color3.fromRGB(200, 200, 200)

				local card = Instance.new("Frame")
				card.Size = UDim2.new(1, 0, 0, 38)
				card.BackgroundColor3 = Color3.fromRGB(22, 28, 44)
				card.BorderSizePixel = 0
				card.Parent = list

				local cCorner = Instance.new("UICorner")
				cCorner.CornerRadius = UDim.new(0, 6)
				cCorner.Parent = card

				local label = Instance.new("TextLabel")
				label.Size = UDim2.new(1, -20, 1, 0)
				label.Position = UDim2.new(0, 10, 0, 0)
				label.BackgroundTransparency = 1
				label.Font = Enum.Font.GothamMedium
				label.TextSize = 13
				label.TextColor3 = rarityColor
				label.TextXAlignment = Enum.TextXAlignment.Left
				label.Text = string.format("● %s: %.1f%% roll  (%.4f%% per node)", rarity, chance * 100, perNode)
				label.Parent = card
			end

			-- Species Index
			local speciesHeader = Instance.new("TextLabel")
			speciesHeader.Text = "DISCOVERED SPECIES BY PLANET"
			speciesHeader.Font = Enum.Font.GothamBold
			speciesHeader.TextSize = 13
			speciesHeader.TextColor3 = Color3.fromRGB(80, 227, 194)
			speciesHeader.Size = UDim2.new(1, 0, 0, 28)
			speciesHeader.TextXAlignment = Enum.TextXAlignment.Left
			speciesHeader.BackgroundTransparency = 1
			speciesHeader.Parent = list

			for poolName, pool in Config.Pools do
				for _, rarity in Config.RarityOrder do
					for _, species in pool[rarity] do
						local discovered = snapshot.index and snapshot.index[species] == true
						local rarityColor = RARITY_COLORS[rarity] or Color3.fromRGB(200, 200, 200)

						local row = Instance.new("Frame")
						row.Size = UDim2.new(1, 0, 0, 36)
						row.BackgroundColor3 = Color3.fromRGB(22, 28, 44)
						row.BorderSizePixel = 0
						row.Parent = list

						local rCorner = Instance.new("UICorner")
						rCorner.CornerRadius = UDim.new(0, 6)
						rCorner.Parent = row

						local rowStroke = Instance.new("UIStroke")
						rowStroke.Color = rarityColor
						rowStroke.Transparency = if discovered then 0.6 else 0.9
						rowStroke.Parent = row

						local rowLabel = Instance.new("TextLabel")
						rowLabel.Size = UDim2.new(1, -20, 1, 0)
						rowLabel.Position = UDim2.new(0, 10, 0, 0)
						rowLabel.BackgroundTransparency = 1
						rowLabel.Font = Enum.Font.GothamMedium
						rowLabel.TextSize = 12
						rowLabel.TextColor3 = if discovered then Color3.fromRGB(240, 245, 255) else Color3.fromRGB(120, 130, 150)
						rowLabel.TextXAlignment = Enum.TextXAlignment.Left
						rowLabel.Text = string.format("[%s] %s  ·  %s", poolName, if discovered then species else "???", rarity)
						rowLabel.Parent = row
					end
				end
			end
		end
	end

	-- Reveal Notification Card (When discovering a pet)
	local reveal = Instance.new("Frame")
	reveal.Name = "PetRevealCard"
	reveal.AnchorPoint = Vector2.new(0.5, 0)
	reveal.Position = UDim2.fromScale(0.5, 0.12)
	reveal.Size = UDim2.fromScale(0.85, 0.14)
	reveal.BackgroundColor3 = Color3.fromRGB(20, 16, 36)
	reveal.BorderSizePixel = 0
	reveal.Visible = false
	reveal.Parent = gui

	local revealConstraint = Instance.new("UISizeConstraint")
	revealConstraint.MaxSize = Vector2.new(460, 90)
	revealConstraint.Parent = reveal

	local revealCorner = Instance.new("UICorner")
	revealCorner.CornerRadius = UDim.new(0, 12)
	revealCorner.Parent = reveal

	local revealStroke = Instance.new("UIStroke")
	revealStroke.Color = Color3.fromRGB(241, 196, 15)
	revealStroke.Thickness = 2
	revealStroke.Parent = reveal

	local revealTitle = Instance.new("TextLabel")
	revealTitle.Text = "🎉 PET UNCOVERED!"
	revealTitle.Font = Enum.Font.GothamBold
	revealTitle.TextSize = 18
	revealTitle.TextColor3 = Color3.fromRGB(241, 196, 15)
	revealTitle.Size = UDim2.new(1, 0, 0, 26)
	revealTitle.Position = UDim2.new(0, 0, 0, 12)
	revealTitle.BackgroundTransparency = 1
	revealTitle.Parent = reveal

	local revealBody = Instance.new("TextLabel")
	revealBody.Text = "Species Details"
	revealBody.Font = Enum.Font.GothamMedium
	revealBody.TextSize = 14
	revealBody.TextColor3 = Color3.fromRGB(255, 255, 255)
	revealBody.Size = UDim2.new(1, 0, 0, 24)
	revealBody.Position = UDim2.new(0, 0, 0, 42)
	revealBody.BackgroundTransparency = 1
	revealBody.Parent = reveal

	local expires = 0

	local function openPanel()
		panel.Visible = true
		backdrop.Visible = true
		remote:FireServer("Sync")
		render()
	end

	local function closePanel()
		panel.Visible = false
		backdrop.Visible = false
	end

	table.insert(connections, open.Activated:Connect(openPanel))
	table.insert(connections, close.Activated:Connect(closePanel))
	table.insert(connections, backdrop.Activated:Connect(closePanel))

	table.insert(connections, invTabBtn.Activated:Connect(function()
		currentTab = "Inventory"
		render()
	end))
	table.insert(connections, indexTabBtn.Activated:Connect(function()
		currentTab = "Index"
		render()
	end))

	table.insert(connections, remote.OnClientEvent:Connect(function(action, payload)
		if action == "OpenUI" then
			openPanel()
		elseif action == "State" then
			snapshot = payload
			render()
		elseif action == "Found" and typeof(payload) == "table" then
			expires += 1
			local version = expires
			local rarityColor = RARITY_COLORS[payload.rarity] or Color3.fromRGB(241, 196, 15)
			revealStroke.Color = rarityColor
			revealTitle.TextColor3 = rarityColor
			revealBody.Text = payload.species .. "  (" .. payload.rarity .. " / " .. payload.variant .. ")"
			reveal.Visible = true
			reveal.BackgroundTransparency = 1

			TweenService:Create(reveal, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
				BackgroundTransparency = 0.05,
			}):Play()

			task.delay(Config.Visual.RevealSeconds or 4, function()
				if version == expires and gui.Parent then
					reveal.Visible = false
				end
			end)
		end
	end))

	table.insert(connections, gui.Destroying:Connect(function()
		expires += 1
		for _, c in connections do c:Disconnect() end
		for _, c in rowConnections do c:Disconnect() end
		table.clear(connections)
		table.clear(rowConnections)
		started = false
	end))

	render()
	gui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
	remote:FireServer("Sync")
end

return Controller
