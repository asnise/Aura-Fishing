--!nonstrict
-- Main HUD (GDD 9): currencies/level, depth stepper, auto/sell buttons, mobile CAST button, notifications,
-- Layout keeps clear of Roblox CoreGui (docs/UI_STYLE.md "Roblox safe areas"): top bar (inset), leaderboard top-right,
-- chat top-left, mobile thumbstick bottom-left, mobile jump bottom-right.
-- catch popups. Layout is baked into StarterGui.HUD (UI/Screens/HUD.luau); this file only binds
-- data/behaviour. Notifications and catch cards are clones of UI components (UI/Components).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Registry = require(Shared.Registry)
local Remotes = require(Shared.Remotes)
local Format = require(Shared.Util.Format)
local Signal = require(Shared.Util.Signal)

local Inventory = require(Shared.Inventory)
local Boosts = require(Shared.Boosts)
local FishingSpot = require(Shared.FishingSpot)
local DailyLogin = require(Shared.DailyLogin)

local New = require(script.Parent.Parent.UI.New)
local Baked = require(script.Parent.Parent.UI.Baked)
local Components = require(script.Parent.Parent.UI.Components)
local HUDScreen = require(script.Parent.Parent.UI.Screens.HUD)
local Modal = require(script.Parent.Parent.UI.Modal)
local MakeTile = (require(script.Parent.Parent.UI.Screens:WaitForChild("Components")) :: any).Make.MenuTile
local CastPopup = require(script.Parent.Parent.UI.CastPopup) -- Depth popup
local DataController = require(script.Parent.DataController)
local SoundController = require(script.Parent.SoundController)

local T = New.Theme
local player = Players.LocalPlayer

local HUD = {}
HUD.WaterLocked = false -- no fishable water in reach and nothing running: CAST / AUTO are locked
HUD.NearWater = false -- fishable water in reach (FishingSpot.NearWater), polled below
HUD.FishingActive = false -- set by FishingController while a cast is in progress
HUD.Gui = nil :: ScreenGui?
HUD.Drawer = nil :: Frame? -- currency drawer (Pearls, Star Tokens, boosts); opened by the chevron next to Gems
HUD.BoostRow = nil :: Frame?
HUD.AdoptToDrawer = nil :: ((GuiObject, number) -> ())? -- EconomyController moves the Pearls chip in
HUD.CastButton = nil :: GuiButton? -- touch-only round CAST button; FishingController reads press + release
HUD.CastCharge = nil :: Frame? -- power bar shown while a cast is held (FishingController)
HUD.PerfectPop = nil :: TextLabel?
HUD.AutoToggled = Signal.new() -- (enabled)
HUD.MenuRequested = Signal.new() -- (menuName)
HUD.HubRequested = Signal.new() -- Main Menu hub button
HUD.MasteryRequested = Signal.new() -- Mastery window
HUD.InventoryRequested = Signal.new() -- (tab?) Bag chip / key B -> Inventory window (B21)
HUD.CharacterRequested = Signal.new() -- key C / Main Menu avatar -> Character window (17)
HUD.SkillsRequested = Signal.new() -- SKILLS button (Character header) -> Skills window (C4)
HUD.AquariumRequested = Signal.new() -- Main Menu Aquarium tile -> EconomyController
HUD.StoreRequested = Signal.new() -- Main Menu Store tile -> EconomyController (Robux store)
HUD.EventsRequested = Signal.new() -- () -> Events hub (E0)
HUD.QuestsRequested = Signal.new() -- () -> Quests window (C7)
HUD.DailyLoginRequested = Signal.new() -- () -> Daily Login calendar window
HUD.BannerRequested = Signal.new() -- (bannerId) -> gacha page for that banner (E1 / G1)
HUD.TargetDepth = 10

local refs: { [string]: any } = {}
local notifyHolder: Frame
local catchCard: GuiObject? = nil

-- Notifications ------------------------------------------------------------

function HUD.Notify(text: string, color: Color3?)
	if not notifyHolder then
		return
	end
	if color and color.R > 0.75 and color.G < 0.5 and color.B < 0.55 then
		New.Sfx("ui_error") -- red notices (full bag, not enough coins, ...)
	end
	local label = Components.Clone("NotifyPill")
	label.Text = text
	label.TextColor3 = color or T.Text
	label.Parent = notifyHolder
	New.Pop(label)
	task.delay(3, function()
		local fadeInfo = TweenInfo.new(0.5)
		TweenService:Create(label, fadeInfo, { TextTransparency = 1, BackgroundTransparency = 1 }):Play()
		for _, desc in label:GetDescendants() do
			if desc:IsA("UIStroke") then
				TweenService:Create(desc, fadeInfo, { Transparency = 1 }):Play()
			elseif desc:IsA("TextLabel") or desc:IsA("TextButton") then
				TweenService:Create(desc, fadeInfo, { TextTransparency = 1, BackgroundTransparency = 1 }):Play()
			elseif desc:IsA("ImageLabel") or desc:IsA("ImageButton") then
				TweenService:Create(desc, fadeInfo, { ImageTransparency = 1, BackgroundTransparency = 1 }):Play()
			elseif desc:IsA("GuiObject") then
				TweenService:Create(desc, fadeInfo, { BackgroundTransparency = 1 }):Play()
			end
		end
		task.wait(0.5)
		if label.Parent then
			label:Destroy()
		end
	end)
end

function HUD.HideCatch()
	if catchCard then
		catchCard:Destroy()
		catchCard = nil
	end
end

function HUD.ShowCatch(result: any)
	local entry = result.Entry
	local fish = Registry.Fish[entry.Fish]
	local rarity = Registry.Rarities[fish.Rarity]
	local mut = entry.Mutation and Registry.Mutations[entry.Mutation]

	-- Figma 04 · Catch Result (Components prefab "CatchCard")
	HUD.HideCatch()
	local card = Components.Clone("CatchCard")
	catchCard = card
	-- the Components sheet stores samples at 0,0 in their grid cell: place the clone at screen centre
	card.AnchorPoint = Vector2.new(0.5, 0.5)
	card.Position = UDim2.fromScale(0.5, 0.5)
	card.Parent = HUD.Gui
	New.FitToScreen(card)
	New.Pop(card) -- built already shown: no Enabled/Visible change to trigger it
	New.ApplyImages(card)

	SoundController.Play("ui_open")
	if rarity.Tier >= 3 then
		SoundController.Play("catch_rare")
	else
		SoundController.Play("catch")
	end
	local tags = card.Tags
	tags.Rarity.Text = string.upper(rarity.Name)
	tags.Rarity.BackgroundColor3 = rarity.Color
	tags.New.Visible = result.New == true
	tags.Mutation.Visible = mut ~= nil
	if mut then
		New.SetImageKey(tags.Mutation, "fish/mut_" .. string.lower(entry.Mutation), mut.Color)
	end
	New.SetImageKey(card.Picture, "fish/" .. entry.Fish, rarity.Color, string.sub(fish.Name, 1, 1))
	card.FishName.Text = (if mut then mut.Name .. " " else "") .. fish.Name
	card.FishName.TextColor3 = rarity.Color
	local meta = { { Text = `{entry.Weight} kg` }, { Text = result.Mode, Color = T.Sky } }
	if result.Perfect then
		table.insert(meta, { Text = "PERFECT", Color = T.Gold })
	end
	if result.Hotspot then
		table.insert(meta, { Text = "HOTSPOT", Color = T.Gold })
	end
	New.SetBadges(card.Meta, meta)
	New.FormatCurrencyChip(card.Rewards.Coins, 20)
	New.FormatCurrencyChip(card.Rewards.Gems, 20)
	card.Rewards.Coins.Value.Text = `+{Format.Number(result.Value)}`
	card.Rewards.Gems.Visible = result.Gems > 0
	card.Rewards.Gems.Value.Text = `+{result.Gems}`
	-- why it's worth that much: mutation, manual and perfect multipliers (GameConfig / Mutations)
	local breakdown = {}
	if mut then
		table.insert(breakdown, { Text = `{mut.Name} x{mut.ValueMultiplier}`, Color = mut.Color })
	end
	if result.Mode == "Manual" then
		table.insert(breakdown, { Text = `Manual x{Registry.GameConfig.ManualMultiplier}`, Color = T.Sky })
	end
	if result.Perfect then
		table.insert(breakdown, { Text = `Perfect +{Registry.GameConfig.PerfectCatchBonus}`, Color = T.Gold })
	end
	New.SetBadges(card.Breakdown, breakdown)
	card.Breakdown.Visible = #breakdown > 0
	card.Size = UDim2.fromOffset(400, if #breakdown > 0 then 404 else 375)
	if result.Kept == false then
		HUD.Notify("Bag full - the fish was released. Sell or open items!", T.Bad)
	end
	if result.Treasure then
		local t = Registry.Treasures[result.Treasure]
		HUD.Notify(`Bonus: {t and t.Name or "Treasure"}! Open it in your Inventory`, T.Gem)
	end
	if result.LevelsGained > 0 then
		HUD.Notify(`LEVEL UP! +{result.LevelsGained * Registry.GameConfig.GemsPerLevel} gems`, T.Gem)
	end
	task.delay(2.6, function()
		if catchCard == card then
			HUD.HideCatch()
		end
	end)
end

-- Bite "!" ---------------------------------------------------------------------

function HUD.SetStatus(text: string?, color: Color3?)
	local s = refs.Status
	if not s then
		return
	end
	s.Visible = text ~= nil
	s.Text = text or ""
	s.TextColor3 = color or T.Text
end

-- The round action button never shows text: every state is a picture.
-- REELING reuses the reel_in picture and AUTO the auto_pro picture until dedicated art exists.
local CAST_ICONS = {
	["CAST"] = "ui/icons/hook_cast",
	["REEL IN"] = "ui/icons/reel_in",
	["HOOK!"] = "ui/icons/hook_catch",
	["REELING"] = "ui/icons/reel_in",
	["AUTO"] = "ui/icons/auto_pro",
}
local PLAIN_STATES = { ["CAST"] = true, ["REEL IN"] = true } -- other states get a highlighted plate

function HUD.SetCastButton(text: string, color: Color3?)
	New.SetImageKey(refs.Cast.Face.Icon, CAST_ICONS[text] or CAST_ICONS.CAST)
	refs.Cast.Text = ""
	HUDScreen.SetPlate(refs.Cast, not PLAIN_STATES[text], color or T.Accent)
end

-- Depth ------------------------------------------------------------------------
-- C25: the depth is set before casting: the HUD Depth button opens the Depth popup.
-- Saved to Settings.TargetDepth a moment after the last change; clamped to the line's MaxDepth.

function HUD.MaxDepth(): number
	local stats = DataController.Stats
	return stats and stats.Values.MaxDepth or 30
end

local depthDirty = 0 -- edit token: a newer press cancels the pending save
function HUD.RefreshDepthButton()
	local profile = DataController.Profile
	if not refs.DepthValue or not profile then
		return
	end
	if depthDirty == 0 then -- don't fight the player's unsaved edit
		HUD.TargetDepth = profile.Settings.TargetDepth or HUD.TargetDepth
	end
	HUD.TargetDepth = math.clamp(HUD.TargetDepth, 0, HUD.MaxDepth())
	refs.DepthValue.Text = `{HUD.TargetDepth}m`
end

-- Sets the target depth (HUD button and Depth popup): clamped to the line, saved shortly after the last change.
function HUD.SetDepth(value: number)
	HUD.TargetDepth = math.clamp(math.round(value), 0, HUD.MaxDepth())
	refs.DepthValue.Text = `{HUD.TargetDepth}m`
	depthDirty += 1
	local mine = depthDirty
	task.delay(0.6, function()
		if mine == depthDirty then
			Remotes.Func("SetSetting"):InvokeServer("TargetDepth", HUD.TargetDepth)
			if mine == depthDirty then -- a press during the save keeps its own pending save
				depthDirty = 0
			end
		end
	end)
end

-- Build ------------------------------------------------------------------------

local function bindBoosts(top: Frame, gui: ScreenGui): (any) -> ()
	local row = New("Frame", {
		Name = "ActiveBoosts",
		Size = UDim2.fromOffset(0, 32),
		AutomaticSize = Enum.AutomaticSize.X,
		BackgroundTransparency = 1,
		Visible = false,
		LayoutOrder = 3,
		Parent = top,
		[New.Children] = { New("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 5), SortOrder = Enum.SortOrder.LayoutOrder, VerticalAlignment = Enum.VerticalAlignment.Center }) }, -- 5px between chips (Figma example)
	})
	HUD.BoostRow = row
	local chips = {}
	for i, id in { "Coins", "Pearls" } do
		-- compact coral pill: boost picture + time left (Figma Currency HUD Options, option 5 boost chip)
		local chip = New("Frame", {
			Name = id,
			Size = UDim2.fromOffset(0, 26),
			AutomaticSize = Enum.AutomaticSize.X,
			BackgroundColor3 = T.Accent,
			LayoutOrder = i,
			Parent = row,
			[New.Children] = {
				New.Pill(),
				New("UIPadding", { PaddingLeft = UDim.new(0, 3), PaddingRight = UDim.new(0, 8) }), -- Figma example: icon at x3, text ends 8px before the edge
				New("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder, VerticalAlignment = Enum.VerticalAlignment.Center }),
			},
		}) :: any
		local icon = New.Image({ Name = "Icon", Key = "ui/shop/boost_" .. string.lower(id), Fallback = T.Accent, Size = UDim2.fromOffset(20, 20), LayoutOrder = 1, Parent = chip })
		New.ApplyImage(icon)
		local value = New.Text({ Name = "Value", Size = UDim2.fromOffset(40, 18), Text = "0:00", TextColor3 = T.OnAccent, FontFace = T.FontBadge, TextSize = 12, TextScaled = false, LayoutOrder = 2, Parent = chip })
		New.FitTextWidth(value, 0) -- real font width: AutomaticSize measured before the font loaded and the chips overlapped
		chips[id] = chip
	end

	local function refresh(profile: any)
		local anyActive = false
		local now = math.floor(workspace:GetServerTimeNow())
		for id, chip in chips do
			local left = if profile then Boosts.Remaining(profile, id, now) else 0
			chip.Visible = left > 0
			if left > 0 then
				local mins, secs = math.floor(left / 60), left % 60
				local clock = if mins >= 60 then string.format("%d:%02d:%02d", math.floor(mins / 60), mins % 60, secs) else string.format("%d:%02d", mins, secs)
				chip.Value.Text = clock
				anyActive = true
			end
		end
		row.Visible = anyActive
	end
	task.spawn(function()
		while gui.Parent do
			task.wait(1)
			refresh(DataController.Profile)
		end
	end)
	return refresh
end

function HUD.Init()
	local gui = Baked.Get("HUD")
	gui.Enabled = true
	HUD.Gui = gui
	local find = function(path: string): any
		return Baked.Find(gui, path)
	end

	local top = find("Stats")
	-- Daily Login lives on the main screen: a pill under the currencies with a red dot while a gift waits
	if not top:FindFirstChild("BtnDaily") then
		local daily = New("TextButton", {
			Name = "BtnDaily",
			Size = UDim2.fromOffset(0, 34),
			AutomaticSize = Enum.AutomaticSize.X,
			BackgroundColor3 = T.Panel,
			Text = "",
			AutoButtonColor = false,
			LayoutOrder = 3,
			Parent = top,
			[New.Children] = {
				New.Pill(),
				New.Stroke(T.Track, 2),
				New("UIPadding", { PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 14) }),
				New("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 6), VerticalAlignment = Enum.VerticalAlignment.Center, SortOrder = Enum.SortOrder.LayoutOrder }),
			},
		}) :: TextButton
		New.Image({ Name = "Icon", Key = "ui/icons/daily_login", Fallback = T.TintButter, Size = UDim2.fromOffset(24, 24), LayoutOrder = 1, Parent = daily })
		local label = New.Text({ Name = "Label", Size = UDim2.fromOffset(0, 20), AutomaticSize = Enum.AutomaticSize.X, Text = "Daily", TextSize = 14, TextColor3 = T.Text, LayoutOrder = 2, Parent = daily })
		label.TextScaled = false
		New("Frame", { Name = "Dot", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(1, -2, 0, 4), Size = UDim2.fromOffset(14, 14), BackgroundColor3 = T.Bad, Visible = false, ZIndex = 10, Parent = daily, [New.Children] = { New.Pill(), New("UIStroke", { Color = Color3.new(1, 1, 1), Thickness = 2 }) } })
		New.ApplyImages(daily)
		daily.Activated:Connect(function()
			HUD.DailyLoginRequested:Fire()
		end)
		refs.DotDaily = daily.Dot
	end
	local refreshBoosts = bindBoosts(top, gui)
	refs.Level = find("Stats/LevelRow/Level")
	refs.XPText = find("Stats/LevelRow/XP")
	-- measured widths (AutomaticSize ran before Fredoka loaded -> "Lv.100" overlapped the XP text)
	New.FitTextWidth(refs.Level, 6) -- + 2 x UIStroke 3
	New.FitTextWidth(refs.XPText, 5) -- + 2 x UIStroke 2.5
	local coinsChip = find("Stats/Currencies/Coins")
	local gemsChip = find("Stats/Currencies/Gems")
	New.FormatCurrencyChip(coinsChip, 20)
	New.FormatCurrencyChip(gemsChip, 20)
	refs.Coins = find("Stats/Currencies/Coins/Value")
	refs.Gems = find("Stats/Currencies/Gems/Value")
	local starTokensChip = find("Stats/Currencies/StarTokens")
	if not starTokensChip then
		local curRow = find("Stats/Currencies")
		if curRow then
			starTokensChip = Components.Clone("CurrencyChip")
			starTokensChip.Name = "StarTokens"
			starTokensChip.LayoutOrder = 4
			New.SetImageKey(starTokensChip.Icon, "ui/status/star_token", T.Accent, "ST")
			starTokensChip.Value.Text = "0"
			starTokensChip.Parent = curRow
		end
	end
	if starTokensChip then
		New.FormatCurrencyChip(starTokensChip, 20)
		refs.StarTokens = starTokensChip:FindFirstChild("Value")
		starTokensChip.Active = true
		starTokensChip.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				HUD.InventoryRequested:Fire("Auras")
			end
		end)
	end
	-- Currency drawer (Figma "Currency HUD Options" 3): Coins + Gems always show; a chevron opens a drawer with
	-- Pearls and Star Tokens; active boosts show as coral chips beside the chevron. It closes by itself after a few seconds.
	do
		local curRow = find("Stats/Currencies")
		local drawer = New("Frame", {
			Name = "Drawer",
			Size = UDim2.fromOffset(0, 0),
			AutomaticSize = Enum.AutomaticSize.XY,
			BackgroundColor3 = T.Panel,
			Visible = false,
			LayoutOrder = 3,
			Parent = top,
			[New.Children] = {
				New.Corner(20),
				New.Stroke(T.Track, 2),
				New("UIPadding", { PaddingLeft = UDim.new(0, 6), PaddingRight = UDim.new(0, 6), PaddingTop = UDim.new(0, 6), PaddingBottom = UDim.new(0, 6) }),
				New("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder, VerticalAlignment = Enum.VerticalAlignment.Center }),
			},
		}) :: Frame
		HUD.Drawer = drawer
		function HUD.AdoptToDrawer(obj: GuiObject, order: number)
			obj.Parent = drawer
			obj.LayoutOrder = order
		end
		if starTokensChip then
			HUD.AdoptToDrawer(starTokensChip, 2)
		end
		-- active boosts: coral chips centred at the bottom of the screen (not hidden in the drawer)
		local boostRow = HUD.BoostRow
		boostRow.Parent = gui
		boostRow.AnchorPoint = Vector2.new(0.5, 1)
		boostRow.Position = UDim2.new(0.5, 0, 1, -10)
		local boostList = boostRow:FindFirstChildOfClass("UIListLayout")
		if boostList then
			boostList.HorizontalAlignment = Enum.HorizontalAlignment.Center
		end

		local more = New("Frame", {
			Name = "More",
			Size = UDim2.fromOffset(34, 34),
			BackgroundColor3 = T.Panel,
			LayoutOrder = 3,
			Parent = curRow,
			[New.Children] = { New.Corner(17), New.Stroke(T.Track, 2) },
		}) :: Frame
		local chevron = New.Image({ Name = "Chevron", Key = "icon_chevron_right", Tint = T.Text, Fallback = T.PanelLight, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(18, 18), Rotation = 90, Parent = more })
		New.ApplyImage(chevron)
		local hit = New("TextButton", { Name = "Hit", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = "", ZIndex = 4, Parent = more })

		local token = 0
		local function setOpen(open: boolean)
			token += 1
			drawer.Visible = open
			chevron.Rotation = if open then -90 else 90
			if open then
				local mine = token
				task.delay(6, function()
					if mine == token then
						setOpen(false)
					end
				end)
			end
		end
		hit.Activated:Connect(function()
			setOpen(not drawer.Visible)
		end)
	end
	notifyHolder = find("Notifications")
	-- toasts draw above every window (Modal 50, DevPanel 60): own ScreenGui on top (Figma 10 Notifications)
	New("ScreenGui", { Name = "Notifications", DisplayOrder = 100, ResetOnSpawn = false, IgnoreGuiInset = false, Parent = gui.Parent })
	notifyHolder.Parent = gui.Parent:FindFirstChild("Notifications")
	local notifLayout = notifyHolder:FindFirstChildOfClass("UIListLayout")
	if notifLayout then
		notifLayout.Padding = UDim.new(0, 8)
	end
	refs.Status = find("Status")
	if not refs.Status:FindFirstChildOfClass("UIPadding") then
		local padding = New.Padding(6)
		padding.PaddingLeft = UDim.new(0, 16)
		padding.PaddingRight = padding.PaddingLeft
		padding.Parent = refs.Status
	end

	refs.Cast = find("CastMobile")
	HUDScreen.StyleCastButton(refs.Cast)
	refs.Cast.Text = "" -- idle state shows the hook icon
	HUD.CastButton = refs.Cast
	HUD.CastCharge = find("CastCharge")
	HUD.PerfectPop = find("PerfectPop")
	local streakHolder = find("StreakHolder")
	-- C12 Hot Streak tag, bottom centre since C25 (was on CAST's corner): x1-4 gold, x5-9 coral, x10 glow;
	-- a snapped line / missed hook shows LOST for 1.5 s; hidden at x0. Server event "Streak".
	do
		local tag = New("Frame", {
			Name = "StreakTag",
			AnchorPoint = Vector2.new(0.5, 1),
			Position = UDim2.fromScale(0.5, 1),
			Size = UDim2.fromOffset(0, 22),
			AutomaticSize = Enum.AutomaticSize.X,
			BackgroundColor3 = T.Gold,
			Visible = false,
			ZIndex = 10,
			Parent = streakHolder,
			[New.Children] = {
				New.Pill(),
				New("UIStroke", { Name = "Ring", Color = Color3.new(1, 1, 1), Thickness = 2 }),
				New("UIPadding", { PaddingLeft = UDim.new(0, 6), PaddingRight = UDim.new(0, 8) }),
				New("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 3), VerticalAlignment = Enum.VerticalAlignment.Center, SortOrder = Enum.SortOrder.LayoutOrder }),
			},
		})
		New.Image({ Name = "Icon", Key = "ui/status/hot_streak", Fallback = T.GoldLip, Size = UDim2.fromOffset(14, 14), LayoutOrder = 1, ZIndex = 11, Parent = tag })
		local text = New("TextLabel", {
			Name = "Text",
			Size = UDim2.fromOffset(0, 18),
			AutomaticSize = Enum.AutomaticSize.X,
			BackgroundTransparency = 1,
			Text = "x1",
			TextColor3 = T.OnAccent,
			FontFace = T.FontBadge,
			TextSize = New.FigmaSize(T.FontBadge, 12),
			LayoutOrder = 2,
			ZIndex = 11,
			Parent = tag,
		})
		New.ApplyImages(tag)
		local ring = tag:FindFirstChild("Ring") :: UIStroke
		local lostToken = 0
		Remotes.Event("Streak").OnClientEvent:Connect(function(info)
			local n = type(info) == "table" and tonumber(info.Streak) or 0
			lostToken += 1
			if type(info) == "table" and info.Lost then
				local mine = lostToken
				tag.BackgroundColor3 = T.Disabled
				text.Text = "LOST"
				ring.Color = Color3.new(1, 1, 1)
				tag.Visible = true
				task.delay(1.5, function()
					if mine == lostToken then
						tag.Visible = false
					end
				end)
				return
			end
			tag.Visible = n ~= nil and n > 0
			if n and n > 0 then
				text.Text = `x{n}`
				tag.BackgroundColor3 = if n >= 10 then T.Bad elseif n >= 5 then T.Accent else T.Gold
				ring.Color = if n >= 10 then T.TintButter else Color3.new(1, 1, 1)
				ring.Thickness = if n >= 10 then 3 else 2
			end
		end)
	end
	refs.DepthValue = find("Actions/Depth/Value")
	HUDScreen.StyleDepthButton(find("Actions/Depth")) -- also upgrades an older baked stepper
	find("Actions/Depth/Hit").Activated:Connect(function()
		CastPopup.Open({
			Get = function()
				return HUD.TargetDepth
			end,
			Max = HUD.MaxDepth,
			Set = HUD.SetDepth,
		})
	end)

	local right = find("Actions")
	refs.Bag = find("Actions/Bag/Value")
	do
		-- the Bag chip is a Frame (CurrencyChip, has a list layout): click it via InputBegan
		local chip = find("Actions/Bag")
		New.FormatCurrencyChip(chip, 20)
		chip.Active = true
		chip.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				HUD.InventoryRequested:Fire()
			end
		end)
		UserInputService.InputBegan:Connect(function(input, processed)
			if not processed and input.KeyCode == Enum.KeyCode.B then
				HUD.InventoryRequested:Fire()
			end
		end)
	end
	refs.Auto = find("Actions/Auto")
	local sell = find("Actions/Sell")
	local autoOn = false
	refs.Auto.Activated:Connect(function()
		if HUD.WaterLocked and not autoOn then
			HUD.Notify("Go to the water to fish", T.Bad)
			return
		end
		autoOn = not autoOn
		HUD.AutoToggled:Fire(autoOn)
	end)
	function HUD.SetAuto(on: boolean)
		autoOn = on
		HUDScreen.SetPlate(refs.Auto, on, T.Good) -- round icon button: the plate colour is the state
	end
	sell.Activated:Connect(function()
		local profile = DataController.Profile
		local stats = DataController.Stats
		-- preview with the same formula the server uses (ShopService.SellAll: fish only)
		local mult = stats and stats.Values.SellMultiplier or 1
		local total, count, mutated = 0, 0, 0
		if profile then
			total, count, mutated = Inventory.SellAllPreview(profile, mult)
		end
		if count == 0 then
			HUD.Notify("No fish to sell", T.Bad)
			return
		end
		Modal.Confirm({
			Title = `Sell all {count} fish?`,
			Message = `You'll get {New.Highlight(Format.Number(total) .. " coins")}.` .. (if mutated > 0 then ` {mutated} fish with mutations are included.` else "")
				.. (function()
					local bonus = profile and Inventory.HotBonus(profile, mult) or 0
					return if bonus > 0 then ` Hot fish bonus {New.Highlight("+" .. Format.Number(bonus), T.BadLip)}.` else ""
				end)(),
			ConfirmText = "Sell",
			ConfirmColor = T.Gold,
			Icon = "ui/status/sell_bag",
			IconColor = T.Gold,
		}, function()
			local ok, msg = Remotes.Func("SellAll"):InvokeServer()
			HUD.Notify(msg, ok and T.Gold or T.Bad)
		end)
	end)

	-- Side menu = the 5 shortcuts that matter while fishing, each with a red dot when something waits:
	--   Bag (new item / full), Shop, Auras (can roll), Quests (reward to claim), Menu = hub (daily login to claim).
	-- Fishdex and the rest live in the hub. Missing tiles / dots are created here so an older bake still works.
	local menu = find("SideMenu")
	local SIDE = { { "Bag", "ui/icons/bag" }, { "Shop", "ui/icons/shop" }, { "Auras", "ui/icons/auras" }, { "Quests", "ui/icons/quests" }, { "Menu", "equipment/StarterPouch", T.TintSky } }
	local old = menu:FindFirstChild("BtnFishdex")
	if old then
		old:Destroy()
	end
	for i, m in SIDE do
		local b = menu:FindFirstChild("Btn" .. m[1])
		if not b then
			b = MakeTile(m[1], m[2], m[3])
			b.Parent = menu
			New.ApplyImages(b)
		end
		b.LayoutOrder = i
		if not b.Tile:FindFirstChild("Dot") then
			New("Frame", {
				Name = "Dot",
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.new(1, -4, 0, 4),
				Size = UDim2.fromOffset(16, 16),
				BackgroundColor3 = T.Bad,
				Visible = false,
				ZIndex = 10,
				Parent = b.Tile,
				[New.Children] = { New.Pill(), New("UIStroke", { Color = Color3.new(1, 1, 1), Thickness = 2 }) },
			})
		end
		refs["Dot" .. m[1]] = b.Tile.Dot
	end
	refs.QuestsTile = menu:FindFirstChild("BtnQuests")
	for _, b in menu:GetChildren() do
		if b:IsA("GuiButton") then
			Components.HookTile(b)
			local name = string.gsub(b.Name, "^Btn", "")
			b.Activated:Connect(function()
				if name == "Menu" then
					HUD.HubRequested:Fire()
				elseif name == "Bag" then
					HUD.InventoryRequested:Fire()
				elseif name == "Quests" then
					HUD.QuestsRequested:Fire()
				elseif name == "Auras" then
					HUD.BannerRequested:Fire("Altar")
				else
					HUD.MenuRequested:Fire(name)
				end
			end)
		end
	end

	-- Responsive layout ---------------------------------------------------------------
	-- Every cluster keeps its corner anchor and gets a UIScale from the real screen size.
	-- Fishing controls only near fishable water: mobile CAST and AUTO hide on land (depth stepper stays).
	-- Stay visible while a cast is in progress or AUTO is on (so it can be turned off).
	local function updateWaterControls()
		local char = player.Character
		local root = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
		HUD.NearWater = root ~= nil and FishingSpot.NearWater(root)
		local show = HUD.NearWater or HUD.FishingActive or autoOn
		-- away from water the buttons stay, locked (HUD.WaterLocked tells the press handlers why nothing happens)
		HUD.WaterLocked = not show
		refs.Cast.Visible = UserInputService.TouchEnabled
		refs.Auto.Visible = true
		HUDScreen.SetLocked(refs.Cast, not show)
		HUDScreen.SetLocked(refs.Auto, not show)
	end
	updateWaterControls()
	task.spawn(function()
		while gui.Parent do
			task.wait(0.3)
			updateWaterControls()
		end
	end)

	-- Short screens (landscape phones): the side menu becomes a row at the top-right
	-- (bottom-left = mobile thumbstick; Roblox hides the leaderboard on phones).
	local clusters = { top, menu, refs.Cast, refs.Status, HUD.CastCharge, HUD.PerfectPop, streakHolder, HUD.BoostRow }
	local scales = {}
	for _, c in clusters do
		scales[c] = c:FindFirstChild("Scale") or New("UIScale", { Name = "Scale", Parent = c })
	end
	local menuList = menu:FindFirstChildOfClass("UIListLayout")
	local function layout()
		local size = gui.AbsoluteSize
		if size.X <= 0 or size.Y <= 0 then
			return
		end
		local compact = size.Y < 500
		local scale = math.clamp(math.min(size.Y / 620, size.X / 1100), 0.6, 1)
		for _, c in clusters do
			scales[c].Scale = scale
		end
		HUD.Compact = compact
		HUD.Scale = scale
		-- side menu: vertical column under the stats (PC) / horizontal row top-right (phone)
		local count = 0
		for _, b in menu:GetChildren() do
			if b:IsA("GuiButton") and b.Visible then
				count += 1
			end
		end
		if compact then
			menuList.FillDirection = Enum.FillDirection.Horizontal
			menu.AnchorPoint = Vector2.new(1, 0)
			menu.Position = UDim2.new(1, -12, 0, 8)
			menu.Size = UDim2.fromOffset(count * 80 + (count - 1) * 10, 88)
		else
			menuList.FillDirection = Enum.FillDirection.Vertical
			-- left side, centred in the free space under the level / currency chips (about 160 design px tall) and
			-- shrunk to fit it, so on short screens (720p) it neither runs off the bottom nor covers the chips
			local menuHeight = count * 88 + (count - 1) * 10
			local freeTop = math.floor(165 * scale)
			local freeHeight = math.max(120, size.Y - freeTop - 12)
			menu.AnchorPoint = Vector2.new(0, 0.5)
			menu.Position = UDim2.new(0, 12, 0, freeTop + math.floor(freeHeight / 2))
			menu.Size = UDim2.fromOffset(80, menuHeight)
			scales[menu].Scale = math.min(scale, freeHeight / math.max(1, menuHeight))
		end
		HUDScreen.LayoutFishingDock(right, size, UserInputService.TouchEnabled, scale)
		-- bottom centre, bottom to top: boost chips, hot streak tag, status pill
		streakHolder.Position = UDim2.new(0.5, 0, 1, -math.floor(44 * scale))
		refs.Status.Position = UDim2.new(0.5, 0, 1, -math.floor(70 * scale) - 16 - math.floor(20 * scale))
		-- mobile CAST: left of and slightly above the Roblox jump button (Figma HUD 3760:5656)
		refs.Cast.Position = UDim2.new(1, -math.floor(172 * scale), 1, -math.floor(78 * scale))
	end
	gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(layout)
	task.defer(layout)

	-- Data binding
	DataController.Observe(function(profile, stats)
		refreshBoosts(profile)
		local need = Registry.GameConfig.XPForLevel(profile.Level)
		refs.Level.Text = `Lv.{profile.Level}`
		refs.XPText.Text = `{Format.Number(profile.XP)} / {Format.Number(need)} XP`
		refs.Coins.Text = Format.Number(profile.Coins)
		refs.Gems.Text = Format.Number(profile.Gems)
		if refs.StarTokens then
			local st = profile.Auras and profile.Auras.StarTokens or 0
			refs.StarTokens.Text = Format.Number(st)
		end
		local cap = Inventory.Capacity(profile)
		local used = Inventory.Used(profile)
		refs.Bag.Text = if Inventory.IsInfinite(profile) then `{used} / Inf` else `{used} / {cap}` -- Infinite Bag: "Inf", same as the Inventory pill
		refs.Bag.TextColor3 = if Inventory.IsFull(profile) then T.Bad else T.Text
		HUD.RefreshDepthButton()
		HUD.RefreshDots(profile)
	end)

	-- Studio only: lets a test script open any menu (ReplicatedStorage.UITest:Invoke("Inventory")) to measure it
	if game:GetService("RunService"):IsStudio() then
		local bf = Instance.new("BindableFunction")
		bf.Name = "UITest"
		bf.OnInvoke = function(name: string)
			local fire = {
				Inventory = function() HUD.InventoryRequested:Fire() end,
				Character = function() HUD.CharacterRequested:Fire() end,
				Shop = function() HUD.MenuRequested:Fire("Shop") end,
				Fishdex = function() HUD.MenuRequested:Fire("Fishdex") end,
				Auras = function() HUD.MenuRequested:Fire("Auras") end,
				Store = function() HUD.StoreRequested:Fire() end,
				Aquarium = function() HUD.AquariumRequested:Fire() end,
				Mastery = function() HUD.MasteryRequested:Fire() end,
				Quests = function() HUD.QuestsRequested:Fire() end,
				Events = function() HUD.EventsRequested:Fire() end,
				DailyLogin = function() HUD.DailyLoginRequested:Fire() end,
				Skills = function() HUD.SkillsRequested:Fire() end,
				Hub = function() HUD.HubRequested:Fire() end,
				Altar = function() HUD.BannerRequested:Fire("Altar") end,
			}
			if fire[name] then
				fire[name]()
			end
		end
		bf.Parent = game:GetService("ReplicatedStorage")
	end

	Remotes.Event("Notify").OnClientEvent:Connect(function(text, color)
		HUD.Notify(text, color)
	end)
	Remotes.Event("CatchResult").OnClientEvent:Connect(function(result)
		HUD.ShowCatch(result)
	end)
end

-- Red dots on the side menu shortcuts (what is waiting for the player).
function HUD.RefreshDots(profile: any)
	local function set(name: string, on: boolean)
		local d = refs["Dot" .. name]
		if d then
			d.Visible = on
		end
	end
	local newItem = false
	for _, s in profile.Bag do
		if s.New then
			newItem = true
			break
		end
	end
	set("Bag", newItem or Inventory.IsFull(profile))
	set("Auras", profile[Registry.GameConfig.AuraRollCurrency] >= Registry.GameConfig.AuraRollCost)
	local questsOn = Registry.Features.Quests.Enabled
	if refs.QuestsTile then
		refs.QuestsTile.Visible = questsOn
	end
	set("Quests", questsOn and profile.Quests ~= nil and profile.Quests.Unclaimed == true)
	local canClaimDaily = DailyLogin.GetState(profile).CanClaim
	set("Daily", canClaimDaily)
	-- the Daily pill only shows while today's check-in is unclaimed
	local dailyBtn = refs.DotDaily and refs.DotDaily.Parent
	if dailyBtn then
		dailyBtn.Visible = canClaimDaily
	end
end

return HUD
