--!strict
local Lighting = game:GetService("Lighting")
local Physics = game:GetService("PhysicsService")
local Config = script.Parent.Parent.config
local Settings = require(Config.WorldLook)
local Palette = require(Config.Palette)
local Assets = require(Config.Assets)
local Cleaning = require(Config.Cleaning)
local PartBuilder = require(script.Parent.AssetBuilder)
local OutpostBuilder = require(script.Parent.OutpostBuilder)
local Builder = {}

function Builder.Build(parent: Instance): ()
	if parent:FindFirstChild("WorldLook") then return end
	if not Physics:IsCollisionGroupRegistered("Decor") then Physics:RegisterCollisionGroup("Decor") end
	Physics:CollisionGroupSetCollidable("Decor", "Default", false)
	local folder = Instance.new("Folder")
	folder.Name = "WorldLook"
	folder.Parent = parent
	Lighting.Ambient = Palette.Ambient
	Lighting.OutdoorAmbient = Palette.OutdoorAmbient
	Lighting.Brightness = Settings.Brightness
	Lighting.ClockTime = Settings.ClockTime
	Lighting.GeographicLatitude = Settings.Latitude
	Lighting.ExposureCompensation = Settings.Exposure
	Lighting.GlobalShadows = true
	Lighting.ShadowSoftness = 0.7
	Lighting.FogColor = Palette.Space
	Lighting.FogStart = Settings.SkyRadius * 2
	Lighting.FogEnd = Settings.SkyRadius * 3
	local atmosphere = Instance.new("Atmosphere")
	atmosphere.Name = "SweeperAtmosphere"
	atmosphere.Density = 0
	atmosphere.Haze = 0
	atmosphere.Glare = 0
	atmosphere.Parent = Lighting
	local correction = Instance.new("ColorCorrectionEffect")
	correction.Name = "SweeperColor"
	correction.TintColor = Palette.Tint
	correction.Contrast = Settings.Contrast
	correction.Saturation = Settings.Saturation
	correction.Parent = Lighting
	local bloom = Instance.new("BloomEffect")
	bloom.Intensity = Settings.BloomIntensity
	bloom.Size = Settings.BloomSize
	bloom.Threshold = Settings.BloomThreshold
	bloom.Parent = Lighting
	local rays = Instance.new("SunRaysEffect")
	rays.Intensity = Settings.SunRaysIntensity
	rays.Parent = Lighting
	local sky = Instance.new("Sky")
	sky.Name = "SweeperSky"
	sky.CelestialBodiesShown = false
	sky.StarCount = 0
	for _, face in {"SkyboxBk", "SkyboxDn", "SkyboxFt", "SkyboxLf", "SkyboxRt", "SkyboxUp"} do (sky :: any)[face] = "" end
	sky.Parent = Lighting
	-- Six opaque, unlit walls provide black space without skybox textures.
	local origin = Cleaning.Origin
	for _, axis in {Vector3.xAxis, Vector3.yAxis, Vector3.zAxis} do
		for _, sign in {-1, 1} do
			local normal = axis * sign
			local wall = PartBuilder.Part("SpaceWall", folder, Vector3.new(Settings.SkyRadius * 2, Settings.SkyRadius * 2, 1), CFrame.lookAt(origin + normal * Settings.SkyRadius, origin, if axis == Vector3.yAxis then Vector3.zAxis else Vector3.yAxis), Palette.Space)
			wall.Material = Enum.Material.Neon
		end
	end
	local random = Random.new(Settings.Seed)
	for _ = 1, Settings.StarCount do
		local direction = Vector3.new(random:NextNumber(-1, 1), random:NextNumber(0.12, 1), random:NextNumber(-1, 1)).Unit
		local star = PartBuilder.Part("Star", folder, Vector3.one * Settings.StarSize, CFrame.new(origin + direction * Settings.SkyRadius * 0.8), Palette.Stars, Enum.PartType.Ball)
		star.Material = Enum.Material.Neon
	end
	local earth = PartBuilder.Part("Earth", folder, Vector3.one * Settings.EarthSize, CFrame.new(origin + Settings.EarthOffset), Palette.Earth, Enum.PartType.Ball)
	if Assets.Earth.MeshId == "" and Assets.Earth.ModelId == "" then
		for index = 1, 7 do
			local direction = Vector3.new(random:NextNumber(-0.6, 0.6), random:NextNumber(-0.6, 0.6), 1).Unit
			PartBuilder.Part("EarthDetail", folder, Vector3.one * Settings.EarthSize * 0.35, CFrame.new(earth.Position + direction * Settings.EarthSize * 0.41), if index % 3 == 0 then Palette.SuitWhite else Palette.EarthLand, Enum.PartType.Ball)
		end
	end
	local sun = PartBuilder.Part("Sun", folder, Vector3.one * Settings.SunSize, CFrame.new(origin + Settings.SunOffset), Palette.Sun, Enum.PartType.Ball)
	sun.Material = Enum.Material.Neon
	local terrain = workspace.Terrain
	terrain:SetMaterialColor(Enum.Material.Mud, Palette.Ground)
	-- Only the Moonlet footprint is written. No Terrain:Clear or writes near other planets.
	for x = -Settings.Radius, Settings.Radius - Settings.Cell, Settings.Cell do
		for z = -Settings.Radius, Settings.Radius - Settings.Cell, Settings.Cell do
			local distance = Vector2.new(x, z).Magnitude
			if distance > Settings.Radius then continue end
			local blend = math.clamp((distance - Settings.FlatRadius) / (Settings.Radius - Settings.FlatRadius), 0, 1)
			local height = origin.Y + Cleaning.GroundThickness / 2 + blend * (Settings.HillHeight * math.sin(blend * math.pi) + math.noise(x / Settings.NoiseScale, z / Settings.NoiseScale, Settings.Seed) * Settings.NoiseHeight)
			local thickness = height - Settings.Bottom
			terrain:FillBlock(CFrame.new(origin.X + x + Settings.Cell / 2, Settings.Bottom + thickness / 2, origin.Z + z + Settings.Cell / 2), Vector3.new(Settings.Cell, thickness, Settings.Cell), Enum.Material.Mud)
		end
		if ((x + Settings.Radius) / Settings.Cell) % Settings.ChunkColumns == 0 then task.wait() end
	end
	for _ = 1, Settings.CraterCount do
		local angle = random:NextNumber(0, math.pi * 2)
		local radius = random:NextNumber(Settings.CraterStart, Settings.CraterEnd)
		local x, z = math.cos(angle) * radius, math.sin(angle) * radius
		local blend = math.clamp((radius - Settings.FlatRadius) / (Settings.Radius - Settings.FlatRadius), 0, 1)
		local height = origin.Y + Cleaning.GroundThickness / 2 + blend * (Settings.HillHeight * math.sin(blend * math.pi) + math.noise(x / Settings.NoiseScale, z / Settings.NoiseScale, Settings.Seed) * Settings.NoiseHeight)
		terrain:FillBall(Vector3.new(origin.X + x, height + Settings.CraterRadius * 0.55, origin.Z + z), Settings.CraterRadius, Enum.Material.Air)
	end
	local ground = parent:FindFirstChild("Ground")
	if ground and ground:IsA("BasePart") then ground.Color = Palette.Ground; ground.Transparency = 1 end
	OutpostBuilder.BuildOutpost(folder, origin)
end
return Builder
