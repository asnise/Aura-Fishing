--!nonstrict
-- Figma 18B · Item Card option A "Classic" (docs/figma/item_detail.py card(), buttons fixed 48 high per
-- docs/figma/inventory_final.py), B21. Static shell + sample content; UI/ItemDetail fills it for any item
-- (Rod / Line / Aura / Fish / Bait / Treasure) and places it next to the pressed slot.
--   (a press outside the card closes it: UI/ItemDetail listens to UserInputService, so the window
--    below stays clickable and pressing another slot swaps the card in one click)
--   Card     cream panel 280 wide, auto height, pad 16, gap 10
--     Head      Picture (ItemSlot 72, count hidden), Info (Name, Tags (Rarity, Kind badges), Stars (5 images))
--     Stats     wrapping badge row (Badge1..8)
--     Desc      wrapped body text
--     Meta      wrapping pill row (Badge1..5): xN, kg, HOT xN, Equipped, +N, chance
--     Modifiers Rods only: Label, Socket1..3 (locked), Spacer, Soon pill
--     Actions   Line (2px top rule), Buttons (A1..A3, 48 high, share the width)
--     GetFrom   not owned only: Line, Title "Get from", Icon, Label
--     Nub       small rotated square on the left or right edge, points at the slot

local New = require(script.Parent.Parent.New)
local Components = require(script.Parent.Components)
local Make = Components.Make
local T = New.Theme

local Screen = { Name = "ItemDetail" }

Screen.CardWidth = 280
local INNER = Screen.CardWidth - 32

local function vlist(gap: number): UIListLayout
	return New("UIListLayout", { Padding = UDim.new(0, gap), SortOrder = Enum.SortOrder.LayoutOrder })
end

local function hlist(gap: number, wraps: boolean?): UIListLayout
	return New("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		Padding = UDim.new(0, gap),
		Wraps = wraps == true,
		VerticalAlignment = Enum.VerticalAlignment.Center,
		SortOrder = Enum.SortOrder.LayoutOrder,
	})
end

local function badges(name: string, count: number, order: number, parent: Instance): Frame
	local row = New.BadgeSlots(count, {
		Name = name,
		Size = UDim2.fromOffset(INNER, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		LayoutOrder = order,
		Parent = parent,
	})
	local layout = row:FindFirstChildOfClass("UIListLayout")
	if layout then
		layout.Wraps = true
	end
	return row
end

local function rule(parent: Instance)
	New("Frame", {
		Name = "Line",
		Size = UDim2.new(1, 0, 0, 2),
		BackgroundColor3 = T.Track,
		BorderSizePixel = 0,
		LayoutOrder = 0,
		Parent = parent,
	})
end

local function head(card: Frame)
	local row = New("Frame", {
		Name = "Head",
		Size = UDim2.fromOffset(INNER, 72),
		BackgroundTransparency = 1,
		LayoutOrder = 1,
		Parent = card,
		[New.Children] = { hlist(12) },
	})
	local pic = Make.ItemSlot(72)
	pic.Name = "Picture"
	pic.LayoutOrder = 1
	pic.Active = false
	pic.Parent = row
	Components.SetItemSlot(pic, { Icon = "equipment/MoonsilverRod", CornerColor = Color3.fromRGB(176, 124, 240) })
	pic.Count.Visible = false
	local info = New("Frame", {
		Name = "Info",
		Size = UDim2.fromOffset(INNER - 84, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		LayoutOrder = 2,
		Parent = row,
		[New.Children] = { vlist(4) },
	})
	New.Title({
		Name = "Name",
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		Text = "Moonsilver Rod",
		TextColor3 = Color3.fromRGB(176, 124, 240),
		TextSize = 18,
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left,
		LayoutOrder = 1,
		Parent = info,
	})
	local tags = New.BadgeSlots(2, { Name = "Tags", Size = UDim2.new(1, 0, 0, 21), LayoutOrder = 2, Parent = info })
	New.SetBadges(tags, { { Text = "EPIC", Color = Color3.fromRGB(176, 124, 240) }, { Text = "Rod" } })
	local stars = New("Frame", {
		Name = "Stars",
		Size = UDim2.new(1, 0, 0, 14),
		BackgroundTransparency = 1,
		Visible = false,
		LayoutOrder = 3,
		Parent = info,
		[New.Children] = { hlist(2) },
	})
	for i = 1, 5 do
		New.Image({ Name = "Star" .. i, Key = "ui/status/xp_star", Fallback = T.Gold, Size = UDim2.fromOffset(14, 14), LayoutOrder = i, Parent = stars })
	end
end

local function modifiers(card: Frame)
	local row = New("Frame", {
		Name = "Modifiers",
		Size = UDim2.fromOffset(INNER, 30),
		BackgroundTransparency = 1,
		LayoutOrder = 6,
		Parent = card,
		[New.Children] = { hlist(6) },
	})
	New.Text({ Name = "Label", Size = UDim2.fromOffset(0, 18), AutomaticSize = Enum.AutomaticSize.X, Text = "Modifiers", TextColor3 = T.SubText, TextSize = 12, LayoutOrder = 1, Parent = row })
	for i = 1, 3 do
		local s = New("Frame", {
			Name = "Socket" .. i,
			Size = UDim2.fromOffset(30, 30),
			BackgroundColor3 = T.PanelLight,
			LayoutOrder = 1 + i,
			Parent = row,
			[New.Children] = { New.Pill(), New.Stroke(T.Track, 2) },
		})
		New.Image({
			Name = "Lock",
			Key = "ui/mastery/locked",
			Fallback = T.Track,
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromOffset(14, 14),
			ImageTransparency = 0.5,
			Parent = s,
		})
	end
	New("Frame", {
		Name = "Spacer",
		Size = UDim2.fromOffset(1, 1),
		BackgroundTransparency = 1,
		LayoutOrder = 10,
		Parent = row,
		[New.Children] = { New("UIFlexItem", { FlexMode = Enum.UIFlexMode.Fill }) },
	})
	local soon = New.BadgeSlots(1, { Name = "Soon", Size = UDim2.fromOffset(0, 21), AutomaticSize = Enum.AutomaticSize.X, LayoutOrder = 11, Parent = row })
	New.SetBadges(soon, { { Text = "Soon", TextColor = T.SubText } })
end

-- Button content "LABEL | icon value" on one line (Figma act48). Hidden; UI/ItemDetail shows it (and
-- clears the button's own Text) when an action has a cost.
local function costContent(button: TextButton)
	local face = button:FindFirstChild("Face")
	local c = New("Frame", {
		Name = "Cost",
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Visible = false,
		ZIndex = 3,
		Parent = face or button,
		[New.Children] = {
			New("UIListLayout", {
				FillDirection = Enum.FillDirection.Horizontal,
				Padding = UDim.new(0, 6),
				HorizontalAlignment = Enum.HorizontalAlignment.Center,
				VerticalAlignment = Enum.VerticalAlignment.Center,
				SortOrder = Enum.SortOrder.LayoutOrder,
			}),
		},
	})
	local function txt(name: string, text: string, order: number)
		New("TextLabel", {
			Name = name,
			Size = UDim2.fromOffset(0, 22),
			AutomaticSize = Enum.AutomaticSize.X,
			BackgroundTransparency = 1,
			Text = text,
			TextColor3 = T.OnAccent,
			FontFace = T.Font,
			TextSize = New.FigmaSize(T.Font, 14),
			LayoutOrder = order,
			ZIndex = 3,
			Parent = c,
		})
	end
	txt("Label", "ENHANCE", 1)
	New("Frame", {
		Name = "Divider",
		Size = UDim2.fromOffset(2, 18),
		BackgroundColor3 = Color3.new(1, 1, 1),
		BackgroundTransparency = 0.55,
		BorderSizePixel = 0,
		LayoutOrder = 2,
		ZIndex = 3,
		Parent = c,
		[New.Children] = { New.Corner(1) },
	})
	New.Image({ Name = "Icon", Key = "ui/status/coin", Fallback = T.Gold, Size = UDim2.fromOffset(18, 18), LayoutOrder = 3, ZIndex = 3, Parent = c })
	txt("Value", "1.2K", 4)
end

local function actions(card: Frame)
	local a = New("Frame", {
		Name = "Actions",
		Size = UDim2.fromOffset(INNER, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		LayoutOrder = 7,
		Parent = card,
		[New.Children] = { vlist(12) },
	})
	rule(a)
	local row = New("Frame", {
		Name = "Buttons",
		Size = UDim2.fromOffset(INNER, 48),
		BackgroundTransparency = 1,
		LayoutOrder = 1,
		Parent = a,
		[New.Children] = { hlist(8) },
	})
	for i, s in { { "EQUIP", T.Good }, { "ENHANCE  1.2k", T.Gold }, { "TANK", T.Sky } } do
		local b = New.Button({
			Name = "A" .. i,
			Size = UDim2.fromOffset(60, 48),
			Text = s[1],
			BackgroundColor3 = s[2],
			MaxTextSize = New.FigmaSize(T.Font, 16),
			Visible = i < 3,
			LayoutOrder = i,
			Parent = row,
		})
		-- not via [New.Children]: New.Button's props would replace its own Lip / Face layers
		New("UIFlexItem", { FlexMode = Enum.UIFlexMode.Fill, Parent = b })
		costContent(b)
	end
end

local function getFrom(card: Frame)
	local g = New("Frame", {
		Name = "GetFrom",
		Size = UDim2.fromOffset(INNER, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		Visible = false,
		LayoutOrder = 8,
		Parent = card,
		[New.Children] = { vlist(10) },
	})
	rule(g)
	local row = New("Frame", {
		Name = "Row",
		Size = UDim2.fromOffset(INNER, 20),
		BackgroundTransparency = 1,
		LayoutOrder = 1,
		Parent = g,
		[New.Children] = { hlist(6) },
	})
	New.Text({ Name = "Title", Size = UDim2.fromOffset(0, 18), AutomaticSize = Enum.AutomaticSize.X, Text = "Get from", TextColor3 = T.SubText, FontFace = T.FontBadge, TextSize = 12, LayoutOrder = 1, Parent = row })
	New.Image({ Name = "Icon", Key = "ui/status/coin", Fallback = T.Gold, Size = UDim2.fromOffset(18, 18), LayoutOrder = 2, Parent = row })
	New.Text({ Name = "Label", Size = UDim2.fromOffset(0, 18), AutomaticSize = Enum.AutomaticSize.X, Text = "Shop - Lv.25 - 900,000", TextColor3 = T.SubText, TextSize = 13, LayoutOrder = 3, Parent = row })
end

function Screen.Build(): ScreenGui
	local gui = New("ScreenGui", {
		Name = "ItemDetail",
		ResetOnSpawn = false,
		IgnoreGuiInset = false,
		Enabled = false,
		DisplayOrder = 30, -- above every window that can open it
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	}) :: ScreenGui
	local card = New.Panel({
		Name = "Card",
		Position = UDim2.fromOffset(400, 200),
		Size = UDim2.fromOffset(Screen.CardWidth, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		Radius = 22,
		ZIndex = 2,
		Active = true, -- clicks on the card do not reach the Catcher
		Parent = gui,
		[New.Children] = { New.Padding(16), vlist(10) },
	})
	head(card)
	local stats = badges("Stats", 8, 2, card)
	New.SetBadges(stats, { { Text = "-10% Auto Wait", Color = T.Gold }, { Text = "+35% Luck" }, { Text = "+50% Reel Power" } })
	New.Text({
		Name = "Desc",
		Size = UDim2.fromOffset(INNER, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		Text = "Forged from moonlight. Steady in deep water.",
		TextColor3 = T.SubText,
		TextWrapped = true,
		TextSize = 13,
		TextXAlignment = Enum.TextXAlignment.Left,
		LayoutOrder = 3,
		Parent = card,
	})
	local meta = badges("Meta", 5, 4, card)
	New.SetBadges(meta, { { Text = "+2", Color = T.Gem } })
	modifiers(card)
	actions(card)
	getFrom(card)
	-- nub: a rotated square half hidden under the card edge, pointing at the slot
	New("Frame", {
		Name = "Nub",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromOffset(0, 42),
		Size = UDim2.fromOffset(14, 14),
		Rotation = 45,
		BackgroundColor3 = T.Panel,
		BorderSizePixel = 0,
		ZIndex = 1,
		Parent = gui, -- sibling under the card so the card covers its inner half
		[New.Children] = { New.Stroke(T.Track, 2) },
	})
	return gui
end

return Screen
