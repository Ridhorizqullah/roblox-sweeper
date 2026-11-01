--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
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

	local panel = Instance.new("Frame")
	panel.Name = "Panel"
	panel.Position = UDim2.fromOffset(Hud.Margin, Hud.Margin)
	panel.Size = UDim2.new(1, -Hud.Margin * 2, 0, Hud.Height)
	panel.BackgroundColor3 = Color3.fromRGB(21, 29, 43)
	panel.BorderSizePixel = 0
	panel.Parent = gui
	local constraint = Instance.new("UISizeConstraint")
	constraint.MaxSize = Vector2.new(Hud.Width, Hud.Height)
	constraint.Parent = panel

	local content = Instance.new("Frame")
	content.BackgroundTransparency = 1
	content.Position = UDim2.fromScale(0.04, 0.06)
	content.Size = UDim2.fromScale(0.92, 0.88)
	content.Parent = panel
	local layout = Instance.new("UIListLayout")
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = content

	local function label(name: string, order: number, height: number): TextLabel
		local text = Instance.new("TextLabel")
		text.Name = name
		text.LayoutOrder = order
		text.Size = UDim2.fromScale(1, height)
		text.BackgroundTransparency = 1
		text.Font = Enum.Font.GothamMedium
		text.TextColor3 = Color3.fromRGB(238, 244, 250)
		text.TextXAlignment = Enum.TextXAlignment.Left
		text.TextScaled = true
		text.Parent = content
		return text
	end
	local money = label("Money", 1, 0.23)
	local bag = label("Bag", 2, 0.20)
	local track = Instance.new("Frame")
	track.Name = "BagProgress"
	track.LayoutOrder = 3
	track.Size = UDim2.fromScale(1, 0.08)
	track.BackgroundColor3 = Color3.fromRGB(47, 60, 79)
	track.BorderSizePixel = 0
	track.ClipsDescendants = true
	track.Parent = content
	local fill = Instance.new("Frame")
	fill.Name = "Fill"
	fill.Size = UDim2.fromScale(0, 1)
	fill.BackgroundColor3 = Color3.fromRGB(83, 214, 165)
	fill.BorderSizePixel = 0
	fill.Parent = track
	local planet = label("Planet", 4, 0.23)
	local status = label("Status", 5, 0.23)
	status.TextColor3 = Color3.fromRGB(255, 210, 128)

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
			money.Text = "$ " .. FormatNumber.Format(balance)
			bag.Text = "Bag: " .. FormatNumber.Format(amount) .. " / " .. FormatNumber.Format(capacity)
			fill.Size = UDim2.fromScale(if capacity > 0 then math.clamp(amount / capacity, 0, 1) else 0, 1)
			planet.Text = "Planet: " .. definition.name
			status.Text = if temporary then "Studio: data sementara" else "Data siap"
		else
			money.Text = "$ —"
			bag.Text = "Bag: — / —"
			fill.Size = UDim2.fromScale(0, 1)
			planet.Text = "Planet: —"
			local message = if ready then "Data tidak tersedia" else "Memuat data..."
			status.Text = if temporary then message .. " · Studio: data sementara" else message
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
