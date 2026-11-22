--!nonstrict
-- Inventory v2 (B21, Figma 18 FINAL "Bookmark Tabs"). Layout is baked into StarterGui.Inventory
-- (UI/Screens/Inventory); this controller fills it from the profile and talks to the server.
--   Open: HUD.InventoryRequested(tab?) (bag chip / key B / Main Menu Bag; "Auras" from the Main Menu Auras
--         tile) -> Toggle / OpenTab. NEW clears individually when seen or pressed.
--   Tabs (bookmarks on the left): All = bag stacks then baits | Fish | Rods | Lines | Auras | Baits | Treasure.
--         Rods / Lines / Auras list OWNED items only (auras behave like normal items, no locked slots).
--         Every tab shows empty "bubble" slots for free bag space (one viewport for Infinite Bag).
--   Grid: UI/VirtualGrid over Components.Clone("ItemSlot") (84px component scaled to 72 in a holder frame).
--         Pressing a slot selects it and opens UI/ItemDetail (Item Card) beside it; every action lives there.
--   Sort pill: Value / Rarity / Count / Name on bag tabs, Rarity / Name on gear + aura tabs.
--   Footer: Fish = "Total N" + SELL ALL (Modal confirm); Auras = "N owned" + ROLL AURA (Altar gacha page);
--           other tabs hide it and the grid grows to 4 rows.
--   Capacity pill UPGRADE -> Bag Upgrade popup: buys the next bag on the ladder (Buy "Bags" = auto equip);
--           at the top of the ladder it offers the Infinite Bag pass (Robux). Hidden once the bag is infinite.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Registry = require(Shared.Registry)
local Remotes = require(Shared.Remotes)
local Inventory = require(Shared.Inventory)
local Format = require(Shared.Util.Format)

local UI = script.Parent.Parent.UI
local New = require(UI.New)
local Baked = require(UI.Baked)
local MenuManager = require(UI.MenuManager)
local InventoryScreen = require(UI.Screens:WaitForChild("Inventory")) :: any
local Modal = require(UI.Modal)
local VirtualGrid = require(UI.VirtualGrid)
local ItemDetail = require(UI.ItemDetail)
local ItemSlots = require(UI.ItemSlots)
local HUD = require(script.Parent.HUDController)
local DataController = require(script.Parent.DataController)
local GachaPageController = require(script.Parent.GachaPageController)

local T = New.Theme

local InventoryController = {}

local TAB_W = InventoryScreen.TabWidth
local BAG_SORTS = { "Value", "Rarity", "Weight", "Name" }
local GEAR_SORTS = { "Rarity", "Name" }
local GEAR = { Rods = { Kind = "Rod", Cat = "Rods" }, Lines = { Kind = "Line", Cat = "Lines" } }
local EMPTY = { Kind = "Empty" }
local NEW_DWELL_SECONDS = 0.6
local NEW_SCAN_INTERVAL = 0.1
local NEW_VISIBLE_FRACTION = 0.75

local gui: any = nil
local refs: any = nil
local isOpen = false
local tab = "All"
local sortIndex = { Bag = 1, Gear = 1 }
local busy = false
local selected: string? = nil -- key of the selected entry (card open)
local acknowledged: { [string]: boolean } = {}
local visibleSince: { [string]: number } = {}
local lastScan = 0
local grid: any = nil
local footerAction: (() -> ())? = nil

local function newToken(stack: any): string?
	local token = stack and stack.New
	return if type(token) == "string" and not acknowledged[token] then token else nil
end

local function observeNewSlots()
	if not isOpen or not gui.Enabled or refs.Upgrade.Visible or Modal.IsOpen() or selected then
		table.clear(visibleSince)
		return
	end
	local now = os.clock()
	if now - lastScan < NEW_SCAN_INTERVAL then
		return
	end
	lastScan = now

	local viewportTop = refs.Grid.AbsolutePosition.Y
	local viewportBottom = viewportTop + refs.Grid.AbsoluteWindowSize.Y
	local visibleNow = {}
	local batch = {}
	-- The active views include buffer rows. Count only loaded slots sufficiently inside the viewport.
	grid:ForEachVisible(function(holder, entry)
		local token = newToken(entry.Stack)
		if not token then
			return
		end
		local top = holder.AbsolutePosition.Y
		local height = holder.AbsoluteSize.Y
		local shown = math.min(viewportBottom, top + height) - math.max(viewportTop, top)
		local icon = holder.ItemSlot.Icon
		if height <= 0 or shown < height * NEW_VISIBLE_FRACTION or (icon.Image ~= "" and not icon.IsLoaded) then
			return
		end

		local since = visibleSince[token] or now
		if now - since >= NEW_DWELL_SECONDS then
			acknowledged[token] = true
			holder.ItemSlot.NewBadge.Visible = false
			table.insert(batch, token)
		else
			visibleNow[token] = since
		end
	end)
	visibleSince = visibleNow
	if #batch > 0 then
		Remotes.Event("BagSeen"):FireServer(batch)
	end
end

local function isBagTab(name: string): boolean
	return name == "All" or name == "Fish" or name == "Treasure" or name == "Baits"
end

local function sorts(): ({ string }, string)
	if isBagTab(tab) then
		return BAG_SORTS, "Bag"
	end
	return GEAR_SORTS, "Gear"
end

local function sortMode(): string
	local list, key = sorts()
	return list[sortIndex[key]] or list[1]
end

local function sellMultiplier(): number
	local stats = DataController.Stats
	return stats and stats.Values.SellMultiplier or 1
end

local function rarityTier(id: string?): number
	local r = id and Registry.Rarities[id]
	return r and r.Tier or 0
end

local function call(name: string, ...: any): (any, any, any)
	if busy then
		return nil, nil, nil
	end
	busy = true
	local ok, a, b, c = pcall(function(...)
		return Remotes.Func(name):InvokeServer(...)
	end, ...)
	busy = false
	if not ok then
		HUD.Notify("Something went wrong, try again", T.Bad)
		return nil, nil, nil
	end
	return a, b, c
end

-- Entries ------------------------------------------------------------------------------------------
-- entry = { Key, Kind (Fish/Treasure/Bait/Rod/Line/Aura), Id, UUID?, Stack?, Count?, Name, Rarity, Icon,
--           Value?, Weight?, Order?, Equipped?, Color?, Plus? }   (one entry per bag item)

local function sortEntries(out: { any })
	local mode = sortMode()
	table.sort(out, function(a, b)
		local ka, kb
		if mode == "Value" then
			ka, kb = a.Value or 0, b.Value or 0
		elseif mode == "Rarity" then
			ka, kb = rarityTier(a.Rarity), rarityTier(b.Rarity)
		elseif mode == "Weight" then
			ka, kb = a.Weight or 0, b.Weight or 0
		end
		if ka ~= nil and ka ~= kb then
			return ka > kb
		end
		if mode == "Name" and a.Name ~= b.Name then
			return a.Name < b.Name
		end
		return (a.Order or 0) < (b.Order or 0)
	end)
end

local function bagEntries(profile: any, kind: string?): { any }
	local mult = sellMultiplier()
	local out = {}
	for i, s in profile.Bag do
		if kind == nil or s.Kind == kind then
			local name, rarity, icon = Inventory.Describe(s)
			table.insert(out, {
				Key = `bag|{s.UUID}`,
				Kind = s.Kind,
				Id = s.Id,
				UUID = s.UUID,
				Stack = s,
				Mutation = s.Mutation,
				Count = s.Count, -- chests only; fish / gear never show a count
				Weight = s.Weight,
				Name = name,
				Rarity = rarity,
				Icon = icon,
				Value = Inventory.SellValue(s, mult),
				Order = i,
				Equipped = Inventory.IsWorn(profile, s),
				Plus = s.Enhance,
			})
		end
	end
	sortEntries(out)
	return out
end

local function baitEntries(profile: any): { any }
	return ItemSlots.Baits(profile)
end

local function gearEntries(profile: any, g: any): { any }
	local out = ItemSlots.Gear(profile, g.Cat)
	sortEntries(out)
	return out
end

local function auraEntries(profile: any): { any }
	local out = ItemSlots.Auras(profile)
	sortEntries(out)
	return out
end

local function entriesFor(profile: any, name: string): { any }
	if name == "Fish" then
		return bagEntries(profile, "Fish")
	elseif name == "Treasure" then
		return bagEntries(profile, "Treasure")
	elseif name == "Baits" then
		return baitEntries(profile)
	elseif name == "Auras" then
		return auraEntries(profile)
	elseif GEAR[name] then
		return gearEntries(profile, GEAR[name])
	end
	local all = bagEntries(profile, nil)
	for _, e in baitEntries(profile) do
		table.insert(all, e)
	end
	return all
end

-- Bag upgrade --------------------------------------------------------------------------------------

local function closeUpgrade()
	if refs then
		refs.Upgrade.Visible = false
	end
end

local function openUpgrade()
	local profile = DataController.Profile
	if not profile or Inventory.IsInfinite(profile) then
		return
	end
	local ladder = Inventory.BagLadder()
	local curCap = Inventory.Capacity(profile)
	local nextId = Inventory.NextBag(profile)
	local u = refs.UpgradeRefs
	-- ladder: shop bags + Bottomless (Infinite Bag pass); the next step gets a sky ring
	for i = 1, 6 do
		local tier = u.Ladder:FindFirstChild("Tier" .. i)
		if tier then
			local id = ladder[i]
			local isLast = id == nil and i == #ladder + 1
			tier.Visible = id ~= nil or isLast
			local ring = tier.Tile:FindFirstChild("Ring")
			if id then
				New.SetImageKey(tier.Icon, `equipment/{id}`, T.PanelLight)
				tier.Cap.Text = tostring(Inventory.BagCapacity(id))
				local reached = Inventory.BagCapacity(id) <= curCap
				tier.Icon.ImageTransparency = if reached then 0 else 0.35
				if ring then
					ring.Color = if id == nextId then T.SkyLip elseif reached then T.Good else T.Track
				end
			elseif isLast then
				New.SetImageKey(tier.Icon, "equipment/BottomlessBag", T.Gem)
				tier.Cap.Text = "Inf"
				if ring then
					ring.Color = if nextId == nil then T.SkyLip else T.Track
				end
			end
		end
	end
	local pass = Registry.Products and Registry.Products.Passes and Registry.Products.Passes.InfiniteBag
	if nextId then
		local bag = Registry.Equipment.Bags.Items[nextId]
		u.Slots.Text = `{curCap} slots -> {New.Highlight(tostring(bag.Capacity) .. " slots", T.GoodLip)}`
		local locked = bag.RequiredLevel and profile.Level < bag.RequiredLevel
		u.Note.Text = if locked
			then `{bag.Name} needs level {bag.RequiredLevel}.`
			else "Bags are upgrades: each one replaces the last, you never go back to a smaller bag."
		u.Confirm.Text = `UPGRADE  {Format.Number(bag.Price)}`
		local afford = profile[bag.Currency] >= bag.Price and not locked
		New.SetButtonColor(u.Confirm, if afford then T.Gold else T.Disabled, if afford then nil else T.DisabledText)
		refs.UpgradeAction = function()
			local ok, msg = call("Buy", "Bags", nextId)
			if msg then
				HUD.Notify(tostring(msg), if ok then T.Good else T.Bad)
			end
			if ok then
				closeUpgrade()
			end
		end
	else
		u.Slots.Text = `{curCap} slots -> {New.Highlight("Unlimited", T.GoodLip)}`
		u.Note.Text = "The last bag is Robux only. Bottomless Bag = Infinite Bag pass: never fill your bag again."
		u.Confirm.Text = `GET  R$ {pass and pass.Price or 349}`
		New.SetButtonColor(u.Confirm, T.Good)
		refs.UpgradeAction = function()
			Remotes.Event("PromptPass"):FireServer("InfiniteBag")
			closeUpgrade()
		end
	end
	refs.Upgrade.Visible = true
end

-- Window -------------------------------------------------------------------------------------------

local function selectEntry(e: any, view: GuiObject)
	if selected == e.Key then
		selected = nil
		ItemDetail.Hide()
	else
		selected = e.Key
		ItemDetail.Show({ Kind = e.Kind, Id = e.Id, UUID = e.UUID }, view)
	end
	grid:Refresh()
end

local function setTab(name: string)
	if tab == name then
		return
	end
	tab = name
	table.clear(visibleSince)
	selected = nil
	ItemDetail.Hide()
	refs.Grid.CanvasPosition = Vector2.zero
	InventoryController.Refresh()
end

local function sellAll()
	local profile = DataController.Profile
	if not profile then
		return
	end
	local total, count, mutated = Inventory.SellAllPreview(profile, sellMultiplier())
	if count == 0 then
		HUD.Notify("No fish to sell", T.Bad)
		return
	end
	ItemDetail.Hide()
	Modal.Confirm({
		Title = `Sell all {count} fish?`,
		Message = `You'll get {New.Highlight(Format.Number(total) .. " coins")}.`
			.. (if mutated > 0 then ` {mutated} fish with mutations are included.` else "")
			.. (function()
				local bonus = Inventory.HotBonus(profile, sellMultiplier())
				return if bonus > 0 then ` Hot fish bonus {New.Highlight("+" .. Format.Number(bonus), T.BadLip)}.` else ""
			end)()
			.. " Treasure chests stay in your bag.",
		ConfirmText = "Sell",
		ConfirmColor = T.Gold,
		Icon = "ui/status/sell_bag",
		IconColor = T.Gold,
	}, function()
		local ok, msg = call("SellAll")
		if msg then
			HUD.Notify(tostring(msg), if ok then T.Gold else T.Bad)
		end
		InventoryController.Refresh()
	end)
end

local function ensure()
	if gui then
		return
	end
	gui = Baked.Get("Inventory")
	gui.Enabled = false
	local root = Baked.Find(gui, "Root")
	local w = Baked.Find(root, "Window")
	local up = Baked.Find(gui, "BagUpgrade")
	refs = {
		Root = root,
		Window = w,
		Tabs = Baked.Find(root, "Tabs"),
		Used = Baked.Find(w, "Header/Capacity/Used"),
		Max = Baked.Find(w, "Header/Capacity/Max"),
		UpgradeButton = Baked.Find(w, "Header/Capacity/Upgrade"),
		Category = Baked.Find(w, "SubHeader/Category"),
		CountLabel = Baked.Find(w, "SubHeader/CountPill/Label"),
		Sort = Baked.Find(w, "SubHeader/Sort"),
		SortLabel = Baked.Find(w, "SubHeader/Sort/Label"),
		Grid = Baked.Find(w, "Grid"),
		Footer = Baked.Find(w, "Footer"),
		FooterInfo = Baked.Find(w, "Footer/Info"),
		FooterAction = Baked.Find(w, "Footer/Action"),
		FooterSecondary = Baked.Find(w, "Footer"):FindFirstChild("Secondary"), -- nil on an older bake
		Upgrade = up,
		UpgradeRefs = {
			Slots = Baked.Find(up, "Panel/Slots"),
			Ladder = Baked.Find(up, "Panel/Ladder"),
			Note = Baked.Find(up, "Panel/Note"),
			Confirm = Baked.Find(up, "Panel/Buttons/Upgrade"),
		},
	}
	refs.MaxColor = refs.Max.TextColor3
	New.FitWindow(root, Vector2.new(600, 480))
	for _, c in refs.Grid:GetChildren() do
		if c:IsA("GuiObject") then
			c:Destroy() -- Figma sample slots
		end
	end
	Baked.Find(w, "Header/Close").Activated:Connect(InventoryController.Close)
	for _, t in InventoryScreen.Tabs do
		local name = t[1]
		Baked.Find(refs.Tabs, name).Activated:Connect(function()
			setTab(name)
		end)
	end
	refs.Sort.Activated:Connect(function()
		local list, key = sorts()
		sortIndex[key] = sortIndex[key] % #list + 1
		InventoryController.Refresh()
	end)
	if refs.FooterSecondary then
		refs.FooterSecondary.Activated:Connect(function()
			HUD.MenuRequested:Fire("Auras") -- stacks on the bag (MenuManager StackOn) -- the old Auras window = Aura Dex (every aura, found or not)
		end)
	end
	refs.FooterAction.Activated:Connect(function()
		local h = footerAction
		if h and not busy then
			h()
		end
	end)
	refs.UpgradeButton.Activated:Connect(openUpgrade)
	Baked.Find(up, "Panel/Buttons/Cancel").Activated:Connect(closeUpgrade)
	refs.UpgradeRefs.Confirm.Activated:Connect(function()
		local h = refs.UpgradeAction
		if h and not busy then
			h()
		end
	end)

	grid = VirtualGrid.new(refs.Grid, {
		Create = function()
			return ItemSlots.NewCell(function(holder)
				local e = grid:ItemOf(holder)
				if e and e.Kind ~= "Empty" then
					local token = newToken(e.Stack)
					if token then
						acknowledged[token] = true
						Remotes.Event("BagSeen"):FireServer({ token })
					end
					selectEntry(e, holder)
				end
			end)
		end,
		Bind = function(holder, e)
			ItemSlots.Bind(holder, e, selected, newToken(e.Stack) ~= nil)
		end,
	})

	ItemDetail.Init({
		Profile = function()
			return DataController.Profile
		end,
		Stats = function()
			return DataController.Stats
		end,
		Notify = HUD.Notify,
		OpenTankPicker = function(id, mutation)
			require(script.Parent.EconomyController).OpenTankPicker(id, mutation)
		end,
		Changed = function()
			InventoryController.Refresh()
		end,
		Hidden = function()
			if selected then
				selected = nil
				if grid then
					grid:Refresh()
				end
			end
		end,
	})
end

local function updateTabs(profile: any)
	local newFish = 0
	for _, s in profile.Bag do
		if s.Kind == "Fish" and newToken(s) then
			newFish += 1
		end
	end
	for i, t in InventoryScreen.Tabs do
		local b = refs.Tabs[t[1]]
		local on = t[1] == tab
		local width = if on then TAB_W + 8 else TAB_W
		b.Size = UDim2.fromOffset(width, b.Size.Y.Offset)
		b.Position = UDim2.fromOffset(-width + 8, b.Position.Y.Offset)
		b.BackgroundColor3 = if on then T.Panel else T.PanelLight
		b.Dot.Visible = t[1] == "Fish" and newFish > 0 and not on
		b.Dot.Text = tostring(newFish)
		local _ = i
	end
end

local function updateFooter(profile: any, entries: { any })
	local show = tab == "Fish" or tab == "Auras"
	refs.Footer.Visible = show
	local h = if show then InventoryScreen.GridH.WithFooter else InventoryScreen.GridH.Full
	refs.Grid.Size = UDim2.fromOffset(refs.Grid.Size.X.Offset, h)
	footerAction = nil
	if refs.FooterSecondary then
		refs.FooterSecondary.Visible = tab == "Auras"
	end
	if tab == "Fish" then
		local total, count = Inventory.SellAllPreview(profile, sellMultiplier())
		refs.FooterInfo.Text = `Total {Format.Number(total)}`
		refs.FooterAction.Text = "SELL ALL"
		New.SetButtonColor(refs.FooterAction, if count > 0 then T.Gold else T.Disabled, if count > 0 then nil else T.DisabledText)
		footerAction = sellAll
	elseif tab == "Auras" then
		refs.FooterInfo.Text = `{#entries} / {#Registry.SortedAuras()} found`
		refs.FooterAction.Text = "ROLL AURA"
		New.SetButtonColor(refs.FooterAction, T.Sky)
		footerAction = function()
			GachaPageController.Open("Altar") -- stacks on the bag (MenuManager StackOn)
		end
	end
end

function InventoryController.Refresh()
	if not isOpen or not gui then
		return
	end
	local profile = DataController.Profile
	if not profile then
		return
	end

	local used, cap = Inventory.Used(profile), Inventory.Capacity(profile)
	local infinite = Inventory.IsInfinite(profile)
	local full = used >= cap
	refs.Used.Text = tostring(used)
	refs.Max.Text = if infinite then "/ Inf" else `/ {cap}`
	refs.Used.TextColor3 = if full then T.Bad else T.Text
	refs.Max.TextColor3 = if full then T.Bad else refs.MaxColor
	refs.UpgradeButton.Visible = not infinite

	updateTabs(profile)
	local entries = entriesFor(profile, tab)
	refs.Category.Text = tab
	local isBag = tab == "All" or tab == "Fish" or tab == "Treasure"
	refs.CountLabel.Text = if tab == "All" or isBag
		then `{#entries} item{if #entries == 1 then "" else "s"}`
		else `{#entries} owned`
	refs.SortLabel.Text = `Sort: {sortMode()}`

	-- selection survives refreshes only while its entry still exists
	if selected then
		local found = false
		for _, e in entries do
			if e.Key == selected then
				found = true
				break
			end
		end
		if not found then
			selected = nil
			ItemDetail.Hide()
		end
	end

	updateFooter(profile, entries)
	local viewportSlots = grid:CountFitting(refs.Grid.Size.Y.Offset)
	local emptySlots = if infinite then viewportSlots - #entries else cap - used
	for _ = 1, emptySlots do
		table.insert(entries, EMPTY)
	end
	-- always finish the last row with bubble placeholders (also when the bag is full or the list is longer than one viewport)
	local cols = grid:_columns()
	local partial = #entries % cols
	if partial > 0 then
		for _ = 1, cols - partial do
			table.insert(entries, EMPTY)
		end
	end
	grid:SetItems(entries)
	local canScroll = #entries > viewportSlots
	refs.Grid.ScrollingEnabled = canScroll
	if not canScroll then
		grid:ScrollToTop()
	end
	ItemDetail.Refresh()
	if refs.Upgrade.Visible then
		openUpgrade() -- prices / ladder after a purchase
	end
end

function InventoryController.IsOpen(): boolean
	return isOpen
end

function InventoryController.Open(tabName: string?)
	ensure()
	if tabName and refs.Tabs:FindFirstChild(tabName) and tab ~= tabName then
		tab = tabName
		table.clear(visibleSince)
		selected = nil
	end
	MenuManager.WillOpen("Inventory") -- also brings it back on top when already open
	if isOpen then
		InventoryController.Refresh()
		return
	end
	isOpen = true
	selected = nil
	table.clear(visibleSince)
	gui.Enabled = true
	refs.Grid.CanvasPosition = Vector2.zero
	InventoryController.Refresh()
end

function InventoryController.Close()
	if not isOpen then
		return
	end
	isOpen = false
	table.clear(visibleSince)
	selected = nil
	ItemDetail.Hide()
	closeUpgrade()
	if gui then
		gui.Enabled = false
	end
	MenuManager.Closed("Inventory")
end

function InventoryController.Toggle(tabName: string?)
	if isOpen and (tabName == nil or tabName == tab) then
		InventoryController.Close()
	else
		InventoryController.Open(tabName)
	end
end

function InventoryController.Init()
	HUD.InventoryRequested:Connect(InventoryController.Toggle)
	DataController.Changed:Connect(function(profile)
		if next(acknowledged) then
			local pending = {}
			for _, stack in profile.Bag do
				if stack.New and acknowledged[stack.New] then
					pending[stack.New] = true
				end
			end
			acknowledged = pending
		end
		InventoryController.Refresh()
	end)
	RunService.Heartbeat:Connect(observeNewSlots)
	task.spawn(ensure) -- find the baked screen early so the first open is instant
end

MenuManager.Register("Inventory", { Layer = "Main", Open = InventoryController.Open, Close = InventoryController.Close, IsOpen = InventoryController.IsOpen, Gui = function()
	return gui
end })

return InventoryController
