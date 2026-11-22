--!nonstrict
-- Figma 18 · Inventory (Bookmark Tabs) FINAL (docs/figma/inventory_final.py, node 3598:46643), B21.
-- Static layout + Figma sample slots only; Controllers/InventoryController clears the Grid and fills it
-- through UI/VirtualGrid, and UI/ItemDetail shows the Item Card when a slot is pressed.
--   Root          600x480 transparent frame (FitWindow scales it; the tabs stick out of its left edge)
--     Tabs        bookmark tabs All/Fish/Rods/Lines/Auras/Baits/Treasure: TextButton 50x42 (selected 58,
--                 panel colour), Icon (ui/tabs/<key>), Dot (red count pill, hidden)
--     Window      cream panel 600x480, pad 20
--       Header    Title "Inventory", Capacity pill (BagIcon, Used, Max, Upgrade gold button), Spacer, Close
--       SubHeader Category, CountPill/Label, Spacer, Sort (sand pill button, Label "Sort: Rarity")
--       Grid      ScrollingFrame + UIGridLayout: 7 columns of 72px slots, gap 8 / 10
--       Footer    Info (left label: "Total 12.4k"), Secondary (AURA DEX, Auras tab only), Action (SELL ALL /
--                 ROLL AURA); hidden on tabs without
--                 a job, then the grid takes the 4th row
--   BagUpgrade    full-screen dim + Panel (Icon, Title, Slots, Ladder (Tier1..6: Tile, Icon, Cap), Note,
--                 Buttons (Cancel, Upgrade)); hidden

local New = require(script.Parent.Parent.New)
local Components = require(script.Parent.Components)
local Make = Components.Make
local T = New.Theme

local Screen = { Name = "Inventory" }

local WINDOW = Vector2.new(600, 480)
local PAD = 20
local INNER = WINDOW.X - PAD * 2 -- 560
local SLOT, GAP, ROW_GAP, COLS = 72, 8, 10, 7
local GRID_Y = PAD + 44 + 12 + 28 + 12 -- 116
local FOOTER_H = 48
local TAB_W, TAB_H, TAB_STEP = 50, 42, 48

-- { tab name, art key under ui/tabs/ }
Screen.Tabs = {
	{ "All", "all" },
	{ "Fish", "fish" },
	{ "Rods", "rods" },
	{ "Lines", "lines" },
	{ "Auras", "auras" },
	{ "Baits", "baits" },
	{ "Treasure", "treasure" },
}
Screen.TabWidth = TAB_W
-- grid heights (ScrollingFrame, incl. its 6px top room for badges)
Screen.GridH = {
	Full = WINDOW.Y - PAD - GRID_Y + 6,
	WithFooter = WINDOW.Y - PAD - FOOTER_H - 12 - GRID_Y + 6,
}

local RARITY = {
	Common = Color3.fromRGB(154, 165, 177),
	Uncommon = Color3.fromRGB(92, 201, 138),
	Rare = Color3.fromRGB(90, 169, 240),
	Epic = Color3.fromRGB(176, 124, 240),
	Legendary = Color3.fromRGB(242, 169, 59),
}
local SAMPLE = {
	{ "equipment/DriftwoodRod", "Common" },
	{ "equipment/BambooRod", "Uncommon" },
	{ "equipment/CoralRod", "Rare", "selected" },
	{ "equipment/MoonsilverRod", "Epic", "equipped" },
	{ "equipment/NagaScaleRod", "Legendary", "new" },
}

local function label(props: { [any]: any }): TextLabel
	local font = props.FontFace or T.Font
	local base = {
		Size = UDim2.fromOffset(0, props.H or 22),
		AutomaticSize = Enum.AutomaticSize.X,
		BackgroundTransparency = 1,
		TextColor3 = T.Text,
		FontFace = font,
		TextSize = New.FigmaSize(font, props.Px or 16),
	}
	props.H, props.Px = nil, nil
	for k, v in props do
		base[k] = v
	end
	return New("TextLabel", base) :: TextLabel
end

local function hlist(gap: number, center: boolean?): UIListLayout
	return New("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		Padding = UDim.new(0, gap),
		VerticalAlignment = Enum.VerticalAlignment.Center,
		HorizontalAlignment = if center then Enum.HorizontalAlignment.Center else Enum.HorizontalAlignment.Left,
		SortOrder = Enum.SortOrder.LayoutOrder,
	})
end

local function spacer(order: number, parent: Instance)
	New("Frame", {
		Name = "Spacer",
		Size = UDim2.fromOffset(1, 1),
		BackgroundTransparency = 1,
		LayoutOrder = order,
		Parent = parent,
		[New.Children] = { New("UIFlexItem", { FlexMode = Enum.UIFlexMode.Fill }) },
	})
end

local function capacityPill(parent: Instance)
	local pill = New("Frame", {
		Name = "Capacity",
		Size = UDim2.fromOffset(0, 32),
		AutomaticSize = Enum.AutomaticSize.X,
		BackgroundColor3 = T.PanelLight,
		LayoutOrder = 2,
		Parent = parent,
		[New.Children] = {
			New.Pill(),
			New("UIPadding", { PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 12) }),
			hlist(6),
		},
	})
	New.Image({ Name = "BagIcon", Key = "ui/icons/bag", Fallback = T.Gold, Size = UDim2.fromOffset(20, 20), LayoutOrder = 1, Parent = pill })
	label({ Name = "Used", Text = "18", Px = 16, LayoutOrder = 2, Parent = pill })
	label({ Name = "Max", Text = "/ 30", Px = 16, TextColor3 = RARITY.Common, LayoutOrder = 3, Parent = pill })
	New.Button({
		Name = "Upgrade",
		Size = UDim2.fromOffset(84, 26),
		Text = "UPGRADE",
		BackgroundColor3 = T.Gold,
		TextSize = 12,
		Radius = 13,
		LayoutOrder = 4,
		Parent = pill,
	})
end

local function header(w: Frame)
	local row = New("Frame", {
		Name = "Header",
		Position = UDim2.fromOffset(PAD, PAD),
		Size = UDim2.fromOffset(INNER, 44),
		BackgroundTransparency = 1,
		Parent = w,
		[New.Children] = { hlist(14) },
	})
	label({ Name = "Title", Text = "Inventory", Px = 24, H = 32, LayoutOrder = 1, Parent = row })
	capacityPill(row)
	spacer(3, row)
	New.Button({ Name = "Close", Size = UDim2.fromOffset(52, 44), Text = "X", BackgroundColor3 = T.Bad, TextSize = 20, LayoutOrder = 4, Parent = row })
end

local function subHeader(w: Frame)
	local row = New("Frame", {
		Name = "SubHeader",
		Position = UDim2.fromOffset(PAD, PAD + 44 + 12),
		Size = UDim2.fromOffset(INNER, 28),
		BackgroundTransparency = 1,
		Parent = w,
		[New.Children] = { hlist(8) },
	})
	label({ Name = "Category", Text = "Rods", Px = 18, H = 26, LayoutOrder = 1, Parent = row })
	local pill = New("Frame", {
		Name = "CountPill",
		Size = UDim2.fromOffset(0, 22),
		AutomaticSize = Enum.AutomaticSize.X,
		BackgroundColor3 = T.PanelLight,
		LayoutOrder = 2,
		Parent = row,
		[New.Children] = { New.Pill(), New("UIPadding", { PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10) }) },
	})
	label({ Name = "Label", Text = "5 owned", Px = 12, H = 22, FontFace = T.FontBadge, TextColor3 = T.SubText, Parent = pill })
	spacer(3, row)
	local sort = New("TextButton", {
		Name = "Sort",
		Size = UDim2.fromOffset(0, 26),
		AutomaticSize = Enum.AutomaticSize.X,
		BackgroundColor3 = T.PanelLight,
		Text = "",
		AutoButtonColor = true,
		LayoutOrder = 4,
		Parent = row,
		[New.Children] = { New.Pill(), New("UIPadding", { PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 12) }) },
	})
	label({ Name = "Label", Text = "Sort: Rarity", Px = 13, H = 26, FontFace = T.FontBadge, Parent = sort })
end

local function grid(w: Frame)
	-- 8px wider on each side than the slots: room for the NEW pill / tick badge that stick out of a slot
	local g = New("ScrollingFrame", {
		Name = "Grid",
		Position = UDim2.fromOffset(PAD - 8, GRID_Y - 6),
		Size = UDim2.fromOffset(COLS * SLOT + (COLS - 1) * GAP + 16, Screen.GridH.WithFooter),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollingDirection = Enum.ScrollingDirection.Y,
		ScrollBarThickness = 4,
		ScrollBarImageColor3 = T.Track,
		VerticalScrollBarInset = Enum.ScrollBarInset.None,
		Parent = w,
		[New.Children] = {
			New("UIPadding", { PaddingTop = UDim.new(0, 8), PaddingBottom = UDim.new(0, 4), PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8) }),
			New("UIGridLayout", {
				CellSize = UDim2.fromOffset(SLOT, SLOT),
				CellPadding = UDim2.fromOffset(GAP, ROW_GAP),
				FillDirectionMaxCells = COLS,
				SortOrder = Enum.SortOrder.LayoutOrder,
			}),
		},
	})
	for i, s in SAMPLE do
		local slot = Make.ItemSlot(SLOT)
		slot.LayoutOrder = i
		slot.Parent = g
		Components.SetItemSlot(slot, {
			Icon = s[1],
			IconColor = RARITY[s[2]],
			CornerColor = RARITY[s[2]],
			New = s[3] == "new",
			Selected = s[3] == "selected",
			Ring = if s[3] == "equipped" then T.SkyLip else nil,
		})
		slot.Count.Visible = false
	end
end

local function footer(w: Frame)
	local f = New("Frame", {
		Name = "Footer",
		Position = UDim2.fromOffset(PAD, WINDOW.Y - PAD - FOOTER_H),
		Size = UDim2.fromOffset(INNER, FOOTER_H),
		BackgroundTransparency = 1,
		Parent = w,
		[New.Children] = { hlist(10) },
	})
	label({ Name = "Info", Text = "Total 12.4k", Px = 14, FontFace = T.FontBody, TextColor3 = T.SubText, LayoutOrder = 1, Parent = f })
	spacer(2, f)
	New.Button({ Name = "Secondary", Size = UDim2.fromOffset(140, FOOTER_H), Text = "AURA DEX", BackgroundColor3 = T.Gem, TextSize = 16, Visible = false, LayoutOrder = 3, Parent = f })
	New.Button({ Name = "Action", Size = UDim2.fromOffset(180, FOOTER_H), Text = "SELL ALL", BackgroundColor3 = T.Gold, TextSize = 16, LayoutOrder = 4, Parent = f })
end

local function tabs(root: Frame)
	local holder = New("Frame", {
		Name = "Tabs",
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		ZIndex = 1,
		Parent = root,
	})
	for i, t in Screen.Tabs do
		local on = i == 3
		local w = if on then TAB_W + 8 else TAB_W
		local tab = New("TextButton", {
			Name = t[1],
			Position = UDim2.fromOffset(-w + 8, 54 + (i - 1) * TAB_STEP),
			Size = UDim2.fromOffset(w, TAB_H),
			BackgroundColor3 = if on then T.Panel else T.PanelLight,
			Text = "",
			AutoButtonColor = false,
			Parent = holder,
			[New.Children] = { New.Corner(12), New.Stroke(T.Track, 2) },
		})
		New.Image({
			Name = "Icon",
			Key = "ui/tabs/" .. t[2],
			Fallback = T.Track,
			FallbackText = string.sub(t[1], 1, 1),
			AnchorPoint = Vector2.new(0, 0.5),
			Position = UDim2.new(0, 7, 0.5, 0),
			Size = UDim2.fromOffset(32, 32),
			Parent = tab,
		})
		New("TextLabel", {
			Name = "Dot",
			Position = UDim2.fromOffset(-8, -6),
			Size = UDim2.fromOffset(0, 18),
			AutomaticSize = Enum.AutomaticSize.X,
			BackgroundColor3 = T.Bad,
			Text = "3",
			TextColor3 = T.OnAccent,
			FontFace = T.FontBadge,
			TextSize = New.FigmaSize(T.FontBadge, 11),
			Visible = false,
			ZIndex = 3,
			Parent = tab,
			[New.Children] = { New.Pill(), New("UIPadding", { PaddingLeft = UDim.new(0, 6), PaddingRight = UDim.new(0, 6) }) },
		})
	end
end

local function bagUpgrade(gui: ScreenGui)
	local dim = New("TextButton", {
		Name = "BagUpgrade",
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color3.new(0, 0, 0),
		BackgroundTransparency = 1, -- no black overlay (still blocks clicks behind)
		Text = "",
		AutoButtonColor = false,
		Visible = false,
		ZIndex = 20,
		Parent = gui,
	})
	local p = New.Panel({
		Name = "Panel",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(440, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		Radius = T.RadiusWindow,
		ZIndex = 21,
		Parent = dim,
		[New.Children] = {
			New.Padding(20),
			New("UIListLayout", { Padding = UDim.new(0, 10), HorizontalAlignment = Enum.HorizontalAlignment.Center, SortOrder = Enum.SortOrder.LayoutOrder }),
		},
	})
	New.Image({ Name = "Icon", Key = "ui/tabs/bag_upgrade", Fallback = T.Gold, Size = UDim2.fromOffset(64, 64), LayoutOrder = 1, ZIndex = 22, Parent = p })
	label({ Name = "Title", Text = "Upgrade Bag", Px = 22, H = 28, LayoutOrder = 2, ZIndex = 22, Parent = p })
	label({ Name = "Slots", Text = "20 slots -> 30 slots", Px = 16, LayoutOrder = 3, ZIndex = 22, RichText = true, Parent = p })
	local ladder = New("Frame", {
		Name = "Ladder",
		Size = UDim2.new(1, 0, 0, 62),
		BackgroundTransparency = 1,
		LayoutOrder = 4,
		ZIndex = 22,
		Parent = p,
		[New.Children] = { hlist(8, true) },
	})
	for i = 1, 6 do
		local tier = New("Frame", {
			Name = "Tier" .. i,
			Size = UDim2.fromOffset(52, 62),
			BackgroundTransparency = 1,
			LayoutOrder = i,
			ZIndex = 22,
			Parent = ladder,
		})
		New("Frame", {
			Name = "Tile",
			Size = UDim2.fromOffset(44, 44),
			Position = UDim2.fromOffset(4, 0),
			BackgroundColor3 = Color3.new(1, 1, 1),
			ZIndex = 22,
			Parent = tier,
			[New.Children] = { New.Corner(12), New("UIStroke", { Name = "Ring", Color = T.Track, Thickness = 2 }) },
		})
		New.Image({ Name = "Icon", Key = "equipment/StarterPouch", Fallback = T.PanelLight, Position = UDim2.fromOffset(8, 4), Size = UDim2.fromOffset(36, 36), ZIndex = 23, Parent = tier })
		New("TextLabel", {
			Name = "Cap",
			Position = UDim2.fromOffset(0, 46),
			Size = UDim2.fromOffset(52, 16),
			BackgroundTransparency = 1,
			Text = "6",
			TextColor3 = T.SubText,
			FontFace = T.FontBadge,
			TextSize = New.FigmaSize(T.FontBadge, 12),
			ZIndex = 23,
			Parent = tier,
		})
	end
	New.Text({
		Name = "Note",
		Size = UDim2.new(1, 0, 0, 34),
		Text = "Bags are upgrades: each one replaces the last, you never go back to a smaller bag.",
		TextColor3 = T.SubText,
		TextWrapped = true,
		TextSize = 13,
		LayoutOrder = 5,
		ZIndex = 22,
		Parent = p,
	})
	local buttons = New("Frame", {
		Name = "Buttons",
		Size = UDim2.new(1, 0, 0, 48),
		BackgroundTransparency = 1,
		LayoutOrder = 6,
		ZIndex = 22,
		Parent = p,
		[New.Children] = { hlist(10, true) },
	})
	New.Button({ Name = "Cancel", Size = UDim2.fromOffset(180, 48), Text = "Cancel", BackgroundColor3 = T.PanelLight, TextSize = 16, LayoutOrder = 1, ZIndex = 22, Parent = buttons })
	New.Button({ Name = "Upgrade", Size = UDim2.fromOffset(180, 48), Text = "UPGRADE  2.5k", BackgroundColor3 = T.Gold, TextSize = 16, LayoutOrder = 2, ZIndex = 22, Parent = buttons })
end

function Screen.Build(): ScreenGui
	local gui = New("ScreenGui", {
		Name = "Inventory",
		ResetOnSpawn = false,
		IgnoreGuiInset = false,
		Enabled = false, -- InventoryController opens it (HUD bag chip / key B)
		DisplayOrder = 12,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	}) :: ScreenGui
	local root = New("Frame", {
		Name = "Root",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(WINDOW.X, WINDOW.Y),
		BackgroundTransparency = 1,
		Parent = gui,
	})
	tabs(root)
	local w = New.Panel({
		Name = "Window",
		Size = UDim2.fromScale(1, 1),
		Radius = T.RadiusWindow,
		ZIndex = 2,
		Parent = root,
	})
	-- Tabs tuck under the panel edge. The shadow stays behind their artwork.
	local windowShadow = New("Frame", {
		Name = "WindowShadow",
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = w.BackgroundColor3,
		BorderSizePixel = 0,
		ZIndex = 0,
		Parent = root,
		[New.Children] = { New.Corner(T.RadiusWindow) },
	})
	New.Shadow(windowShadow, "slice_shadow_window")
	header(w)
	subHeader(w)
	grid(w)
	footer(w)
	bagUpgrade(gui)
	return gui
end

return Screen
