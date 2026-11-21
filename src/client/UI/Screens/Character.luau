--!nonstrict
-- Figma 17 · Character v2 (docs/figma/inventory_final.py, node 3599:48078), B21. Rod / Line / Bait / Aura
-- (no Bag: bags are an upgrade). Pressing any item (equipped slot or the owned grid) opens UI/ItemDetail.
-- Static layout + samples; Controllers/CharacterController fills it.
--   Window       cream panel 720x520, pad 20
--     Header     Title "Character", Spacer, Skills (C4 window), Close
--     Left       x 20, 200 wide
--       Avatar   ViewportFrame 200x200 (player clone, drag to spin), NameTag (Name, Level)
--       Equipped Rod / Line / Bait / Aura: Slot (holder for a 44px ItemSlot) + Label
--       Stats    sand box, Row1..5 (Key, Value)
--     Right      x 240, 460 wide
--       Tabs     chips Rods / Lines / Baits / Auras (Icon + Label; selected = Accent)
--       Grid     ScrollingFrame + UIGridLayout, 5 columns of 72px slots
--       Empty    "Nothing here yet" (hidden)
--       Hint     "Tap an item to see it. Blue ring = equipped."

local New = require(script.Parent.Parent.New)
local Components = require(script.Parent.Components)
local Make = Components.Make
local T = New.Theme

local Screen = { Name = "Character" }

local WINDOW = Vector2.new(720, 520)
local PAD = 20
local LEFT_W = 200
local RIGHT_X = PAD + LEFT_W + 20 -- 240
local RIGHT_W = WINDOW.X - RIGHT_X - PAD -- 460
local SLOT, GAP, ROW_GAP, COLS = 72, 8, 10, 5

Screen.Tabs = { { "Rods", "rods" }, { "Lines", "lines" }, { "Baits", "baits" }, { "Auras", "auras" } }
Screen.Equipped = { { "Rod", "ROD" }, { "Line", "LINE" }, { "Bait", "BAIT" }, { "Aura", "AURA" } }
Screen.StatRows = 5

local function label(props: { [any]: any }): TextLabel
	local font = props.FontFace or T.Font
	local base = {
		Size = UDim2.fromOffset(0, props.H or 20),
		AutomaticSize = Enum.AutomaticSize.X,
		BackgroundTransparency = 1,
		TextColor3 = T.Text,
		FontFace = font,
		TextSize = New.FigmaSize(font, props.Px or 14),
	}
	props.H, props.Px = nil, nil
	for k, v in props do
		base[k] = v
	end
	return New("TextLabel", base) :: TextLabel
end

local function header(w: Frame)
	local row = New("Frame", {
		Name = "Header",
		Position = UDim2.fromOffset(PAD, PAD),
		Size = UDim2.fromOffset(WINDOW.X - PAD * 2, 44),
		BackgroundTransparency = 1,
		Parent = w,
		[New.Children] = {
			New("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 10), VerticalAlignment = Enum.VerticalAlignment.Center, SortOrder = Enum.SortOrder.LayoutOrder }),
		},
	})
	label({ Name = "Title", Text = "Character", Px = 24, H = 32, LayoutOrder = 1, Parent = row })
	New("Frame", {
		Name = "Spacer",
		Size = UDim2.fromOffset(1, 1),
		BackgroundTransparency = 1,
		LayoutOrder = 2,
		Parent = row,
		[New.Children] = { New("UIFlexItem", { FlexMode = Enum.UIFlexMode.Fill }) },
	})
	-- C4: skills window (text shows unspent points, e.g. "SKILLS  3")
	New.Button({ Name = "Skills", Size = UDim2.fromOffset(130, 44), Text = "SKILLS", BackgroundColor3 = T.Gem, TextSize = 16, LayoutOrder = 3, Parent = row })
	New.Button({ Name = "Close", Size = UDim2.fromOffset(52, 44), Text = "X", BackgroundColor3 = T.Bad, TextSize = 20, LayoutOrder = 4, Parent = row })
end

local function left(w: Frame)
	local col = New("Frame", {
		Name = "Left",
		Position = UDim2.fromOffset(PAD, PAD + 44 + 12),
		Size = UDim2.fromOffset(LEFT_W, WINDOW.Y - PAD * 2 - 56),
		BackgroundTransparency = 1,
		Parent = w,
	})
	local avatar = New("ViewportFrame", {
		Name = "Avatar",
		Size = UDim2.fromOffset(LEFT_W, 200),
		BackgroundColor3 = T.TintMint,
		Ambient = Color3.fromRGB(200, 200, 200),
		LightColor = Color3.fromRGB(255, 255, 255),
		LightDirection = Vector3.new(-1, -1, -1),
		Active = true,
		Parent = col,
		[New.Children] = { New.Corner(T.RadiusCard), New.Stroke(T.Track, 2) },
	})
	local tag = New("Frame", {
		Name = "NameTag",
		Position = UDim2.fromOffset(0, 8),
		Size = UDim2.new(1, 0, 0, 40),
		BackgroundTransparency = 1,
		ZIndex = 2,
		Parent = avatar,
		[New.Children] = { New("UIListLayout", { HorizontalAlignment = Enum.HorizontalAlignment.Center, SortOrder = Enum.SortOrder.LayoutOrder }) },
	})
	label({ Name = "Name", Text = "PipFisher", Px = 16, LayoutOrder = 1, ZIndex = 2, Parent = tag })
	label({ Name = "Level", Text = "Lv.42", Px = 12, FontFace = T.FontBadge, TextColor3 = T.SubText, LayoutOrder = 2, ZIndex = 2, Parent = tag })
	label({
		Name = "Hint",
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -6),
		Text = "drag to spin",
		Px = 11,
		FontFace = T.FontBody,
		TextColor3 = T.SubText,
		ZIndex = 2,
		Parent = avatar,
	})

	local eq = New("Frame", {
		Name = "Equipped",
		Position = UDim2.fromOffset(0, 212),
		Size = UDim2.fromOffset(LEFT_W, 64),
		BackgroundTransparency = 1,
		Parent = col,
		[New.Children] = {
			New("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 8), HorizontalAlignment = Enum.HorizontalAlignment.Center, SortOrder = Enum.SortOrder.LayoutOrder }),
		},
	})
	for i, e in Screen.Equipped do
		local cell = New("Frame", { Name = e[1], Size = UDim2.fromOffset(44, 64), BackgroundTransparency = 1, LayoutOrder = i, Parent = eq })
		local slot = Make.ItemSlot(44)
		slot.Name = "Slot"
		slot.Parent = cell
		Components.SetItemSlot(slot, { Empty = true })
		New("TextLabel", {
			Name = "Label",
			Position = UDim2.fromOffset(0, 47),
			Size = UDim2.fromOffset(44, 14),
			BackgroundTransparency = 1,
			Text = e[2],
			TextColor3 = T.SubText,
			FontFace = T.FontBadge,
			TextSize = New.FigmaSize(T.FontBadge, 10),
			Parent = cell,
		})
	end

	local stats = New("Frame", {
		Name = "Stats",
		Position = UDim2.fromOffset(0, 286),
		Size = UDim2.fromOffset(LEFT_W, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundColor3 = T.PanelLight,
		Parent = col,
		[New.Children] = {
			New.Corner(12),
			New("UIPadding", { PaddingTop = UDim.new(0, 8), PaddingBottom = UDim.new(0, 8), PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 12) }),
			New("UIListLayout", { Padding = UDim.new(0, 2), SortOrder = Enum.SortOrder.LayoutOrder }),
		},
	})
	for i = 1, Screen.StatRows do
		local row = New("Frame", { Name = "Row" .. i, Size = UDim2.new(1, 0, 0, 18), BackgroundTransparency = 1, LayoutOrder = i, Parent = stats })
		New("TextLabel", {
			Name = "Key", -- not "Name": row.Name is the Instance property
			Size = UDim2.fromScale(0.6, 1),
			BackgroundTransparency = 1,
			Text = "Luck",
			TextColor3 = T.SubText,
			FontFace = T.FontBody,
			TextSize = New.FigmaSize(T.FontBody, 13),
			TextXAlignment = Enum.TextXAlignment.Left,
			Parent = row,
		})
		New("TextLabel", {
			Name = "Value",
			AnchorPoint = Vector2.new(1, 0),
			Position = UDim2.fromScale(1, 0),
			Size = UDim2.fromScale(0.4, 1),
			BackgroundTransparency = 1,
			Text = "+60%",
			TextColor3 = T.Text,
			FontFace = T.FontBadge,
			TextSize = New.FigmaSize(T.FontBadge, 13),
			TextXAlignment = Enum.TextXAlignment.Right,
			Parent = row,
		})
	end
end

local function right(w: Frame)
	local col = New("Frame", {
		Name = "Right",
		Position = UDim2.fromOffset(RIGHT_X, PAD + 44 + 12),
		Size = UDim2.fromOffset(RIGHT_W, WINDOW.Y - PAD * 2 - 56),
		BackgroundTransparency = 1,
		Parent = w,
	})
	local tabs = New("Frame", {
		Name = "Tabs",
		Size = UDim2.fromOffset(RIGHT_W, 34),
		BackgroundTransparency = 1,
		Parent = col,
		[New.Children] = {
			New("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }),
		},
	})
	for i, t in Screen.Tabs do
		local chip = New("TextButton", {
			Name = t[1],
			Size = UDim2.fromOffset(0, 34),
			AutomaticSize = Enum.AutomaticSize.X,
			BackgroundColor3 = if i == 1 then T.Accent else T.PanelLight,
			Text = "",
			AutoButtonColor = false,
			LayoutOrder = i,
			Parent = tabs,
			[New.Children] = {
				New.Pill(),
				New("UIPadding", { PaddingLeft = UDim.new(0, 6), PaddingRight = UDim.new(0, 14) }),
				New("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 6), VerticalAlignment = Enum.VerticalAlignment.Center, SortOrder = Enum.SortOrder.LayoutOrder }),
			},
		})
		New.Image({ Name = "Icon", Key = "ui/tabs/" .. t[2], Fallback = T.Track, Size = UDim2.fromOffset(24, 24), LayoutOrder = 1, Parent = chip })
		label({ Name = "Label", Text = t[1], Px = 15, H = 22, TextColor3 = if i == 1 then T.OnAccent else T.Text, LayoutOrder = 2, Parent = chip })
	end
	New("ScrollingFrame", {
		Name = "Grid",
		Position = UDim2.fromOffset(-8, 42),
		Size = UDim2.fromOffset(COLS * SLOT + (COLS - 1) * GAP + 16, 4 * SLOT + 3 * ROW_GAP + 14),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollingDirection = Enum.ScrollingDirection.Y,
		ScrollBarThickness = 4,
		ScrollBarImageColor3 = T.Track,
		VerticalScrollBarInset = Enum.ScrollBarInset.None,
		Parent = col,
		[New.Children] = {
			New("UIPadding", { PaddingTop = UDim.new(0, 8), PaddingBottom = UDim.new(0, 4), PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8) }),
			New("UIGridLayout", { CellSize = UDim2.fromOffset(SLOT, SLOT), CellPadding = UDim2.fromOffset(GAP, ROW_GAP), FillDirectionMaxCells = COLS, SortOrder = Enum.SortOrder.LayoutOrder }),
		},
	})
	label({
		Name = "Empty",
		Position = UDim2.fromOffset(0, 60),
		Text = "Nothing here yet",
		Px = 14,
		FontFace = T.FontBody,
		TextColor3 = T.SubText,
		Visible = false,
		Parent = col,
	})
	label({
		Name = "Hint",
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.fromScale(0, 1),
		Text = "Tap an item to see it. Blue ring = equipped.",
		Px = 12,
		FontFace = T.FontBody,
		TextColor3 = T.SubText,
		Parent = col,
	})
end

function Screen.Build(): ScreenGui
	local gui = New("ScreenGui", {
		Name = "Character",
		ResetOnSpawn = false,
		IgnoreGuiInset = false,
		Enabled = false, -- CharacterController opens it (key C / Main Menu avatar)
		DisplayOrder = 12,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	}) :: ScreenGui
	local w = New.Panel({
		Name = "Window",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(WINDOW.X, WINDOW.Y),
		Radius = T.RadiusWindow,
		Parent = gui,
	})
	New.Shadow(w, "slice_shadow_window")
	header(w)
	left(w)
	right(w)
	return gui
end

return Screen
