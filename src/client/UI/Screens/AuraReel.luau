--!nonstrict
-- Eclipse reveal (Figma 3717:1425 / 3717:1547). UI/AuraReel drives the animation and centered Item Card.

local New = require(script.Parent.Parent.New)
local T = New.Theme

local WHITE = Color3.new(1, 1, 1)
local K = 1920 / 560 -- storyboard px -> canvas px
local LEGENDARY = Color3.fromRGB(242, 169, 59)

local Screen = { Name = "AuraReel", Canvas = Vector2.new(1920, 1080) }

local function px(v: number): number
	return math.round(v * K)
end

local function ring(name: string, size: number, fill: boolean, parent: Instance): Frame
	local frame = New("Frame", {
		Name = name,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(size, size),
		BackgroundColor3 = Color3.fromRGB(15, 16, 34),
		BackgroundTransparency = if fill then 0 else 1,
		BorderSizePixel = 0,
		Visible = false,
		ZIndex = 5,
		Parent = parent,
		[New.Children] = { New("UICorner", { CornerRadius = UDim.new(0.5, 0) }) },
	}) :: Frame
	-- The edge is Figma's own ring (5px stroke + glow, exported from 3717:1434) so it scales and glows like the design.
	-- The picture covers the ring plus its glow: ring diameter = 0.926 of the image.
	local edge = New.Image({ Name = "Ring", Key = "auras/fx_ring", Fallback = WHITE, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(1 / 0.926, 1 / 0.926), ImageTransparency = 1, ZIndex = 6, Parent = frame })
	edge.Fallback.BackgroundTransparency = 1
	return frame
end

local function pill(name: string, text: string, color: Color3, order: number, parent: Instance): TextLabel
	return New("TextLabel", {
		Name = name,
		Size = UDim2.fromOffset(0, px(19)),
		AutomaticSize = Enum.AutomaticSize.X,
		BackgroundColor3 = color,
		Text = text,
		TextColor3 = WHITE,
		FontFace = T.FontBadge,
		TextSize = New.FigmaSize(T.FontBadge, px(12)),
		LayoutOrder = order,
		ZIndex = 22,
		Parent = parent,
		[New.Children] = { New.Pill(), New("UIPadding", { PaddingLeft = UDim.new(0, px(8)), PaddingRight = UDim.new(0, px(8)) }) },
	}) :: TextLabel
end

-- result-bar button (Figma "Btn EQUIP": r9, darker lip, Fredoka 11)
local function barButton(name: string, text: string, face: Color3, w: number, order: number, parent: Instance): TextButton
	return New.Button({ Name = name, Size = UDim2.fromOffset(px(w), px(26)), Text = text, BackgroundColor3 = face, TextSize = px(11), LayoutOrder = order, ZIndex = 22, Parent = parent })
end

function Screen.Build(): ScreenGui
	local gui = New("ScreenGui", {
		Name = "AuraReel",
		ResetOnSpawn = false,
		IgnoreGuiInset = true,
		DisplayOrder = 28, -- under the centered Item Card (30)
		Enabled = false,
		ZIndexBehavior = Enum.ZIndexBehavior.Global,
	}) :: ScreenGui

	New("TextButton", {
		Name = "Dim",
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color3.new(0, 0, 0),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Text = "",
		AutoButtonColor = false,
		ZIndex = 1,
		Parent = gui,
	})
	New("Frame", {
		Name = "RarityOverlay", Size = UDim2.fromScale(1, 1), BackgroundColor3 = WHITE, BackgroundTransparency = 1,
		BorderSizePixel = 0, ZIndex = 2, Parent = gui,
		[New.Children] = { New("UIGradient", {
			Rotation = 90,
			Transparency = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.5, 0.72), NumberSequenceKeypoint.new(1, 0.17),
			}),
		}) },
	})
	New("Frame", { Name = "EclipseDim", Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 1, BorderSizePixel = 0, ZIndex = 3, Parent = gui })

	local cv = New("Frame", {
		Name = "Canvas",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(1920, 1080),
		BackgroundTransparency = 1,
		ZIndex = 4,
		Parent = gui,
		[New.Children] = { New("UIScale", { Name = "Scale" }) },
	})

	ring("EclipseRim", 462, true, cv)
	ring("Shockwave", 478, false, cv)
	local sparkle = New.Image({
		Name = "CoreSparkle", Key = "auras/fx_sparkle", Fallback = WHITE,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(36, 36),
		ImageTransparency = 1,
		ZIndex = 7,
		Parent = cv,
	})
	sparkle.Fallback.BackgroundTransparency = 1

	local card = New("Frame", {
		Name = "Card",
		Position = UDim2.fromOffset(px(111), px(240)),
		Size = UDim2.fromOffset(px(337), px(71)),
		BackgroundColor3 = Color3.fromRGB(255, 248, 236),
		BackgroundTransparency = 0.04,
		Visible = false,
		ZIndex = 20,
		Parent = cv,
		[New.Children] = { New.Corner(px(16)), New("UIScale", { Name = "Pop" }) },
	})
	local row = New("Frame", {
		Name = "Row",
		Position = UDim2.fromOffset(0, px(8)),
		Size = UDim2.new(1, 0, 0, px(22)),
		BackgroundTransparency = 1,
		ZIndex = 21,
		Parent = card,
		[New.Children] = { New("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, px(6)), HorizontalAlignment = Enum.HorizontalAlignment.Center, VerticalAlignment = Enum.VerticalAlignment.Center, SortOrder = Enum.SortOrder.LayoutOrder }) },
	})
	pill("Rarity", "LEGENDARY", LEGENDARY, 1, row)
	New("TextLabel", {
		Name = "AuraName",
		Size = UDim2.fromOffset(0, px(22)),
		AutomaticSize = Enum.AutomaticSize.X,
		BackgroundTransparency = 1,
		Text = "Abyssal Shadow",
		TextColor3 = T.Text,
		FontFace = T.Font,
		TextSize = New.FigmaSize(T.Font, px(18)),
		LayoutOrder = 2,
		ZIndex = 22,
		Parent = row,
	})
	pill("NewBadge", "NEW!", T.Accent, 3, row)
	local buttons = New("Frame", {
		Name = "Buttons",
		Position = UDim2.fromOffset(0, px(35)),
		Size = UDim2.new(1, 0, 0, px(26)),
		BackgroundTransparency = 1,
		ZIndex = 21,
		Parent = card,
		[New.Children] = { New("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, px(6)), HorizontalAlignment = Enum.HorizontalAlignment.Center, SortOrder = Enum.SortOrder.LayoutOrder }) },
	})
	barButton("Equip", "EQUIP", T.Good, 80, 1, buttons)
	barButton("RollAgain", "ROLL AGAIN", T.Gem, 100, 2, buttons)
	barButton("Close", "CLOSE", Color3.fromRGB(201, 187, 163), 70, 3, buttons)

	return gui
end

return Screen
