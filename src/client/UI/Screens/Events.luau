--!nonstrict
-- E0 · Events hub (Cozy Lake, look of Figma "E1 · Event — Aura Banner": lilac window gradient, cream
-- cards, pills). The hub is only a LIST OF CARDS built from Config/Events; each card's OPEN runs the
-- event's Action (UI/EventActions/<Kind>). Static layout + one baked sample card per Figma event;
-- Controllers/EventController clears List and clones Templates.Card per visible event.
--   Window      920x540 r32, gradient FBF7EF -> EFE6F8, Track border
--     Header    Icon (ui/icons/events), Title "Events", Right: Gems (CurrencyChip), Close (red X)
--     List      ScrollingFrame + UIGridLayout (2 columns of 430x176 cards, gap 12/16)
--     Hint      "New events every week"
--   Templates   (Folder, hidden) Card
-- Card (430x176) children = API (Screen.SetCard fills them):
--   Art (140px tile: gradient, Rays, Glow, Icon, Banner = wide art covering the tile when the event has one)
--   Tag (pill over the art), Title, Subtitle, Bottom (Timer pill: Icon + Value | Open button)

local New = require(script.Parent.Parent.New)
local Components = require(script.Parent.Components)
local Make = Components.Make
local T = New.Theme

local Screen = { Name = "Events" }

local WINDOW = Vector2.new(920, 540) -- Figma E0 Events Window (docs/figma/events_hub.py)
local PAD = 24
local INNER = WINDOW.X - PAD * 2 -- 872
local CARD = Vector2.new(430, 176)
local GAP_X, GAP_Y = INNER - 2 * CARD.X, 16 -- 12, 16
local LIST_Y = 96
local LIST_H = 2 * CARD.Y + GAP_Y -- 2 rows visible, scrolls when there are more
local ART = 140
local TX = 14 + ART + 14 -- text column x = 168
local TW = CARD.X - TX - 14 -- 248

local WHITE = Color3.new(1, 1, 1)
local CREAM_TOP = Color3.fromRGB(251, 247, 239) -- #FBF7EF
local LILAC_BOTTOM = Color3.fromRGB(239, 230, 248) -- #EFE6F8
local CARD_TOP = Color3.fromRGB(255, 253, 247) -- #FFFDF7
local CARD_BOTTOM = Color3.fromRGB(246, 240, 251) -- #F6F0FB
local ART_TOP = Color3.fromRGB(229, 219, 250) -- #E5DBFA
local ART_BOTTOM = Color3.fromRGB(211, 236, 250) -- #D3ECFA

Screen.TagColors = {
	LIMITED = T.Accent,
	NEW = T.Good,
	SOON = T.SubText,
	STANDARD = T.Gem,
	HOT = T.Bad,
}

local function vGradient(top: Color3, bottom: Color3): UIGradient
	return New("UIGradient", { Rotation = 90, Color = ColorSequence.new(top, bottom) }) :: UIGradient
end

local function pill(name: string, text: string, color: Color3, order: number?): TextLabel
	local b = Make.Badge(text, color)
	b.Name = name
	b.LayoutOrder = order or 0
	return b
end

-- Timer pill (Figma timer_pill): white, Track border, ui/status/auto_timer + coral Fredoka value.
function Screen.TimerPill(iconSize: number, textSize: number, height: number): Frame
	local f = New("Frame", {
		Name = "Timer",
		Size = UDim2.fromOffset(0, height),
		AutomaticSize = Enum.AutomaticSize.X,
		BackgroundColor3 = WHITE,
		[New.Children] = {
			New.Pill(),
			New.Stroke(),
			New("UIPadding", { PaddingLeft = UDim.new(0, 6), PaddingRight = UDim.new(0, 12) }),
			New("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 5), VerticalAlignment = Enum.VerticalAlignment.Center, SortOrder = Enum.SortOrder.LayoutOrder }),
		},
	})
	New.Image({ Name = "Icon", Key = "ui/status/auto_timer", Fallback = T.Accent, Size = UDim2.fromOffset(iconSize, iconSize), LayoutOrder = 1, Parent = f })
	New("TextLabel", {
		Name = "Value",
		Size = UDim2.fromOffset(0, height - 4),
		AutomaticSize = Enum.AutomaticSize.X,
		BackgroundTransparency = 1,
		Text = "13d 05h left",
		TextColor3 = T.AccentLip,
		FontFace = T.Font,
		TextSize = New.FigmaSize(T.Font, textSize),
		LayoutOrder = 2,
		Parent = f,
	})
	return f :: Frame
end

local function card(): Frame
	local c = New("Frame", {
		Name = "Card",
		Size = UDim2.fromOffset(CARD.X, CARD.Y),
		BackgroundColor3 = WHITE,
		[New.Children] = { New.Corner(T.RadiusWindow), New.Stroke(), vGradient(CARD_TOP, CARD_BOTTOM) },
	})
	-- art tile (Figma art(): 140x140 r18, per-event gradient, 12 rays 16%, glow 96 35%, image ~110)
	local art = New("CanvasGroup", { -- CanvasGroup: rays clip to the rounded corners
		Name = "Art",
		Position = UDim2.fromOffset(14, (CARD.Y - ART) / 2),
		Size = UDim2.fromOffset(ART, ART),
		BackgroundColor3 = WHITE,
		Parent = c,
		[New.Children] = { New.Corner(18), New.Stroke(), vGradient(ART_TOP, ART_BOTTOM) },
	})
	local rays = New.Image({
		Name = "Rays",
		Key = "fx_rays",
		Fallback = T.Gem,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(320, 320),
		Tint = Color3.fromRGB(242, 169, 59),
		ImageTransparency = 0.84,
		ZIndex = 1,
		Parent = art,
	})
	rays.Fallback.BackgroundTransparency = 1
	New("Frame", {
		Name = "Glow",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(96, 96),
		BackgroundColor3 = Color3.fromRGB(242, 169, 59),
		BackgroundTransparency = 0.65,
		ZIndex = 2,
		Parent = art,
		[New.Children] = { New.Pill() },
	})
	New.Image({
		Name = "Icon",
		Key = "auras/AbyssalShadow",
		Fallback = T.Gem,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(112, 112),
		ZIndex = 3,
		Parent = art,
	})
	New.Image({
		Name = "Banner",
		Key = "ui/icons/events",
		Fallback = T.Gem,
		Size = UDim2.fromScale(1, 1),
		ScaleType = Enum.ScaleType.Crop,
		Visible = false,
		ZIndex = 3,
		Parent = art,
	})
	-- tag pill over the art's top-left corner
	local tag = pill("Tag", "LIMITED", T.Accent)
	tag.Position = UDim2.fromOffset(22, (CARD.Y - ART) / 2 + 8)
	tag.Size = UDim2.fromOffset(0, 20)
	tag.ZIndex = 2
	tag.Parent = c

	New.Title({
		Name = "Title",
		Position = UDim2.fromOffset(TX, 20),
		Size = UDim2.fromOffset(TW, 28),
		Text = "Neon Tide Banner",
		TextXAlignment = Enum.TextXAlignment.Left,
		TextSize = 22,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Parent = c,
	})
	New.Text({
		Name = "Subtitle",
		Position = UDim2.fromOffset(TX, 52),
		Size = UDim2.fromOffset(TW, 40),
		Text = "Neon Wave x2\nFeatured: Abyssal Shadow",
		TextColor3 = T.SubText,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Top,
		TextWrapped = true,
		LineHeight = 1.1,
		TextSize = 14,
		Parent = c,
	})
	local bottom = New("Frame", {
		Name = "Bottom",
		Position = UDim2.fromOffset(TX, CARD.Y - 14 - 56),
		Size = UDim2.fromOffset(TW, 56),
		BackgroundTransparency = 1,
		Parent = c,
	})
	local timer = Screen.TimerPill(18, 14, 32)
	timer.AnchorPoint = Vector2.new(0, 0.5)
	timer.Position = UDim2.fromScale(0, 0.5)
	timer.Parent = bottom
	New.Button({
		Name = "Open",
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.fromScale(1, 0.5),
		Size = UDim2.fromOffset(116, 57),
		Text = "OPEN",
		BackgroundColor3 = T.Accent,
		TextSize = 22,
		Parent = bottom,
	})
	return c :: Frame
end

-- Fill a Card (sample bake + EventController). info:
--   Title, Subtitle? (" | " becomes a line break, like Figma), Icon (UIAssets key), IconSize?, Banner? (wide art key),
--   Tag?, TagColor?, Timer? (text; nil = hidden), Disabled?, OpenText? ("OPEN"), ArtTop?/ArtBottom? (tile gradient),
--   ArtColor? (rays/glow tint)
function Screen.SetCard(c: any, info: { [string]: any })
	c.Title.Text = info.Title or ""
	local sub = if info.Subtitle then (string.gsub(info.Subtitle, "%s*|%s*", "\n")) else ""
	c.Subtitle.Text = sub
	c.Subtitle.Visible = info.Subtitle ~= nil
	local art = c.Art
	local hasBanner = info.Banner ~= nil
	art.Banner.Visible = hasBanner
	art.Icon.Visible = not hasBanner
	art.Rays.Visible = not hasBanner
	art.Glow.Visible = not hasBanner
	if hasBanner then
		New.SetImageKey(art.Banner, info.Banner)
	end
	New.SetImageKey(art.Icon, info.Icon or "ui/icons/events", T.Gem, string.sub(info.Title or "?", 1, 1))
	local size = info.IconSize or 110
	art.Icon.Size = UDim2.fromOffset(size, size)
	local grad = art:FindFirstChildOfClass("UIGradient")
	if grad then
		grad.Color = ColorSequence.new(info.ArtTop or ART_TOP, info.ArtBottom or ART_BOTTOM)
	end
	local tint = info.ArtColor or T.Gem
	art.Rays.ImageColor3 = tint
	art.Glow.BackgroundColor3 = tint
	local tag = c.Tag
	tag.Visible = info.Tag ~= nil
	if info.Tag then
		tag.Text = info.Tag
		tag.BackgroundColor3 = info.TagColor or Screen.TagColors[info.Tag] or T.Sky
	end
	local bottom = c.Bottom
	bottom.Timer.Visible = info.Timer ~= nil
	bottom.Timer.Value.Text = info.Timer or ""
	local open = bottom.Open
	open.Text = info.OpenText or (if info.Disabled then (info.Tag or "SOON") else "OPEN")
	if info.Disabled then
		New.SetButtonColor(open, T.PanelLight, T.SubText) -- Figma "Ghost" button
	else
		New.SetButtonColor(open, T.Accent)
	end
	open.AutoButtonColor = not info.Disabled
	open.Active = not info.Disabled
	c:SetAttribute("Disabled", info.Disabled == true)
	Components.Fade(c, if info.Disabled then 0.55 else 1) -- Figma: disabled card opacity 55%
end

-- Figma sample (docs/figma/events_hub.py EVENTS)
local SAMPLE = {
	{ Title = "Neon Tide Banner", Subtitle = "Neon Wave x2 | Featured: Abyssal Shadow", Icon = "auras/AbyssalShadow", IconSize = 118, Tag = "LIMITED", Timer = "13d 05h left",
		ArtTop = Color3.fromRGB(229, 219, 250), ArtBottom = Color3.fromRGB(211, 236, 250), ArtColor = Color3.fromRGB(242, 169, 59) },
	{ Title = "Aura Altar", Subtitle = "Standard aura roll | Mythic guaranteed every 100", Icon = "ui/icons/auras", IconSize = 104,
		ArtTop = Color3.fromRGB(229, 219, 250), ArtBottom = Color3.fromRGB(251, 216, 226), ArtColor = Color3.fromRGB(176, 124, 240) },
	{ Title = "Naga Boss", Subtitle = "Every 30 minutes | Team up to reel it in", Icon = "fish/NagaHatchling", IconSize = 112, Tag = "SOON", Disabled = true,
		ArtTop = Color3.fromRGB(210, 240, 226), ArtBottom = Color3.fromRGB(211, 236, 250), ArtColor = Color3.fromRGB(92, 201, 138) },
	{ Title = "Daily Login", Subtitle = "Gems and bait every day", Icon = "ui/icons/quests", IconSize = 100, Tag = "SOON", Disabled = true,
		ArtTop = Color3.fromRGB(251, 234, 184), ArtBottom = Color3.fromRGB(255, 220, 207), ArtColor = T.Gold },
}

local function header(w: Frame)
	local h = New("Frame", { Name = "Header", Position = UDim2.fromOffset(PAD, 20), Size = UDim2.fromOffset(INNER, 57), BackgroundTransparency = 1, Parent = w })
	local title = New("Frame", {
		Name = "TitleRow",
		Size = UDim2.fromOffset(400, 57),
		BackgroundTransparency = 1,
		Parent = h,
		[New.Children] = { New("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 10), VerticalAlignment = Enum.VerticalAlignment.Center, SortOrder = Enum.SortOrder.LayoutOrder }) },
	})
	New.Image({ Name = "Icon", Key = "ui/icons/events", Fallback = T.Accent, Size = UDim2.fromOffset(44, 44), LayoutOrder = 1, Parent = title })
	New("TextLabel", {
		Name = "Title",
		Size = UDim2.fromOffset(0, 46),
		AutomaticSize = Enum.AutomaticSize.X,
		BackgroundTransparency = 1,
		Text = "Events",
		TextColor3 = T.Text,
		FontFace = T.Font,
		TextSize = New.FigmaSize(T.Font, 40),
		LayoutOrder = 2,
		Parent = title,
	})
	local right = New("Frame", {
		Name = "Right",
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.fromScale(1, 0),
		Size = UDim2.fromOffset(0, 57),
		AutomaticSize = Enum.AutomaticSize.X,
		BackgroundTransparency = 1,
		Parent = h,
		[New.Children] = { New("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 10), VerticalAlignment = Enum.VerticalAlignment.Center, HorizontalAlignment = Enum.HorizontalAlignment.Right, SortOrder = Enum.SortOrder.LayoutOrder }) },
	})
	local gems = Make.CurrencyChip("ui/status/gem", T.Gem)
	gems.Name = "Gems"
	gems.LayoutOrder = 1
	gems.Value.Text = "320"
	gems.Parent = right
	New.Button({ Name = "Close", Size = UDim2.fromOffset(73, 57), Text = "X", BackgroundColor3 = T.Bad, TextSize = 22, LayoutOrder = 2, Parent = right })
end

-- Lilac window (Figma Events Window): white panel + vertical gradient (also on the 9-slice shadow,
-- which draws the panel once the shadow PNG is uploaded).
function Screen.Window(parent: Instance, name: string, size: Vector2): Frame
	local w = New.Panel({
		Name = name,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(size.X, size.Y),
		BackgroundColor3 = WHITE,
		Radius = T.RadiusWindow,
		Parent = parent,
		[New.Children] = { vGradient(CREAM_TOP, LILAC_BOTTOM) },
	})
	local shadow = New.Shadow(w, "slice_shadow_window")
	vGradient(CREAM_TOP, LILAC_BOTTOM).Parent = shadow
	return w
end

function Screen.Build(): ScreenGui
	local gui = New("ScreenGui", {
		Name = "Events",
		ResetOnSpawn = false,
		IgnoreGuiInset = false,
		Enabled = false, -- EventController opens it (HUD.EventsRequested / Main Menu Events tile)
		DisplayOrder = 14,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	}) :: ScreenGui
	local w = Screen.Window(gui, "Window", WINDOW)
	header(w)
	local list = New("ScrollingFrame", {
		Name = "List",
		Position = UDim2.fromOffset(PAD - 4, LIST_Y - 4), -- 4px inset: card strokes draw outside the cards
		Size = UDim2.fromOffset(INNER + 12, LIST_H + 8),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollingDirection = Enum.ScrollingDirection.Y,
		ScrollBarThickness = 4,
		ScrollBarImageColor3 = T.Track,
		Parent = w,
		[New.Children] = {
			New("UIPadding", { PaddingTop = UDim.new(0, 4), PaddingBottom = UDim.new(0, 4), PaddingLeft = UDim.new(0, 4), PaddingRight = UDim.new(0, 4) }),
			New("UIGridLayout", { CellSize = UDim2.fromOffset(CARD.X, CARD.Y), CellPadding = UDim2.fromOffset(GAP_X, GAP_Y), FillDirectionMaxCells = 2, SortOrder = Enum.SortOrder.LayoutOrder }),
		},
	})
	New.Text({
		Name = "Hint",
		Position = UDim2.fromOffset(PAD, LIST_Y + LIST_H + 22),
		Size = UDim2.fromOffset(INNER, 18),
		Text = "New events every week",
		TextColor3 = T.SubText,
		TextSize = 12,
		Parent = w,
	})

	local templates = New("Folder", { Name = "Templates", Parent = gui })
	local tpl = card()
	tpl.Visible = false
	tpl.Parent = templates

	for i, s in SAMPLE do
		local c = tpl:Clone()
		c.Name = "Sample" .. i
		c.Visible = true
		c.LayoutOrder = i
		c.Parent = list
		Screen.SetCard(c, s)
	end
	return gui
end

return Screen
