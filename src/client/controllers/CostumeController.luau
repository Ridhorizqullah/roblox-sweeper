--!strict
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Config = require(RS.Shared.config.Costume)
local Builder = require(RS.Shared.art.AstronautBuilder)
local Controller = {}
local started = false

function Controller.Start()
	if started then return end
	started = true
	local folder = Instance.new("Folder")
	folder.Name = "LocalBootDust"
	folder.Parent = workspace
	local pool: {{part: BasePart, age: number, origin: Vector3}} = {}
	for _ = 1, Config.Dust.PoolSize do
		table.insert(pool, {part = Builder.Dust(folder), age = Config.Dust.Lifetime, origin = Vector3.zero})
	end
	local hidden: {[BasePart]: number} = {}
	local nextStep: {[Player]: number} = {}
	local sides: {[Player]: number} = {}
	local cursor = 0
	local accumulator = 0
	local clock = 0
	local function restore()
		for part, original in hidden do
			if part.Parent then part.LocalTransparencyModifier = original end
		end
		table.clear(hidden)
	end
	local removing = Players.PlayerRemoving:Connect(function(player)
		nextStep[player] = nil; sides[player] = nil
	end)
	local heartbeat = RunService.Heartbeat:Connect(function(dt)
		accumulator += dt
		if accumulator < Config.Dust.Tick then return end
		local elapsed = accumulator
		accumulator = 0
		clock += elapsed
		local camera = workspace.CurrentCamera
		if not camera then return end
		local localCharacter = Players.LocalPlayer.Character
		local head = localCharacter and localCharacter:FindFirstChild("Head")
		local firstPerson = head and head:IsA("BasePart") and (camera.CFrame.Position - head.Position).Magnitude < Config.FirstPersonDistance
		if firstPerson and localCharacter then
			local suit = localCharacter:FindFirstChild(Config.Name)
			if suit then
				for _, part in suit:GetChildren() do
					if part:IsA("BasePart") and part:GetAttribute("Helmet") then
						if hidden[part] == nil then hidden[part] = part.LocalTransparencyModifier end
						part.LocalTransparencyModifier = 1
					end
				end
			end
			for part in hidden do if not part.Parent then hidden[part] = nil end end
		else restore() end
		for _, puff in pool do
			puff.age = math.min(puff.age + elapsed, Config.Dust.Lifetime)
			local alpha = puff.age / Config.Dust.Lifetime
			puff.part.Transparency = Config.Dust.Transparency + (1 - Config.Dust.Transparency) * alpha
			puff.part.Size = Config.Dust.Size * (1 + alpha * Config.Dust.Growth)
			puff.part.Position = puff.origin + Vector3.new(0, alpha * Config.Dust.Rise, 0)
		end
		for _, player in Players:GetPlayers() do
			local character = player.Character
			local root = character and character:FindFirstChild("HumanoidRootPart")
			local humanoid = character and character:FindFirstChildOfClass("Humanoid")
			if not character or not character:FindFirstChild(Config.Name) or not root or not root:IsA("BasePart") or not humanoid then continue end
			if humanoid.Health <= 0 or humanoid.Sit or humanoid.FloorMaterial == Enum.Material.Air then continue end
			if humanoid.MoveDirection.Magnitude == 0 or Vector3.new(root.AssemblyLinearVelocity.X, 0, root.AssemblyLinearVelocity.Z).Magnitude < Config.Dust.MinimumSpeed then continue end
			if (camera.CFrame.Position - root.Position).Magnitude > Config.Dust.CullDistance or clock < (nextStep[player] or 0) then continue end
			nextStep[player] = clock + Config.Dust.StepInterval
			sides[player] = -(sides[player] or 1)
			local params = RaycastParams.new()
			params.FilterType = Enum.RaycastFilterType.Exclude
			params.FilterDescendantsInstances = {character, folder}
			local origin = root.Position + root.CFrame.RightVector * Config.Dust.FootOffset * sides[player]
			local hit = workspace:Raycast(origin, Vector3.new(0, -Config.Dust.RayLength, 0), params)
			if hit then
				cursor = cursor % #pool + 1
				local puff = pool[cursor]
				puff.age = 0; puff.origin = hit.Position
				puff.part.Position = hit.Position
				puff.part.Size = Config.Dust.Size
				puff.part.Transparency = Config.Dust.Transparency
			end
		end
	end)
	script.Destroying:Once(function()
		heartbeat:Disconnect(); removing:Disconnect()
		restore(); folder:Destroy()
		table.clear(pool); table.clear(nextStep); table.clear(sides)
	end)
end
return Controller
