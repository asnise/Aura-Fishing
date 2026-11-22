--!nonstrict
-- Fills the baked "Menus" screen (UI/Screens/Menus) from Config + a profile: Shop (Figma 05/06),
-- Auras (07, Aura Card Row), Fishdex (09, 3x2 cards). No network/player access, so it also runs in
-- Studio edit mode (tools/ui/preview.mjs fills the windows with Figma's sample data for comparisons).
-- MenuController owns the context (window refs, pages, click handlers, server calls).

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Registry = require(Shared.Registry)
local Format = require(Shared.Util.Format)

local New = require(script.Parent.New)
local MenusScreen = require(script.Parent.Screens.Menus)
local ItemDetail = require(script.Parent.ItemDetail)
local ItemSlots = require(script.Parent.ItemSlots)
local Inventory = require(ReplicatedStorage.Shared.Inventory)
local _AuraStars = require(ReplicatedStorage.Shared.AuraStars)

local T = New.Theme

local MenuFill = {}

-- ctx = { windows = {Shop=, Auras=, Fishdex=}, pages = {}, pageCount = {}, handlers = {},
--         currentTab = string?, invoke(name, ...), refresh(), rollAura(), setSetting(key, value) }
local ctx: any = nil

function MenuFill.Setup(context: any)
	ctx = context
end

-- B21: picture "Hit" button (added by MenuController) -> Item Card for this item
local CARD_KIND = { Rods = "Rod", Lines = "Line", Baits = "Bait", Bags = "Bag" }
local function cardOn(picture: any, item: any)
	local hit = picture:FindFirstChild("Hit")
	if hit then
		ctx.handlers[hit] = function()
			if ItemDetail.IsShowing() then
				local cur = ItemDetail.Current()
				if cur and cur.Kind == item.Kind and cur.Id == item.Id then
					ItemDetail.Hide()
					return
				end
			end
			ItemDetail.Show(item, picture)
		end
	end
end

-- Set a button's text/colour/handler; nil handler = inactive (no hover, no click).
local function setButton(button: any, text: string, color: Color3, handler: (() -> ())?)
	button.Visible = true
	button.Text = text
	New.SetButtonColor(button, color)
	button.AutoButtonColor = handler ~= nil
	ctx.handlers[button] = handler
	local price = button:FindFirstChild("Price")
	if price then
		price.Visible = false
	end
end

local CURRENCY_ICON = { Coins = "ui/status/coin", Gems = "ui/status/gem" }

-- Buy button showing [currency icon] price (Figma 05/06); grey when the player can't afford it.
local function setPriceButton(button: any, amount: number, currency: string, afford: boolean, handler: () -> ())
	if amount == 0 then
		setButton(button, "Free", T.Gold, handler)
		return
	end
	setButton(button, "", if afford then T.Gold else T.Disabled, handler)
	local price = button:FindFirstChild("Price")
	if not price then -- screen baked before the price slot existed
		button.Text = `{Format.Number(amount)} {currency}`
		return
	end
	price.Visible = true
	price.Label.Text = Format.Number(amount)
	price.Label.TextColor3 = if afford then T.OnAccent else T.DisabledText
	New.SetImageKey(price.Icon.Image, CURRENCY_ICON[currency] or CURRENCY_ICON.Coins, if currency == "Gems" then T.Gem else T.Gold)
	price.Icon.Image.ImageTransparency = if afford then 0 else 0.45 -- faded coin on a disabled button
	price.Icon.BackgroundTransparency = if afford then 0 else 0.5
end

local function statBadges(stats: { [string]: number }?, mutations: { [string]: number }?): { any }
	local out = {}
	if stats then
		local keys = {}
		for k in stats do
			table.insert(keys, k)
		end
		-- highlighted (selling-point) stats first, then A-Z
		table.sort(keys, function(a, b)
			local ha, hb = Registry.StatDefs[a].Highlight == true, Registry.StatDefs[b].Highlight == true
			if ha ~= hb then
				return ha
			end
			return a < b
		end)
		for _, k in keys do
			local def = Registry.StatDefs[k]
			table.insert(out, { Text = Format.Stat(k, def, stats[k]), Color = if def.Highlight then T.Gold else nil })
		end
	end
	if mutations then
		for m, v in mutations do
			local mut = Registry.Mutations[m]
			table.insert(out, { Text = `{Format.Percent(v)} {mut.Name}`, Color = mut.Color })
		end
	end
	return out
end

local function statsText(stats: { [string]: number }?): string
	local parts = {}
	for _, b in statBadges(stats) do
		table.insert(parts, b.Text)
	end
	return table.concat(parts, ", ")
end

local function initial(name: string): string
	return string.upper(string.sub(name, 1, 1))
end

local function setPager(menu: string, total: number, perPage: number)
	local count = math.max(1, math.ceil(total / perPage))
	ctx.pageCount[menu] = count
	ctx.pages[menu] = math.clamp(ctx.pages[menu], 1, count)
	local pager = ctx.windows[menu].Footer:FindFirstChild("Pager")
	if pager then
		pager.Label.Text = `{ctx.pages[menu]} / {count}`
		pager.Prev.AutoButtonColor = ctx.pages[menu] > 1
		pager.Next.AutoButtonColor = ctx.pages[menu] < count
	end
	return (ctx.pages[menu] - 1) * perPage
end

local function setWallet(menu: string, profile: any)
	local wallet = ctx.windows[menu].Footer:FindFirstChild("Wallet")
	if not wallet then
		return
	end
	wallet.AutomaticSize = Enum.AutomaticSize.X
	local wlist = wallet:FindFirstChildOfClass("UIListLayout")
	if wlist then
		wlist.HorizontalAlignment = Enum.HorizontalAlignment.Right
	end
	for _, cur in { "Coins", "Gems" } do
		local c = wallet:FindFirstChild(cur)
		if c then
			New.FormatCurrencyChip(c, 20)
			c.Value.Text = Format.Number(profile[cur])
		end
	end
end

-- Shop (Figma 05/06) ---------------------------------------------------------------------------

local function shopCategories(): { string }
	local cats = {}
	for id in Registry.Equipment do
		table.insert(cats, id)
	end
	table.sort(cats)
	return cats
end

local function fillShop(profile: any)
	local w = ctx.windows.Shop
	local cats = shopCategories()
	ctx.currentTab = if ctx.currentTab and Registry.Equipment[ctx.currentTab] then ctx.currentTab else cats[1]

	local tabs = w.Tabs
	local shown = 0
	for i = 1, 6 do
		local tab = tabs:FindFirstChild("Tab" .. i)
		if not tab then
			continue
		end
		local id = cats[i]
		tab.Visible = id ~= nil
		if id then
			shown += 1
			tab.Text = Registry.Equipment[id].DisplayName
			New.SetButtonColor(tab, if id == ctx.currentTab then T.Accent else T.PanelLight)
			ctx.handlers[tab] = function()
				if ctx.currentTab ~= id then
					ctx.currentTab = id
					ctx.pages.Shop = 1
					ctx.refresh()
				end
			end
		end
	end
	if #cats > 6 then
		warn(`[Shop] {#cats} categories but only 6 tab slots in the baked Menus screen`)
	end
	for i = 1, shown do
		tabs["Tab" .. i].Size = UDim2.new(1 / shown, -8 * (shown - 1) / shown, 1, 0)
	end

	local catId = ctx.currentTab :: string
	local cat = Registry.Equipment[catId]
	local items = {}
	for _, id in Registry.SortedItems(catId) do
		-- Exclusive items (Starter Pack rod...) only show once owned
		local it = cat.Items[id]
		local have = if Inventory.IsGearCategory(catId) then Inventory.CountGear(profile, catId, id) > 0 else (cat.Kind == "Permanent" and profile.Owned[catId][id] == true)
		if not it.Exclusive or have then
			table.insert(items, id)
		end
	end
	local offset = setPager("Shop", #items, MenusScreen.ShopRows)
	w.List.Empty.Visible = #items == 0

	for slot = 1, MenusScreen.ShopRows do
		local row = w.List:FindFirstChild("Row" .. slot)
		if not row then
			continue
		end
		local itemId = items[offset + slot]
		row.Visible = itemId ~= nil
		if not itemId then
			continue
		end
		local item = cat.Items[itemId]
		New.SetImageKey(row.Picture, `equipment/{itemId}`, T.Track, initial(item.Name))
		if CARD_KIND[catId] then
			cardOn(row.Picture, { Kind = CARD_KIND[catId], Id = itemId, Info = true })
		end
		-- C16: +N on owned, enhanced rods / lines
		ItemSlots.PlusBadge(row.Picture, row.Picture.AbsoluteSize.Y > 0 and row.Picture.AbsoluteSize.Y or 56)
		local worn = Inventory.Worn(profile, catId)
		ItemSlots.SetPlus(row.Picture, if worn and worn.Id == itemId then worn.Enhance else nil)
		local sub = statsText(item.Stats)
		if item.Capacity then
			sub = `{item.Capacity} slots` .. (if sub ~= "" then ", " .. sub else "")
		end
		if sub == "" then
			sub = item.Description or ""
		end
		local price = if item.Price == 0 then "Free" else `{Format.Number(item.Price)} {item.Currency}`
		local equipped = profile.Equipped[catId] == itemId
		local title = row.Top.Title
		title.TextColor3 = T.Text
		row.Use.Visible = false
		ctx.handlers[row.Use] = nil

		if Inventory.IsGearCategory(catId) then
			-- Rods / Lines: buy as many as you like (every one is its own bag item); wear them from the Inventory
			local copies = Inventory.CountGear(profile, catId, itemId)
			local isWorn = worn ~= nil and worn.Id == itemId
			title.Text = item.Name .. (if copies > 0 then `  x{copies}` else "") .. (if isWorn then "  (worn)" else "")
			title.TextColor3 = if isWorn then T.GoodLip else T.Text
			row.Sub.Text = sub
			if item.RequiredLevel and profile.Level < item.RequiredLevel then
				title.TextColor3 = T.SubText
				row.Sub.Text = sub .. "  |  " .. price
				setButton(row.Action, `Lv. {item.RequiredLevel}`, T.Disabled, nil)
				row.Action.TextColor3 = T.DisabledText
			else
				local afford = (profile[item.Currency] or 0) >= item.Price
				setPriceButton(row.Action, item.Price, item.Currency, afford, function()
					ctx.invoke("Buy", catId, itemId)
				end)
			end
		elseif cat.Kind == "Permanent" then
			local owned = profile.Owned[catId][itemId]
			title.Text = item.Name
			row.Sub.Text = sub
			-- B21: bags are upgrades - a bag not bigger than the one in use can't be equipped or bought
			local smallerBag = catId == "Bags"
				and (item.Capacity or 0) <= ((cat.Items[profile.Equipped.Bags] or {} :: any).Capacity or 0)
			if equipped then
				setButton(row.Action, if catId == "Bags" then "In use" else "Equipped", T.Good, nil)
			elseif smallerBag then
				setButton(row.Action, if owned then "Owned" else "Smaller", T.Disabled, nil)
				row.Action.TextColor3 = T.DisabledText
			elseif owned then
				setButton(row.Action, "Equip", T.Sky, function()
					ctx.invoke("Equip", catId, itemId)
				end)
			elseif item.RequiredLevel and profile.Level < item.RequiredLevel then
				title.TextColor3 = T.SubText
				row.Sub.Text = sub .. "  |  " .. price
				setButton(row.Action, `Lv. {item.RequiredLevel}`, T.Disabled, nil)
				row.Action.TextColor3 = T.DisabledText
			else
				row.Sub.Text = sub
				local afford = (profile[item.Currency] or 0) >= item.Price
				setPriceButton(row.Action, item.Price, item.Currency, afford, function()
					ctx.invoke("Buy", catId, itemId)
				end)
			end
		else
			local count = profile.Consumables[catId][itemId] or 0
			title.Text = `{item.Name}  x{count}` .. (if equipped then "  (equipped)" else "")
			title.TextColor3 = if equipped then T.GoodLip else T.Text
			row.Sub.Text = sub .. "  |  " .. `pack of {item.BuyAmount}`
			local afford = (profile[item.Currency] or 0) >= item.Price
			setPriceButton(row.Action, item.Price, item.Currency, afford, function()
				ctx.invoke("Buy", catId, itemId)
			end)
			if count > 0 and not equipped then
				setButton(row.Use, "Use", T.Sky, function()
					ctx.invoke("Equip", catId, itemId)
				end)
			end
		end
	end
	setWallet("Shop", profile)
end

-- Aura Index - Gem Tracker (Figma 3611:54189) --------------------------------------------------

local function fillAuras(profile: any)
	local w = ctx.windows.Auras
	local ids = Registry.SortedAuras()
	local totalAuras = #ids

	-- 1. Discovered count
	local discovered = 0
	if profile.Auras and profile.Auras.Owned then
		for id, count in profile.Auras.Owned do
			if count > 0 and Registry.Auras[id] then
				discovered += 1
			end
		end
	end

	-- Header collection count pill: "3 / 15"
	if w.Header:FindFirstChild("CollectionCount") then
		w.Header.CollectionCount.Used.Text = tostring(discovered)
		w.Header.CollectionCount.Max.Text = "/ " .. tostring(totalAuras)
	end

	-- 2. Discovery log: "+15 / 75 Gems earned", progress bar, "12 first finds left"
	local log = w:FindFirstChild("DiscoveryLog")
	if log then
		local earnedGems = discovered * 5
		local maxGems = totalAuras * 5
		local left = math.max(0, totalAuras - discovered)
		log.GemsEarned.Text = `{earnedGems} / {maxGems} Gems earned`
		log.FindsLeft.Text = `{left} first finds left`
		local frac = math.clamp(discovered / math.max(1, totalAuras), 0, 1)
		log.ProgressBar.Fill.Size = UDim2.fromScale(frac, 1)
	end

	-- Star Tokens wallet
	local tokensBox = w:FindFirstChild("StarTokens")
	if tokensBox and tokensBox:FindFirstChild("TextGroup") then
		local val = tokensBox.TextGroup:FindFirstChild("Value")
		if val then
			val.Text = Format.Number(profile.Auras and profile.Auras.StarTokens or 0)
		end
	end

	-- 3. Go to Altar button in Footer
	local altar = w.Footer:FindFirstChild("Altar")
	if altar then
		setButton(altar, "Go to Altar", T.Gem, ctx.rollAura)
	end

	-- 4. Grid cards (Screen.AuraCards = 6)
	local offset = setPager("Auras", totalAuras, MenusScreen.AuraCards)
	for slot = 1, MenusScreen.AuraCards do
		local card = w.Grid:FindFirstChild("Card" .. slot)
		if not card then
			continue
		end
		local id = ids[offset + slot]
		card.Visible = id ~= nil
		if not id then
			continue
		end

		local a = Registry.Auras[id]
		local r = Registry.Rarities[a.Rarity]
		local owned = if profile.Auras and profile.Auras.Owned then (profile.Auras.Owned[id] or 0) else 0
		local known = owned > 0

		New.SetImageKey(card.Picture, if known then "auras/" .. id else "auras/UnknownAura", if known then a.Visual.Color[1] else T.Track, if known then "" else "?")
		cardOn(card.Picture, { Kind = "Aura", Id = id, Info = true })

		card.AuraName.Text = if known then a.Name else "???"
		card.AuraName.TextColor3 = if known then r.Color else T.SubText

		card.Rarity.Text = r.Name
		card.State.Text = if known then "Discovered" else "Locked"
		card.State.TextColor3 = if known then Color3.fromRGB(91, 65, 141) else T.SubText
		card.Chance.Text = "1 in " .. Format.Number(a.Chance)

		if card:FindFirstChild("LockedMark") then
			card.LockedMark.Visible = not known
		end

		local foot = card:FindFirstChild("Footer")
		if foot then
			foot.Amount.Text = "+5 Gems"
			foot.RewardState.Text = if known then "Awarded" else "First find"
		end
	end
end

-- Fishdex (Figma 09, 3x2 cards) ----------------------------------------------------------------

-- Sort modes the Sort button cycles through (Depth = the old fixed order). Undiscovered fish never
-- sort by their real name/catch data, so "???" cards can't leak what they are: they go last.
local DEX_SORTS = { "Depth", "Rarity", "Name", "Caught", "Found" }
local dexSort = 1

local function byDepth(a: string, b: string): boolean
	local fa, fb = Registry.Fish[a], Registry.Fish[b]
	if fa.DepthMin ~= fb.DepthMin then
		return fa.DepthMin < fb.DepthMin
	end
	return a < b
end

local function sortedFish(profile: any): { string }
	local ids = {}
	for id in Registry.Fish do
		table.insert(ids, id)
	end
	local mode = DEX_SORTS[dexSort]
	local dex = profile.Fishdex
	table.sort(ids, function(a, b)
		local da, db = dex[a], dex[b]
		if mode == "Rarity" then
			local ta, tb = Registry.Rarities[Registry.Fish[a].Rarity].Tier, Registry.Rarities[Registry.Fish[b].Rarity].Tier
			if ta ~= tb then
				return ta > tb -- rarest first (rarity is shown on "???" cards anyway)
			end
		elseif mode ~= "Depth" then
			if (da ~= nil) ~= (db ~= nil) then
				return da ~= nil -- discovered first
			end
			if da and db then
				if mode == "Name" and Registry.Fish[a].Name ~= Registry.Fish[b].Name then
					return Registry.Fish[a].Name < Registry.Fish[b].Name
				elseif mode == "Caught" and da.Count ~= db.Count then
					return da.Count > db.Count
				end
			end
		end
		return byDepth(a, b)
	end)
	return ids
end

local function fillFishdex(profile: any)
	local w = ctx.windows.Fishdex
	local ids = sortedFish(profile)
	local found = 0
	for id in profile.Fishdex do
		if Registry.Fish[id] then
			found += 1
		end
	end
	local sum = w.Summary
	local count = sum.Count
	local text = `{found} / {#ids}`
	local value = count:FindFirstChild("Value")
	if value then
		value.Text = text
		count.Size = UDim2.fromOffset(117 + math.max(0, #text - 6) * 11, 40) -- grow for 3-digit totals
	else
		count.Text = text -- screen baked before the chip existed
	end
	local sort = sum:FindFirstChild("Sort")
	if sort then
		setButton(sort, `Sort: {DEX_SORTS[dexSort]}`, T.PanelLight, function()
			dexSort = dexSort % #DEX_SORTS + 1
			ctx.pages.Fishdex = 1
			ctx.refresh()
		end)
	end

	local offset = setPager("Fishdex", #ids, MenusScreen.DexCards)
	for slot = 1, MenusScreen.DexCards do
		local card = w.Grid:FindFirstChild("Card" .. slot)
		if not card then
			continue
		end
		local id = ids[offset + slot]
		card.Visible = id ~= nil
		if not id then
			continue
		end
		local f = Registry.Fish[id]
		local r = Registry.Rarities[f.Rarity]
		local dex = profile.Fishdex[id]
		New.SetImageKey(card.Picture.Image, if dex then `fish/{id}` else "fish/MysteryFish", if dex then r.Color else T.Track, if dex then initial(f.Name) else "?")
		cardOn(card.Picture, { Kind = "Species", Id = id, Info = true })
		card.FishName.Text = if dex then f.Name else "???"
		card.FishName.TextColor3 = if dex then T.Text else T.SubText
		New.SetBadges(card.Where, {
			{ Text = string.upper(r.Name), Color = r.Color },
			{ Text = `{f.DepthMin}-{f.DepthMax}m`, Color = T.Sky },
		})
		New.SetBadges(
			card.Record,
			if dex then { { Text = `Caught x{dex.Count}` }, { Text = string.format("Best %.2f kg", dex.Best) } } else { { Text = "Not caught yet" } }
		)
	end
end

MenuFill.Shop = fillShop
MenuFill.Auras = fillAuras
MenuFill.Fishdex = fillFishdex

return MenuFill
