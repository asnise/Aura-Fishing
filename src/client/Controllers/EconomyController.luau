--!nonstrict
-- Economy screens built in code (placeholders until Figma designs land; data contract in
-- docs/HANDOFF_ECONOMY_UI.md):
--   HUD    Pearls chip next to Coins/Gems (live count-up, tap -> Aquarium); tap Gems / Coins -> Store
--   Aquarium window   UI/AquariumScreen (Figma Economy 2): tank fish, add, remove, expand; MASTERY button
--   Put in Tank       own window: 4:3 cards, multi-select, CONFIRM once (C14)
--   Mastery           UI/MasteryScreen (Figma Economy 3): 7 permanent upgrades paid with Pearls (C15)
--   Store window      Passes / Gems / Boosts & Packs (C13/C6/C19; real Robux prices from Roblox)
--   Offline popup     OfflineReward (Pearls earned while away)

local _MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Registry = require(Shared.Registry)
local Remotes = require(Shared.Remotes)
local Format = require(Shared.Util.Format)
local Aquarium = require(Shared.Aquarium)
local _Boosts = require(Shared.Boosts)

local New = require(script.Parent.Parent.UI.New)
local Window = require(script.Parent.Parent.UI.Window)
local AquariumScreen = require(script.Parent.Parent.UI.AquariumScreen)
local MasteryScreen = require(script.Parent.Parent.UI.MasteryScreen)
local StoreScreen = require(script.Parent.Parent.UI.StoreScreen)
local Components = require(script.Parent.Parent.UI.Components)
local VirtualGrid = require(script.Parent.Parent.UI.VirtualGrid)
local TankQuantity = require(script.Parent.Parent.UI.TankQuantity)
local Modal = require(script.Parent.Parent.UI.Modal)
local HUD = require(script.Parent.HUDController)
local DataController = require(script.Parent.DataController)

local T = New.Theme
local _Products = Registry.Products

local EconomyController = {}

local profile: any = nil
local syncedAt = os.clock()
local pearlsChip: any = nil
local aquarium: any = nil
local store: any = nil

local function notify(ok: boolean, msg: string?)
	if msg and msg ~= "" then
		HUD.Notify(msg, if ok then T.GoodLip else T.Bad)
	end
end

local function pearlsNow(): number
	if not profile then
		return 0
	end
	local rate = Aquarium.CurrentRate(profile, DataController.Stats)
	return profile.Pearls + rate * (os.clock() - syncedAt) / 60
end

local function _rarityColor(fishId: string): Color3
	local f = Registry.Fish[fishId]
	return if f then Registry.Rarities[f.Rarity].Color else T.Track
end

local function fishName(id: string, mutation: string?): string
	local f = Registry.Fish[id]
	local name = if f then f.Name else id
	local m = mutation and Registry.Mutations[mutation]
	return if m then `{m.Name} {name}` else name
end

-- HUD -------------------------------------------------------------------------

-- Chips are Frames inside a UIListLayout (a button child would be laid out as an item) and the HUD
-- Notifications frame sits above them, so: a transparent button at ScreenGui level that follows the
-- chip's on-screen rectangle.
local function clickable(chip: GuiObject, onClick: () -> ())
	local gui = chip:FindFirstAncestorWhichIsA("ScreenGui")
	local hit = New("TextButton", {
		Name = "Hit_" .. chip.Name,
		BackgroundTransparency = 1,
		Text = "",
		ZIndex = 50,
		Parent = gui,
	})
	hit.Activated:Connect(onClick)
	local function follow()
		-- AbsolutePosition is in the same space as the ScreenGui's own children
		hit.Position = UDim2.fromOffset(chip.AbsolutePosition.X, chip.AbsolutePosition.Y)
		hit.Size = UDim2.fromOffset(chip.AbsoluteSize.X, chip.AbsoluteSize.Y)
		hit.Visible = chip.Visible
	end
	chip:GetPropertyChangedSignal("AbsolutePosition"):Connect(follow)
	chip:GetPropertyChangedSignal("AbsoluteSize"):Connect(follow)
	follow()
end

local function buildHud()
	local gui = HUD.Gui
	local row = gui and gui:FindFirstChild("Currencies", true)
	if not row then
		warn("[Economy] HUD Currencies row not found")
		return
	end
	pearlsChip = Components.Clone("CurrencyChip")
	pearlsChip.Name = "Pearls"
	pearlsChip.LayoutOrder = 3
	New.SetImageKey(pearlsChip.Icon, "ui/status/pearl", T.Sky, "P")
	pearlsChip.Value.Text = "0"
	New("TextLabel", {
		Name = "Rate",
		Size = UDim2.fromOffset(0, 26),
		AutomaticSize = Enum.AutomaticSize.X,
		BackgroundTransparency = 1,
		Text = "+0/s",
		TextColor3 = T.GoodLip,
		FontFace = T.FontBadge,
		TextSize = New.FigmaSize(T.FontBadge, 12),
		LayoutOrder = 3,
		Parent = pearlsChip,
	})
	HUD.AdoptToDrawer(pearlsChip, 1) -- Pearls live in the currency drawer, not in the always-visible row
	New.FormatCurrencyChip(pearlsChip, 20)
	clickable(pearlsChip, function()
		EconomyController.OpenAquarium()
	end)

	-- no Store button: tap a currency chip (Gems -> Gems tab, Coins -> Boosts & Packs)
	local gems = row:FindFirstChild("Gems")
	if gems then
		clickable(gems, function()
			store.Open("Gems")
		end)
	end
	local coins = row:FindFirstChild("Coins")
	if coins then
		clickable(coins, function()
			store.Open("Boosts")
		end)
	end
	local starTokens = gui and gui:FindFirstChild("StarTokens", true) -- moved into the drawer
	if starTokens then
		clickable(starTokens, function()
			HUD.InventoryRequested:Fire("Auras")
		end)
	end
end

-- AQUARIUM (Figma "Economy · 2 Aquarium" → UI/AquariumScreen) ------------------------------

local tankAction = false
local function invoke(name: string, ...): any
	if tankAction then
		return nil
	end
	tankAction = true
	local ok, res = pcall(function(...)
		return Remotes.Func(name):InvokeServer(...)
	end, ...)
	tankAction = false
	if not ok then
		notify(false, "Something went wrong, try again")
		return nil
	end
	return res
end

local picker: any = nil
local masteryWin: any = nil

-- Put in Tank: a single fish toggles directly; stacks use the C14 quantity modal.
local selection: { [string]: number? } = {}
local renderPicker: () -> () -- defined below (cards call it back)
local quantity: any = nil
local quantityKey: string? = nil
local pickerFromBag = false

local function selectedTotal(): number
	local n = 0
	for _, v in selection do
		n += v
	end
	return n
end

-- Cards are virtualized (UI/VirtualGrid, nested in the Window body): pooled card views, only the visible
-- rows exist; a tap / MAX only rebinds the visible cards instead of rebuilding the whole body.
local pickerUI: any = nil -- { Bar, Empty, Grid, Refs = { [card]: parts } }

local function pickFish(it: any)
	if it.MaxPick <= 0 and it.Mine == 0 then
		notify(false, "Your tank is full - unlock more slots")
	elseif it.G.Count > 1 then
		local g = it.G
		quantityKey = it.Key
		quantity.Open(it, fishName(g.Id, g.Mutation), _rarityColor(g.Id), function(count)
			selection[it.Key] = if count > 0 then count else nil
			renderPicker()
		end)
	else
		selection[it.Key] = if it.Mine > 0 then nil else 1
		renderPicker()
	end
end

local function pickerStatus(r: any, it: any)
	if it.Picked then
		local multi = it.G.Count > 1
		r.Status.Text = if multi then `{it.Mine} / {it.G.Count}` else "SELECTED"
		r.Status.BackgroundColor3 = if multi then T.Accent else T.Good
		r.Status.TextColor3 = T.OnAccent
		r.StatusStroke.Enabled = false
	else
		r.Status.Text = "+ Select"
		r.Status.BackgroundColor3 = Color3.new(1, 1, 1)
		r.Status.TextColor3 = T.SubText
		r.StatusStroke.Enabled = true
	end
end

local function createPickerCard(): GuiObject
	local refs: any = {}
	local card = New("TextButton", {
		Name = "Card",
		BackgroundColor3 = T.Panel,
		AutoButtonColor = false,
		Text = "",
		[New.Children] = { New.Corner(T.RadiusCard) },
	})
	refs.Stroke = New("UIStroke", { Color = T.Track, Thickness = 2, ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Parent = card })

	-- Picture box (Figma F4FAFD soft water fill)
	local pic = New("Frame", {
		Name = "Picture",
		Position = UDim2.fromOffset(10, 10),
		Size = UDim2.new(1, -20, 0, 70),
		BackgroundColor3 = Color3.fromRGB(244, 250, 253),
		BorderSizePixel = 0,
		Parent = card,
		[New.Children] = { New.Corner(12) },
	})
	refs.Icon = New.Image({
		Name = "Icon",
		Key = "fish/PebbleMinnow",
		Fallback = T.PanelLight,
		FallbackText = "?",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(88, 58),
		Parent = pic,
	})
	refs.Mutation = New.Image({
		Name = "Mutation",
		Key = "",
		Fallback = T.Good,
		Position = UDim2.fromOffset(6, 6),
		Size = UDim2.fromOffset(22, 22),
		Visible = false,
		Parent = pic,
	})

	-- Fish Name
	refs.Name = New.Title({
		Name = "Name",
		Position = UDim2.fromOffset(10, 84),
		Size = UDim2.new(1, -20, 0, 20),
		Text = "",
		TextXAlignment = Enum.TextXAlignment.Left,
		MaxTextSize = 16,
		Parent = card,
	})

	-- Meta Row: [RARITY TAG] + [+RATE/s PILL]
	local meta = New("Frame", {
		Name = "Meta",
		Position = UDim2.fromOffset(10, 107),
		Size = UDim2.new(1, -20, 0, 22),
		BackgroundTransparency = 1,
		Parent = card,
		[New.Children] = {
			New("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 6), VerticalAlignment = Enum.VerticalAlignment.Center, SortOrder = Enum.SortOrder.LayoutOrder }),
		},
	})
	refs.Rarity = New("TextLabel", {
		Name = "RarityTag",
		LayoutOrder = 1,
		Size = UDim2.fromOffset(0, 20),
		AutomaticSize = Enum.AutomaticSize.X,
		BackgroundColor3 = T.Track,
		Text = "",
		TextColor3 = T.OnAccent,
		FontFace = T.FontBadge,
		TextSize = 11,
		Parent = meta,
		[New.Children] = { New.Pill(), New("UIPadding", { PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 12) }) },
	})
	local ratePill = New("Frame", {
		Name = "RatePill",
		LayoutOrder = 2,
		Size = UDim2.fromOffset(0, 20),
		AutomaticSize = Enum.AutomaticSize.X,
		BackgroundColor3 = T.PanelLight,
		Parent = meta,
		[New.Children] = {
			New.Pill(),
			New("UIPadding", { PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 12) }),
			New("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 4), VerticalAlignment = Enum.VerticalAlignment.Center, SortOrder = Enum.SortOrder.LayoutOrder }),
		},
	})
	New.Image({ Name = "PearlIcon", Key = "ui/status/pearl", LayoutOrder = 1, Size = UDim2.fromOffset(12, 12), Parent = ratePill })
	refs.Rate = New("TextLabel", {
		Name = "RateValue",
		LayoutOrder = 2,
		Size = UDim2.new(0, 0, 1, 0),
		AutomaticSize = Enum.AutomaticSize.X,
		BackgroundTransparency = 1,
		Text = "",
		TextColor3 = T.Good,
		FontFace = T.FontBadge,
		TextSize = 11,
		Parent = ratePill,
	})

	-- Action Row (matching Fishdex Record row): [ In Bag: xN ]  [ Action / Status ]  [ MAX ]
	local actRow = New("Frame", {
		Name = "ActionRow",
		Position = UDim2.fromOffset(10, 134),
		Size = UDim2.new(1, -20, 0, 24),
		BackgroundTransparency = 1,
		Parent = card,
		[New.Children] = {
			New("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 6), VerticalAlignment = Enum.VerticalAlignment.Center, SortOrder = Enum.SortOrder.LayoutOrder }),
		},
	})
	refs.Bag = New("TextLabel", {
		Name = "Bag",
		LayoutOrder = 1,
		Size = UDim2.fromOffset(0, 22),
		AutomaticSize = Enum.AutomaticSize.X,
		BackgroundColor3 = T.PanelLight,
		Text = "",
		TextColor3 = T.Text,
		FontFace = T.FontBadge,
		TextSize = 11,
		Parent = actRow,
		[New.Children] = { New.Pill(), New("UIPadding", { PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 12) }) },
	})
	refs.Status = New("TextLabel", {
		Name = "Status",
		LayoutOrder = 2,
		Size = UDim2.fromOffset(0, 22),
		AutomaticSize = Enum.AutomaticSize.X,
		BackgroundColor3 = Color3.new(1, 1, 1),
		Text = "+ Select",
		TextColor3 = T.SubText,
		FontFace = T.FontBadge,
		TextSize = 11,
		Parent = actRow,
		[New.Children] = { New.Pill(), New("UIPadding", { PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10) }) },
	})
	refs.StatusStroke = New.Stroke(T.Track, 1.5)
	refs.StatusStroke.Parent = refs.Status
	refs.Max = New.Button({
		Name = "Max",
		LayoutOrder = 3,
		Size = UDim2.fromOffset(42, 22),
		Text = "MAX",
		BackgroundColor3 = T.PanelLight,
		MaxTextSize = 11,
		Parent = actRow,
	})

	pickerUI.Refs[card] = refs
	refs.Max.Activated:Connect(function()
		local it = pickerUI.Grid:ItemOf(card)
		if not it then
			return
		end
		if it.Mine >= it.MaxPick and it.Mine > 0 then
			selection[it.Key] = nil
		elseif it.MaxPick > 0 then
			selection[it.Key] = it.MaxPick
		else
			notify(false, "Your tank is full - unlock more slots")
		end
		renderPicker()
	end)
	card.Activated:Connect(function()
		local it = pickerUI.Grid:ItemOf(card)
		if it then
			pickFish(it)
		end
	end)
	return card
end

local function bindPickerCard(card: any, it: any)
	local r = pickerUI.Refs[card]
	local g = it.G
	local f = Registry.Fish[g.Id]
	local rarity = f and Registry.Rarities[f.Rarity]
	card.Name = "Card " .. it.Key
	r.Stroke.Color = if it.Picked then T.Accent else T.Track
	r.Stroke.Thickness = if it.Picked then 3 else 2
	New.SetImageKey(r.Icon, "fish/" .. g.Id, T.PanelLight, "?")
	local mut = g.Mutation and Registry.Mutations[g.Mutation]
	r.Mutation.Visible = g.Mutation ~= nil
	if g.Mutation then
		New.SetImageKey(r.Mutation, "fish/mut_" .. string.lower(g.Mutation), if mut then mut.Color else T.Good)
	end
	r.Name.Text = fishName(g.Id, g.Mutation)
	r.Rarity.Text = if rarity then string.upper(rarity.Name) else "COMMON"
	r.Rarity.BackgroundColor3 = if rarity then rarity.Color else T.Track
	r.Rate.Text = Aquarium.FormatRate(it.RatePer)
	r.Bag.Text = `In Bag: x{g.Count}`
	pickerStatus(r, it)
	r.Max.Visible = g.Count > 1
	r.Max.Text = if it.Mine >= it.MaxPick and it.Mine > 0 then "CLR" else "MAX"
end

local function ensurePickerUI()
	local body = picker.Body
	if pickerUI and pickerUI.Grid.Content.Parent and pickerUI.Bar.Parent == body then
		return
	end
	Window.Clear(body)
	Window.List(body, 12)
	pickerUI = { Refs = {} }
	pickerUI.Bar = New("Frame", { Name = "Bar", LayoutOrder = 0, Size = UDim2.new(1, 0, 0, 48), BackgroundTransparency = 1, Parent = body })
	pickerUI.Empty = New.Text({ Name = "Empty", LayoutOrder = 1, Size = UDim2.new(1, 0, 0, 40), Text = "No fish in your bag. Go catch some!", TextColor3 = T.SubText, MaxTextSize = 18, Visible = false, Parent = body })
	local holder = New("Frame", { Name = "Cards", LayoutOrder = 2, Size = UDim2.new(1, 0, 0, 0), BackgroundTransparency = 1, Parent = body })
	pickerUI.Grid = VirtualGrid.new(holder, {
		CellSize = Vector2.new(220, 165), -- 4:3 matching Fishdex
		Gap = Vector2.new(12, 12),
		Create = createPickerCard,
		Bind = function(card, it)
			bindPickerCard(card, it)
		end,
	})
end

renderPicker = function()
	ensurePickerUI()
	local free = Aquarium.Free(profile)
	-- bag fish grouped by species + mutation
	local groups, order = {}, {}
	for _, s in profile.Bag do
		if s.Kind == "Fish" then
			local key = s.Id .. "|" .. (s.Mutation or "")
			if not groups[key] then
				groups[key] = { Key = key, Id = s.Id, Mutation = s.Mutation, Count = 0 }
				table.insert(order, key)
			end
			groups[key].Count += 1 -- fish never stack: one bag item = one fish
		end
	end
	table.sort(order, function(a, b)
		return Aquarium.FishRate(groups[a].Id, groups[a].Mutation, 1) > Aquarium.FishRate(groups[b].Id, groups[b].Mutation, 1)
	end)
	-- drop selections that no longer exist / exceed what is in the bag
	for key, n in selection do
		local g = groups[key]
		selection[key] = if g then math.min(n, g.Count) else nil
	end

	local total = selectedTotal()
	local pr = DataController.Stats and DataController.Stats.Values.PearlRate or 1
	local totalRate = 0
	for _, key in order do
		local n = selection[key]
		if n and n > 0 then
			totalRate += Aquarium.FishRate(groups[key].Id, groups[key].Mutation, pr) * n
		end
	end

	-- top bar: back  -  "n selected (+rate/s) / free"  -  confirm (3 instances: rebuilt, the cards are not)
	local bar = pickerUI.Bar
	bar:ClearAllChildren()
	local back = New.Button({ Name = "Back", Size = UDim2.fromOffset(140, 46), Text = if pickerFromBag then "< Bag" else "< Tank", BackgroundColor3 = T.Sky, MaxTextSize = 18, Parent = bar })
	back.Activated:Connect(function()
		table.clear(selection)
		picker.Close() -- stacked on the Aquarium: closing shows the tank again
	end)
	local rateText = if total > 0 then ` ({Aquarium.FormatRate(totalRate)})` else ""
	New.Text({
		Name = "Count",
		Position = UDim2.fromOffset(150, 0),
		Size = UDim2.new(1, -340, 1, 0),
		Text = `<b>{total}</b> selected{rateText} | {math.max(0, free - total)}/{free}`,
		RichText = true,
		TextColor3 = if total > free then T.Bad else T.SubText,
		MaxTextSize = 18,
		Parent = bar,
	})
	local isFull = (free == 0) or (total > free)
	local confirmText = if isFull then "Full" else `CONFIRM ({total})`
	local confirm = New.Button({
		Name = "Confirm",
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.fromScale(1, 0),
		Size = UDim2.fromOffset(180, 46),
		Text = confirmText,
		BackgroundColor3 = T.Good,
		MaxTextSize = 20,
		Parent = bar,
	})
	if total == 0 or isFull then
		New.SetButtonColor(confirm, T.Disabled, T.DisabledText)
	else
		confirm.Activated:Connect(function()
			local list = {}
			for _, key in order do
				local n = selection[key]
				if n and n > 0 then
					table.insert(list, { Id = groups[key].Id, Mutation = groups[key].Mutation, Count = n })
				end
			end
			local res = invoke("PutInTank", list)
			if res then
				notify(res.ok, if res.ok then `Added {total} fish to your tank` else res.reason)
				if res.ok then
					table.clear(selection)
					picker.Close()
				end
			end
		end)
	end

	pickerUI.Empty.Visible = #order == 0
	local items = table.create(#order)
	local byKey = {}
	for _, key in order do
		local g = groups[key]
		local mine = selection[key] or 0
		local room = math.max(0, free - (total - mine))
		local item = {
			Key = key,
			G = g,
			Mine = mine,
			MaxPick = math.min(g.Count, room),
			Room = room,
			Picked = mine > 0,
			RatePer = Aquarium.FishRate(g.Id, g.Mutation, pr),
		}
		table.insert(items, item)
		byKey[key] = item
	end
	pickerUI.ByKey = byKey
	pickerUI.Grid:SetItems(items)
	if quantity.IsOpen() then
		local item = quantityKey and byKey[quantityKey]
		if item then
			quantity.Refresh(item)
		else
			quantity.Close()
		end
	end
end

-- AQUARIUM: Mastery (Figma "Economy · 3 Mastery" → UI/MasteryScreen) ------------------------

local function renderMastery()
	masteryWin.Render(profile, pearlsNow())
end

local function upgradeMastery(t: any)
	local res = invoke("UpgradeMastery", t.Id)
	if res then
		notify(res.ok, if res.ok then `{t.Name} Lv.{t.Level + 1}!` else res.reason)
	end
end

local function renderAquarium()
	if not profile then
		return
	end
	if aquarium and aquarium.IsOpen() then
		aquarium.Render(profile, DataController.Stats)
	end
	if picker and picker.IsOpen() then
		renderPicker()
	end
	if masteryWin and masteryWin.IsOpen() then
		renderMastery()
	end
end

-- OFFLINE POPUP --------------------------------------------------------------------

local function offlinePopup(info: any)
	local player = Players.LocalPlayer
	local playerGui = player and player:FindFirstChild("PlayerGui")
	if not playerGui then
		return
	end

	local oldGui = playerGui:FindFirstChild("OfflineRewardGui")
	if oldGui then
		oldGui:Destroy()
	end

	local secs = info.Seconds or info.Credited or 0
	local h, m = math.floor(secs / 3600), math.floor((secs % 3600) / 60)
	local timeStr = if h > 0 then `{h}h {m}m` else `{m}m`
	local awayLabel = if info.Capped
		then `Away {timeStr} | capped at {info.CapHours or 4}h`
		else `Away {timeStr}`

	local isCapped = info.Capped == true
	local cardWidth = 520
	local cardHeight = if isCapped then 431 else 397

	local gui = New("ScreenGui", {
		Name = "OfflineRewardGui",
		ResetOnSpawn = false,
		DisplayOrder = 20,
		IgnoreGuiInset = true,
		Parent = playerGui,
	})

	local dim = New("TextButton", {
		Name = "Dim",
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color3.new(0, 0, 0),
		BackgroundTransparency = 0.5,
		Text = "",
		AutoButtonColor = false,
		BorderSizePixel = 0,
		Parent = gui,
	})

	local card = New.Panel({
		Name = "Modal",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(cardWidth, cardHeight),
		Radius = 36,
		Clip = true, -- sand footer follows the rounded bottom corners
		Parent = dim,
	})
	card.Active = true
	New.FitToScreen(card, 24)

	local body = New("Frame", {
		Name = "Body",
		Size = UDim2.new(1, 0, 0, if isCapped then 334 else 300),
		BackgroundTransparency = 1,
		Parent = card,
	})
	New("UIListLayout", {
		FillDirection = Enum.FillDirection.Vertical,
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(0, 10),
		Parent = body,
	})
	New("UIPadding", {
		PaddingTop = UDim.new(0, 34),
		PaddingBottom = UDim.new(0, 26),
		PaddingLeft = UDim.new(0, 40),
		PaddingRight = UDim.new(0, 40),
		Parent = body,
	})

	-- 1. Image
	New.Image({
		Name = "Img ui/status/offline_reward",
		Key = "ui/status/offline_reward",
		Size = UDim2.fromOffset(110, 110),
		LayoutOrder = 1,
		Parent = body,
	})

	-- 2. Title
	New.Title({
		Name = "Title",
		Size = UDim2.new(1, 0, 0, 30),
		Text = "While you were away",
		TextSize = 26,
		TextColor3 = T.Text,
		TextXAlignment = Enum.TextXAlignment.Center,
		LayoutOrder = 2,
		Parent = body,
	})

	-- 3. Away text
	New.Text({
		Name = "Away",
		Size = UDim2.new(1, 0, 0, 22),
		Text = awayLabel,
		TextSize = 16,
		TextColor3 = T.SubText,
		TextXAlignment = Enum.TextXAlignment.Center,
		LayoutOrder = 3,
		Parent = body,
	})

	-- 4. Amount row (Pearl icon + Value)
	local amountRow = New("Frame", {
		Name = "Amount",
		Size = UDim2.new(1, 0, 0, 48),
		BackgroundTransparency = 1,
		LayoutOrder = 4,
		Parent = body,
	})
	New("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
		VerticalAlignment = Enum.VerticalAlignment.Center,
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(0, 8),
		Parent = amountRow,
	})
	New.Image({
		Name = "Img ui/status/pearl",
		Key = "ui/status/pearl",
		Size = UDim2.fromOffset(40, 40),
		LayoutOrder = 1,
		Parent = amountRow,
	})
	New.Text({
		Name = "Value",
		Size = UDim2.new(0, 0, 1, 0),
		AutomaticSize = Enum.AutomaticSize.X,
		Text = `+{Format.Number(info.Pearls or 0)}`,
		TextSize = 38,
		TextColor3 = Color3.fromHex("8C6FD6"),
		FontFace = T.Font,
		TextXAlignment = Enum.TextXAlignment.Left,
		LayoutOrder = 2,
		Parent = amountRow,
	})

	-- 5. Cap Info Pill (if capped)
	if isCapped then
		local pill = New("Frame", {
			Name = "CapPill",
			Size = UDim2.fromOffset(0, 24),
			AutomaticSize = Enum.AutomaticSize.X,
			BackgroundColor3 = T.PanelLight,
			BorderSizePixel = 0,
			LayoutOrder = 5,
			Parent = body,
		})
		New.Corner(999).Parent = pill
		New("UIPadding", {
			PaddingTop = UDim.new(0, 4),
			PaddingBottom = UDim.new(0, 4),
			PaddingLeft = UDim.new(0, 10),
			PaddingRight = UDim.new(0, 12),
			Parent = pill,
		})
		New("UIListLayout", {
			FillDirection = Enum.FillDirection.Horizontal,
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
			VerticalAlignment = Enum.VerticalAlignment.Center,
			SortOrder = Enum.SortOrder.LayoutOrder,
			Padding = UDim.new(0, 6),
			Parent = pill,
		})
		New.Image({
			Name = "Icon",
			Key = "icon_info",
			Size = UDim2.fromOffset(14, 14),
			ImageColor3 = Color3.fromHex("CC5454"),
			LayoutOrder = 1,
			Parent = pill,
		})
		New.Text({
			Name = "Label",
			Size = UDim2.new(0, 0, 1, 0),
			AutomaticSize = Enum.AutomaticSize.X,
			Text = "Cap full - raise it in Mastery or with VIP (12h)",
			TextSize = 12,
			FontFace = T.FontBadge,
			TextColor3 = Color3.fromHex("CC5454"),
			LayoutOrder = 2,
			Parent = pill,
		})
	end

	-- Footer (Bottom section)
	local footer = New("Frame", {
		Name = "Footer",
		Size = UDim2.new(1, 0, 0, 94),
		Position = UDim2.new(0, 0, 1, -94),
		BackgroundColor3 = T.PanelLight,
		BorderSizePixel = 0,
		Parent = card,
	})
	New("UIPadding", {
		PaddingTop = UDim.new(0, 16),
		PaddingBottom = UDim.new(0, 20),
		PaddingLeft = UDim.new(0, 32),
		PaddingRight = UDim.new(0, 32),
		Parent = footer,
	})
	New("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
		VerticalAlignment = Enum.VerticalAlignment.Center,
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(0, 16),
		Parent = footer,
	})

	local p = profile or DataController.Profile
	local hasBoost = (info.BoostPearls or 0) > 0 or (p and p.Boosts and (p.Boosts.Pearls or 0) > os.time())

	local collectBtn = New.Button({
		Name = "BtnCollect",
		Size = UDim2.fromOffset(354, 54),
		Text = "COLLECT",
		BackgroundColor3 = T.Good,
		TextSize = 22,
		TextColor3 = Color3.new(1, 1, 1),
		Radius = 16,
		Parent = footer,
	})
	collectBtn.Activated:Connect(function()
		gui:Destroy()
	end)

	local boostBtn = New.Button({
		Name = "BtnCollectX2",
		Size = UDim2.fromOffset(82, 54),
		Text = "",
		BackgroundColor3 = Color3.fromHex("B79CF2"),
		Radius = 16,
		Parent = footer,
	})
	local face = boostBtn:FindFirstChild("Face")
	if face then
		local _content = New("Frame", {
			Name = "Content",
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			ZIndex = 2,
			Parent = face,
			[New.Children] = {
				New("UIListLayout", {
					FillDirection = Enum.FillDirection.Horizontal,
					HorizontalAlignment = Enum.HorizontalAlignment.Center,
					VerticalAlignment = Enum.VerticalAlignment.Center,
					SortOrder = Enum.SortOrder.LayoutOrder,
					Padding = UDim.new(0, 4),
				}),
				New.Title({
					Name = "Label",
					Size = UDim2.new(0, 0, 1, 0),
					AutomaticSize = Enum.AutomaticSize.X,
					Text = "x2",
					TextSize = 20,
					TextColor3 = Color3.new(1, 1, 1),
					LayoutOrder = 1,
					ZIndex = 3,
				}),
				New.Image({
					Name = "Icon",
					Key = "ui/shop/boost_pearls",
					Size = UDim2.fromOffset(24, 24),
					LayoutOrder = 2,
					ZIndex = 3,
				}),
			},
		})
	end
	boostBtn.Activated:Connect(function()
		if not hasBoost then
			Remotes.Event("PromptProduct"):FireServer("BoostPearls")
		end
		gui:Destroy()
	end)
end

-- INIT ---------------------------------------------------------------------------

function EconomyController.Init()
	aquarium = AquariumScreen.Create({
		OnSelect = function(f)
			local fn = fishName(f.Id, f.Mutation)
			local rateStr = Aquarium.FormatRate(f.Rate)
			local mutText = if f.Mutation and Registry.Mutations[f.Mutation] then ` | Mutation: {Registry.Mutations[f.Mutation].Name}` else ""
			Modal.Confirm({
				Title = fn,
				Message = `Pearl income: {New.Highlight(rateStr)}{mutText}\nDo you want to return this fish to your bag?`,
				ConfirmText = "Return to Bag",
				ConfirmColor = T.Accent, -- coral (Theme has no "Coral" key: it fell back to green)
				CancelText = "Keep in Tank",
				Icon = "fish/" .. f.Id,
			}, function()
				local res = invoke("TakeFromTank", f.Uid)
				if res then
					notify(res.ok, if res.ok then `{fn} went back to your bag` else res.reason)
				end
			end)
		end,
		OnRemove = function(f)
			local res = invoke("TakeFromTank", f.Uid)
			if res then
				notify(res.ok, if res.ok then `{fishName(f.Id, f.Mutation)} went back to your bag` else res.reason)
			end
		end,
		OnAdd = function()
			table.clear(selection)
			pickerFromBag = false
			picker.Open()
		end,
		OnExpand = function()
			local res = invoke("BuyTankSlot")
			if res then
				notify(res.ok, if res.ok then "New tank slot!" else res.reason)
			end
		end,
		OnMastery = function()
			EconomyController.OpenMastery()
		end,
	})
	picker = Window.Create({ Name = "PutInTank", Title = "Put in Tank", Size = Vector2.new(760, 610), StackOn = { "Aquarium", "Inventory" } })
	quantity = TankQuantity.Create()
	picker.OnClose = quantity.Close
	picker.OnOpen = function()
		picker.Header.Text = "Pick fish from your bag - they make Pearls while in the tank."
		renderPicker()
	end
	masteryWin = MasteryScreen.Create({ OnUpgrade = upgradeMastery })
	store = StoreScreen.Create({
		OnGachaRates = function()
			local Gacha = require(script.Parent.GachaPageController)
			if Gacha and Gacha.Open then
				Gacha.Open()
			end
		end,
	})

	buildHud()
	HUD.MasteryRequested:Connect(EconomyController.OpenMastery)
	HUD.AquariumRequested:Connect(EconomyController.OpenAquarium)
	HUD.StoreRequested:Connect(function()
		EconomyController.OpenStore()
	end)

	DataController.Observe(function(p)
		profile = p
		syncedAt = os.clock()
		renderAquarium()
		if store.IsOpen() then
			store.Render(profile, DataController.Stats)
		end
	end)
	Remotes.Event("OfflineReward").OnClientEvent:Connect(offlinePopup)

	-- live Pearls count-up every frame (chip + Aquarium head)
	RunService.RenderStepped:Connect(function()
		if not profile then
			return
		end
		local now = pearlsNow()
		local currentRate = Aquarium.CurrentRate(profile, DataController.Stats)
		if pearlsChip then
			pearlsChip.Value.Text = Aquarium.FormatPearls(now)
			local rLbl = pearlsChip:FindFirstChild("Rate")
			if rLbl and rLbl:IsA("TextLabel") then
				rLbl.Text = Aquarium.FormatRate(currentRate)
			end
		end
		if aquarium.IsOpen() then
			aquarium.Tick(now, currentRate)
		end
		if masteryWin and masteryWin.IsOpen() then
			masteryWin.Tick(now, currentRate)
		end
	end)
end

-- Opened from other screens (Main Menu tiles etc.)
function EconomyController.OpenTankPicker(id: string, mutation: string?)
	if not profile or not picker then
		return
	end
	table.clear(selection)
	pickerFromBag = true
	picker.Open()
	local fish = pickerUI.ByKey[id .. "|" .. (mutation or "")]
	if fish then
		pickFish(fish)
	end
end

function EconomyController.OpenAquarium()
	aquarium.Open() -- MenuManager closes Main Menu and the other windows
	if profile then
		aquarium.Render(profile, DataController.Stats)
	end
end
function EconomyController.OpenMastery()
	masteryWin.Open() -- MenuManager closes Main Menu and the other windows
	if profile then
		renderMastery()
	end
end
function EconomyController.OpenStore(tab: string?)
	store.Open(tab or "Passes")
	if profile then
		store.Render(profile, DataController.Stats)
	end
end

return EconomyController
