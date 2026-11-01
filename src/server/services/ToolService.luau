--!strict
local Shared = game:GetService("ReplicatedStorage").Shared
local Tools = require(Shared.config.Tools)
local Shop = require(Shared.config.Shop)
local DataService = require(script.Parent.DataService)
local Service = {}
function Service.Refresh(player: Player): ()
	local data = DataService.Get(player)
	local character = player.Character
	local backpack = player:FindFirstChildOfClass("Backpack")
	local humanoid = if character then character:FindFirstChildOfClass("Humanoid") else nil
	if not data or not character or not backpack or not humanoid or humanoid.Health <= 0 then return end
	local definition = Tools.ById[data.equippedTool]
	if not definition or not data.ownedTools[data.equippedTool] then return end
	for _, container in {character, backpack} do
		for _, child in container:GetChildren() do
			if child:IsA("Tool") and child:GetAttribute("SweeperTool") then child:Destroy() end
		end
	end
	local tool = Instance.new("Tool")
	tool.Name = definition.name
	tool.CanBeDropped = false
	tool:SetAttribute("SweeperTool", true)
	tool:SetAttribute("ToolId", data.equippedTool)
	local handle = Instance.new("Part")
	handle.Name = "Handle"
	handle.Size = Shop.ToolHandleSize
	handle.Color = Color3.fromHSV(definition.level / #Tools.Order, 0.6, 0.9)
	handle.CanCollide = false
	handle.CanTouch = false
	handle.Massless = true
	handle.Parent = tool
	local head = Instance.new("Part")
	head.Name = "CleanerHead"
	head.Size = Shop.ToolHeadSize * (1 + definition.level * Shop.ToolTierScale)
	head.CFrame = handle.CFrame * Shop.ToolHeadOffset
	head.Color = handle.Color
	head.CanCollide = false
	head.CanTouch = false
	head.Massless = true
	head.Parent = tool
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = handle
	weld.Part1 = head
	weld.Parent = head
	tool.Parent = backpack
	humanoid:EquipTool(tool)
end
function Service.IsEquipped(player: Player, id: string): boolean
	local character = player.Character
	if not character then return false end
	for _, child in character:GetChildren() do
		if child:IsA("Tool") and child:GetAttribute("SweeperTool") == true and child:GetAttribute("ToolId") == id then return true end
	end
	return false
end
return Service
