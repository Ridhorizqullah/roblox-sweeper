--!strict
local Assets = require(script.Parent.Parent.config.Assets)

export type Slot = {
	LocalModel: string,
	Kind: "Tool" | "Model",
	Category: "Tool" | "Pet" | "Vehicle",
	MaxParts: number,
	DefaultColor: Color3,
	Colors: {[string]: Color3},
}

local Importer = {}

local function finite(value: number): boolean
	return value == value and math.abs(value) < math.huge
end

local function validPart(part: BasePart): boolean
	for _, value in {part.Size.X, part.Size.Y, part.Size.Z} do
		if not finite(value) or value <= 0 then return false end
	end
	for _, value in {part.CFrame:GetComponents()} do
		if not finite(value) then return false end
	end
	return true
end

-- Reconstruct primitives rather than cloning: no imported code, joints, URLs or effects survive.
local function construct(slot: Slot, allocated: {Instance}): Model | Tool | nil
	local library = script.Parent.Parent:FindFirstChild("assets")
	local source = library and library:FindFirstChild(slot.LocalModel)
	if not source then return nil end
	if slot.Kind == "Tool" then
		if not source:IsA("Tool") then return nil end
	elseif slot.Kind == "Model" then
		if not source:IsA("Model") then return nil end
	else
		return nil
	end
	local parts: {BasePart} = {}
	for _, item in source:GetDescendants() do
		if item:IsA("BasePart") then
			if not (item:IsA("Part") or item:IsA("WedgePart") or item:IsA("CornerWedgePart")) then return nil end
			if not validPart(item) then return nil end
			table.insert(parts, item)
		end
	end
	local limit = if slot.Category == "Tool" then 15 elseif slot.Category == "Pet" then 25 else 40
	if (slot.Kind == "Tool") ~= (slot.Category == "Tool") then return nil end
	if not finite(slot.MaxParts) or slot.MaxParts < 1 then return nil end
	if #parts == 0 or #parts > math.min(slot.MaxParts, limit) then return nil end
	local sourceHandle = source:FindFirstChild("Handle")
	if slot.Kind == "Tool" and (not sourceHandle or not sourceHandle:IsA("BasePart")) then return nil end
	local result: Model | Tool
	if source:IsA("Tool") then
		local tool = Instance.new("Tool")
		tool.Grip = source.Grip
		tool.RequiresHandle = true
		tool.CanBeDropped = false
		result = tool
	else
		result = Instance.new("Model")
	end
	table.insert(allocated, result)
	result.Name = source.Name
	local handle: BasePart? = nil
	for _, original in parts do
		local copy = Instance.new(original.ClassName) :: BasePart
		copy.Name = original.Name
		copy.Size = original.Size
		copy.CFrame = original.CFrame
		copy.Color = slot.Colors[original.Name] or slot.DefaultColor
		copy.Material = original.Material
		copy.Transparency = original.Transparency
		copy.Reflectance = original.Reflectance
		if copy:IsA("Part") and original:IsA("Part") then copy.Shape = original.Shape end
		copy.Anchored = slot.Kind ~= "Tool"
		copy.Massless = true
		copy.CanCollide = false
		copy.CanTouch = false
		copy.CanQuery = false
		copy.CastShadow = false
		-- Decor is registered by the world bootstrap; isolated previews may not have it yet.
		pcall(function() copy.CollisionGroup = "Decor" end)
		copy.Parent = result
		if original == sourceHandle then handle = copy end
	end
	if result:IsA("Tool") and handle then
		for _, child in result:GetChildren() do
			if child:IsA("BasePart") and child ~= handle then
				local weld = Instance.new("WeldConstraint")
				weld.Part0 = handle
				weld.Part1 = child
				weld.Parent = child
			end
		end
	elseif result:IsA("Model") then
		result:PivotTo(CFrame.identity)
	end
	return result
end

-- Returns an unparented safe copy. Callers own placement, parenting, cleanup and procedural fallback.
function Importer.Load(key: string): Model | Tool | nil
	local slot = (Assets.ImportedModels :: {[string]: Slot})[key]
	if not slot then return nil end
	local allocated: {Instance} = {}
	local ok, result = pcall(construct, slot, allocated)
	if not ok then
		for _, instance in allocated do instance:Destroy() end
		return nil
	end
	return result
end

return Importer
