--!strict
local RS = game:GetService("ReplicatedStorage")
local Config = require(script.Parent.Parent.config.Costume)
local Palette = require(script.Parent.Parent.config.Palette)
local Assets = require(script.Parent.Parent.config.Assets)
local Builder = {}

local function safePart(part: BasePart)
	part.Anchored = false
	part.Massless = true
	part.CanCollide = false
	part.CanTouch = false
	part.CanQuery = false
	part.CastShadow = false
	part.CollisionGroup = "Decor"
end

function Builder.Build(character: Model): Model?
	local head = character:FindFirstChild("Head")
	local torso = character:FindFirstChild("UpperTorso") or character:FindFirstChild("Torso")
	if not head or not head:IsA("BasePart") or not torso or not torso:IsA("BasePart") then return nil end
	local suit = Instance.new("Model")
	suit.Name = Config.Name
	local count = 0
	local function attach(name: string, rig: BasePart, scale: Vector3, offset: Vector3, color: Color3, ball: boolean?, slot: Assets.AssetEntry?): BasePart?
		local size = rig.Size * scale
		local cf = rig.CFrame * CFrame.new(rig.Size * offset)
		local library = RS:FindFirstChild("CustomAssets")
		local source = slot and slot.ModelId and slot.ModelId ~= "" and library and library:FindFirstChild(slot.ModelId)
		-- Copy only geometry, never executable descendants, constraints, or arbitrary imported instances.
		if source and source:IsA("Model") and (not slot or slot.MeshId == "") then
			local geometry: {BasePart} = {}
			for _, item in source:GetDescendants() do
				if item:IsA("BasePart") then table.insert(geometry, item) end
			end
			if #geometry > 0 and count + #geometry <= Config.PartBudget then
				local boundsCF, bounds = source:GetBoundingBox()
				local factor = math.min(size.X / math.max(bounds.X, 0.01), size.Y / math.max(bounds.Y, 0.01), size.Z / math.max(bounds.Z, 0.01))
				local first: BasePart? = nil
				for _, original in geometry do
					local part = original:Clone()
					part:ClearAllChildren()
					for _, child in original:GetChildren() do
						if child:IsA("DataModelMesh") or child:IsA("Decal") or child:IsA("Texture") then
							local visual = child:Clone()
							visual:ClearAllChildren()
							if visual:IsA("SpecialMesh") then visual.Scale *= factor end
							visual.Parent = part
						end
					end
					local relative = boundsCF:ToObjectSpace(original.CFrame)
					part.Size = original.Size * factor
					part.CFrame = cf * (relative.Rotation + relative.Position * factor)
					part.Name = name
					part:SetAttribute("Helmet", rig == head)
					safePart(part)
					local weld = Instance.new("WeldConstraint")
					weld.Part0 = rig; weld.Part1 = part; weld.Parent = part
					part.Parent = suit
					count += 1
					first = first or part
				end
				return first
			end
		end
		if count >= Config.PartBudget then return nil end
		local part = Instance.new("Part")
		part.Name = name
		part.Size = size
		part.CFrame = cf
		part.Color = color
		part.Material = Enum.Material.SmoothPlastic
		part.Shape = if ball then Enum.PartType.Ball else Enum.PartType.Block
		part:SetAttribute("Helmet", rig == head)
		safePart(part)
		if slot and slot.MeshId ~= "" then
			local mesh = Instance.new("SpecialMesh")
			mesh.MeshType = Enum.MeshType.FileMesh
			mesh.MeshId = slot.MeshId
			mesh.TextureId = slot.TextureId
			mesh.Scale = slot.Scale or size
			mesh.Parent = part
		elseif slot and slot.TextureId ~= "" then
			local decal = Instance.new("Decal")
			decal.Texture = slot.TextureId
			decal.Parent = part
		end
		local weld = Instance.new("WeldConstraint")
		weld.Part0 = rig; weld.Part1 = part; weld.Parent = part
		part.Parent = suit
		count += 1
		return part
	end
	-- Reserve the complete procedural silhouette before allowing multi-part replacements.
	local slots = Assets.Costumes
	attach("Helmet", head, Config.HelmetScale, Vector3.zero, Palette.SuitWhite, true)
	local visor = attach("Visor", head, Config.HelmetScale * Config.VisorScale, Config.VisorOffset, Palette.SuitVisor, true)
	if visor then visor.Reflectance = Config.VisorReflectance end
	attach("BackpackDetail", torso, Config.DetailScale, Config.DetailOffset, Palette.AccentOrange)
	for _, rig in character:GetChildren() do
		if rig:IsA("BasePart") and rig ~= head and rig.Name ~= "HumanoidRootPart" then
			local extremity = string.find(rig.Name, "Hand") or string.find(rig.Name, "Foot")
			attach("Shell", rig, Config.ShellScale, Vector3.zero, if extremity then Palette.SuitBackpack else Palette.SuitWhite)
			if string.find(rig.Name, "UpperArm") or string.find(rig.Name, "UpperLeg") or string.find(rig.Name, " Arm") or string.find(rig.Name, " Leg") then
				attach("Band", rig, Config.BandScale, Vector3.zero, Palette.SuitRed)
			end
			if string.find(rig.Name, " Arm") or string.find(rig.Name, " Leg") then
				attach("R6GloveBoot", rig, Config.R6ExtremityScale, Config.R6ExtremityOffset, Palette.SuitBackpack)
			end
		end
	end
	attach("Backpack", torso, Config.BackpackScale, Config.BackpackOffset, Palette.SuitBackpack, false, slots.Backpack)
	-- Replacing one shell at a time keeps all imported geometry inside the same hard budget.
	for _, spec in {{"Helmet", head, Config.HelmetScale, Vector3.zero, slots.Helmet}, {"Shell", torso, Config.ShellScale, Vector3.zero, slots.AstronautSuit}} do
		local name = spec[1] :: string
		local rig = spec[2] :: BasePart
		local slot = spec[5] :: Assets.AssetEntry
		if slot.MeshId ~= "" or slot.TextureId ~= "" or (slot.ModelId and slot.ModelId ~= "") then
			for _, part in suit:GetChildren() do
				local weld = part:FindFirstChildOfClass("WeldConstraint")
				if part.Name == name and weld and weld.Part0 == rig then part:Destroy(); count -= 1; break end
			end
			attach(name, rig, spec[3] :: Vector3, spec[4] :: Vector3, Palette.SuitWhite, name == "Helmet", slot)
		end
	end
	if visor then
		local glow = Instance.new("PointLight")
		glow.Color = Palette.AccentTeal; glow.Brightness = Config.GlowBrightness; glow.Range = Config.GlowRange
		glow.Shadows = false; glow.Parent = visor
	end
	suit:SetAttribute("PartCount", count)
	suit.Parent = character
	return suit
end

function Builder.Dust(parent: Instance): BasePart
	local part = Instance.new("Part")
	part.Name = "BootDust"
	part.Shape = Enum.PartType.Ball
	part.Color = Palette.PebbleLight
	part.Size = Config.Dust.Size
	safePart(part)
	part.Anchored = true
	part.Transparency = 1
	part.Parent = parent
	return part
end
return Builder
