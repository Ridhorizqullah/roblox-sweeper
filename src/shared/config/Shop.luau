--!strict
local Layout = require(script.Parent.Layout)

return {
	-- Sourced from Layout (Single Source of Truth)
	Offset = Vector3.new(Layout.Shop.Center.X, 0, Layout.Shop.Center.Y),
	Size = Layout.Shop.Size,
	Radius = Layout.Shop.MaxDistance,

	RequestCooldown = 0.25,
	Color = Color3.fromRGB(100, 150, 255),
	PanelWidth = 460,
	PanelHeight = 520,
	RowHeight = 64,
	ToolHandleSize = Vector3.new(0.35, 2, 0.35),
	ToolHeadSize = Vector3.new(1.2, 0.5, 0.6),
	ToolHeadOffset = CFrame.new(0, 1, 0),
	ToolTierScale = 0.15,
}
