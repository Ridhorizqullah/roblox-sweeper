--!strict
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Config = require(RS.Shared.config.Pets)
local Controller = {}
local started = false
function Controller.Start(): ()
	if started then return end
	started = true
	local remote = RS:WaitForChild("PlanetSweepersPets") :: RemoteEvent
	local gui = Instance.new("ScreenGui")
	gui.Name = "PetInventory"
	gui.ResetOnSpawn = false
	local connections: {RBXScriptConnection} = {}
	local rowConnections: {RBXScriptConnection} = {}
	local snapshot: any = {pets = {}, equipped = {}, index = {}, multiplier = 1}
	local function button(parent: Instance, text: string): TextButton
		local b = Instance.new("TextButton")
		b.Text = text
		b.TextWrapped = true
		b.TextSize = 16
		b.TextColor3 = Color3.new(1, 1, 1)
		b.BackgroundColor3 = Color3.fromRGB(70, 105, 140)
		b.Size = UDim2.new(1, -8, 0, 56)
		b.Parent = parent
		return b
	end
	local open = button(gui, "PETS")
	open.Size = UDim2.fromOffset(100, 48)
	open.AnchorPoint = Vector2.new(1, 0)
	open.Position = UDim2.new(1, -16, 0, 16)
	local panel = Instance.new("Frame")
	panel.Size = UDim2.fromScale(0.92, 0.8)
	panel.Position = UDim2.fromScale(0.5, 0.55)
	panel.AnchorPoint = Vector2.new(0.5, 0.5)
	panel.BackgroundColor3 = Color3.fromRGB(21, 29, 43)
	panel.Visible = false
	panel.Parent = gui
	local constraint = Instance.new("UISizeConstraint")
	constraint.MaxSize = Vector2.new(560, 620)
	constraint.Parent = panel
	local close = button(panel, "Close pets")
	local list = Instance.new("ScrollingFrame")
	list.Position = UDim2.fromOffset(4, 60)
	list.Size = UDim2.new(1, -8, 1, -64)
	list.BackgroundTransparency = 1
	list.AutomaticCanvasSize = Enum.AutomaticSize.Y
	list.CanvasSize = UDim2.new()
	list.Parent = panel
	local layout = Instance.new("UIListLayout")
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Padding = UDim.new(0, 5)
	layout.Parent = list
	local function render()
		for _, connection in rowConnections do connection:Disconnect() end
		table.clear(rowConnections)
		for _, child in list:GetChildren() do if child:IsA("GuiObject") then child:Destroy() end end
		local order = 0
		local function row(text: string): TextButton
			order += 1
			local b = button(list, text)
			b.LayoutOrder = order
			b.Active = false
			b.AutoButtonColor = false
			return b
		end
		row(string.format("Income x%.2f | Equipped %d/%d | Inventory %d/%d", snapshot.multiplier, #snapshot.equipped, Config.EquipSlots, #snapshot.pets, Config.MaximumInventory))
		row(string.format("Discovery: %.2f%% per depleted node. Full inventory: no drops. Duplicates possible.", Config.DiscoveryChance * 100))
		local total = 0
		for _, rarity in Config.RarityOrder do total += Config.Rarities[rarity].weight end
		for _, rarity in Config.RarityOrder do
			local chance = Config.Rarities[rarity].weight / total
			row(string.format("%s: %.2f%% of discoveries | %.4f%% per node", rarity, chance * 100, chance * Config.DiscoveryChance * 100))
		end
		for _, variant in Config.VariantOrder do
			row(string.format("%s: %.2f%% of discoveries | pet bonus x%.1f", variant, Config.Variants[variant].chance * 100, Config.Variants[variant].bonusMultiplier))
		end
		row("INVENTORY — tap to equip / unequip")
		for _, pet in snapshot.pets do
			local equipped = table.find(snapshot.equipped, pet.id) ~= nil
			local b = row(pet.species .. " | " .. pet.rarity .. " / " .. pet.variant .. " | " .. (if equipped then "Unequip" else "Equip"))
			b.Active = equipped or #snapshot.equipped < Config.EquipSlots
			b.AutoButtonColor = b.Active
			table.insert(rowConnections, b.Activated:Connect(function()
				if b.Active then remote:FireServer(if equipped then "Unequip" else "Equip", pet.id) end
			end))
		end
		row("PET INDEX — all planets; species are equally likely within each rarity")
		for poolName, pool in Config.Pools do
			for _, rarity in Config.RarityOrder do
				for _, species in pool[rarity] do
					row(poolName .. " | " .. rarity .. " | " .. (if snapshot.index[species] then species else "???") .. string.format(" | %.4f%%/node", Config.DiscoveryChance * Config.Rarities[rarity].weight / total / #pool[rarity] * 100))
				end
			end
		end
	end
	local reveal = button(gui, "")
	reveal.AnchorPoint = Vector2.new(0.5, 0)
	reveal.Position = UDim2.fromScale(0.5, 0.15)
	reveal.Size = UDim2.fromScale(0.85, 0.12)
	reveal.Visible = false
	local expires = 0
	table.insert(connections, open.Activated:Connect(function() panel.Visible = not panel.Visible; remote:FireServer("Sync") end))
	table.insert(connections, close.Activated:Connect(function() panel.Visible = false end))
	table.insert(connections, remote.OnClientEvent:Connect(function(action, payload)
		if action == "State" then snapshot = payload; render()
		elseif action == "Found" then
			expires += 1
			local version = expires
			reveal.Text = "PET FOUND! " .. payload.species .. "\n" .. payload.rarity .. " / " .. payload.variant
			reveal.Visible = true
			reveal.BackgroundTransparency = 1
			TweenService:Create(reveal, TweenInfo.new(Config.RequestCooldown), {BackgroundTransparency = 0}):Play()
			task.delay(Config.Visual.RevealSeconds, function() if version == expires and gui.Parent then reveal.Visible = false end end)
		end
	end))
	table.insert(connections, gui.Destroying:Connect(function()
		expires += 1
		for _, c in connections do c:Disconnect() end
		for _, c in rowConnections do c:Disconnect() end
		started = false
	end))
	render()
	gui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
	remote:FireServer("Sync")
end
return Controller
