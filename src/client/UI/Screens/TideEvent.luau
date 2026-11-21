--!strict
-- Screen builder for TideEvent (C5). Baked into StarterGui.TideEvent.
-- Dynamic behaviour + remote connection in Controllers/TideEventController.

local New = require(script.Parent.Parent.New)

local T = New.Theme

local Screen = { Name = "TideEvent" }

-- Reuses the same named parts in places with an older baked TideEvent.
function Screen.Compact(panel: any)
	panel.AnchorPoint = Vector2.zero
	panel.Position = UDim2.fromOffset(12, 104)
	panel.Size = UDim2.fromOffset(294, 52)

	local content = panel.Content
	local padding = content:FindFirstChildOfClass("UIPadding")
	padding.PaddingLeft = UDim.new(0, 8)
	padding.PaddingRight = UDim.new(0, 8)
	padding.PaddingTop = UDim.new(0, 4)
	padding.PaddingBottom = UDim.new(0, 4)
	local badge = content.IconBadge
	badge.AnchorPoint = Vector2.new(0, 0.5)
	badge.Position = UDim2.fromScale(0, 0.5)
	badge.Size = UDim2.fromOffset(36, 36)
	badge.Icon.Size = UDim2.fromOffset(30, 30)

	local center = content.CenterArea
	center.Position = UDim2.fromOffset(43, 0)
	center.Size = UDim2.new(1, -93, 1, 0)
	center:FindFirstChildOfClass("UIListLayout").Padding = UDim.new(0, 2)
	center.TopRow.Size = UDim2.new(1, 0, 0, 21)
	center.TopRow.Title.Size = UDim2.fromOffset(0, 21)
	center.TopRow.Title.TextSize = 16
	center.TopRow.TimePill.Size = UDim2.fromOffset(0, 18)
	center.TopRow.TimePill.TimeText.Size = UDim2.fromOffset(0, 18)
	center.TopRow.TimePill.TimeText.TextSize = 11

	local status = center.StatusContainer
	status.Size = UDim2.new(1, 0, 0, 18)
	for _, pill in { status.OutsideRow.NavPill, status.OutsideRow.AnglersPill } do
		pill.Size = UDim2.fromOffset(0, 18)
		local label = pill:FindFirstChildOfClass("TextLabel")
		label.Size = UDim2.fromOffset(0, 18)
		label.TextSize = 11
	end
	local inside = status.InsideRow.InsideText
	inside.TextSize = 11
	inside.TextTruncate = Enum.TextTruncate.AtEnd

	local loot = content.LootPreview
	loot.Size = UDim2.fromOffset(45, 22)
	loot.LootTitle.Visible = false
	local icons = loot.LootIcons
	icons.Size = UDim2.fromScale(1, 1)
	icons:FindFirstChildOfClass("UIListLayout").Padding = UDim.new(0, 4)
	for _, slot in { icons.Slot1, icons.Slot2 } do
		slot.Size = UDim2.fromOffset(20, 20)
		slot.Img.Size = UDim2.fromOffset(16, 16)
	end
end

function Screen.Build(): ScreenGui
	local gui = New("ScreenGui", {
		Name = "TideEvent",
		ResetOnSpawn = false,
		IgnoreGuiInset = false,
		Enabled = false,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		DisplayOrder = 5,
	}) :: ScreenGui

	local panel = New.Panel({
		Name = "Top",
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 56),
		Size = UDim2.fromOffset(480, 76),
		Radius = 18,
		Parent = gui,
	})

	-- Inner content frame (avoids shrinking the 9-slice shadow child)
	local content = New("Frame", {
		Name = "Content",
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Parent = panel,
		[New.Children] = {
			New("UIPadding", {
				PaddingLeft = UDim.new(0, 10),
				PaddingRight = UDim.new(0, 10),
				PaddingTop = UDim.new(0, 8),
				PaddingBottom = UDim.new(0, 8),
			}),
		},
	})

	-- Left: Event Icon Badge (58x58)
	New("Frame", {
		Name = "IconBadge",
		Size = UDim2.fromOffset(58, 58),
		BackgroundColor3 = T.TintMint,
		Parent = content,
		[New.Children] = {
			New.Corner(14),
			New.Stroke(T.Track, 1.5),
			New.Image({
				Name = "Icon",
				Key = "fish/NagaHatchling",
				Size = UDim2.fromOffset(50, 50),
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromScale(0.5, 0.5),
			}),
		} :: { Instance },
	})

	-- Center: Info Area
	local centerArea = New("Frame", {
		Name = "CenterArea",
		Position = UDim2.fromOffset(68, 0),
		Size = UDim2.new(1, -68 - 84, 1, 0),
		BackgroundTransparency = 1,
		Parent = content,
		[New.Children] = {
			New("UIListLayout", {
				SortOrder = Enum.SortOrder.LayoutOrder,
				Padding = UDim.new(0, 4),
				VerticalAlignment = Enum.VerticalAlignment.Center,
			}),
		},
	})

	-- Row 1: Title + Time Pill
	local topRow = New("Frame", {
		Name = "TopRow",
		Size = UDim2.new(1, 0, 0, 26),
		BackgroundTransparency = 1,
		LayoutOrder = 1,
		Parent = centerArea,
		[New.Children] = {
			New("UIListLayout", {
				FillDirection = Enum.FillDirection.Horizontal,
				SortOrder = Enum.SortOrder.LayoutOrder,
				Padding = UDim.new(0, 8),
				VerticalAlignment = Enum.VerticalAlignment.Center,
			}),
		},
	})

	New.Title({
		Name = "Title",
		Size = UDim2.fromOffset(0, 24),
		AutomaticSize = Enum.AutomaticSize.X,
		Text = "Naga Tide",
		TextColor3 = T.Text,
		TextSize = 18,
		LayoutOrder = 1,
		Parent = topRow,
	})

	local timePill = New("Frame", {
		Name = "TimePill",
		Size = UDim2.fromOffset(0, 22),
		AutomaticSize = Enum.AutomaticSize.X,
		BackgroundColor3 = T.PanelLight,
		LayoutOrder = 2,
		Parent = topRow,
		[New.Children] = {
			New.Pill(),
			New.Stroke(T.Track, 1),
			New("UIPadding", {
				PaddingLeft = UDim.new(0, 8),
				PaddingRight = UDim.new(0, 8),
			}),
		} :: { Instance },
	})
	New.Text({
		Name = "TimeText",
		Size = UDim2.fromOffset(0, 20),
		AutomaticSize = Enum.AutomaticSize.X,
		Text = "05:00 left",
		TextColor3 = T.Text,
		FontFace = T.FontBadge,
		TextSize = 12,
		Parent = timePill,
	})

	-- Row 2: Status container
	local statusContainer = New("Frame", {
		Name = "StatusContainer",
		Size = UDim2.new(1, 0, 0, 26),
		BackgroundTransparency = 1,
		LayoutOrder = 2,
		Parent = centerArea,
	})

	-- State Outside: Distance + Anglers pills
	local outsideRow = New("Frame", {
		Name = "OutsideRow",
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Visible = true,
		Parent = statusContainer,
		[New.Children] = {
			New("UIListLayout", {
				FillDirection = Enum.FillDirection.Horizontal,
				SortOrder = Enum.SortOrder.LayoutOrder,
				Padding = UDim.new(0, 6),
				VerticalAlignment = Enum.VerticalAlignment.Center,
			}),
		},
	})

	local navPill = New("Frame", {
		Name = "NavPill",
		Size = UDim2.fromOffset(0, 22),
		AutomaticSize = Enum.AutomaticSize.X,
		BackgroundColor3 = T.PanelLight,
		LayoutOrder = 1,
		Parent = outsideRow,
		[New.Children] = {
			New.Pill(),
			New.Stroke(T.Track, 1),
			New("UIPadding", {
				PaddingLeft = UDim.new(0, 8),
				PaddingRight = UDim.new(0, 8),
			}),
		} :: { Instance },
	})
	New.Text({
		Name = "NavText",
		Size = UDim2.fromOffset(0, 20),
		AutomaticSize = Enum.AutomaticSize.X,
		Text = "Searching...",
		TextColor3 = T.SubText,
		FontFace = T.FontBadge,
		TextSize = 12,
		Parent = navPill,
	})

	local anglersPill = New("Frame", {
		Name = "AnglersPill",
		Size = UDim2.fromOffset(0, 22),
		AutomaticSize = Enum.AutomaticSize.X,
		BackgroundColor3 = T.PanelLight,
		LayoutOrder = 2,
		Parent = outsideRow,
		[New.Children] = {
			New.Pill(),
			New.Stroke(T.Track, 1),
			New("UIPadding", {
				PaddingLeft = UDim.new(0, 8),
				PaddingRight = UDim.new(0, 8),
			}),
		} :: { Instance },
	})
	New.Text({
		Name = "AnglersText",
		Size = UDim2.fromOffset(0, 20),
		AutomaticSize = Enum.AutomaticSize.X,
		Text = "0 anglers",
		TextColor3 = T.SubText,
		FontFace = T.FontBadge,
		TextSize = 12,
		Parent = anglersPill,
	})

	-- State Inside: Glowing Mint Banner
	local insideRow = New("Frame", {
		Name = "InsideRow",
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundColor3 = T.Good,
		Visible = false,
		Parent = statusContainer,
		[New.Children] = {
			New.Pill(),
			New.Stroke(T.GoodLip, 1.5),
			New("UIPadding", {
				PaddingLeft = UDim.new(0, 10),
				PaddingRight = UDim.new(0, 10),
			}),
		} :: { Instance },
	})
	New.Text({
		Name = "InsideText",
		Size = UDim2.fromScale(1, 1),
		Text = "IN TIDE: +50% LUCK",
		TextColor3 = T.OnAccent,
		FontFace = T.FontBadge,
		TextSize = 12,
		TextXAlignment = Enum.TextXAlignment.Center,
		Parent = insideRow,
	})

	-- Right: Rare Catches Preview Area (78x56)
	local lootPreview = New("Frame", {
		Name = "LootPreview",
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, 0, 0.5, 0),
		Size = UDim2.fromOffset(78, 56),
		BackgroundTransparency = 1,
		Parent = content,
		[New.Children] = {
			New("UIListLayout", {
				SortOrder = Enum.SortOrder.LayoutOrder,
				Padding = UDim.new(0, 2),
				HorizontalAlignment = Enum.HorizontalAlignment.Center,
				VerticalAlignment = Enum.VerticalAlignment.Center,
			}),
		},
	})

	New.Text({
		Name = "LootTitle",
		Size = UDim2.new(1, 0, 0, 14),
		Text = "LOOT",
		TextColor3 = T.SubText,
		FontFace = T.FontBadge,
		TextSize = 10,
		LayoutOrder = 1,
		Parent = lootPreview,
	})

	local lootIcons = New("Frame", {
		Name = "LootIcons",
		Size = UDim2.new(1, 0, 0, 36),
		BackgroundTransparency = 1,
		LayoutOrder = 2,
		Parent = lootPreview,
		[New.Children] = {
			New("UIListLayout", {
				FillDirection = Enum.FillDirection.Horizontal,
				SortOrder = Enum.SortOrder.LayoutOrder,
				Padding = UDim.new(0, 6),
				HorizontalAlignment = Enum.HorizontalAlignment.Center,
				VerticalAlignment = Enum.VerticalAlignment.Center,
			}),
		},
	})

	-- Naga Hatchling micro-slot
	New("Frame", {
		Name = "Slot1",
		Size = UDim2.fromOffset(32, 32),
		BackgroundColor3 = T.PanelLight,
		LayoutOrder = 1,
		Parent = lootIcons,
		[New.Children] = {
			New.Corner(8),
			New.Stroke(Color3.fromRGB(242, 102, 139), 1.5), -- Mythic color
			New.Image({
				Name = "Img",
				Key = "fish/NagaHatchling",
				Size = UDim2.fromOffset(26, 26),
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromScale(0.5, 0.5),
			}),
		} :: { Instance },
	})

	-- Coral Seahorse micro-slot
	New("Frame", {
		Name = "Slot2",
		Size = UDim2.fromOffset(32, 32),
		BackgroundColor3 = T.PanelLight,
		LayoutOrder = 2,
		Parent = lootIcons,
		[New.Children] = {
			New.Corner(8),
			New.Stroke(Color3.fromRGB(242, 169, 59), 1.5), -- Legendary color
			New.Image({
				Name = "Img",
				Key = "fish/CoralSeahorse",
				Size = UDim2.fromOffset(26, 26),
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromScale(0.5, 0.5),
			}),
		} :: { Instance },
	})

	Screen.Compact(panel)
	return gui
end

return Screen
