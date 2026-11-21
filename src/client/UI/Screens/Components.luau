--!nonstrict
-- Reusable UI components ("prefabs"). Two ways they are used:
--   1. Screen builders call Components.Make.<Name>(...) so every screen gets the same piece.
--   2. Baked into StarterGui.Components (disabled ScreenGui, one sample of each). At runtime
--      UI/Components.Clone("<Name>") clones that sample for things made on the fly
--      (notifications, catch cards, badges, depth bands...). Edit a sample in Studio and set
--      the ScreenGui attribute Locked = true to keep your edit -> every runtime copy changes.
-- Rule: a component's child names are its API (scripts find parts by name), so keep them.

local New = require(script.Parent.Parent.New)
local T = New.Theme

local Make = {}

-- Pill badge: TextLabel (Text, BackgroundColor3, TextColor3).
function Make.Badge(text: string?, color: Color3?): TextLabel
	return New("TextLabel", {
		Name = "Badge",
		Size = UDim2.fromOffset(0, 22),
		AutomaticSize = Enum.AutomaticSize.X,
		BackgroundColor3 = color or T.PanelLight,
		Text = text or "BADGE",
		TextColor3 = if color then T.OnAccent else T.Text,
		FontFace = T.FontBadge,
		TextSize = New.FigmaSize(T.FontBadge, 12),
		[New.Children] = { New.Pill(), New("UIPadding", { PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10) }) },
	}) :: TextLabel
end

-- Currency chip (HUD Stats E, Figma "Coins"/"Gems"): Icon (ImageLabel) + Value (TextLabel).
function Make.CurrencyChip(iconKey: string?, fallback: Color3?): Frame
	local chip = New("Frame", {
		Name = "CurrencyChip",
		Size = UDim2.fromOffset(0, 40),
		AutomaticSize = Enum.AutomaticSize.X,
		BackgroundColor3 = T.Panel,
		[New.Children] = {
			New.Pill(),
			New.Stroke(),
			New("UIPadding", { PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 20) }),
			New("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 10), VerticalAlignment = Enum.VerticalAlignment.Center, SortOrder = Enum.SortOrder.LayoutOrder }),
			New.Image({ Name = "Icon", Key = iconKey or "ui/status/coin", Fallback = fallback or T.Gold, Size = UDim2.fromOffset(28, 28), LayoutOrder = 1 }),
		},
	})
	New("TextLabel", {
		Name = "Value",
		Size = UDim2.fromOffset(0, 26),
		AutomaticSize = Enum.AutomaticSize.X,
		BackgroundTransparency = 1,
		Text = "0",
		TextColor3 = T.Text,
		FontFace = T.Font,
		TextSize = New.FigmaSize(T.Font, 20),
		LayoutOrder = 2,
		Parent = chip,
	})
	return chip :: Frame
end

-- Side-menu tile (Figma 01 "Btn Shop"): 80x88 button, Tile (64x64) with Icon, outlined Label below; hover pop is
-- added at runtime by UI/Components.HookTile.
function Make.MenuTile(tileName: string?, iconKey: string?, tint: Color3?): TextButton
	-- Figma 01 "Btn Shop": 64x64 cream tile (r20, Track border) with a 50px icon; the label sits UNDER the
	-- tile as outlined text (white + slate outline, like the HUD Lv./XP). Button stays 80x88 for the menu layout.
	local name: string = tileName or "Shop"
	local b = New("TextButton", {
		Name = "Btn" .. name,
		Size = UDim2.fromOffset(80, 88),
		BackgroundTransparency = 1,
		Text = "",
		AutoButtonColor = false,
		[New.Children] = { New("UIScale", { Name = "Pop" }) },
	}) :: TextButton
	b:SetAttribute("MenuTile", true)
	local tile = New("Frame", {
		Name = "Tile",
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 0),
		Size = UDim2.fromOffset(64, 64),
		BackgroundColor3 = tint or T.Panel,
		Parent = b,
		[New.Children] = { New.Corner(20), New.Stroke(T.Track, 2) },
	})
	New.Image({ Name = "Icon", Key = iconKey or "ui/icons/shop", Fallback = T.Track, FallbackText = string.sub(name, 1, 1), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(50, 50), Parent = tile })
	New("TextLabel", {
		Name = "Label",
		Position = UDim2.fromOffset(0, 66),
		Size = UDim2.fromOffset(80, 20),
		BackgroundTransparency = 1,
		Text = name,
		TextColor3 = Color3.new(1, 1, 1),
		FontFace = T.Font,
		TextSize = New.FigmaSize(T.Font, 14),
		Parent = b,
		[New.Children] = {
			New("UIStroke", { Color = T.Text, Thickness = 2, ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual, LineJoinMode = Enum.LineJoinMode.Round }),
		},
	})
	return b
end

-- Toast at the top centre: TextLabel pill.
function Make.NotifyPill(): TextLabel
	return New("TextLabel", {
		Name = "NotifyPill",
		Size = UDim2.fromOffset(0, 34),
		AutomaticSize = Enum.AutomaticSize.X,
		BackgroundColor3 = T.Panel,
		Text = "Notification",
		TextColor3 = T.Text,
		FontFace = T.FontBody,
		TextSize = 18,
		[New.Children] = {
			New.Pill(),
			New.Stroke(),
			New("UIPadding", { PaddingLeft = UDim.new(0, 16), PaddingRight = UDim.new(0, 16) }),
		},
	}) :: TextLabel
end

-- Catch result card (Figma 04 · Catch Result, node 3492:16817): 400x404, children at Figma positions
-- (no UIListLayout: the 9-slice Shadow child would be laid out as a list item).
--   Tags (Rarity badge, New pill, Mutation icon) / Picture (fish art 356x150) / FishName (Fredoka 40, rarity colour)
--   / Meta badges (kg, mode, PERFECT, HOTSPOT) / Divider / Rewards (Coins + Gems chips) / Breakdown badges (x multipliers)
function Make.CatchCard(): Frame
	local card = New("Frame", {
		Name = "CatchCard",
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 72), -- Figma y 130 minus the 58px top bar
		Size = UDim2.fromOffset(400, 404), -- HUD.ShowCatch drops 29px when the Breakdown row is hidden
		BackgroundColor3 = T.Panel,
		[New.Children] = {
			New.Corner(T.RadiusWindow),
			New.Stroke(),
		},
	})
	local X, W = 24, 352 -- content inset (Figma pad 22 + 2px border) and width
	New.Shadow(card, "slice_shadow_window") -- Figma drop shadow r18 y6 10% (same as the windows, radius 24)

	local function row(name: string, y: number, h: number, gap: number): Frame
		return New("Frame", {
			Name = name,
			Position = UDim2.fromOffset(X, y),
			Size = UDim2.fromOffset(W, h),
			BackgroundTransparency = 1,
			Parent = card,
			[New.Children] = {
				New("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, gap), VerticalAlignment = Enum.VerticalAlignment.Center, SortOrder = Enum.SortOrder.LayoutOrder }),
			},
		}) :: Frame
	end

	local tags = row("Tags", 24, 30, 8)
	local function pill(name: string, text: string, color: Color3, order: number)
		New("TextLabel", {
			Name = name,
			Size = UDim2.fromOffset(0, 20),
			AutomaticSize = Enum.AutomaticSize.X,
			BackgroundColor3 = color,
			Text = text,
			TextColor3 = T.OnAccent,
			FontFace = T.FontBadge,
			TextSize = New.FigmaSize(T.FontBadge, 12),
			LayoutOrder = order,
			Parent = tags,
			[New.Children] = { New.Pill(), New("UIPadding", { PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10) }) },
		})
	end
	local RARE = Color3.fromRGB(90, 169, 240) -- sample only (Rarities.Rare); HUD.ShowCatch sets the real rarity colour
	pill("Rarity", "RARE", RARE, 1)
	pill("New", "NEW!", T.Accent, 2)
	New.Image({ Name = "Mutation", Key = "fish/mut_glowing", Fallback = T.Good, Size = UDim2.fromOffset(30, 30), LayoutOrder = 3, Parent = tags })

	New.Image({ Name = "Picture", Key = "fish/GlowEel", Fallback = T.PanelLight, FallbackText = "?", Position = UDim2.fromOffset(X, 62), Size = UDim2.fromOffset(W, 150), Parent = card })
	local fb = card.Picture:FindFirstChild("Fallback")
	if fb then
		fb.Label.TextColor3 = T.SubText
	end

	New.Title({
		Name = "FishName",
		Position = UDim2.fromOffset(X, 220),
		Size = UDim2.fromOffset(W, 44),
		Text = "Glowing Glow Eel",
		TextColor3 = RARE,
		TextXAlignment = Enum.TextXAlignment.Left,
		MaxTextSize = New.FigmaSize(T.Font, 40), -- scales down for long names
		Parent = card,
	})
	local meta = New.BadgeSlots(4, { Name = "Meta", Position = UDim2.fromOffset(X, 272), Size = UDim2.fromOffset(W, 21), Parent = card })
	New.SetBadges(meta, { { Text = "4.2 kg" }, { Text = "Manual", Color = T.Sky }, { Text = "PERFECT", Color = T.Gold }, { Text = "HOTSPOT", Color = T.Gold } })
	New("Frame", { Name = "Divider", Position = UDim2.fromOffset(X, 301), Size = UDim2.fromOffset(W, 2), BackgroundColor3 = T.Track, BorderSizePixel = 0, Parent = card })

	local rewards = row("Rewards", 311, 40, 10)
	local coins = Make.CurrencyChip("ui/status/coin", T.Gold)
	coins.Name = "Coins"
	coins.LayoutOrder = 1
	coins.Value.Text = "+468"
	coins.Parent = rewards
	local gems = Make.CurrencyChip("ui/status/gem", T.Gem)
	gems.Name = "Gems"
	gems.LayoutOrder = 2
	gems.Value.Text = "+1"
	gems.Parent = rewards

	local breakdown = New.BadgeSlots(3, { Name = "Breakdown", Position = UDim2.fromOffset(X, 359), Size = UDim2.fromOffset(W, 21), Parent = card })
	New.SetBadges(breakdown, {
		{ Text = "Glowing x1.8", Color = Color3.fromRGB(60, 196, 176) },
		{ Text = "Manual x1.5", Color = T.Sky },
		{ Text = "Perfect +0.25", Color = T.Gold },
	})
	return card :: Frame
end

-- Depth zone band for the Cast popup slider: Frame (Position/Size/BackgroundColor3 set by script).
function Make.ZoneBand(): Frame
	return New("Frame", { Name = "ZoneBand", Size = UDim2.fromScale(0.25, 1), BackgroundColor3 = T.Sky, BorderSizePixel = 0 }) :: Frame
end

-- Small pill chip used in the minigame header / tension row: TextLabel.
function Make.Chip(text: string?): TextLabel
	return New("TextLabel", {
		Name = "Chip",
		Size = UDim2.fromOffset(0, 22),
		AutomaticSize = Enum.AutomaticSize.X,
		BackgroundColor3 = T.PanelLight,
		Text = text or "CHIP",
		TextColor3 = T.SubText,
		FontFace = T.FontBody,
		TextSize = 12,
		[New.Children] = { New.Pill(), New("UIPadding", { PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10) }) },
	}) :: TextLabel
end

-- Primary button (Figma "Btn" component, face + 5px lip). Text/colour set by script.
function Make.Button(): TextButton
	return New.Button({ Name = "Button", Size = UDim2.fromOffset(200, 57), Text = "Button", BackgroundColor3 = T.Accent, TextSize = 22 })
end

local COMMON = Color3.fromRGB(154, 165, 177) -- Rarities.Common (sample default; scripts set the real colour)

-- Fill an ItemSlot (Make.ItemSlot / UI/Components.Clone("ItemSlot")) in one call; exported as Screen.SetItemSlot.
--   { Empty = true }  -> sand tile with 3 small bubbles, everything else hidden (slot attribute Empty = true)
--   { Icon = key, IconColor?, IconText? (fallback until the art is uploaded), CornerColor = rarity colour,
--     Count = number, New = bool, Mutation = key?, MutationColor?, Selected = bool,
--     Ring = Color3? (B21: coloured ring without the tick, e.g. Sky = equipped), Locked = bool (B21: dim art + lock) }
local function setItemSlot(slot: any, info: { [string]: any })
	local empty = info.Empty == true
	slot:SetAttribute("Empty", empty)
	slot.Tile.BackgroundColor3 = if empty then T.PanelLight else Color3.new(1, 1, 1)
	slot.Empty.Visible = empty
	slot.Icon.Visible = not empty
	slot.Corner.Visible = not empty
	slot.Count.Visible = not empty and info.Count ~= nil
	if not empty then
		if info.Icon then
			New.SetImageKey(slot.Icon, info.Icon, info.IconColor, info.IconText)
		end
		slot.Corner.BackgroundColor3 = info.CornerColor or COMMON
		slot.Count.Text = `x{info.Count or 1}`
	end
	local mutation = not empty and info.Mutation ~= nil
	slot.Mutation.Visible = mutation
	if mutation then
		New.SetImageKey(slot.Mutation, info.Mutation, info.MutationColor)
	end
	slot.NewBadge.Visible = not empty and info.New == true
	local selected = not empty and info.Selected == true
	local ring = if selected then T.Accent elseif not empty then info.Ring else nil
	slot.SelectedRing.Visible = ring ~= nil
	local stroke = slot.SelectedRing:FindFirstChildOfClass("UIStroke")
	if stroke and ring then
		stroke.Color = ring
	end
	slot.Check.Visible = selected
	-- B21 locked look (not owned). Older baked slots have no Lock child: then only the art dims.
	local locked = not empty and info.Locked == true
	slot.Icon.ImageTransparency = if locked then 0.65 else 0
	local lock = slot:FindFirstChild("Lock")
	if lock then
		lock.Visible = locked
	end
end

-- Inventory item slot (Figma 13 "Item Slot", docs/UI_STYLE.md Option F "Corner Ribbon": white tile, rarity
-- triangle in the top-left corner, no star, always 1:1; 84px in the Inventory window). Spec: item_slot() in
-- docs/figma/cozy_menus_spec.py. Root = transparent TextButton "ItemSlot" (click = select). Children (API):
--   Tile      white rounded square (r19, Track 2px stroke); sand (PanelLight) when the slot is empty
--   Icon      New.Image item art (68/88 of the slot, top-centred)
--   Corner    rarity triangle: a full-size Frame with the tile's UICorner + a hard-edged UIGradient (Rotation 45),
--             drawn behind the art, with only the top-left triangle opaque.
--             Colour = Corner.BackgroundColor3 (rarity colour; baits use Gold).
--   Count     "x23" bottom-right (Fredoka 15/88)
--   Empty     3 sand bubbles of an empty slot (Frame, hidden on a filled slot)
--   SelectedRing coral 3px ring (Frame + UIStroke, hidden; not "Selected" = GuiButton property)  Check    coral tick badge top-right (hidden)
--   NewBadge  coral "NEW" pill above the top-left (hidden)     Mutation  small New.Image bottom-left (hidden)
-- Empty look: Make.ItemSlot(nil, true), or at runtime SetItemSlot(slot, { Empty = true }).
function Make.ItemSlot(size: number?, empty: boolean?): TextButton
	local s: number = size or 84
	local k = s / 88
	local radius = math.round(20 * k)
	local slot = New("TextButton", {
		Name = "ItemSlot",
		Size = UDim2.fromOffset(s, s),
		BackgroundTransparency = 1,
		Text = "",
		AutoButtonColor = false,
	}) :: TextButton
	New("Frame", {
		Name = "Tile",
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color3.new(1, 1, 1),
		ZIndex = 1,
		Parent = slot,
		[New.Children] = { New.Corner(radius), New.Stroke(T.Track, 2) },
	})
	local pic = math.round(68 * k)
	New.Image({
		Name = "Icon",
		Key = "fish/PebbleMinnow",
		Fallback = T.PanelLight,
		FallbackText = "?",
		Position = UDim2.fromOffset(math.round((s - pic) / 2), math.round(6 * k)),
		Size = UDim2.fromOffset(pic, pic),
		ZIndex = 3,
		Parent = slot,
	})
	local leg = 26 * k / (2 * s) -- triangle legs (Figma 30/88 of the slot; 26 looks the same once the r19 corner eats the tip) as a fraction of the 45-degree gradient axis
	New("Frame", {
		Name = "Corner",
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = COMMON,
		BorderSizePixel = 0,
		ZIndex = 2,
		Parent = slot,
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
	})
	New("TextLabel", {
		Name = "Count",
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -math.round(8 * k), 0, s - math.round(24 * k)),
		Size = UDim2.fromOffset(s - 16, math.round(20 * k)),
		BackgroundTransparency = 1,
		Text = "x1",
		TextColor3 = T.Text,
		FontFace = T.Font,
		TextSize = New.FigmaSize(T.Font, math.round(15 * k)),
		TextXAlignment = Enum.TextXAlignment.Right,
		ZIndex = 4,
		Parent = slot,
	})
	-- Empty look = Figma "18 · Empty Slot" option 5 "Bubbles" (user, 2026-11-18): three small sand bubbles,
	-- drawn in a 28x28 box at (22,22) of a 72px slot (circles cx,cy,r = 8,19,4 / 18,11,3 / 21,21,2).
	local b = s / 72
	local bubbles = New("Frame", {
		Name = "Empty",
		Position = UDim2.fromOffset(math.round(22 * b), math.round(22 * b)),
		Size = UDim2.fromOffset(math.round(28 * b), math.round(28 * b)),
		BackgroundTransparency = 1,
		Visible = false,
		ZIndex = 4,
		Parent = slot,
	})
	for _, c in { { 8, 19, 4 }, { 18, 11, 3 }, { 21, 21, 2 } } do
		New("Frame", {
			Name = "Bubble",
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromOffset(c[1] * b, c[2] * b),
			Size = UDim2.fromOffset(c[3] * 2 * b, c[3] * 2 * b),
			BackgroundColor3 = Color3.fromRGB(217, 205, 184), -- Figma #D9CDB8
			BorderSizePixel = 0,
			ZIndex = 4,
			Parent = bubbles,
			[New.Children] = { New.Pill() },
		})
	end
	New("Frame", {
		Name = "SelectedRing",
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Visible = false,
		ZIndex = 5,
		Parent = slot,
		[New.Children] = { New.Corner(radius), New("UIStroke", { Color = T.Accent, Thickness = 3 }) },
	})
	local check = New("Frame", {
		Name = "Check",
		Position = UDim2.fromOffset(s - 18, -6),
		Size = UDim2.fromOffset(24, 24),
		BackgroundColor3 = T.Accent,
		Visible = false,
		ZIndex = 6,
		Parent = slot,
		[New.Children] = { New.Pill(), New("UIStroke", { Color = Color3.new(1, 1, 1), Thickness = 2 }) },
	})
	New.Image({
		Name = "Tick",
		Key = "icon_check",
		Fallback = T.Accent,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(16, 16),
		ZIndex = 6,
		Parent = check,
	})
	New("TextLabel", {
		Name = "NewBadge",
		Position = UDim2.fromOffset(-6, -8),
		Size = UDim2.fromOffset(0, 18),
		AutomaticSize = Enum.AutomaticSize.X,
		BackgroundColor3 = T.Accent,
		Text = "NEW",
		TextColor3 = T.OnAccent,
		FontFace = T.FontBadge,
		TextSize = New.FigmaSize(T.FontBadge, 11),
		Visible = false,
		ZIndex = 6,
		Parent = slot,
		[New.Children] = { New.Pill(), New("UIPadding", { PaddingLeft = UDim.new(0, 9), PaddingRight = UDim.new(0, 9) }) },
	})
	local mut = math.round(26 * k)
	New.Image({
		Name = "Mutation",
		Key = "fish/mut_glowing",
		Fallback = T.Good,
		-- bottom-left inside the tile: top-right is the Selected tick, top-left the rarity corner / NEW,
		-- bottom-right the count -> nothing overlaps when a mutated stack is selected
		Position = UDim2.fromOffset(math.round(6 * k), s - mut - math.round(6 * k)),
		Size = UDim2.fromOffset(mut, mut),
		Visible = false,
		ZIndex = 6,
		Parent = slot,
	})
	New.Image({
		Name = "Lock",
		Key = "ui/status/lock",
		Fallback = T.SubText,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(math.round(30 * k), math.round(30 * k)),
		Visible = false,
		ZIndex = 6,
		Parent = slot,
	})
	if empty then
		setItemSlot(slot, { Empty = true })
	end
	return slot
end

-- Group opacity without a CanvasGroup (Figma "opacity 55%" on a card / tile): scales every
-- Background/Text/Image/Stroke transparency under root (root included). The original values are
-- remembered in attributes, so Fade(root, 1) restores them and repeated calls don't stack.
local FADE_GUI = { "BackgroundTransparency", "TextTransparency", "TextStrokeTransparency", "ImageTransparency" }
local FADE_STROKE = { "Transparency" } -- (GuiObject.Transparency is a deprecated alias of BackgroundTransparency)
local function fade(root: Instance, opacity: number)
	local function apply(o: Instance)
		local props = if o:IsA("GuiObject") then FADE_GUI elseif o:IsA("UIStroke") then FADE_STROKE else nil
		if not props then
			return
		end
		for _, prop in props do
			local ok, cur = pcall(function()
				return (o :: any)[prop]
			end)
			if ok and type(cur) == "number" then
				local attr = "Fade_" .. prop
				local base = o:GetAttribute(attr)
				if base == nil then
					base = cur
					o:SetAttribute(attr, cur)
				end
				(o :: any)[prop] = 1 - (1 - base) * opacity
			end
		end
	end
	apply(root)
	for _, d in root:GetDescendants() do
		apply(d)
	end
end

local Screen = { Name = "Components", Make = Make, SetItemSlot = setItemSlot, Fade = fade }

-- Disabled ScreenGui holding one sample of every component (the runtime clone source).
function Screen.Build(): ScreenGui
	local gui = New("ScreenGui", {
		Name = "Components",
		ResetOnSpawn = false,
		Enabled = false,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	}) :: ScreenGui
	local sheet = New("Frame", {
		Name = "Sheet",
		Position = UDim2.fromOffset(24, 80),
		Size = UDim2.fromOffset(760, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundColor3 = T.Scene,
		Parent = gui,
		[New.Children] = {
			New.Corner(24),
			New.Padding(20),
			New("UIGridLayout", { CellSize = UDim2.fromOffset(350, 140), CellPadding = UDim2.fromOffset(20, 20), SortOrder = Enum.SortOrder.LayoutOrder }),
		},
	})
	local samples = {
		Make.Badge("RARE", T.Sky),
		Make.CurrencyChip("ui/status/coin", T.Gold),
		Make.MenuTile("Shop", "ui/icons/shop"),
		Make.NotifyPill(),
		Make.CatchCard(),
		Make.ZoneBand(),
		Make.Chip("GOOD"),
		Make.Button(),
		Make.ItemSlot(),
	}
	-- each sample sits in a named cell so the grid layout does not resize the component itself
	for i, c in samples do
		local cell = New("Frame", { Name = c.Name, BackgroundTransparency = 1, LayoutOrder = i, Parent = sheet })
		c.Name = "Sample"
		if c:IsA("GuiObject") then
			c.AnchorPoint = Vector2.new(0, 0)
			c.Position = UDim2.fromOffset(0, 0)
		end
		c.Parent = cell
	end
	return gui
end

return Screen
