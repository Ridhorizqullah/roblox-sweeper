--!strict
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local Layout = require(RS.Shared.config.Layout)
local Planets = require(RS.Shared.config.Planets)
local Cleaning = require(RS.Shared.config.Cleaning)
local World = require(script.Parent.WorldService)
local Data = require(script.Parent.DataService)
local State = require(script.Parent.PlayerStateService)
local Service = {}
local last: {[Player]: number} = {}
local connections: {RBXScriptConnection} = {}
local initialized = false
function Service.Init(): ()
	if initialized then return end
	initialized = true
	for _, sourceId in Planets.Order do
		local source = World.GetSpawn(sourceId)
		local slot = 0
		for targetIndex, targetId in Planets.Order do
			if sourceId == targetId then continue end
			local definition = Planets.ById[targetId]
			local portal = Instance.new("Part")
			portal.Name = "Portal_" .. targetId
			portal.Size = Layout.Portal.Size
			portal.CFrame = Layout.GetCFrame(source.Position, Layout.Portal.Center + Vector2.new(slot * (Layout.Portal.Spacing or 14), 0), Layout.Portal.Size, true)
			portal.Anchored = true
			portal.Material = Enum.Material.Neon
			portal.Color = definition.dirtColor
			portal.Parent = source.Parent
			slot += 1

			local billboard = Instance.new("BillboardGui")
			billboard.Name = "Instructions"
			billboard.Size = UDim2.fromOffset(240, 56)
			billboard.StudsOffset = Layout.Portal.StudsOffset
			billboard.MaxDistance = 40
			billboard.AlwaysOnTop = true
			billboard.Adornee = portal

			local label = Instance.new("TextLabel")
			label.Size = UDim2.fromScale(1, 1)
			label.BackgroundTransparency = 1
			label.Text = "PORTAL: " .. definition.name:upper() .. "\n$" .. definition.unlockPrice
			label.TextColor3 = Color3.fromRGB(255, 255, 255)
			label.TextStrokeTransparency = 0.2
			label.TextStrokeColor3 = Color3.fromRGB(20, 25, 35)
			label.TextSize = 15
			label.TextWrapped = true
			label.Font = Enum.Font.GothamBold
			label.Parent = billboard
			billboard.Parent = portal

			local prompt = Instance.new("ProximityPrompt")
			prompt.ActionText = "Travel / unlock $" .. definition.unlockPrice
			prompt.ObjectText = definition.name .. " (owned: free)"
			prompt.MaxActivationDistance = Layout.Portal.MaxDistance
			prompt.HoldDuration = Planets.Portal.HoldSeconds
			prompt.RequiresLineOfSight = false
			prompt.Parent = portal
			table.insert(connections, prompt.Triggered:Connect(function(player)
				local now = os.clock()
				if now - (last[player] or -math.huge) < Planets.Portal.Cooldown then return end
				last[player] = now
				local data = Data.Get(player)
				local character = player.Character
				local root = character and character:FindFirstChild("HumanoidRootPart")
				local humanoid = character and character:FindFirstChildOfClass("Humanoid")
				if not data or not character or not root or not root:IsA("BasePart") or not humanoid or humanoid.Health <= 0 then return end
				if not ((root.Position - portal.Position).Magnitude <= Planets.Portal.Radius) then return end
				if data.currentPlanet ~= sourceId or not data.unlockedPlanets[sourceId] then return end
				if not data.unlockedPlanets[targetId] then
					local previous = Planets.Order[targetIndex - 1]
					if previous and not data.unlockedPlanets[previous] then return end
					local cost = definition.unlockPrice
					if cost ~= cost or cost < 0 or cost == math.huge or data.money < cost then return end
					-- Atomic unlock: a repeated prompt sees ownership before any deduction.
					data.money -= cost
					data.unlockedPlanets[targetId] = true
				end
				local destination = World.GetSpawn(targetId)
				data.currentPlanet = targetId
				player.RespawnLocation = destination
				character:PivotTo(destination.CFrame + Vector3.new(0, Cleaning.SpawnLift, 0))
				root.AssemblyLinearVelocity = Vector3.zero
				root.AssemblyAngularVelocity = Vector3.zero
				State.Publish(player)
			end))
		end
	end
	table.insert(connections, Players.PlayerRemoving:Connect(function(player) last[player] = nil end))
	game:BindToClose(function()
		for _, connection in connections do connection:Disconnect() end
		table.clear(connections)
		table.clear(last)
	end)
end
return Service
