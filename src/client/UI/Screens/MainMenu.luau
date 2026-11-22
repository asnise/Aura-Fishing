--!nonstrict
-- Figma 12 · Main Menu (node 3492:17320, spec hub_panel in docs/figma/cozy_menus_spec.py):
-- phone-style hub opened from the HUD. Glass frame + cream phone, sky header (avatar, clock,
-- day phase, weather, wavy edge), 3x3 icon tiles with red dots / badges, close tab on the right.
-- Static layout only; MainMenuController fills it. Baked into StarterGui by tools/ui/bake.mjs.

local New = require(script.Parent.Parent.New)
local T = New.Theme

local Screen = { Name = "MainMenu" }
local CODEX_TILE = { Id = "StatsCodex", Label = "Stats Codex", Tint = T.OnAccent }
local DAILY_TILE = { Id = "DailyLogin", Label = "Daily", Tint = T.TintButter, Icon = "ui/icons/daily_login" }

-- Tile order = Figma grid order (Economy 7 "Main Menu hub": 13 tiles, 4 per row). Tint = icon circle
-- colour; Icon overrides the default key ui/icons/<id lowercased>.
Screen.Tiles = {
	{ Id = "Shop", Tint = T.TintPeach },
	{ Id = "Auras", Tint = T.TintLilac },
	{ Id = "Fishdex", Tint = T.TintSky },
	{ Id = "Bag", Tint = T.TintButter },
	{ Id = "Character", Tint = T.TintPeach, Icon = "npc/Pip_happy" },
	{ Id = "Aquarium", Tint = T.TintSky },
	{ Id = "Mastery", Tint = T.TintMint },
	{ Id = "Store", Tint = T.TintLilac },
	{ Id = "Quests", Tint = T.TintMint },
	{ Id = "Rebirth", Tint = T.TintPink },
	{ Id = "Events", Tint = T.TintPeach },
	{ Id = "Friends", Tint = T.TintSky },
	{ Id = "Settings", Tint = T.TintSand },
	CODEX_TILE,
	DAILY_TILE,
}
local COLS = 4
local TILE_W, TILE_H = 84, 94 -- 4 x 84 = 336 (grid width), 4 rows x 94 = 376 (fits the 379 grid)
local CIRCLE = 64

local WHITE = Color3.new(1, 1, 1)

local function dot(parent: Instance, name: string, x: number, y: number)
	New("Frame", {
		Name = name,
		Position = UDim2.fromOffset(x + 2, y + 2),
		Size = UDim2.fromOffset(12, 12), -- 12 + 3px outside stroke ~ Figma 16px dot with inside stroke
		BackgroundColor3 = T.Bad,
		Visible = false,
		ZIndex = 3,
		Parent = parent,
		[New.Children] = { New.Pill(), New.Stroke(WHITE, 3) },
	})
end

local function populateTile(b: TextButton, def: any)
	local circle = New("Frame", {
		Name = "Circle",
		Position = UDim2.fromOffset((TILE_W - CIRCLE) / 2, 6),
		Size = UDim2.fromOffset(CIRCLE, CIRCLE),
		BackgroundColor3 = def.Tint,
		Parent = b,
		[New.Children] = { New.Pill(), New.Stroke(WHITE, 3) },
	})
	New.Image({
		Name = "Icon",
		Key = def.Icon or ("ui/icons/" .. string.lower(def.Id)),
		Fallback = def.Tint,
		FallbackText = def.Label or string.sub(def.Id, 1, 1),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(48, 48),
		Parent = circle,
	})
	local fb = circle.Icon:FindFirstChild("Fallback")
	if fb then
		fb.Label.TextColor3 = T.SubText
	end
	-- badge pill at the top centre ("SALE", "Lv.100") and red dot top-right
	New("TextLabel", {
		Name = "Badge",
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.fromOffset(TILE_W / 2, 0),
		Size = UDim2.fromOffset(0, 20),
		AutomaticSize = Enum.AutomaticSize.X,
		BackgroundColor3 = T.Bad,
		Text = "NEW",
		TextColor3 = T.OnAccent,
		FontFace = T.FontBadge,
		TextSize = New.FigmaSize(T.FontBadge, 12),
		Visible = false,
		ZIndex = 3,
		Parent = b,
		[New.Children] = { New.Pill(), New("UIPadding", { PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10) }) },
	})
	dot(b, "Dot", (TILE_W + CIRCLE) / 2 - 12, 4)
	New.Text({
		Name = "Label",
		Position = UDim2.fromOffset(0, 74),
		Size = UDim2.fromOffset(TILE_W, 18),
		Text = def.Label or def.Id,
		TextSize = 13,
		Parent = b,
	})
end

local function tile(grid: Instance, i: number, def: any)
	local col, row = (i - 1) % COLS, (i - 1) // COLS
	local b = New("TextButton", {
		Name = def.Id,
		Position = UDim2.fromOffset(col * TILE_W, row * TILE_H),
		Size = UDim2.fromOffset(TILE_W, TILE_H),
		BackgroundTransparency = 1,
		Text = "",
		AutoButtonColor = false,
		Parent = grid,
	})
	populateTile(b, def)
end

function Screen.EnsureCodexTile(grid: ScrollingFrame)
	local existing = grid:FindFirstChild(CODEX_TILE.Id)
	if not existing then
		tile(grid, table.find(Screen.Tiles, CODEX_TILE) :: number, CODEX_TILE)
	elseif existing:IsA("TextButton") then
		local oldTextTile = existing:FindFirstChild("TextTile")
		if oldTextTile then
			oldTextTile:Destroy()
			populateTile(existing, CODEX_TILE)
		end
	end
end

-- Older bakes have no Daily tile: add it at its grid slot.
function Screen.EnsureDailyTile(grid: ScrollingFrame)
	if not grid:FindFirstChild(DAILY_TILE.Id) then
		tile(grid, table.find(Screen.Tiles, DAILY_TILE) :: number, DAILY_TILE)
	end
end

function Screen.Build(): ScreenGui
	local gui = New("ScreenGui", {
		Name = "MainMenu",
		ResetOnSpawn = false,
		IgnoreGuiInset = false,
		DisplayOrder = 20,
		Enabled = false,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	}) :: ScreenGui

	-- 440x614 root; Figma x=560 y=64 on the 1280x720 frame -> centre offset (+140, -18) in code
	local root = New("Frame", {
		Name = "Hub",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 140, 0.5, -18),
		Size = UDim2.fromOffset(440, 614),
		BackgroundTransparency = 1,
		Parent = gui,
	})

	-- close tab sticking out of the right edge (behind the glass)
	local close = New("TextButton", {
		Name = "Close",
		Position = UDim2.fromOffset(362, 104),
		Size = UDim2.fromOffset(66, 74),
		BackgroundColor3 = WHITE,
		BackgroundTransparency = 0.4,
		Text = "",
		AutoButtonColor = true,
		Parent = root,
		[New.Children] = { New.Corner(20), New.Stroke(WHITE, 1.5) },
	})
	New.Image({ Name = "Icon", Key = "icon_close", Tint = T.SubText, Fallback = T.SubText, FallbackText = "X", Position = UDim2.fromOffset(31, 24), Size = UDim2.fromOffset(26, 26), Parent = close })

	local glass = New("Frame", {
		Name = "Glass",
		Size = UDim2.fromOffset(392, 612),
		BackgroundColor3 = WHITE,
		BackgroundTransparency = 0.45,
		ZIndex = 2,
		Parent = root,
		[New.Children] = { New.Corner(48), New.Stroke(WHITE, 1.5) },
	})
	New.Shadow(glass, "slice_shadow_glass")
	local phone = New("Frame", {
		Name = "Phone",
		Position = UDim2.fromOffset(14, 14),
		Size = UDim2.fromOffset(364, 584),
		BackgroundColor3 = T.Panel,
		ZIndex = 2,
		Parent = glass,
		[New.Children] = { New.Corner(36) },
	})

	-- header: sky gradient with rounded top corners (bottom corners covered by the wave)
	local header = New("Frame", {
		Name = "Header",
		Size = UDim2.fromOffset(364, 160),
		BackgroundColor3 = WHITE,
		ZIndex = 2,
		Parent = phone,
		[New.Children] = {
			New.Corner(36),
			New("UIGradient", { Rotation = 90, Color = ColorSequence.new(T.HubSkyTop, T.HubSkyBottom) }),
		},
	})
	New("Frame", {
		Name = "Square",
		Position = UDim2.fromOffset(0, 120),
		Size = UDim2.fromOffset(364, 40),
		BackgroundColor3 = WHITE,
		BorderSizePixel = 0,
		ZIndex = 2,
		Parent = header,
		[New.Children] = { New("UIGradient", { Rotation = 90, Color = ColorSequence.new(T.HubSkyTop:Lerp(T.HubSkyBottom, 0.75), T.HubSkyBottom) }) },
	})
	for _, b in { { 118, 18, 10 }, { 250, 14, 6 }, { 330, 110, 14 }, { 22, 124, 8 }, { 300, 84, 5 } } do
		New("Frame", {
			Name = "Bubble",
			Position = UDim2.fromOffset(b[1], b[2]),
			Size = UDim2.fromOffset(b[3], b[3]),
			BackgroundColor3 = WHITE,
			BackgroundTransparency = 0.65,
			ZIndex = 3,
			Parent = header,
			[New.Children] = { New.Pill() },
		})
	end
	local avatar = New.Image({
		Name = "Avatar",
		Key = "npc/Pip_happy",
		Fallback = T.Panel,
		Position = UDim2.fromOffset(26, 32),
		Size = UDim2.fromOffset(76, 76), -- + 4px outside stroke = Figma 84px circle
		ScaleType = Enum.ScaleType.Crop,
		BackgroundTransparency = 0,
		BackgroundColor3 = T.Panel,
		ZIndex = 3,
		Parent = header,
	})
	New.Pill().Parent = avatar
	New.Stroke(WHITE, 4).Parent = avatar
	local afb = avatar:FindFirstChild("Fallback")
	if afb then
		afb:FindFirstChildOfClass("UICorner"):Destroy()
		New.Pill().Parent = afb
	end
	dot(header, "AvatarDot", 90, 30)
	-- VIP pill under the avatar (Figma Economy 7), shown when the VIP pass is owned
	New("TextLabel", {
		Name = "VipBadge",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromOffset(64, 108),
		Size = UDim2.fromOffset(0, 20),
		AutomaticSize = Enum.AutomaticSize.X,
		BackgroundColor3 = T.Gold,
		Text = "VIP",
		TextColor3 = WHITE,
		FontFace = T.FontBadge,
		TextSize = New.FigmaSize(T.FontBadge, 12),
		Visible = false,
		ZIndex = 4,
		Parent = header,
		[New.Children] = { New.Pill(), New.Stroke(WHITE, 2), New("UIPadding", { PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10) }) },
	})
	New("TextLabel", {
		Name = "Clock",
		Position = UDim2.fromOffset(130, 22),
		Size = UDim2.fromOffset(138, 70),
		BackgroundTransparency = 1,
		Text = "16:07",
		TextColor3 = WHITE,
		FontFace = T.Font,
		TextSize = New.FigmaSize(T.Font, 58),
		ZIndex = 3,
		Parent = header,
	})
	-- day phase: night, dawn, day (pill = current), dusk
	local phase = New("Frame", { Name = "DayPhase", Position = UDim2.fromOffset(138, 96), Size = UDim2.fromOffset(110, 22), BackgroundTransparency = 1, ZIndex = 3, Parent = header })
	local phases = {
		{ "Night", "icon_moon", 0, 16 },
		{ "Dawn", "icon_dawn", 24, 18 },
		{ "Day", "icon_day", 50, 16 }, -- baked as the current phase (white pill 36 wide), like Figma
		{ "Dusk", "icon_moon", 94, 16 },
	}
	for _, ph in phases do
		local holder = New("Frame", {
			Name = ph[1],
			Position = UDim2.fromOffset(ph[3], 0),
			Size = UDim2.fromOffset(if ph[1] == "Day" then 36 else ph[4], 22),
			BackgroundColor3 = WHITE,
			BackgroundTransparency = if ph[1] == "Day" then 0 else 1,
			ZIndex = 3,
			Parent = phase,
			[New.Children] = { New.Pill() },
		})
		New.Image({
			Name = "Icon",
			Key = ph[2],
			Tint = if ph[1] == "Day" then T.SkyLip else WHITE,
			Fallback = WHITE,
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromOffset(ph[4], 16),
			ZIndex = 3,
			Parent = holder,
		})
	end
	New.Image({ Name = "Weather", Key = "icon_sun", Fallback = T.Gold, Position = UDim2.fromOffset(278, 26), Size = UDim2.fromOffset(66, 66), ZIndex = 3, Parent = header })
	local wave = New.Image({
		Name = "Wave",
		Key = "shape_wave_edge",
		Tint = T.Panel,
		Fallback = T.Panel,
		Position = UDim2.fromOffset(0, 140),
		Size = UDim2.fromOffset(364, 26),
		ScaleType = Enum.ScaleType.Stretch,
		ZIndex = 3,
		Parent = phone,
	})
	local wfb = wave:FindFirstChild("Fallback")
	if wfb then
		wfb:FindFirstChildOfClass("UICorner"):Destroy() -- flat cream strip until the wave PNG is uploaded
	end

	local rows = math.ceil(#Screen.Tiles / COLS)
	local grid = New("ScrollingFrame", {
		Name = "Grid",
		Position = UDim2.fromOffset(14, 178),
		Size = UDim2.fromOffset(336, 379),
		CanvasSize = UDim2.fromOffset(0, rows * TILE_H),
		ScrollBarThickness = 4,
		ScrollBarImageColor3 = T.Track,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ZIndex = 2,
		Parent = phone,
	})
	for i, def in Screen.Tiles do
		tile(grid, i, def)
	end
	return gui
end

return Screen
