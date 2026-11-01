--!strict
local RS = game:GetService("ReplicatedStorage")
local Assets = require(script.Parent.Parent.config.Assets)
local Builder = {}
function Builder.Part(key: string, parent: Instance, size: Vector3, cf: CFrame, color: Color3, shape: Enum.PartType?): BasePart
	local entry = Assets[key]
	local part = Instance.new("Part")
	part.Shape = shape or Enum.PartType.Block
	part.Name = key
	part.Size = size
	part.CFrame = cf
	part.Color = color
	part.Anchored = true
	part.CanCollide = false
	part.CanTouch = false
	part.CanQuery = false
	part.CastShadow = false
	part.CollisionGroup = "Decor"
	part.Parent = parent
	if entry and entry.MeshId ~= "" then
		local mesh = Instance.new("SpecialMesh")
		mesh.MeshType = Enum.MeshType.FileMesh
		mesh.MeshId = entry.MeshId
		mesh.TextureId = entry.TextureId
		mesh.Parent = part
	elseif entry and entry.ModelId ~= "" then
		local library = RS:FindFirstChild("CustomAssets")
		local source = library and library:FindFirstChild(entry.ModelId)
		if source and source:IsA("Model") then
			local model = source:Clone()
			for _, item in model:GetDescendants() do
				if item:IsA("LuaSourceContainer") then item:Destroy()
				elseif item:IsA("BasePart") then
					item.Anchored = true; item.CanCollide = false; item.CanTouch = false; item.CanQuery = false; item.CollisionGroup = "Decor"
				end
			end
			model:PivotTo(cf)
			model.Parent = parent
			part.Transparency = 1
		else warn("[Art] Missing imported model slot:", key, entry.ModelId) end
	elseif entry and entry.TextureId ~= "" then
		local texture = Instance.new("Decal")
		texture.Texture = entry.TextureId
		texture.Parent = part
	end
	if entry and entry.SoundId ~= "" then
		local sound = Instance.new("Sound")
		sound.SoundId = entry.SoundId
		sound.Parent = part
	end
	return part
end
return Builder
