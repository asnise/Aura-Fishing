--!nonstrict
-- Figma 01 · HUD (node 3492:16667). Static layout only; behaviour + data in Controllers/HUDController.
--   Stats        Level row (Level, XP) + Currencies (Coins, Gems = CurrencyChip)
--   SideMenu     BtnShop / BtnAuras / BtnFishdex / BtnMenu (MenuTile)
--   Actions      Bag (Icon + Value), Depth stepper (Minus, Value, Plus), Auto, Sell
--   CastMobile   round CAST button (touch only), CastCharge power bar + PerfectPop, StreakHolder (C25)
--   Status       "Waiting..." / "!" pill bottom centre
--   Notifications  holder for NotifyPill clones (top centre)
-- Each cluster has a UIScale named "Scale" that HUDController sets from the screen size.

local New = require(script.Parent.Parent.New)
local Make = require(script.Parent.Components).Make
local T = New.Theme

local Screen = { Name = "HUD" }

local function outlined(name: string, size: number, thickness: number, order: number, text: string): TextLabel
	return New("TextLabel", {
		Name = name,
		Size = UDim2.fromOffset(0, size + 4),
		AutomaticSize = Enum.AutomaticSize.X,
		BackgroundTransparency = 1,
		Text = text,
		TextColor3 = Color3.new(1, 1, 1),
		FontFace = T.Font,
		TextSize = New.FigmaSize(T.Font, size),
		LayoutOrder = order,
		[New.Children] = {
			New("UIStroke", { Color = T.Text, Thickness = thickness, ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual, LineJoinMode = Enum.LineJoinMode.Round }),
		},
	}) :: TextLabel
end

local function scale(parent: Instance)
	New("UIScale", { Name = "Scale", Parent = parent })
end

local CIRCLE = 88

local function round(obj: Instance)
	for _, corner in obj:GetDescendants() do
		if corner:IsA("UICorner") then
			corner.CornerRadius = UDim.new(0.5, 0)
		end
	end
	local own = obj:FindFirstChildOfClass("UICorner")
	if own then
		own.CornerRadius = UDim.new(0.5, 0)
	end
end

local function circleIcon(parent: Instance, key: string, fallback: Color3)
	local icon = parent:FindFirstChild("Icon")
	if not icon then
		icon = New.Image({ Name = "Icon", Key = key, Fallback = fallback, ZIndex = 3, Parent = parent })
		New.ApplyImage(icon)
	end
	icon.AnchorPoint = Vector2.new(0.5, 0.5)
	icon.Position = UDim2.fromScale(0.5, 0.5)
	icon.Size = UDim2.fromOffset(48, 48)
end

local BLACK = Color3.new(0, 0, 0)

-- Round action buttons are translucent dark plates (Figma HUD 3760:5656: fill #000 25%, 5px edge #000 10%).
-- on = highlighted state (AUTO running, CAST/REEL text states) with a tint.
function Screen.SetPlate(button: any, on: boolean, tint: Color3?)
	New.SetButtonColor(button, if on and tint then tint else BLACK)
	local face = button:FindFirstChild("Face")
	if face then
		face.BackgroundTransparency = if on then 0.25 else 0.75
	end
end

local function plate(button: any)
	local lip = button:FindFirstChild("Lip")
	if lip then
		lip.BackgroundTransparency = 1 -- flat plate: no bottom lip
	end
	local face = button:FindFirstChild("Face")
	if face then
		face.Size = UDim2.fromScale(1, 1)
		if not face:FindFirstChild("Plate") then
			New("UIStroke", { Name = "Plate", Color = BLACK, Thickness = 5, Transparency = 0.9, ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Parent = face })
		end
	end
	Screen.SetPlate(button, false)
end

-- Depth = round icon button (bobber, no number) that opens the Depth popup; HUDController binds "Hit".
-- Also upgrades a baked HUD that still has the old [-] DEPTH [+] stepper.
function Screen.StyleDepthButton(depth: any)
	for _, name in { "Minus", "Plus", "DepthLabel" } do
		local old = depth:FindFirstChild(name)
		if old then
			old:Destroy()
		end
	end
	depth.Size = UDim2.fromOffset(CIRCLE, CIRCLE)
	round(depth)
	depth.BackgroundColor3 = BLACK
	depth.BackgroundTransparency = 0.75
	-- same edge as the AUTO / SELL plates (Border mode, 5px, 90% clear): one stroke, never two
	local edge = depth:FindFirstChildOfClass("UIStroke")
	if not edge then
		edge = New("UIStroke", { Parent = depth }) :: UIStroke
	end
	edge.Name = "Plate"
	edge.Color, edge.Thickness, edge.Transparency = BLACK, 5, 0.9
	edge.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	for _, other in depth:GetChildren() do
		if other:IsA("UIStroke") and other ~= edge then
			other:Destroy()
		end
	end
	circleIcon(depth, "ui/status/bobber", T.TintSky)
	depth.Value.Visible = false -- the popup shows the number; HUDController still keeps the text current
	if not depth:FindFirstChild("Hit") then
		New("TextButton", { Name = "Hit", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = "", ZIndex = 4, Parent = depth })
	end
end

-- Auto = round icon button; ON/OFF is the face colour (HUDController.SetAuto).
function Screen.StyleAutoButton(auto: any)
	auto.Text = ""
	auto.Size = UDim2.fromOffset(CIRCLE, CIRCLE)
	round(auto)
	plate(auto)
	circleIcon(auto:FindFirstChild("Face") or auto, "ui/icons/auto_pro", T.TintSky)
end

-- Locked = no fishable water near: the button stays visible, dimmed, with a lock on top (pressing it explains why).
function Screen.SetLocked(button: any, locked: boolean)
	local face = button:FindFirstChild("Face") or button
	local lock = face:FindFirstChild("Lock")
	if not lock then
		lock = New.Image({ Name = "Lock", Key = "icon_lock", Tint = Color3.new(1, 1, 1), Fallback = T.SubText, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(30, 30), ZIndex = 5, Parent = face })
		New.ApplyImage(lock)
	end
	lock.Visible = locked
	local icon = face:FindFirstChild("Icon")
	if icon then
		icon.ImageTransparency = if locked then 0.65 else 0
	end
end

-- Sell All = round button with the bag icon.
function Screen.StyleSellButton(sell: any)
	sell.AnchorPoint = Vector2.zero
	sell.Text = ""
	sell.Size = UDim2.fromOffset(CIRCLE, CIRCLE)
	round(sell)
	plate(sell)
	circleIcon(sell:FindFirstChild("Face") or sell, "ui/status/sell_bag", T.Gold)
end

-- CAST = round button with the hook charm (Figma 3760:5762) while idle; other states (REEL IN, HOOK!, ...) show text.
function Screen.StyleCastButton(cast: any)
	cast.Size = UDim2.fromOffset(CIRCLE, CIRCLE)
	round(cast)
	plate(cast)
	circleIcon(cast:FindFirstChild("Face") or cast, "ui/icons/hook_cast", T.Accent)
	cast.Face.Icon.Size = UDim2.fromOffset(56, 56)
end

-- Mobile-game layout (Figma HUD 3760:5656): Bag and Sell All stack at the top right of the dock; the round
-- Depth and Auto buttons sit under them, left of the Roblox jump button. Applied to baked HUDs at runtime too.
-- Dock design size 350 x 176; touch: bottom edge 180px above the screen bottom (clear of the jump button).
function Screen.LayoutFishingDock(dock: any, size: Vector2, touch: boolean, uiScale: number?)
	local oldList = dock:FindFirstChildOfClass("UIListLayout")
	if oldList then
		oldList:Destroy()
	end

	local factor = uiScale or math.clamp(math.min(size.Y / 620, size.X / 1100), 0.6, 1) -- same scale as the other HUD clusters
	dock.Scale.Scale = factor
	dock.Size = UDim2.fromOffset(350, 176)
	dock.AnchorPoint = Vector2.new(1, 1)
	dock.Position = UDim2.new(1, -12, 1, if touch then -math.floor(180 * factor) else -12)

	dock.Bag.AnchorPoint = Vector2.new(1, 0)
	dock.Bag.Position = UDim2.fromOffset(350, 0)
	dock.Bag.Size = UDim2.fromOffset(0, 40)

	-- Sell = round bag icon button (Figma 3762:5764): bottom-left of CAST on touch, left of Depth on PC.
	Screen.StyleSellButton(dock.Sell)
	dock.Sell.Position = if touch then UDim2.fromOffset(0, 252) else UDim2.fromOffset(26, 88)

	Screen.StyleDepthButton(dock.Depth)
	dock.Depth.Position = UDim2.fromOffset(146, 88)
	Screen.StyleAutoButton(dock.Auto)
	dock.Auto.Position = UDim2.fromOffset(250, 88)
end

function Screen.Build(): ScreenGui
	local gui = New("ScreenGui", {
		Name = "HUD",
		ResetOnSpawn = false,
		IgnoreGuiInset = false,
		Enabled = false, -- HUDController enables it in game; the Aura UI panel shows it in edit mode
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	}) :: ScreenGui

	-- Top-left: HUD Stats E "Minimal Floating"
	local stats = New("Frame", {
		Name = "Stats",
		Position = UDim2.fromOffset(12, 12),
		AutomaticSize = Enum.AutomaticSize.XY,
		BackgroundTransparency = 1,
		Parent = gui,
		[New.Children] = { New("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }) },
	})
	scale(stats)
	local levelRow = New("Frame", {
		Name = "LevelRow",
		Size = UDim2.fromOffset(0, 36),
		AutomaticSize = Enum.AutomaticSize.X,
		BackgroundTransparency = 1,
		LayoutOrder = 1,
		Parent = stats,
		[New.Children] = { New("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 10), VerticalAlignment = Enum.VerticalAlignment.Center, SortOrder = Enum.SortOrder.LayoutOrder }) },
	})
	outlined("Level", 30, 3, 1, "Lv.12").Parent = levelRow
	outlined("XP", 16, 2.5, 2, "340 / 900 XP").Parent = levelRow
	local currencies = New("Frame", {
		Name = "Currencies",
		Size = UDim2.fromOffset(0, 40),
		AutomaticSize = Enum.AutomaticSize.X,
		BackgroundTransparency = 1,
		LayoutOrder = 2,
		Parent = stats,
		[New.Children] = { New("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }) },
	})
	for _, c in {
		{ "Coins", "ui/status/coin", T.Gold, "12,450", 1 },
		{ "Gems", "ui/status/gem", T.Gem, "320", 2 },
		{ "StarTokens", "ui/status/star_token", T.Accent, "7", 4 },
	} do
		local chip = Make.CurrencyChip(c[2], c[3])
		chip.Name = c[1]
		chip.LayoutOrder = c[5]
		chip.Value.Text = c[4]
		chip.Parent = currencies
	end

	-- Left: side menu (vertical on PC, row top-right on short screens — HUDController.layout)
	local menu = New("Frame", {
		Name = "SideMenu",
		Position = UDim2.fromOffset(12, 234), -- Figma y 292 minus the 58px top bar (below the desktop chat window)
		Size = UDim2.fromOffset(80, 382),
		BackgroundTransparency = 1,
		Parent = gui,
		[New.Children] = { New("UIListLayout", { Name = "List", Padding = UDim.new(0, 10), SortOrder = Enum.SortOrder.LayoutOrder }) },
	})
	scale(menu)
	for i, m in { { "Bag", "ui/icons/bag" }, { "Shop", "ui/icons/shop" }, { "Auras", "ui/icons/auras" }, { "Quests", "ui/icons/quests" }, { "Menu", "equipment/StarterPouch", T.TintSky } } do
		local tile = Make.MenuTile(m[1], m[2], m[3])
		tile.LayoutOrder = i
		tile.Parent = menu
	end

	-- Status pill ("Waiting... (40m)", "!")
	local status = New.Text({
		Name = "Status",
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -126),
		Size = UDim2.fromOffset(300, 56),
		Text = "Waiting... (40m)",
		Visible = false,
		BackgroundTransparency = 0,
		BackgroundColor3 = T.Panel,
		FontFace = T.Font,
		MaxTextSize = 40,
		Parent = gui,
	})
	New.Pill().Parent = status
	New.Stroke().Parent = status
	scale(status)

	-- C25 cast rework: no button in the middle. Hot Streak tag sits bottom centre (HUDController parents StreakTag here).
	local streak = New("Frame", {
		Name = "StreakHolder",
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -24),
		Size = UDim2.fromOffset(120, 30),
		BackgroundTransparency = 1,
		Parent = gui,
	})
	scale(streak)

	-- Touch only: round CAST button left of the Roblox jump button (Figma "Btn Cast Mobile"); PC = click the world
	local castMobile = New.Button({
		Name = "CastMobile",
		AnchorPoint = Vector2.new(1, 1),
		Position = UDim2.new(1, -180, 1, -24),
		Size = UDim2.fromOffset(88, 88),
		Text = "CAST",
		BackgroundColor3 = T.Accent,
		TextSize = 20,
		Radius = 44,
		Visible = false,
		Parent = gui,
	})
	scale(castMobile)

	-- Shown while a cast is held (Figma "Cast Charge [state: holding]"): power bar right of the character
	local charge = New("CanvasGroup", { -- CanvasGroup: the fill follows the tube's rounded ends
		Name = "CastCharge",
		Position = UDim2.new(0.5, 60, 0.5, -130),
		Size = UDim2.fromOffset(26, 170),
		BackgroundColor3 = T.Panel,
		Visible = false,
		Parent = gui,
		[New.Children] = { New.Corner(13), New.Stroke() },
	})
	scale(charge)
	-- Perfect zone / fill positions are set by FishingController from GameConfig.Cast
	New("Frame", { Name = "Fill", AnchorPoint = Vector2.new(0, 1), Position = UDim2.fromScale(0, 1), Size = UDim2.fromScale(1, 0.7), BackgroundColor3 = T.Accent, BorderSizePixel = 0, Parent = charge })
	New("Frame", { Name = "PerfectZone", Size = UDim2.fromScale(1, 0.12), Position = UDim2.fromScale(0, 0.1), BackgroundColor3 = T.Gold, BackgroundTransparency = 0.15, BorderSizePixel = 0, ZIndex = 2, Parent = charge })
	New("Frame", { Name = "Needle", AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.fromScale(0, 0.3), Size = UDim2.new(1, 0, 0, 4), BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0, ZIndex = 3, Parent = charge })
	local pop = outlined("PerfectPop", 30, 3, 0, "PERFECT!")
	pop.AnchorPoint = Vector2.new(0.5, 1)
	pop.Position = UDim2.new(0.5, 73, 0.5, -136)
	pop.TextColor3 = T.Gold
	pop.Visible = false
	pop.Parent = gui
	scale(pop)

	-- Bottom right: bag status above the Depth / Auto / Sell All row.
	local actions = New("Frame", {
		Name = "Actions",
		BackgroundTransparency = 1,
		Parent = gui,
	})
	scale(actions)
	local bag = Make.CurrencyChip("ui/icons/bag", T.Gold)
	bag.Name = "Bag"
	bag.Value.Text = "18 / 50"
	bag.Parent = actions
	-- Depth stepper (Figma "Depth Stepper"): [-] DEPTH 80m [+]
	local stepper = New("Frame", { Name = "Depth", BackgroundColor3 = T.Panel, Parent = actions, [New.Children] = { New.Corner(T.RadiusButton), New.Stroke() } })
	New.Title({ Name = "Value", Text = "80m", Parent = stepper })
	New.Button({ Name = "Auto", Text = "AUTO: OFF", Parent = actions })
	New.Button({ Name = "Sell", Text = "SELL ALL", BackgroundColor3 = T.Gold, Parent = actions })
	Screen.LayoutFishingDock(actions, Vector2.new(1280, 720), false)

	-- Top centre: notifications (NotifyPill clones) and the catch card slot
	New("Frame", {
		Name = "Notifications",
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 8),
		Size = UDim2.new(0.6, 0, 0, 200),
		BackgroundTransparency = 1,
		Parent = gui,
		[New.Children] = { New("UIListLayout", { Padding = UDim.new(0, 2), HorizontalAlignment = Enum.HorizontalAlignment.Center, SortOrder = Enum.SortOrder.LayoutOrder }) },
	})
	return gui
end

return Screen
