--!nonstrict
-- Gacha page = Figma "Gacha Redesign v2 — A / D", concept D "Glass Card" (3662:56279, user-edited) + the E1 parts
-- the user asked to keep (Mythic pity box, Milestones box, Skip animation, Auto-roll until Epic+). Full screen:
-- a 1280x720 Canvas that UI/GachaPage scales to the safe area. The binder moves Bg and Floor into its
-- full-bleed art layer. ONE layout for every Config/AuraBanners banner; UI/GachaPage fills it.
--   Window (safe area)
--     Bg (ui/gacha_bg_celestial, Crop), Floor (white -> lilac gradient, bottom 1/6)
--     Canvas (1280x720, UIScale "Scale")
--       Glow0..2, Hero (auras_Art/<id>, or the orb when the aura has no illustration)
--       TopBar     Back, Title, Chips (Gems, StarTokens: buttons, open Top Up)
--       Rail       ScrollingFrame of BannerCard clones (Templates)
--       InfoCard   Ribbon/Label, Title, Stars, Timer (Icon, Text), Desc, Featured (Inventory item slots -> Item Card), PityNote (Icon, Text)
--       PityMythic Label, Value, Bar/Fill (hard pity; hidden when the banner has none)
--       Milestones Label, Value, View (+ Dot), Bar/Fill (event banners with milestones)
--       Options    Skip, Auto (checkbox: Box/Tick + Label)
--       NamePlate  Rarity, AuraName, Stars
--       SmallButtons Shop, Rates
--       PayToggle  Gems, Tokens (selected = coral)
--       RollBar    Roll1, Roll10 (Title, Price: Icon, Value; Roll10 also Guarantee "RARE+")
--     RatesPopup (transparent input shield) Panel: Title, Close, List of RateRow clones
--     MilestonesPopup, Summary (x10 results, Figma G6) — same as before
--   Templates  (Folder, hidden) RateRow, MilestoneCell, ResultCell, BannerCard
-- Child names are the API (UI/GachaPage finds parts by name).

local New = require(script.Parent.Parent.New)
local Components = require(script.Parent.Components)
local T = New.Theme

local Screen = { Name = "GachaPage" }

local ROW_H = 56
local TILE, CELL_W, CELL_H = 80, 104, 100
local WHITE = Color3.new(1, 1, 1)


-- sample rarity colours (Config/Rarities; runtime uses Registry)
local R = {
	Common = Color3.fromRGB(154, 165, 177),
	Uncommon = Color3.fromRGB(92, 201, 138),
	Rare = Color3.fromRGB(90, 169, 240),
	Epic = Color3.fromRGB(176, 124, 240),
	Legendary = Color3.fromRGB(242, 169, 59),
	Mythic = Color3.fromRGB(242, 102, 139),
}

local function hList(gap: number, align: Enum.HorizontalAlignment?): UIListLayout
	return New("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		Padding = UDim.new(0, gap),
		VerticalAlignment = Enum.VerticalAlignment.Center,
		HorizontalAlignment = align or Enum.HorizontalAlignment.Left,
		SortOrder = Enum.SortOrder.LayoutOrder,
	}) :: UIListLayout
end

local function autoText(name: string, text: string, font: Font, size: number, color: Color3, h: number, order: number?): TextLabel
	return New("TextLabel", {
		Name = name,
		Size = UDim2.fromOffset(0, h),
		AutomaticSize = Enum.AutomaticSize.X,
		BackgroundTransparency = 1,
		Text = text,
		TextColor3 = color,
		FontFace = font,
		TextSize = New.FigmaSize(font, size),
		LayoutOrder = order or 0,
	}) :: TextLabel
end

local function smallPill(name: string, text: string, color: Color3, h: number?, order: number?): TextLabel
	return New("TextLabel", {
		Name = name,
		Size = UDim2.fromOffset(0, h or 20),
		AutomaticSize = Enum.AutomaticSize.X,
		BackgroundColor3 = color,
		Text = text,
		TextColor3 = WHITE,
		FontFace = T.FontBadge,
		TextSize = New.FigmaSize(T.FontBadge, 11),
		LayoutOrder = order or 0,
		[New.Children] = { New.Pill(), New("UIPadding", { PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8) }) },
	}) :: TextLabel
end

-- Rarity triangle in the top-left corner (same trick as Make.ItemSlot: UICorner + hard UIGradient).
local function rarityCorner(size: number, radius: number, legPx: number, z: number): Frame
	local leg = legPx / (2 * size)
	return New("Frame", {
		Name = "Corner",
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = R.Common,
		BorderSizePixel = 0,
		ZIndex = z,
		[New.Children] = {
			New.Corner(radius),
			New("UIGradient", {
				Rotation = 45,
				Transparency = NumberSequence.new({
					NumberSequenceKeypoint.new(0, 0),
					NumberSequenceKeypoint.new(leg, 0),
					NumberSequenceKeypoint.new(leg + 0.002, 1),
					NumberSequenceKeypoint.new(1, 1),
				}),
			}),
		},
	}) :: Frame
end

-- Checkbox (Figma m.checkbox: 30px r9; on = mint + mint-lip border + white tick) + Label.
local function checkbox(name: string, text: string, x: number, w: number): TextButton
	local b = New("TextButton", {
		Name = name,
		Position = UDim2.fromOffset(x, 0),
		Size = UDim2.fromOffset(w, 30),
		BackgroundTransparency = 1,
		Text = "",
		AutoButtonColor = false,
	})
	local box = New("Frame", {
		Name = "Box",
		Size = UDim2.fromOffset(30, 30),
		BackgroundColor3 = T.Panel,
		Parent = b,
		[New.Children] = { New.Corner(9), New.Stroke() },
	})
	New.Image({ Name = "Tick", Key = "icon_check", Fallback = T.Good, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(18, 18), Visible = false, Parent = box })
	New.Text({ Name = "Label", Position = UDim2.fromOffset(38, 0), Size = UDim2.new(1, -38, 1, 0), Text = text, TextXAlignment = Enum.TextXAlignment.Left, TextSize = 14, Parent = b })
	return b :: TextButton
end

function Screen.SetCheckbox(b: any, on: boolean, text: string?)
	b.Box.BackgroundColor3 = if on then T.Good else T.Panel
	local stroke = b.Box:FindFirstChildOfClass("UIStroke")
	if stroke then
		stroke.Color = if on then T.GoodLip else T.Track
	end
	b.Box.Tick.Visible = on
	b.Box.Tick.ImageColor3 = WHITE
	if text then
		b.Label.Text = text
	end
end

-- Templates -----------------------------------------------------------------------------------------

-- Drop-rate row (Figma rates_panel row): sand r14, Orb 40, AuraName (Heading), Meta (Rarity tag, RateUp "x2", Chance), Owned.
-- Highlight = gold ring for the banner's featured aura.
local function rateRow(): Frame
	local row = New("Frame", {
		Name = "RateRow",
		Size = UDim2.new(1, 0, 0, ROW_H),
		BackgroundColor3 = T.PanelLight,
		[New.Children] = { New.Corner(14), New("UIStroke", { Name = "Highlight", Color = T.Gold, Thickness = 2, Enabled = false, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }) },
	})
	New.Image({ Name = "Orb", Key = "auras/SparklingDew", Fallback = T.Gem, Position = UDim2.fromOffset(6, 8), Size = UDim2.fromOffset(40, 40), Parent = row })
	New.Title({ Name = "AuraName", Position = UDim2.fromOffset(56, 5), Size = UDim2.new(1, -120, 0, 24), Text = "Sparkling Dew", TextXAlignment = Enum.TextXAlignment.Left, TextSize = 20, Parent = row })
	local meta = New("Frame", { Name = "Meta", Position = UDim2.fromOffset(56, 31), Size = UDim2.new(1, -120, 0, 18), BackgroundTransparency = 1, Parent = row, [New.Children] = { hList(6) } })
	smallPill("Rarity", "COMMON", R.Common, 18, 1).Parent = meta
	local ru = smallPill("RateUp", "x2", T.SkyLip, 18, 2)
	ru.Visible = false
	ru.Parent = meta
	autoText("Chance", "1/10", T.FontBadge, 12, T.SubText, 18, 3).Parent = meta
	New.Title({ Name = "Owned", AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -12, 0.5, 0), Size = UDim2.fromOffset(60, 20), Text = "x3", TextXAlignment = Enum.TextXAlignment.Right, TextSize = 16, Parent = row })
	return row :: Frame
end

-- info: { Orb, Name ("???" = unknown), Rarity, RarityColor, Chance (text), Owned, RateUp? (text "x2"), Featured? }
function Screen.SetRateRow(row: any, info: { [string]: any })
	New.SetImageKey(row.Orb, info.Orb or "auras/UnknownAura", info.RarityColor)
	row.AuraName.Text = info.Name or "???"
	row.AuraName.TextColor3 = if info.Name == "???" then T.SubText else T.Text
	local meta = row.Meta
	meta.Rarity.Text = string.upper(info.Rarity or "")
	meta.Rarity.BackgroundColor3 = info.RarityColor or R.Common
	meta.RateUp.Visible = info.RateUp ~= nil
	meta.RateUp.Text = info.RateUp or ""
	meta.Chance.Text = info.Chance or ""
	meta.Chance.TextColor3 = if info.RateUp then T.SkyLip else T.SubText
	local owned = info.Owned or 0
	row.Owned.Text = if owned > 0 then `x{owned}` else "-"
	row.Owned.TextColor3 = if owned > 0 then T.Text else R.Common
	row.Highlight.Enabled = info.Featured == true
	row.BackgroundColor3 = if info.Featured then T.TintButter else T.PanelLight
end

-- Milestone cell (Figma E1 milestone_cell): 104x100. Tile (80, white r18) with Icon, Corner, Count; Ring;
-- Label under; Check / Lock badge top-right; Claim pill above.
local function milestoneCell(): Frame
	local cell = New("Frame", { Name = "MilestoneCell", Size = UDim2.fromOffset(CELL_W, CELL_H), BackgroundTransparency = 1 })
	local tx = (CELL_W - TILE) / 2
	local tile = New("Frame", { Name = "Tile", Position = UDim2.fromOffset(tx, 0), Size = UDim2.fromOffset(TILE, TILE), BackgroundColor3 = WHITE, ZIndex = 1, Parent = cell, [New.Children] = { New.Corner(18), New.Stroke() } })
	New.Image({ Name = "Icon", Key = "ui/status/gem", Fallback = T.PanelLight, FallbackText = "?", Position = UDim2.fromOffset(13, 5), Size = UDim2.fromOffset(54, 54), ZIndex = 3, Parent = tile })
	rarityCorner(TILE, 18, 26, 2).Parent = tile
	New("TextLabel", {
		Name = "Count",
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -7, 0, TILE - 22),
		Size = UDim2.fromOffset(TILE - 10, 18),
		BackgroundTransparency = 1,
		Text = "+20",
		TextColor3 = T.Text,
		FontFace = T.Font,
		TextSize = New.FigmaSize(T.Font, 14),
		TextXAlignment = Enum.TextXAlignment.Right,
		ZIndex = 4,
		Parent = tile,
	})
	New("Frame", { Name = "Ring", Position = UDim2.fromOffset(tx, 0), Size = UDim2.fromOffset(TILE, TILE), BackgroundTransparency = 1, Visible = false, ZIndex = 5, Parent = cell, [New.Children] = { New.Corner(18), New("UIStroke", { Color = T.Accent, Thickness = 3 }) } })
	New("TextLabel", {
		Name = "Label",
		Position = UDim2.fromOffset(0, TILE + 3),
		Size = UDim2.fromOffset(CELL_W, 18),
		BackgroundTransparency = 1,
		Text = "10 pulls",
		TextColor3 = T.SubText,
		FontFace = T.Font,
		TextSize = New.FigmaSize(T.Font, 14),
		Parent = cell,
	})
	local check = New("Frame", { Name = "Check", Position = UDim2.fromOffset(tx + TILE - 18, -6), Size = UDim2.fromOffset(24, 24), BackgroundColor3 = T.Good, Visible = false, ZIndex = 6, Parent = cell, [New.Children] = { New.Pill(), New("UIStroke", { Color = WHITE, Thickness = 2 }) } })
	New.Image({ Name = "Tick", Key = "icon_check", Fallback = T.Good, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(14, 14), ZIndex = 6, Parent = check })
	local lock = New("Frame", { Name = "Lock", Position = UDim2.fromOffset(tx + TILE - 16, -6), Size = UDim2.fromOffset(22, 22), BackgroundColor3 = WHITE, Visible = false, ZIndex = 6, Parent = cell, [New.Children] = { New.Pill(), New.Stroke() } })
	New.Image({ Name = "Icon", Key = "icon_lock", Fallback = T.SubText, Tint = T.SubText, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(12, 12), ZIndex = 6, Parent = lock })
	New("TextButton", {
		Name = "Claim",
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.fromOffset(CELL_W / 2, -12),
		Size = UDim2.fromOffset(64, 24),
		BackgroundColor3 = T.Accent,
		Text = "CLAIM",
		TextColor3 = WHITE,
		FontFace = T.Font,
		TextSize = New.FigmaSize(T.Font, 13),
		Visible = false,
		ZIndex = 7,
		Parent = cell,
		[New.Children] = { New.Pill(), New("UIStroke", { Color = T.AccentLip, Thickness = 2, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }) },
	})
	return cell :: Frame
end

-- info: { Icon, IconColor?, CornerColor, Count (text), Pulls (number), State = "claimed"|"claimable"|"locked", LabelColor? }
function Screen.SetMilestoneCell(cell: any, info: { [string]: any })
	local state = info.State or "locked"
	local tile = cell.Tile
	New.SetImageKey(tile.Icon, info.Icon or "ui/status/gem", info.IconColor)
	tile.Corner.BackgroundColor3 = info.CornerColor or R.Common
	tile.Count.Text = info.Count or ""
	tile.BackgroundColor3 = if state == "claimed" then T.TintMint else WHITE
	cell.Ring.Visible = state == "claimable"
	cell.Check.Visible = state == "claimed"
	cell.Lock.Visible = state == "locked"
	cell.Claim.Visible = state == "claimable"
	cell.Label.Text = if state == "claimed" then "Claimed" else `{info.Pulls} pulls`
	cell.Label.TextColor3 = if state == "claimed" then T.GoodLip elseif state == "claimable" then T.AccentLip else (info.LabelColor or T.SubText)
	Components.Fade(tile, if state == "locked" then 0.6 else 1)
end

-- x10 result cell (Figma G6): white r20 card 120x118, Orb 72, Rarity tag, NEW! pill (top-right), Glow ring on the best.
local function resultCell(): Frame
	local c = New("Frame", {
		Name = "ResultCell",
		Size = UDim2.fromOffset(120, 118),
		BackgroundColor3 = WHITE,
		[New.Children] = { New.Corner(20), New.Stroke(), New("UIStroke", { Name = "Glow", Color = R.Legendary, Thickness = 3, Enabled = false, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }) },
	})
	New.Image({ Name = "Orb", Key = "auras/SparklingDew", Fallback = T.Gem, Position = UDim2.fromOffset(24, 10), Size = UDim2.fromOffset(72, 72), Parent = c })
	local r = smallPill("Rarity", "COMMON", R.Common, 20)
	r.AnchorPoint = Vector2.new(0.5, 0)
	r.Position = UDim2.fromOffset(60, 88)
	r.Parent = c
	local n = smallPill("NewBadge", "NEW!", T.Accent, 20)
	n.Position = UDim2.fromOffset(66, -8)
	n.Visible = false
	n.ZIndex = 2
	n.Parent = c
	return c :: Frame
end

-- info: { Orb, Rarity, RarityColor, New, Best }
function Screen.SetResultCell(c: any, info: { [string]: any })
	New.SetImageKey(c.Orb, info.Orb or "auras/UnknownAura", info.RarityColor)
	c.Rarity.Text = string.upper(info.Rarity or "")
	c.Rarity.BackgroundColor3 = info.RarityColor or R.Common
	c.NewBadge.Visible = info.New == true
	c.Glow.Enabled = info.Best == true
	c.Glow.Color = info.RarityColor or R.Common
end


-- Full-window shield absorbs input behind the popup.
local function inputShield(name: string, w: Frame): TextButton
	return New("TextButton", {
		Name = name,
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Text = "",
		AutoButtonColor = false,
		Visible = false,
		ZIndex = 20,
		Parent = w,
	}) :: TextButton
end

local function overlayPanel(d: Instance, w: number, h: number): TextButton
	return New("TextButton", { -- a button so clicks on the panel don't reach the shield
		Name = "Panel",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(w, h),
		BackgroundColor3 = T.Panel,
		Text = "",
		AutoButtonColor = false,
		ZIndex = 21,
		Parent = d,
		[New.Children] = { New.Corner(28), New.Stroke() },
	}) :: TextButton
end

local MS_SAMPLE = {
	{ 10, "ui/status/gem", "+20", "Common", "claimed" },
	{ 30, "ui/status/gem", "+50", "Uncommon", "claimable" },
	{ 50, "equipment/Shrimp", "x10", "Rare", "locked" },
	{ 100, "ui/status/treasure_chest", "x2", "Epic", "locked" },
	{ 200, "ui/status/gem", "+150", "Epic", "locked" },
	{ 400, "auras/AbyssalShadow", "x1", "Legendary", "locked" },
}

local function milestonesPopup(w: Frame, cellTpl: Frame)
	local d = inputShield("MilestonesPopup", w)
	local PW, PH = 460, 372
	local p = overlayPanel(d, PW, PH)
	local head = New("Frame", { Name = "Head", Position = UDim2.fromOffset(20, 16), Size = UDim2.fromOffset(PW - 40, 44), BackgroundTransparency = 1, ZIndex = 21, Parent = p })
	New.Title({ Name = "Title", Size = UDim2.fromOffset(260, 24), Text = "Pull milestones", TextXAlignment = Enum.TextXAlignment.Left, TextSize = 20, ZIndex = 21, Parent = head })
	New.Text({ Name = "Hint", Position = UDim2.fromOffset(0, 24), Size = UDim2.fromOffset(260, 16), Text = "REWARDS AT TOTAL PULLS", FontFace = T.FontBadge, TextColor3 = T.SubText, TextXAlignment = Enum.TextXAlignment.Left, TextSize = 12, ZIndex = 21, Parent = head })
	New.Button({ Name = "Close", AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -16, 0, 14), Size = UDim2.fromOffset(52, 44), Text = "X", BackgroundColor3 = T.Bad, TextSize = 18, ZIndex = 21, Parent = p })
	local grid = New("Frame", {
		Name = "Grid",
		Position = UDim2.fromOffset(20, 78),
		Size = UDim2.fromOffset(PW - 40, 2 * CELL_H + 12),
		BackgroundTransparency = 1,
		ZIndex = 21,
		Parent = p,
		[New.Children] = { New("UIGridLayout", { CellSize = UDim2.fromOffset(CELL_W, CELL_H), CellPadding = UDim2.fromOffset(24, 14), FillDirectionMaxCells = 3, HorizontalAlignment = Enum.HorizontalAlignment.Center, SortOrder = Enum.SortOrder.LayoutOrder }) },
	})
	for i, s in MS_SAMPLE do
		local c = cellTpl:Clone()
		c.Name = "M" .. s[1]
		c.Visible = true
		c.LayoutOrder = i
		c.Parent = grid
		Screen.SetMilestoneCell(c, { Pulls = s[1], Icon = s[2], Count = s[3], CornerColor = R[s[4]], State = s[5], LabelColor = if s[4] == "Legendary" then T.GoldLip else nil })
	end
	local prog = New("Frame", { Name = "Progress", Position = UDim2.fromOffset(20, PH - 20 - 40), Size = UDim2.fromOffset(PW - 40, 40), BackgroundTransparency = 1, ZIndex = 21, Parent = p })
	New.Text({ Name = "Label", Size = UDim2.fromOffset(200, 20), Text = "Banner pulls", TextColor3 = T.SubText, TextXAlignment = Enum.TextXAlignment.Left, TextSize = 14, ZIndex = 21, Parent = prog })
	New.Title({ Name = "Value", AnchorPoint = Vector2.new(1, 0), Position = UDim2.fromScale(1, 0), Size = UDim2.fromOffset(200, 20), Text = "37 / 400 pulls", TextXAlignment = Enum.TextXAlignment.Right, TextSize = 16, ZIndex = 21, Parent = prog })
	local bar = New("Frame", { Name = "Bar", Position = UDim2.fromOffset(0, 26), Size = UDim2.new(1, 0, 0, 14), BackgroundColor3 = T.Track, ClipsDescendants = true, ZIndex = 21, Parent = prog, [New.Children] = { New.Pill() } })
	New("Frame", { Name = "Fill", Size = UDim2.fromScale(37 / 400, 1), BackgroundColor3 = WHITE, ZIndex = 21, Parent = bar, [New.Children] = { New.Pill(), New("UIGradient", { Color = ColorSequence.new(T.Gem, T.GemLip) }) } })
end

local function summary(w: Frame)
	local d = inputShield("Summary", w)
	local PW, PH = 760, 440
	local p = overlayPanel(d, PW, PH)
	New.Title({ Name = "Title", Position = UDim2.fromOffset(24, 22), Size = UDim2.fromOffset(300, 32), Text = "x10 Results", TextXAlignment = Enum.TextXAlignment.Left, TextSize = 26, ZIndex = 21, Parent = p })
	New.Text({ Name = "Best", AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -24, 0, 26), Size = UDim2.fromOffset(400, 26), Text = "Best: Abyssal Shadow (Legendary)", RichText = true, TextXAlignment = Enum.TextXAlignment.Right, TextSize = 16, ZIndex = 21, Parent = p })
	New("Frame", {
		Name = "Grid",
		Position = UDim2.fromOffset(24, 76),
		Size = UDim2.fromOffset(PW - 48, 2 * 118 + 14),
		BackgroundTransparency = 1,
		ZIndex = 21,
		Parent = p,
		[New.Children] = { New("UIGridLayout", { CellSize = UDim2.fromOffset(120, 118), CellPadding = UDim2.fromOffset(12, 14), FillDirectionMaxCells = 5, HorizontalAlignment = Enum.HorizontalAlignment.Center, SortOrder = Enum.SortOrder.LayoutOrder }) },
	})
	local buttons = New("Frame", { Name = "Buttons", Position = UDim2.fromOffset(24, PH - 24 - 57), Size = UDim2.fromOffset(PW - 48, 57), BackgroundTransparency = 1, ZIndex = 21, Parent = p, [New.Children] = { hList(10, Enum.HorizontalAlignment.Center) } })
	New.Button({ Name = "EquipBest", Size = UDim2.fromOffset(200, 57), Text = "EQUIP BEST", BackgroundColor3 = T.Accent, TextSize = 20, LayoutOrder = 1, ZIndex = 21, Parent = buttons })
	New.Button({ Name = "Again", Size = UDim2.fromOffset(220, 57), Text = "ROLL x10 AGAIN", BackgroundColor3 = T.Gold, TextSize = 20, LayoutOrder = 2, ZIndex = 21, Parent = buttons })
	New.Button({ Name = "Close", Size = UDim2.fromOffset(140, 57), Text = "CLOSE", BackgroundColor3 = T.PanelLight, TextSize = 20, LayoutOrder = 3, ZIndex = 21, Parent = buttons })
end


-- Concept D layout ---------------------------------------------------------------------------------

local CANVAS = Vector2.new(1280, 720)
local INK = Color3.fromRGB(61, 75, 92) -- Figma #3D4B5C (= T.Text)
local PLUM = Color3.fromRGB(74, 58, 122) -- Figma #4A3A7A (info card title)
local LILAC = Color3.fromRGB(183, 156, 242) -- #B79CF2
local VIOLET = Color3.fromRGB(140, 111, 214) -- #8C6FD6
local NAVY = Color3.fromRGB(14, 22, 48) -- #0E1630 (dark glass)
local NAVY2 = Color3.fromRGB(27, 34, 51) -- #1B2233 (name plate)
local CARD_END = Color3.fromRGB(27, 36, 64) -- #1B2440 (banner card gradient end)
local SAND_LINE = Color3.fromRGB(230, 220, 203) -- #E6DCCB

Screen.Canvas = CANVAS
Screen.HeroArt = { -- auras with a big illustration in assets/art/auras_Art (a different set from the round orbs)
	AbyssalShadow = true,
	CelestialLeviathan = true,
	DragonEmperor = true,
	LotusNaga = true,
	NebulaKoi = true,
	SerpentOfTheVoid = true,
}

local function abs(name: string, x: number, y: number, w: number, h: number, parent: Instance, props: { [string]: any }?): Frame
	local f = New("Frame", { Name = name, Position = UDim2.fromOffset(x, y), Size = UDim2.fromOffset(w, h), BackgroundTransparency = 1, Parent = parent })
	local any: any = f
	for k, v in (props or {}) :: { [string]: any } do
		any[k] = v
	end
	return f :: Frame
end

local function hGrad(a: Color3, b: Color3): UIGradient
	return New("UIGradient", { Color = ColorSequence.new(a, b) }) :: UIGradient
end

local function label(name: string, text: string, font: Font, size: number, color: Color3, props: { [string]: any }?): TextLabel
	local l = New("TextLabel", {
		Name = name,
		Size = UDim2.fromOffset(0, size + 6),
		AutomaticSize = Enum.AutomaticSize.X,
		BackgroundTransparency = 1,
		Text = text,
		TextColor3 = color,
		FontFace = font,
		TextSize = New.FigmaSize(font, size),
		TextXAlignment = Enum.TextXAlignment.Left,
	})
	local any: any = l
	for k, v in (props or {}) :: { [string]: any } do
		any[k] = v
	end
	return l :: TextLabel
end

local function outline(l: TextLabel, color: Color3?, thickness: number?)
	New("UIStroke", { Color = color or INK, Thickness = thickness or 2, ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual, Parent = l })
end

local function stars(name: string, size: number, gap: number, n: number, parent: Instance, order: number?): Frame
	local row = New("Frame", {
		Name = name,
		Size = UDim2.fromOffset(n * size + (n - 1) * gap, size),
		BackgroundTransparency = 1,
		LayoutOrder = order or 0,
		Parent = parent,
		[New.Children] = { hList(gap) },
	})
	for i = 1, n do
		local s = New.Image({ Name = "S" .. i, Key = "icon_star", Fallback = T.Gold, Tint = T.Gold, Size = UDim2.fromOffset(size, size), LayoutOrder = i, Parent = row })
		s.Fallback.BackgroundTransparency = 1
	end
	return row :: Frame
end

-- pill button on the light floor (Figma "Btn Shop / Rates / History"): white 90%, sand stroke, icon 20 + label
local function smallButton(name: string, key: string, text: string, order: number, parent: Instance): TextButton
	local b = New("TextButton", {
		Name = name,
		Size = UDim2.fromOffset(0, 41),
		AutomaticSize = Enum.AutomaticSize.X,
		BackgroundColor3 = WHITE,
		BackgroundTransparency = 0.1,
		Text = "",
		AutoButtonColor = true,
		LayoutOrder = order,
		Parent = parent,
		[New.Children] = {
			New.Pill(),
			New("UIStroke", { Color = SAND_LINE, Thickness = 1.5, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }),
			New("UIPadding", { PaddingLeft = UDim.new(0, 14), PaddingRight = UDim.new(0, 16) }),
			hList(6),
		},
	})
	New.Image({ Name = "Icon", Key = key, Fallback = T.PanelLight, Size = UDim2.fromOffset(20, 20), LayoutOrder = 1, Parent = b })
	label("Label", text, T.FontBody, 14, INK, { LayoutOrder = 2 }).Parent = b
	return b :: TextButton
end

-- currency chip on the top bar (dark glass, no "+": tapping it opens Top Up)
local function chip(name: string, key: string, value: string, order: number, parent: Instance): TextButton
	local c = New("TextButton", {
		Name = name,
		Size = UDim2.fromOffset(0, 39),
		AutomaticSize = Enum.AutomaticSize.X,
		BackgroundColor3 = NAVY,
		BackgroundTransparency = 0.45,
		Text = "",
		AutoButtonColor = true,
		LayoutOrder = order,
		Parent = parent,
		[New.Children] = {
			New.Pill(),
			New("UIStroke", { Color = WHITE, Transparency = 0.75, Thickness = 1.5, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }),
			New("UIPadding", { PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 18) }),
			hList(8),
		},
	})
	New.Image({ Name = "Icon", Key = key, Fallback = T.Gem, Size = UDim2.fromOffset(26, 26), LayoutOrder = 1, Parent = c })
	label("Value", value, T.Font, 17, WHITE, { LayoutOrder = 2 }).Parent = c
	return c :: TextButton
end

-- Banner card (Figma "Banner Neon Tide"): 232x92 r18, colour -> navy gradient, white stroke (3px selected),
-- Orb 110 peeking from the right edge, Kind pill, Name, Time.
local function bannerCard(): TextButton
	local c = New("TextButton", {
		Name = "BannerCard",
		Size = UDim2.fromOffset(232, 92),
		BackgroundColor3 = WHITE,
		Text = "",
		AutoButtonColor = false,
		ClipsDescendants = true,
		[New.Children] = {
			New.Corner(18),
			hGrad(T.Gem, CARD_END),
			New("UIStroke", { Name = "Ring", Color = WHITE, Thickness = 3, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }),
		},
	})
	local orb = New.Image({ Name = "Orb", Key = "auras/AbyssalShadow", Fallback = T.Gem, Position = UDim2.fromOffset(128, -8), Size = UDim2.fromOffset(110, 110), Parent = c })
	orb.Fallback.BackgroundTransparency = 1
	local kind = New("TextLabel", {
		Name = "Kind",
		Position = UDim2.fromOffset(12, 12),
		Size = UDim2.fromOffset(0, 23),
		AutomaticSize = Enum.AutomaticSize.X,
		BackgroundColor3 = WHITE,
		BackgroundTransparency = 0.08,
		Text = "EVENT",
		TextColor3 = T.Gem,
		FontFace = T.FontBadge,
		TextSize = New.FigmaSize(T.FontBadge, 12),
		ZIndex = 2,
		Parent = c,
		[New.Children] = { New.Pill(), New("UIPadding", { PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 12) }) },
	})
	local _ = kind
	local n = label("BannerName", "Neon Tide", T.Font, 20, WHITE, { Position = UDim2.fromOffset(12, 40), ZIndex = 2 })
	outline(n)
	n.Parent = c
	label("Time", "11d left", T.FontBadge, 12, WHITE, { Position = UDim2.fromOffset(12, 66), ZIndex = 2 }).Parent = c
	return c :: TextButton
end

-- info: { Name, Kind ("EVENT" | "STANDARD"), Time, Orb, Color, Selected }
function Screen.SetBannerCard(c: any, info: { [string]: any })
	local col = info.Color or T.Gem
	c.UIGradient.Color = ColorSequence.new(col, CARD_END)
	c.Ring.Thickness = if info.Selected then 3 else 1.5
	c.Ring.Transparency = if info.Selected then 0 else 0.75
	c.Kind.Text = info.Kind or ""
	c.Kind.TextColor3 = col
	c.BannerName.Text = info.Name or ""
	c.Time.Text = info.Time or ""
	New.SetImageKey(c.Orb, info.Orb or "auras/UnknownAura")
	c.Orb.ImageTransparency = if info.Selected then 0 else 0.1
end

local function topBar(cv: Frame)
	local bar = abs("TopBar", 16, 70, 1248, 40, cv)
	local back = New("TextButton", {
		Name = "Back",
		Size = UDim2.fromOffset(56, 40),
		BackgroundColor3 = NAVY,
		BackgroundTransparency = 0.45,
		Text = "<",
		TextColor3 = WHITE,
		FontFace = T.Font,
		TextSize = New.FigmaSize(T.Font, 24),
		AutoButtonColor = true,
		Parent = bar,
		[New.Children] = { New.Corner(14), New("UIStroke", { Color = WHITE, Transparency = 0.7, Thickness = 1.5, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }) },
	})
	local _ = back
	local title = label("Title", "Aura Summon", T.Font, 26, WHITE, { Position = UDim2.fromOffset(68, 4) })
	outline(title)
	title.Parent = bar
	local chips = New("Frame", {
		Name = "Chips",
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.fromScale(1, 0),
		Size = UDim2.fromOffset(0, 40),
		AutomaticSize = Enum.AutomaticSize.X,
		BackgroundTransparency = 1,
		Parent = bar,
		[New.Children] = { hList(12, Enum.HorizontalAlignment.Right) },
	})
	chip("Gems", "ui/status/gem", "1,240", 1, chips)
	chip("StarTokens", "ui/status/star_token", "12", 2, chips)
end

local function rail(cv: Frame, cardTpl: TextButton)
	local r = New("ScrollingFrame", {
		Name = "Rail",
		Position = UDim2.fromOffset(12, 126),
		Size = UDim2.fromOffset(240, 408),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollingDirection = Enum.ScrollingDirection.Y,
		ScrollBarThickness = 0,
		Parent = cv,
		[New.Children] = {
			New.Padding(4),
			New("UIListLayout", { Padding = UDim.new(0, 12), SortOrder = Enum.SortOrder.LayoutOrder }),
		},
	})
	for i, s in { { "Neon Tide", "EVENT", "11d left", "auras/AbyssalShadow", T.Gem, true }, { "Aura Altar", "STANDARD", "Always", "auras/CelestialLeviathan", T.SkyLip } } do
		local c = cardTpl:Clone()
		c.Name = "Sample" .. i
		c.Visible = true
		c.LayoutOrder = i
		c.Parent = r
		Screen.SetBannerCard(c, { Name = s[1], Kind = s[2], Time = s[3], Orb = s[4], Color = s[5], Selected = s[6] })
	end
end

local function infoCard(cv: Frame)
	local card = abs("InfoCard", 264, 130, 450, 314, cv, { BackgroundColor3 = WHITE, BackgroundTransparency = 0.14 })
	New.Corner(20).Parent = card
	New("UIStroke", { Color = WHITE, Thickness = 2, ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Parent = card })
	local ribbon = New("Frame", {
		Name = "Ribbon",
		Position = UDim2.fromOffset(12, 7),
		Size = UDim2.fromOffset(0, 25),
		AutomaticSize = Enum.AutomaticSize.X,
		BackgroundColor3 = WHITE,
		Parent = card,
		[New.Children] = { New.Pill(), hGrad(LILAC, VIOLET), New("UIPadding", { PaddingLeft = UDim.new(0, 14), PaddingRight = UDim.new(0, 14) }) },
	})
	label("Label", "Event Banner  |  Rate Up", T.FontBadge, 12, WHITE, { Size = UDim2.fromOffset(0, 25) }).Parent = ribbon
	label("Title", "Abyssal Shadow Surge", T.Font, 30, PLUM, { Position = UDim2.fromOffset(12, 40), Size = UDim2.fromOffset(426, 40), AutomaticSize = Enum.AutomaticSize.None, TextTruncate = Enum.TextTruncate.AtEnd }).Parent = card
	local st = stars("Stars", 18, 2, 5, card)
	st.Position = UDim2.fromOffset(12, 88)
	local timer = abs("Timer", 12, 113, 300, 20, card)
	New("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 6), VerticalAlignment = Enum.VerticalAlignment.Center, Parent = timer })
	local ti = New.Image({ Name = "Icon", Key = "icon_timer", Fallback = VIOLET, Tint = VIOLET, Size = UDim2.fromOffset(16, 16), LayoutOrder = 1, Parent = timer })
	ti.Fallback.BackgroundTransparency = 1
	label("Text", "11d 6h left", T.FontBody, 14, VIOLET, { LayoutOrder = 2 }).Parent = timer
	New.Text({
		Name = "Desc",
		Position = UDim2.fromOffset(12, 140),
		Size = UDim2.fromOffset(410, 40),
		Text = "Abyssal Shadow and Neon Wave are 2x more likely. Every x10 guarantees a Rare or better.",
		TextColor3 = INK,
		TextSize = 14,
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Top,
		Parent = card,
	})
	local feat = abs("Featured", 12, 187, 426, 72, card)
	New("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 10), SortOrder = Enum.SortOrder.LayoutOrder, Parent = feat })
	for i, s in { { "auras/AbyssalShadow", R.Legendary }, { "auras/NeonWave", R.Uncommon } } do
		local f = Components.Make.ItemSlot(72)
		f.LayoutOrder = i
		f.Parent = feat
		Components.SetItemSlot(f, { Icon = s[1], IconColor = s[2], CornerColor = s[2] })
	end
	local note = abs("PityNote", 12, 265, 426, 42, card, { BackgroundColor3 = WHITE, BackgroundTransparency = 0 })
	New.Corner(14).Parent = note
	hGrad(LILAC, VIOLET).Parent = note
	New.Image({ Name = "Icon", Key = "ui/status/star_token", Fallback = T.Gold, Position = UDim2.fromOffset(14, 10), Size = UDim2.fromOffset(22, 22), Parent = note })
	label("Text", "62 more pulls and a Legendary is guaranteed", T.FontBody, 14, WHITE, { Position = UDim2.fromOffset(44, 9), RichText = true }).Parent = note
end

local function bar(parent: Instance, y: number, w: number, frac: number, a: Color3, b: Color3)
	local track = abs("Bar", 12, y, w, 8, parent, { BackgroundColor3 = SAND_LINE, BackgroundTransparency = 0, ClipsDescendants = true })
	New.Pill().Parent = track
	New("Frame", { Name = "Fill", Size = UDim2.fromScale(frac, 1), BackgroundColor3 = WHITE, Parent = track, [New.Children] = { New.Pill(), hGrad(a, b) } })
end

local function e1Box(name: string, x: number, cv: Frame): Frame
	local f = abs(name, x, 456, 219, 52, cv, { BackgroundColor3 = WHITE, BackgroundTransparency = 0.1 })
	New.Corner(16).Parent = f
	New("UIStroke", { Color = SAND_LINE, Thickness = 1.5, ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Parent = f })
	return f
end

-- E1 parts (user: keep them): Mythic pity box, Milestones box, Skip / Auto checkboxes
local function e1Parts(cv: Frame)
	local p = e1Box("PityMythic", 264, cv)
	label("Label", "Mythic guaranteed in", T.FontBadge, 12, T.SubText, { Position = UDim2.fromOffset(12, 9) }).Parent = p
	label("Value", "262 rolls", T.Font, 14, R.Mythic, { AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -12, 0, 8), TextXAlignment = Enum.TextXAlignment.Right }).Parent = p
	bar(p, 33, 195, 38 / 300, R.Legendary, R.Mythic)

	local m = e1Box("Milestones", 495, cv)
	label("Label", "Milestones", T.FontBody, 14, T.SubText, { Position = UDim2.fromOffset(12, 7) }).Parent = m
	label("Value", "37/400", T.Font, 15, VIOLET, { Position = UDim2.fromOffset(92, 6) }).Parent = m
	local view = New("TextButton", {
		Name = "View",
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -12, 0, 6),
		Size = UDim2.fromOffset(46, 22),
		BackgroundColor3 = T.Sky,
		Text = "View",
		TextColor3 = WHITE,
		FontFace = T.FontBadge,
		TextSize = New.FigmaSize(T.FontBadge, 12),
		Parent = m,
		[New.Children] = { New.Pill() },
	})
	New("TextLabel", {
		Name = "Dot",
		Position = UDim2.new(1, -8, 0, -7),
		Size = UDim2.fromOffset(16, 16),
		BackgroundColor3 = T.Bad,
		Text = "1",
		TextColor3 = WHITE,
		FontFace = T.Font,
		TextSize = New.FigmaSize(T.Font, 10),
		ZIndex = 2,
		Parent = view,
		[New.Children] = { New.Pill(), New("UIStroke", { Color = WHITE, Thickness = 1.5 }) },
	})
	bar(m, 35, 195, 37 / 400, LILAC, VIOLET)

	local o = abs("Options", 264, 524, 0, 41, cv, { AutomaticSize = Enum.AutomaticSize.X, BackgroundColor3 = WHITE, BackgroundTransparency = 0.1 })
	New.Corner(10).Parent = o
	New("UIStroke", { Color = SAND_LINE, Thickness = 1.5, ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Parent = o })
	New("UIPadding", { PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 14), PaddingTop = UDim.new(0, 4), Parent = o })
	New("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 12), VerticalAlignment = Enum.VerticalAlignment.Center, SortOrder = Enum.SortOrder.LayoutOrder, Parent = o })
	local skip = checkbox("Skip", "Skip animation", 0, 140)
	skip.LayoutOrder = 1
	skip.Parent = o
	local auto = checkbox("Auto", "Auto-roll until Epic+", 0, 196)
	auto.LayoutOrder = 2
	auto.Parent = o
	for _, b in { skip, auto } do
		b.Label.TextColor3 = INK
		b.Box.Size = UDim2.fromOffset(26, 26)
		b.Box.Position = UDim2.fromOffset(0, 2)
		b.Label.Position = UDim2.fromOffset(34, 0)
	end
end

local function namePlate(cv: Frame)
	local p = New("Frame", {
		Name = "NamePlate",
		Position = UDim2.fromOffset(820, 520),
		Size = UDim2.fromOffset(0, 40),
		AutomaticSize = Enum.AutomaticSize.X,
		BackgroundColor3 = NAVY2,
		BackgroundTransparency = 0.12,
		Parent = cv,
		[New.Children] = { New.Pill(), New("UIPadding", { PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 18) }), hList(10) },
	})
	smallPill("Rarity", "LEGENDARY", R.Legendary, 23, 1).Parent = p
	label("AuraName", "Abyssal Shadow", T.Font, 20, WHITE, { LayoutOrder = 2 }).Parent = p
	stars("Stars", 12, 2, 5, p, 3)
end

-- Roll button (Figma "Btn Roll x1"): flat lip button, Title left, Price pill (lip colour, Gem 26 + value 20) right
local function rollButton(name: string, title: string, face: Color3, lip: Color3, cost: string, x: number, w: number, parent: Instance): TextButton
	local b = New.Button({ Name = name, Position = UDim2.fromOffset(x, 0), Size = UDim2.fromOffset(w, 60), Text = "", BackgroundColor3 = face, Parent = parent })
	label("Title", title, T.Font, 20, WHITE, { AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 18, 0.5, -2), ZIndex = 2 }).Parent = b
	local price = New("Frame", {
		Name = "Price",
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -8, 0.5, -2),
		Size = UDim2.fromOffset(0, 32),
		AutomaticSize = Enum.AutomaticSize.X,
		BackgroundColor3 = lip,
		ZIndex = 2,
		Parent = b,
		[New.Children] = { New.Pill(), New("UIPadding", { PaddingLeft = UDim.new(0, 4), PaddingRight = UDim.new(0, 12) }), hList(4) },
	})
	New.Image({ Name = "Icon", Key = "ui/status/gem", Fallback = T.GemLip, Size = UDim2.fromOffset(26, 26), LayoutOrder = 1, ZIndex = 2, Parent = price })
	label("Value", cost, T.Font, 20, WHITE, { LayoutOrder = 2, ZIndex = 2 }).Parent = price
	return b
end

local function bottom(cv: Frame)
	local sb = abs("SmallButtons", 16, 640, 520, 41, cv)
	hList(10).Parent = sb
	smallButton("Shop", "ui/icons/shop", "Shop", 1, sb)
	smallButton("Rates", "ui/status/xp_star", "Rates", 2, sb)

	local tg = abs("PayToggle", 1076, 580, 180, 37, cv, { BackgroundColor3 = WHITE, BackgroundTransparency = 0.1 })
	New.Pill().Parent = tg
	New("UIStroke", { Color = WHITE, Thickness = 1.5, ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Parent = tg })
	for i, s in { { "Gems", "ui/status/gem" }, { "Tokens", "ui/status/star_token" } } do
		local o = New("TextButton", {
			Name = s[1],
			Position = UDim2.fromOffset(4 + (i - 1) * 86, 4),
			Size = UDim2.fromOffset(86, 29),
			BackgroundColor3 = T.Accent,
			BackgroundTransparency = if i == 1 then 0 else 1,
			Text = "",
			AutoButtonColor = false,
			Parent = tg,
			[New.Children] = { New.Pill(), hList(5, Enum.HorizontalAlignment.Center) },
		})
		New.Image({ Name = "Icon", Key = s[2], Fallback = T.Gem, Size = UDim2.fromOffset(20, 20), LayoutOrder = 1, Parent = o })
		label("Label", s[1], T.Font, 14, if i == 1 then WHITE else INK, { LayoutOrder = 2 }).Parent = o
	end

	local rb = abs("RollBar", 790, 632, 464, 60, cv)
	rollButton("Roll1", "ROLL x1", T.Gem, T.GemLip, "5", 0, 200, rb)
	local r10 = rollButton("Roll10", "ROLL x10", T.Gold, T.GoldLip, "45", 214, 250, rb)
	local g = smallPill("Guarantee", "RARE+", T.Accent, 20)
	g.AnchorPoint = Vector2.new(1, 0)
	g.Position = UDim2.new(1, -2, 0, -10)
	g.ZIndex = 3
	g.Parent = r10
end

local function ratesPopup(w: Frame, rowTpl: Frame)
	local d = inputShield("RatesPopup", w)
	local PW, PH = 520, 520
	local p = overlayPanel(d, PW, PH)
	New.Title({ Name = "Title", Position = UDim2.fromOffset(24, 22), Size = UDim2.fromOffset(300, 28), Text = "Drop rates", TextXAlignment = Enum.TextXAlignment.Left, TextSize = 24, ZIndex = 21, Parent = p })
	New.Text({ Name = "OwnedLabel", Position = UDim2.fromOffset(24, 52), Size = UDim2.fromOffset(300, 16), Text = "REAL CHANCE PER ROLL  |  OWNED", FontFace = T.FontBadge, TextColor3 = T.SubText, TextXAlignment = Enum.TextXAlignment.Left, TextSize = 12, ZIndex = 21, Parent = p })
	New.Button({ Name = "Close", AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -16, 0, 16), Size = UDim2.fromOffset(52, 44), Text = "X", BackgroundColor3 = T.Bad, TextSize = 18, ZIndex = 21, Parent = p })
	local list = New("ScrollingFrame", {
		Name = "List",
		Position = UDim2.fromOffset(20, 80),
		Size = UDim2.fromOffset(PW - 40, PH - 100),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollingDirection = Enum.ScrollingDirection.Y,
		ScrollBarThickness = 4,
		ScrollBarImageColor3 = T.Track,
		ZIndex = 21,
		Parent = p,
		[New.Children] = {
			New("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }),
			-- room for the 2px gold Highlight stroke (drawn outside the row) and the scrollbar
			New("UIPadding", { PaddingTop = UDim.new(0, 4), PaddingBottom = UDim.new(0, 4), PaddingLeft = UDim.new(0, 4), PaddingRight = UDim.new(0, 12) }),
		},
	})
	local row = rowTpl:Clone()
	row.Visible = true
	row.Parent = list
end

function Screen.Build(): ScreenGui
	local gui = New("ScreenGui", {
		Name = "GachaPage",
		ResetOnSpawn = false,
		IgnoreGuiInset = false,
		SafeAreaCompatibility = Enum.SafeAreaCompatibility.None,
		Enabled = false, -- GachaPageController opens it (Events hub OPEN, Auras ROLL AURA, altar prompt)
		DisplayOrder = 16,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	}) :: ScreenGui
	local templates = New("Folder", { Name = "Templates", Parent = gui })
	local rowTpl, cellTpl, resTpl, cardTpl = rateRow(), milestoneCell(), resultCell(), bannerCard()
	for _, t in { rowTpl, cellTpl, resTpl, cardTpl } do
		t.Visible = false
		t.Parent = templates
	end

	local w = New("Frame", { Name = "Window", Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.fromRGB(197, 214, 240), BorderSizePixel = 0, Parent = gui })
	local bg = New.Image({ Name = "Bg", Key = "ui/gacha_bg_celestial", Fallback = Color3.fromRGB(197, 214, 240), Size = UDim2.fromScale(1, 1), ScaleType = Enum.ScaleType.Crop, Parent = w })
	bg.Fallback.BackgroundTransparency = 1
	New("Frame", {
		Name = "Floor",
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.fromScale(0, 1),
		Size = UDim2.fromScale(1, 1 / 6),
		BackgroundColor3 = WHITE,
		BorderSizePixel = 0,
		Parent = w,
		[New.Children] = {
			New("UIGradient", {
				Rotation = 90,
				Color = ColorSequence.new(WHITE, T.TintLilac),
				Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.35, 0.35), NumberSequenceKeypoint.new(1, 0.25) }),
			}),
		},
	})

	local cv = New("Frame", {
		Name = "Canvas",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(CANVAS.X, CANVAS.Y),
		BackgroundTransparency = 1,
		Parent = w,
		[New.Children] = { New("UIScale", { Name = "Scale" }) },
	})
	for i, g in { { 770, 110, 440 }, { 810, 150, 361 }, { 849, 189, 282 } } do
		abs("Glow" .. (i - 1), g[1], g[2], g[3], g[3], cv, { BackgroundColor3 = WHITE, BackgroundTransparency = 0.75 })
		New("UICorner", { CornerRadius = UDim.new(0.5, 0), Parent = cv["Glow" .. (i - 1)] })
	end
	local hero = New.Image({ Name = "Hero", Key = "auras_Art/AbyssalShadow", Fallback = T.Gem, Position = UDim2.fromOffset(760, 90), Size = UDim2.fromOffset(480, 480), Parent = cv })
	hero.Fallback.BackgroundTransparency = 1
	topBar(cv)
	rail(cv, cardTpl :: any)
	infoCard(cv)
	e1Parts(cv)
	namePlate(cv)
	bottom(cv)

	ratesPopup(w, rowTpl)
	milestonesPopup(w, cellTpl)
	summary(w)
	for _, n in { "RatesPopup", "MilestonesPopup", "Summary" } do
		New("UIScale", { Name = "Scale", Parent = w[n].Panel })
	end
	return gui
end

return Screen
