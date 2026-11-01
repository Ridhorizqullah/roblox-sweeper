--!strict
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Http = game:GetService("HttpService")
local Config = require(game:GetService("ReplicatedStorage").Shared.config.Pets)
local Controller = {}
local started = false
function Controller.Start(): ()
	if started then return end
	started = true
	local folder = Instance.new("Folder")
	folder.Name = "LocalPetFollowers"
	folder.Parent = workspace
	local visuals: {[Player]: {parts: {Part}, source: string}} = {}
	local function clear(player: Player)
		local entry = visuals[player]
		if entry then for _, part in entry.parts do part:Destroy() end end
		visuals[player] = nil
	end
	local elapsed = 0
	local connection = RunService.RenderStepped:Connect(function(dt)
		elapsed += dt
		if elapsed >= Config.Visual.ReconcileSeconds then
			elapsed = 0
			local localRoot = Players.LocalPlayer.Character and Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
			for player in visuals do if player.Parent ~= Players then clear(player) end end
			for _, player in Players:GetPlayers() do
				local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
				local visible = root and root:IsA("BasePart") and localRoot and localRoot:IsA("BasePart") and (root.Position - localRoot.Position).Magnitude <= Config.Visual.CullDistance
				local source = player:GetAttribute("PetFollowers")
				if not visible or type(source) ~= "string" then clear(player); continue end
				if visuals[player] and visuals[player].source == source then continue end
				clear(player)
				local ok, pets = pcall(function() return Http:JSONDecode(source) end)
				if not ok or type(pets) ~= "table" then continue end
				local parts = {}
				for index, pet in pets do
					if index > Config.EquipSlots then break end
					local part = Instance.new("Part")
					part.Name = pet.species
					part.Shape = Enum.PartType.Ball
					part.Size = Vector3.one * Config.Visual.Size
					part.Anchored = true
					part.CanCollide = false
					part.CanTouch = false
					part.CanQuery = false
					part.Color = if pet.variant == "Gold" then Color3.fromRGB(255, 208, 60) else Color3.fromHSV((table.find(Config.RarityOrder, pet.rarity) or 1) / #Config.RarityOrder, 0.5, 1)
					part:SetAttribute("Rainbow", pet.variant == "Rainbow")
					part.Position = (root :: BasePart).Position
					part.Parent = folder
					local label = Instance.new("BillboardGui")
					label.Size = UDim2.fromOffset(120, 32)
					label.StudsOffset = Vector3.new(0, 2, 0)
					label.Parent = part
					local text = Instance.new("TextLabel")
					text.Size = UDim2.fromScale(1, 1)
					text.BackgroundTransparency = 1
					text.Text = pet.species
					text.TextColor3 = Color3.new(1, 1, 1)
					text.TextStrokeTransparency = 0
					text.Parent = label
					table.insert(parts, part)
				end
				visuals[player] = {source = source, parts = parts}
			end
		end
		for player, entry in visuals do
			local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
			if not root or not root:IsA("BasePart") then clear(player); continue end
			for index, part in entry.parts do
				local target = root.CFrame * CFrame.new((index - (#entry.parts + 1) / 2) * Config.Visual.Spacing, Config.Visual.Height, Config.Visual.Behind)
				part.CFrame = part.CFrame:Lerp(target, 1 - math.exp(-Config.Visual.FollowSpeed * dt))
				if part:GetAttribute("Rainbow") then part.Color = Color3.fromHSV((os.clock() / Config.Visual.RevealSeconds) % 1, 0.65, 1) end
			end
		end
	end)
	folder.Destroying:Once(function()
		connection:Disconnect()
		table.clear(visuals)
		started = false
	end)
end
return Controller
