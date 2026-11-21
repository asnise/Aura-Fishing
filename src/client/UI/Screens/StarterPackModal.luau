--!nonstrict
-- Figma 3546:36782 (Screen C19 · Starter Pack offer).
-- Static layout only; behaviour lives in UI/StarterPackModal.luau. Baked into StarterGui by tools/ui/bake.mjs.

local New = require(script.Parent.Parent.New)
local T = New.Theme

local Screen = { Name = "StarterPackModal" }

local DESIGN_SIZE = Vector2.new(520, 557)

function Screen.Build(): ScreenGui
	local gui = New("ScreenGui", {
		Name = "StarterPackModal",
		ResetOnSpawn = false,
		IgnoreGuiInset = true,
		DisplayOrder = 25, -- below Item Detail (30) so tapped item cards show on top
		Enabled = false,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	}) :: ScreenGui

	-- Dim background
	New("TextButton", {
		Name = "Dim",
		Size = UDim2.fromScale(1, 1),
		Position = UDim2.fromScale(0, 0),
		BackgroundColor3 = Color3.fromRGB(61, 75, 92),
		BackgroundTransparency = 0.72,
		BorderSizePixel = 0,
		Text = "",
		AutoButtonColor = false,
		Active = true,
		ZIndex = 1,
		Parent = gui,
	})

	-- Window panel: 520x557 r36
	local window = New.Panel({
		Name = "Window",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(DESIGN_SIZE.X, DESIGN_SIZE.Y),
		Radius = 36,
		Clip = true, -- footer follows the rounded corners
		ZIndex = 2,
		Parent = gui,
	})
	New.Shadow(window, "slice_shadow_modal")
	New.FitToScreen(window)

	-- Body container (464 px high)
	local body = New("Frame", {
		Name = "Body",
		Size = UDim2.new(1, 0, 0, 464),
		BackgroundTransparency = 1,
		ZIndex = 3,
		Parent = window,
	})

	-- Ribbon: "ONE-TIME OFFER"
	local ribbon = New("Frame", {
		Name = "Ribbon",
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 34),
		Size = UDim2.fromOffset(132, 20),
		BackgroundColor3 = Color3.fromRGB(255, 158, 128),
		ZIndex = 4,
		Parent = body,
		[New.Children] = {
			New.Corner(999),
		},
	})
	New("TextLabel", {
		Name = "Label",
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Text = "ONE-TIME OFFER",
		TextColor3 = Color3.new(1, 1, 1),
		FontFace = T.FontBadge,
		TextSize = New.FigmaSize(T.FontBadge, 12),
		ZIndex = 5,
		Parent = ribbon,
	})

	-- Bundle artwork image
	New.Image({
		Name = "BundleImage",
		Key = "ui/shop/starter_bundle",
		Fallback = T.Accent,
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 64),
		Size = UDim2.fromOffset(150, 150),
		ZIndex = 4,
		Parent = body,
	})

	-- Title
	New.Title({
		Name = "Title",
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 224),
		Size = UDim2.fromOffset(460, 44),
		Text = "Starter Pack",
		TextSize = 38,
		TextColor3 = T.Text,
		TextXAlignment = Enum.TextXAlignment.Center,
		ZIndex = 4,
		Parent = body,
	})

	-- Items list container
	local items = New("Frame", {
		Name = "Items",
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 278),
		Size = UDim2.fromOffset(400, 156),
		BackgroundTransparency = 1,
		ZIndex = 4,
		Parent = body,
		[New.Children] = {
			New("UIListLayout", {
				FillDirection = Enum.FillDirection.Vertical,
				HorizontalAlignment = Enum.HorizontalAlignment.Center,
				Padding = UDim.new(0, 6),
				SortOrder = Enum.SortOrder.LayoutOrder,
			}),
		},
	})

	local itemList = {
		{ Key = "ui/status/gem", Fallback = T.Gem, Label = "100 Gems", Order = 1 },
		{ Key = "equipment/Shrimp", Fallback = T.Accent, Label = "Shrimp bait x50", Order = 2 },
		{ Key = "equipment/SweetheartRod", Fallback = T.Gold, Label = "Sweetheart Rod (cosmetic + light stats)", Order = 3 },
	}

	for _, item in itemList do
		local row = New("Frame", {
			Name = "ItemRow",
			Size = UDim2.new(1, 0, 0, 48),
			BackgroundColor3 = T.PanelLight,
			LayoutOrder = item.Order,
			ZIndex = 4,
			Parent = items,
			[New.Children] = {
				New.Corner(14),
			},
		})
		New.Image({
			Name = "Icon",
			Key = item.Key,
			Fallback = item.Fallback,
			AnchorPoint = Vector2.new(0, 0.5),
			Position = UDim2.new(0, 6, 0.5, 0),
			Size = UDim2.fromOffset(36, 36),
			ZIndex = 5,
			Parent = row,
		})
		New("TextLabel", {
			Name = "Label",
			AnchorPoint = Vector2.new(0, 0.5),
			Position = UDim2.new(0, 50, 0.5, 0),
			Size = UDim2.new(1, -56, 0, 24),
			BackgroundTransparency = 1,
			Text = item.Label,
			TextColor3 = T.Text,
			FontFace = T.FontBadge,
			TextSize = New.FigmaSize(T.FontBadge, 15),
			TextXAlignment = Enum.TextXAlignment.Left,
			ZIndex = 5,
			Parent = row,
		})
	end

	-- Footer bar: 93 px high
	local footer = New("Frame", {
		Name = "Footer",
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.new(0, 0, 1, 0),
		Size = UDim2.new(1, 0, 0, 93),
		BackgroundColor3 = T.PanelLight,
		ZIndex = 3,
		Parent = window,
		[New.Children] = {
			New.Corner(36),
		},
	})

	local buttonsRow = New("Frame", {
		Name = "ButtonsRow",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.new(1, -48, 0, 57),
		BackgroundTransparency = 1,
		ZIndex = 4,
		Parent = footer,
		[New.Children] = {
			New("UIListLayout", {
				FillDirection = Enum.FillDirection.Horizontal,
				HorizontalAlignment = Enum.HorizontalAlignment.Center,
				VerticalAlignment = Enum.VerticalAlignment.Center,
				Padding = UDim.new(0, 14),
				SortOrder = Enum.SortOrder.LayoutOrder,
			}),
		},
	})

	-- Later button
	local btnLater = New.Button({
		Name = "BtnLater",
		Size = UDim2.new(1, -126, 1, 0),
		BackgroundColor3 = T.PanelLight,
		TextColor3 = T.Text,
		Text = "Later",
		TextSize = 22,
		LayoutOrder = 1,
		ZIndex = 5,
		Parent = buttonsRow,
	})
	local laterStroke = btnLater:FindFirstChildOfClass("UIStroke")
	if not laterStroke then
		New.Stroke(T.Stroke, 1.5).Parent = btnLater
	end

	New.RobuxButton({
		Name = "BtnBuy",
		Size = UDim2.fromOffset(112, 57),
		BackgroundColor3 = T.Good,
		LayoutOrder = 2,
		ZIndex = 5,
		Parent = buttonsRow,
	}, 49)

	New.ApplyImages(gui)
	return gui
end

return Screen
