--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
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
	local panel = Instance.new("Frame")
	panel.AnchorPoint = Vector2.new(0.5, 0.5)
	panel.Position = UDim2.fromScale(0.5, 0.5)
	panel.Size = UDim2.fromScale(0.92, 0.85)
	panel.BackgroundColor3 = Color3.fromRGB(21, 29, 43)
	panel.Parent = gui
	local limit = Instance.new("UISizeConstraint")
	limit.MaxSize = Vector2.new(Shop.PanelWidth, Shop.PanelHeight)
	limit.Parent = panel
	local title = Instance.new("TextLabel")
	title.Text = "TOOLS & BAGS"
	title.Size = UDim2.new(1, -64, 0, 48)
	title.TextColor3 = Color3.new(1, 1, 1)
	title.TextSize = 22
	title.BackgroundTransparency = 1
	title.Parent = panel
	local close = Instance.new("TextButton")
	close.Text = "X"
	close.Size = UDim2.fromOffset(48, 48)
	close.Position = UDim2.new(1, -48, 0, 0)
	close.Parent = panel
	local status = Instance.new("TextLabel")
	status.Size = UDim2.new(1, 0, 0, 36)
	status.Position = UDim2.fromOffset(0, 48)
	status.BackgroundTransparency = 1
	status.TextColor3 = Color3.new(1, 1, 1)
	status.Text = "Pembelian hanya dekat toko."
	status.TextSize = 14
	status.Parent = panel
	local list = Instance.new("ScrollingFrame")
	list.Position = UDim2.fromOffset(8, 88)
	list.Size = UDim2.new(1, -16, 1, -96)
	list.BackgroundTransparency = 1
	list.AutomaticCanvasSize = Enum.AutomaticSize.Y
	list.CanvasSize = UDim2.new()
	list.ScrollBarThickness = 6
	list.Parent = panel
	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 6)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = list
	local connections: {RBXScriptConnection} = {}
	local rows: {[string]: TextButton} = {}
	local function button(id: string, order: number): TextButton
		local row = Instance.new("TextButton")
		row.Size = UDim2.new(1, -8, 0, Shop.RowHeight)
		row.LayoutOrder = order
		row.TextSize = 16
		row.TextWrapped = true
		row.TextColor3 = Color3.new(1, 1, 1)
		row.Parent = list
		rows[id] = row
		return row
	end
	for index, id in Tools.Order do
		local row = button(id, index)
		table.insert(connections, row.Activated:Connect(function()
			if row.Active then remote:FireServer("Tool", id) end
		end))
	end
	local bag = button("Bag", #Tools.Order + 1)
	table.insert(connections, bag.Activated:Connect(function()
		if bag.Active then remote:FireServer("Bag", tostring((state:GetAttribute("BagLevel") or 0) + 1)) end
	end))
	for index, id in Vehicles.Order do
		local row = button("Robot_" .. id, #Tools.Order + 1 + index)
		table.insert(connections, row.Activated:Connect(function()
			if row.Active then remote:FireServer("Robot", id, state:GetAttribute("Robot_" .. id) or 0) end
		end))
	end
	local function render()
		local ready = state:GetAttribute("DataReady") == true
		local money = state:GetAttribute("Money") or 0
		local robotTotal = 0
		for _, id in Vehicles.Order do robotTotal += state:GetAttribute("Robot_" .. id) or 0 end
		for _, id in Vehicles.Order do
			local definition = Vehicles.ById[id]
			local row = rows["Robot_" .. id]
			row.Active = ready and robotTotal < Vehicles.MaximumRobots and money >= definition.price
			row.AutoButtonColor = row.Active
			row.BackgroundColor3 = if row.Active then Shop.Color else Color3.fromRGB(60, 65, 75)
			row.Text = definition.name .. " | $" .. Format.Format(definition.price) .. " | Owned " .. (state:GetAttribute("Robot_" .. id) or 0) .. "\nRobot slots " .. robotTotal .. "/" .. Vehicles.MaximumRobots
		end
		local equippedDefinition = Tools.ById[state:GetAttribute("EquippedTool") or "Toothbrush"]
		local world = workspace:FindFirstChild("PlanetSweepersWorld")
		local dirt = if world then world:FindFirstChild("DirtNodes") else nil
		if dirt and equippedDefinition then
			for _, node in dirt:GetChildren() do
				local prompt = node:FindFirstChildOfClass("ProximityPrompt")
				if prompt then prompt.MaxActivationDistance = equippedDefinition.range end
			end
		end
		for _, id in Tools.Order do
			local definition = Tools.ById[id]
			local row = rows[id]
			local owned = state:GetAttribute("Owned_" .. id) == true
			local equipped = state:GetAttribute("EquippedTool") == id
			local previous = Tools.Order[definition.level]
			local unlocked = previous == nil or state:GetAttribute("Owned_" .. previous) == true
			local cost = math.ceil(definition.price)
			row.Active = ready and not equipped and (owned or (unlocked and money >= cost))
			row.AutoButtonColor = row.Active
			row.BackgroundColor3 = if row.Active then Shop.Color else Color3.fromRGB(60, 65, 75)
			local action = if equipped then "Equipped" elseif owned then "Equip" elseif not unlocked then "Locked" else "$" .. Format.Format(cost)
			row.Text = definition.name .. " | " .. action .. "\nPower " .. definition.power .. " · " .. definition.speed .. "s · Range " .. definition.range
		end
		local level = state:GetAttribute("BagLevel") or 0
		local cost = math.ceil(Bags.BaseCost * Bags.CostGrowth ^ level)
		bag.Active = ready and level < Bags.MaximumLevel and money >= cost
		bag.AutoButtonColor = bag.Active
		bag.BackgroundColor3 = if bag.Active then Shop.Color else Color3.fromRGB(60, 65, 75)
		bag.Text = if level >= Bags.MaximumLevel then "Bag MAX" else "Bag level " .. (level + 1) .. " | $" .. Format.Format(cost) .. "\nCapacity " .. (Bags.BaseCapacity + Bags.CapacityPerLevel * (level + 1))
	end
	table.insert(connections, state.AttributeChanged:Connect(render))
	table.insert(connections, close.Activated:Connect(function() gui.Enabled = false end))
	table.insert(connections, remote.OnClientEvent:Connect(function(action, message)
		if action == "Open" then gui.Enabled = true; render()
		elseif action == "Result" and type(message) == "string" then status.Text = message end
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
