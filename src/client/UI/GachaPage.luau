--!nonstrict
-- Gacha page logic for the concept D "Glass Card" layout (Figma "Gacha Redesign v2 — A / D" 3662:56279 + the E1
-- parts: Mythic pity box, Milestones box, Skip / Auto). Fills the baked "GachaPage" ScreenGui (UI/Screens/GachaPage)
-- from Config/AuraBanners + the profile, for EVERY banner: the left rail lists the open banners (events first),
-- the info card / hero / buttons follow the selected one. What a banner doesn't have stays hidden (no hard pity ->
-- no Mythic box, no milestones -> no Milestones box). New banner = new Config/AuraBanners entry, no UI work.
--
-- No remotes / controllers are required here: everything that talks to the game comes in through ctx,
-- so Studio previews can fill the page with a fake profile.
--   GachaPage.Bind(gui, ctx)   once: connect the baked buttons, scale the 1280x720 canvas to the screen
--       ctx = { invoke(name, ...) -> ..., notify(text, color?), playReveal(auraId, opts), reelPlaying() -> bool,
--               profile() -> profile, isOpen() -> bool, close(), back(), refresh()?, openStore(tab?)? }
--   GachaPage.Show(bannerId)   switch banner (closes overlays, stops auto-roll)
--   GachaPage.Fill(profile)    redraw from data (call on every profile change)
--   GachaPage.Tick()           timer texts; closes the page when the banner ends
--   GachaPage.Stop()           stop auto-roll + close overlays (page closed)
--   GachaPage.Pull(count)      ROLL x1 / x10 (also the reveal's ROLL AGAIN)
-- Options (Skip animation / Auto-roll until Epic+ / pay-with toggle) are client-side module state only.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Registry = require(Shared:WaitForChild("Registry"))
local Roll = require(Shared:WaitForChild("Roll"))
local Format = require(Shared:WaitForChild("Util"):WaitForChild("Format"))

local New = require(script.Parent.New)
local EventHub = require(script.Parent.EventHub)
local ItemDetail = require(script.Parent.ItemDetail)
local ItemSlots = require(script.Parent.ItemSlots)
local PageScreen = require(script.Parent:WaitForChild("Screens"):WaitForChild("GachaPage")) :: any

local T = New.Theme
local WHITE = Color3.new(1, 1, 1)
local AUTO_STOP_TIER = 4 -- Epic+
local AUTO_DELAY = 0.6 -- server allows one pull per 0.4s

local GachaPage = {}

local gui: any = nil
local w: any = nil
local ctx: any = nil
local state = {
	bannerId = nil :: string?,
	busy = false,
	skip = false,
	auto = false,
	autoPulls = 0,
	pay = "Gems", -- pay-with toggle (Gems | Tokens); only Gems rolls exist on the server for now
	lastResults = nil :: { any }?, -- x10 summary (EQUIP BEST)
}

local function tierOf(auraId: string): number
	return Registry.Rarities[Registry.Auras[auraId].Rarity].Tier
end

local function rarityColor(rarityId: string): Color3
	local r = Registry.Rarities[rarityId]
	return if r then r.Color else T.SubText
end

local function banner(): any
	return state.bannerId and Registry.AuraBanners[state.bannerId]
end

function GachaPage.Cost(b: any, count: number): number
	return if count == 10 then math.floor(b.Cost * 10 * (1 - b.Ten.Discount) + 0.5) else b.Cost
end

local function currencyIcon(currency: string): string
	return if currency == "Coins" then "ui/status/coin" else "ui/status/gem"
end

local function owned(profile: any): { [string]: number }
	return profile and profile.Auras and profile.Auras.Owned or {}
end

local function profileGacha(profile: any, key: string): { [string]: any }
	local g = profile and profile.Gacha
	local t = g and g[key]
	return if type(t) == "table" then t else {}
end

-- An aura's name/orb is shown when the player owns it or the banner advertises it (featured / rate-up).
local function known(b: any, profile: any, id: string): boolean
	return (owned(profile)[id] or 0) > 0 or id == b.Featured or (b.RateUp ~= nil and b.RateUp[id] ~= nil)
end

local function orbKey(b: any, profile: any, id: string): string
	return if known(b, profile, id) then `auras/{id}` else "auras/UnknownAura"
end

-- Milestone reward -> picture key, count text, rarity (corner colour).
local function milestoneLook(m: any): (string, string, string)
	if m.Kind == "Aura" then
		return `auras/{m.Id}`, "x1", Registry.Auras[m.Id].Rarity
	elseif m.Kind == "Treasure" then
		local t = Registry.Treasures[m.Id]
		return "ui/status/treasure_chest", `x{m.Amount or 1}`, t and t.Rarity or "Epic"
	elseif m.Kind == "Bait" then
		return `equipment/{m.Id}`, `x{m.Amount or 1}`, "Rare"
	end
	local amount = m.Amount or 0
	local rarity = if amount <= 20 then "Common" elseif amount <= 50 then "Uncommon" elseif amount <= 100 then "Rare" else "Epic"
	return currencyIcon(m.Kind), `+{amount}`, rarity
end

local function clear(parent: Instance)
	for _, c in parent:GetChildren() do
		if c:IsA("GuiObject") then
			c:Destroy()
		end
	end
end

-- Fill pieces (concept D layout, UI/Screens/GachaPage) --------------------------------------------

local refresh: () -> () -- defined below (rail cards switch banner and redraw)
local DIM_STAR = Color3.fromRGB(230, 220, 203)

local function canvas(): any
	return w.Canvas
end

local function bannerOpen(b: any): boolean
	local now = os.time()
	return (b.StartsUTC == nil or now >= b.StartsUTC) and (b.EndsUTC == nil or now < b.EndsUTC)
end

-- open banners for the rail: events first (ending soonest first), then standard ones
local function openBanners(): { string }
	local ids = {}
	for id, b in Registry.AuraBanners do
		if bannerOpen(b) then
			table.insert(ids, id)
		end
	end
	table.sort(ids, function(a, c)
		local x, y = Registry.AuraBanners[a], Registry.AuraBanners[c]
		if (x.Kind == "Event") ~= (y.Kind == "Event") then
			return x.Kind == "Event"
		end
		return (x.EndsUTC or math.huge) < (y.EndsUTC or math.huge) or ((x.EndsUTC or math.huge) == (y.EndsUTC or math.huge) and x.Name < y.Name)
	end)
	return ids
end

-- showcase aura: the banner's Featured one, else the rarest aura that has a big illustration
local function heroAura(b: any): string
	if b.Featured then
		return b.Featured
	end
	local ids = Registry.SortedAuras()
	for i = #ids, 1, -1 do
		if PageScreen.HeroArt[ids[i]] then
			return ids[i]
		end
	end
	return ids[#ids]
end

local function heroKey(id: string): string
	return if PageScreen.HeroArt[id] then `auras_Art/{id}` else `auras/{id}`
end

local function bannerColor(b: any): Color3
	return if b.Kind == "Event" then T.Gem else T.SkyLip
end

local function timeLeft(b: any): string
	return if b.EndsUTC then EventHub.TimeLeft(b.EndsUTC - os.time()) else "Always"
end

local function fillTop(profile: any)
	local chips = canvas().TopBar.Chips
	chips.Gems.Value.Text = Format.Number(profile and profile.Gems or 0)
	chips.StarTokens.Value.Text = Format.Number(profile and profile.Auras and profile.Auras.StarTokens or 0)
end

local function fillRail()
	local rail = canvas().Rail
	clear(rail)
	for i, id in openBanners() do
		local b = Registry.AuraBanners[id]
		local c = gui.Templates.BannerCard:Clone()
		c.Name = id
		c.Visible = true
		c.LayoutOrder = i
		c.Parent = rail
		PageScreen.SetBannerCard(c, {
			Name = b.Name,
			Kind = if b.Kind == "Event" then "EVENT" else "STANDARD",
			Time = timeLeft(b),
			Orb = `auras/{heroAura(b)}`,
			Color = bannerColor(b),
			Selected = id == state.bannerId,
		})
		c.Activated:Connect(function()
			if state.bannerId ~= id and not state.busy and not state.auto then
				GachaPage.Show(id)
				refresh()
			end
		end)
	end
end

local function rateUpNames(b: any): string
	local names = {}
	for id in b.RateUp or {} do
		table.insert(names, Registry.Auras[id].Name)
	end
	table.sort(names)
	return table.concat(names, " and ")
end

local function fillInfo(b: any, profile: any)
	local card = canvas().InfoCard
	local event = b.Kind == "Event"
	local hasRateUp = b.RateUp ~= nil and next(b.RateUp) ~= nil
	card.Ribbon.Label.Text = if event then (if hasRateUp then "Event Banner  |  Rate Up" else "Event Banner") else "Standard Banner"
	card.Title.Text = b.Name
	card.Timer.Text.Text = if b.EndsUTC then timeLeft(b) else "Always open"
	local tenRarity = b.Ten and b.Ten.MinRarity or "Rare"
	local mult, upCount = 2, 0
	for _, m in b.RateUp or {} do
		mult = m
		upCount += 1
	end
	card.Desc.Text = if hasRateUp
		then `{rateUpNames(b)} {if upCount > 1 then "are" else "is"} {mult}x more likely. Every x10 guarantees a {tenRarity} or better.`
		else `Every x10 guarantees a {tenRarity} or better. A {b.PityRarity} is guaranteed every {b.PityPulls} pulls.`
	-- featured tiles: the banner's featured + rate-up auras (rarest first), standard banner = its 3 rarest auras
	local ids = {}
	if hasRateUp or b.Featured then
		local seen = {}
		for _, id in { b.Featured } do
			if id and not seen[id] then
				seen[id] = true
				table.insert(ids, id)
			end
		end
		for id in b.RateUp or {} do
			if not seen[id] then
				seen[id] = true
				table.insert(ids, id)
			end
		end
		table.sort(ids, function(x, y)
			return tierOf(x) > tierOf(y)
		end)
	else
		local all = Registry.SortedAuras()
		for i = #all, math.max(1, #all - 2), -1 do
			table.insert(ids, all[i])
		end
	end
	local feat = card.Featured
	clear(feat)
	for i, id in ids do
		local aura = Registry.Auras[id]
		local slot = ItemSlots.NewCell(function(holder)
			ItemDetail.Show({ Kind = "Aura", Id = id, Info = true }, holder.ItemSlot)
		end)
		slot.Name = id
		slot.Size = UDim2.fromOffset(ItemSlots.Size, ItemSlots.Size)
		slot.LayoutOrder = i
		local key = orbKey(b, profile, id)
		ItemSlots.Bind(slot, {
			Kind = "Aura",
			Id = id,
			Name = if key == "auras/UnknownAura" then "?" else aura.Name,
			Rarity = aura.Rarity,
			Icon = key,
		})
		slot.Parent = feat
	end
	local pity = profileGacha(profile, "Pity")[state.bannerId] or 0
	local left = math.max(1, b.PityPulls - pity)
	card.PityNote.Text.Text = `{left} more pull{if left == 1 then "" else "s"} and a {b.PityRarity} is guaranteed`
end

local function fillHero(b: any, profile: any)
	local cv = canvas()
	local id = heroAura(b) -- always the banner's highlight aura (shop front), never the last pull
	local a = Registry.Auras[id]
	New.SetImageKey(cv.Hero, heroKey(id), rarityColor(a.Rarity))
	local plate = cv.NamePlate
	plate.Rarity.Text = string.upper(a.Rarity)
	plate.Rarity.BackgroundColor3 = rarityColor(a.Rarity)
	plate.AuraName.Text = a.Name
	local stars = profile and profile.Auras and profile.Auras.Stars and profile.Auras.Stars[id] or 0
	for i = 1, 5 do
		local s = plate.Stars:FindFirstChild("S" .. i)
		if s then
			s.ImageColor3 = if i <= stars then T.Gold else DIM_STAR
		end
	end
end

local function fillRates(b: any, profile: any)
	local list = w.RatesPopup.Panel.List
	local have = owned(profile)
	local rates = Roll.AuraRates(0, b.RateUp) -- C17: real chance per roll (0..1) for this banner
	clear(list)
	for i, id in Registry.SortedAuras() do
		local a = Registry.Auras[id]
		local mult = (b.RateUp and b.RateUp[id]) or 1
		local show = known(b, profile, id)
		local row = gui.Templates.RateRow:Clone()
		row.Name = id
		row.Visible = true
		row.LayoutOrder = i
		row.Parent = list
		local r = rates[id]
		local chance
		if not r then
			chance = Format.Chance(math.max(1, math.floor(a.Chance / mult + 0.5)))
		else
			local pct = r * 100
			chance = if pct >= 10 then string.format("%.1f%%", pct) elseif pct >= 0.1 then string.format("%.2f%%", pct) else string.format("%.3f%%", pct)
		end
		PageScreen.SetRateRow(row, {
			Orb = orbKey(b, profile, id),
			Name = if show then a.Name else "???",
			Rarity = a.Rarity,
			RarityColor = rarityColor(a.Rarity),
			Chance = chance,
			Owned = have[id] or 0,
			RateUp = if mult ~= 1 then `x{mult}` else nil,
			Featured = id == b.Featured,
		})
	end
end

local function fillPity(b: any, profile: any)
	local box = canvas().PityMythic
	local hard = b.HardPity
	box.Visible = hard ~= nil
	if not hard then
		return
	end
	local hp = profileGacha(profile, "PityHard")[state.bannerId] or 0
	local left = math.max(1, hard.Pulls - hp)
	box.Label.Text = `{hard.Rarity} guaranteed in`
	box.Value.Text = `{left} roll{if left == 1 then "" else "s"}`
	box.Value.TextColor3 = rarityColor(hard.Rarity)
	box.Bar.Fill.Size = UDim2.fromScale(math.clamp(hp / hard.Pulls, 0, 1), 1)
end

local function fillMilestones(b: any, profile: any)
	local row = canvas().Milestones
	local popup = w.MilestonesPopup
	local list = b.Milestones
	row.Visible = list ~= nil and #list > 0
	if not row.Visible then
		popup.Visible = false
		return
	end
	local pulls = profileGacha(profile, "Pulls")[state.bannerId] or 0
	local claimed = profileGacha(profile, "Claimed")[state.bannerId] or {}
	local sorted = table.clone(list)
	table.sort(sorted, function(x, y)
		return x.Pulls < y.Pulls
	end)
	local goal = sorted[#sorted].Pulls
	local grid = popup.Panel.Grid
	clear(grid)
	local claimable = 0
	for i, ms in sorted do
		local icon, count, rarity = milestoneLook(ms)
		local st = if claimed[tostring(ms.Pulls)] then "claimed" elseif pulls >= ms.Pulls then "claimable" else "locked"
		if st == "claimable" then
			claimable += 1
		end
		local cell = gui.Templates.MilestoneCell:Clone()
		cell.Name = "M" .. ms.Pulls
		cell.Visible = true
		cell.LayoutOrder = i
		cell.Parent = grid
		PageScreen.SetMilestoneCell(cell, {
			Icon = icon,
			IconColor = rarityColor(rarity),
			CornerColor = rarityColor(rarity),
			Count = count,
			Pulls = ms.Pulls,
			State = st,
			LabelColor = if Registry.Rarities[rarity] and Registry.Rarities[rarity].Tier >= 5 then T.GoldLip else nil,
		})
		local p = ms.Pulls
		cell.Claim.Activated:Connect(function()
			GachaPage.Claim(p)
		end)
	end
	row.Value.Text = `{math.min(pulls, goal)}/{goal}`
	row.View.Dot.Visible = claimable > 0
	row.View.Dot.Text = tostring(claimable)
	local f = math.clamp(pulls / goal, 0, 1)
	row.Bar.Fill.Size = UDim2.fromScale(if pulls > 0 then math.max(f, 0.04) else 0, 1)
	local prog = popup.Panel.Progress
	prog.Value.Text = `{pulls} / {goal} pulls`
	prog.Bar.Fill.Size = UDim2.fromScale(if pulls > 0 then math.max(f, 0.04) else 0, 1)
end

local function paintRoll(btn: any, face: Color3, lip: Color3, cost: number, canPay: boolean, iconKey: string)
	New.SetButtonColor(btn, if canPay then face else T.Disabled, if canPay then nil else T.DisabledText)
	btn.AutoButtonColor = canPay
	local txt = if canPay then WHITE else T.DisabledText
	btn.Title.TextColor3 = txt
	btn.Price.BackgroundColor3 = if canPay then lip else T.DisabledLip
	btn.Price.Value.Text = Format.Number(cost)
	btn.Price.Value.TextColor3 = txt
	New.SetImageKey(btn.Price.Icon, iconKey)
	btn.Price.Icon.ImageTransparency = if canPay then 0 else 0.5
end

local function fillButtons(b: any, profile: any)
	local cv = canvas()
	local money = profile and profile[b.Currency] or 0
	local icon = currencyIcon(b.Currency)
	local c1, c10 = GachaPage.Cost(b, 1), GachaPage.Cost(b, 10)
	local free = not state.auto and not state.busy
	paintRoll(cv.RollBar.Roll1, T.Gem, T.GemLip, c1, free and money >= c1, icon)
	paintRoll(cv.RollBar.Roll10, T.Gold, T.GoldLip, c10, free and money >= c10, icon)
	cv.RollBar.Roll10.Guarantee.Text = string.upper(b.Ten and b.Ten.MinRarity or "Rare") .. "+"
	local o = cv.Options
	PageScreen.SetCheckbox(o.Skip, state.skip)
	PageScreen.SetCheckbox(o.Auto, state.auto, if state.auto then `Auto-rolling... {state.autoPulls} (tap to stop)` else "Auto-roll until Epic+")
	o.Auto.Size = UDim2.fromOffset(if state.auto then 250 else 196, 30)
	-- pay-with toggle: only Gems rolls exist on the server today (Star Token price not decided)
	local tg = cv.PayToggle
	for _, n in { "Gems", "Tokens" } do
		local on = n == state.pay
		tg[n].BackgroundTransparency = if on then 0 else 1
		tg[n].Label.TextColor3 = if on then WHITE else T.Text
	end
end

function GachaPage.Fill(profile: any)
	local b = banner()
	if not w or not b then
		return
	end
	fillTop(profile)
	fillRail()
	fillInfo(b, profile)
	fillHero(b, profile)
	fillRates(b, profile)
	fillPity(b, profile)
	fillMilestones(b, profile)
	fillButtons(b, profile)
	GachaPage.Tick()
end

function GachaPage.Tick()
	local b = banner()
	if not w or not b then
		return
	end
	for _, c in canvas().Rail:GetChildren() do
		local cb = Registry.AuraBanners[c.Name]
		if cb and c:FindFirstChild("Time") then
			c.Time.Text = timeLeft(cb)
		end
	end
	if not b.EndsUTC then
		return
	end
	local left = b.EndsUTC - os.time()
	canvas().InfoCard.Timer.Text.Text = timeLeft(b)
	if left <= 0 and ctx and ctx.isOpen() then
		GachaPage.Stop()
		ctx.notify(`{b.Name} has ended`, T.Bad)
		ctx.close()
	end
end

refresh = function()
	if ctx and ctx.refresh then
		ctx.refresh()
	elseif ctx then
		GachaPage.Fill(ctx.profile())
	end
end

-- Actions -----------------------------------------------------------------------------------------

local function best(results: { any }): any
	local top = results[1]
	for _, r in results do
		local tr, tt = tierOf(r.Aura), tierOf(top.Aura)
		if tr > tt or (tr == tt and Registry.Auras[r.Aura].Chance > Registry.Auras[top.Aura].Chance) then
			top = r
		end
	end
	return top
end

local function describe(r: any): string
	local a = Registry.Auras[r.Aura]
	return `{a.Name} ({a.Rarity}){if r.New then " NEW!" else ""}`
end

local function showSummary(results: { any })
	local p = w.Summary.Panel
	clear(p.Grid)
	local top = best(results)
	for i, r in results do
		local a = Registry.Auras[r.Aura]
		local cell = gui.Templates.ResultCell:Clone()
		cell.Visible = true
		cell.LayoutOrder = i
		cell.Parent = p.Grid
		PageScreen.SetResultCell(cell, { Orb = `auras/{r.Aura}`, Rarity = a.Rarity, RarityColor = rarityColor(a.Rarity), New = r.New, Best = r == top })
	end
	local a = Registry.Auras[top.Aura]
	local tokens = 0
	for _, r in results do
		tokens += r.Tokens or 0
	end
	-- C17 (Figma G6): duplicates turn into Star Tokens
	p.Best.Text = `Best: {New.Highlight(a.Name, rarityColor(a.Rarity))} ({a.Rarity})`
		.. (if tokens > 0 then `   +{New.Highlight(tostring(tokens) .. " Star Token" .. (if tokens == 1 then "" else "s"), T.GoldLip)} from duplicates` else "")
	state.lastResults = results
	w.Summary.Visible = true
end

local function reveal(r: any, equippedId: string?, onClose: (() -> ())?)
	if state.skip then
		local a = Registry.Auras[r.Aura]
		ctx.notify(`You got {describe(r)}`, rarityColor(a.Rarity))
		if onClose then
			onClose()
		end
		return
	end
	local auraId = r.Aura
	if (r.Tokens or 0) > 0 then
		-- C17: already owned -> Star Tokens instead of NEW!
		local a = Registry.Auras[auraId]
		ctx.notify(`{a.Name} already owned: +{r.Tokens} Star Token{if r.Tokens == 1 then "" else "s"}`, T.GoldLip)
	end
	w.Visible = false -- the roll window replaces the shop front (nothing shows through)
	ctx.playReveal(auraId, {
		isNew = r.New,
		equipped = equippedId == auraId,
		onEquip = function()
			ctx.invoke("EquipAura", auraId)
		end,
		-- x10 (onClose = summary): the middle button shows all 10 instead of pulling one more
		rollAgainText = if onClose then "SEE ALL 10" else nil,
		onRollAgain = function()
			w.Visible = true -- back first: if this pull fails (no gems) the page must not stay hidden
			if onClose then
				onClose()
			else
				GachaPage.Pull(1)
			end
		end,
		onClose = function()
			w.Visible = true
			if onClose then
				onClose()
			end
		end,
	})
end

local function canAfford(b: any, count: number): boolean
	local profile = ctx.profile()
	return (profile and profile[b.Currency] or 0) >= GachaPage.Cost(b, count)
end

function GachaPage.Pull(count: number)
	local b = banner()
	if not b or state.busy or state.auto or ctx.reelPlaying() then
		return
	end
	if not canAfford(b, count) then
		ctx.notify(`Need {GachaPage.Cost(b, count)} {string.lower(b.Currency)}`, T.Bad)
		return
	end
	state.busy = true
	fillButtons(b, ctx.profile())
	local ok, results, equippedId = ctx.invoke("PullAura", state.bannerId, count)
	state.busy = false
	if ok and type(results) == "table" and #results > 0 then
	end
	refresh()
	if not ok or type(results) ~= "table" or #results == 0 then
		ctx.notify(if type(results) == "string" then results else "Something went wrong, try again", T.Bad)
		return
	end
	if count == 10 then
		if state.skip then
			showSummary(results)
			return
		end
		reveal(best(results), equippedId, function()
			showSummary(results)
		end)
	else
		reveal(best(results), equippedId)
	end
end

function GachaPage.Claim(pulls: number)
	if state.busy then
		return
	end
	state.busy = true
	local ok, msg = ctx.invoke("ClaimMilestone", state.bannerId, pulls)
	state.busy = false
	if msg then
		ctx.notify(tostring(msg), if ok then T.Good else T.Bad)
	end
	refresh()
end

local function runAuto()
	local b = banner()
	local bannerId = state.bannerId
	state.auto = true
	state.autoPulls = 0
	refresh()
	local reason, got, equippedId = nil, nil, nil
	while state.auto do
		if not ctx.isOpen() or state.bannerId ~= bannerId then
			break
		end
		if not canAfford(b, 1) then
			reason = `out of {string.lower(b.Currency)}`
			break
		end
		state.busy = true
		local ok, results, eq = ctx.invoke("PullAura", bannerId, 1)
		state.busy = false
		if not ok or type(results) ~= "table" or #results == 0 then
			reason = if type(results) == "string" then results else "server error"
			break
		end
		state.autoPulls += 1
		local r = results[1]
		local a = Registry.Auras[r.Aura]
		if tierOf(r.Aura) >= AUTO_STOP_TIER then
			got, equippedId = r, eq
			reason = `got {a.Name}!`
			break
		end
		ctx.notify(`#{state.autoPulls}: {describe(r)}`, rarityColor(a.Rarity))
		refresh()
		task.wait(AUTO_DELAY)
	end
	local pulled = state.autoPulls
	state.auto = false
	state.busy = false
	refresh()
	if reason then
		ctx.notify(`Auto-roll stopped after {pulled} roll{if pulled == 1 then "" else "s"}: {reason}`, if got then T.GoldLip else T.SubText)
	end
	if got and ctx.isOpen() then
		reveal(got, equippedId)
	end
end

function GachaPage.SetAuto(on: boolean)
	if on == state.auto then
		return
	end
	if on then
		if state.busy or ctx.reelPlaying() then
			return
		end
		task.spawn(runAuto)
	else
		state.auto = false -- the loop sees it before the next pull
		refresh()
	end
end

function GachaPage.Stop()
	state.auto = false
	if w then
		w.Visible = true
		w.Summary.Visible = false
		w.MilestonesPopup.Visible = false
		w.RatesPopup.Visible = false
	end
end

function GachaPage.Show(bannerId: string)
	GachaPage.Stop()
	state.bannerId = bannerId
end

function GachaPage.Banner(): string?
	return state.bannerId
end

local function rescale()
	local vp = w.AbsoluteSize
	local margin = 8
	if vp.X <= margin * 2 or vp.Y <= margin * 2 then
		return
	end
	-- The first 58 design pixels reserved for CoreGui are already outside this window.
	local canvas = PageScreen.Canvas
	local topInset = 58
	local width, height = vp.X - margin * 2, vp.Y - margin * 2
	local s = math.min(width / canvas.X, height / (canvas.Y - topInset))
	local cv = w.Canvas
	cv.Scale.Scale = s
	cv.Position = UDim2.new(0.5, 0, 0.5, -topInset * s / 2)
	for _, n in { "RatesPopup", "MilestonesPopup", "Summary" } do
		local panel = w[n].Panel
		panel.Scale.Scale = math.min(1, width / panel.Size.X.Offset, height / panel.Size.Y.Offset)
	end
end

local function popup(d: any)
	local close = d.Panel:FindFirstChild("Close")
	if close then
		close.Activated:Connect(function()
			d.Visible = false
		end)
	end
end

local function mountScenery(screen: ScreenGui, window: Frame)
	-- Separate the edge-to-edge art from the controls that must respect CoreGui and device cutouts.
	local scenery = New("ScreenGui", {
		Name = "GachaScenery", Enabled = false, ResetOnSpawn = false,
		ScreenInsets = Enum.ScreenInsets.None, SafeAreaCompatibility = Enum.SafeAreaCompatibility.None,
		ClipToDeviceSafeArea = false, Parent = screen.Parent,
	}) :: ScreenGui
	local art = New("Frame", {
		Name = "Art", Size = UDim2.fromScale(1, 1), BackgroundColor3 = window.BackgroundColor3,
		BorderSizePixel = 0, Parent = scenery,
	}) :: Frame
	window.BackgroundTransparency = 1
	local tint = window:FindFirstChild("Dim")
	if tint then
		tint:Destroy() -- older baked copies tinted only the inset rectangle
	end
	for _, name in { "Bg", "Floor" } do
		local layer = window:FindFirstChild(name)
		if layer then
			layer.Parent = art
		end
	end

	for i, position in { Vector2.new(0.11, 0.76), Vector2.new(0.87, 0.25) } do
		local image = New.Image({
			Name = "Bubbles" .. i, Key = "fish/deco_bubbles", AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(position.X, position.Y), Size = UDim2.fromScale(0.13, 0.31), ImageTransparency = 0.77,
			ZIndex = 2, Parent = art,
		})
		image.Fallback.BackgroundTransparency = 1
	end

	local function syncOrder()
		scenery.DisplayOrder = screen.DisplayOrder - 1
	end
	local function syncVisibility()
		scenery.Enabled = screen.Enabled and window.Visible
	end
	screen:GetPropertyChangedSignal("DisplayOrder"):Connect(syncOrder)
	screen:GetPropertyChangedSignal("Enabled"):Connect(syncVisibility)
	window:GetPropertyChangedSignal("Visible"):Connect(syncVisibility)
	screen.Destroying:Connect(function()
		scenery:Destroy()
	end)
	syncOrder()
	syncVisibility()
end

function GachaPage.Bind(screenGui: any, context: any)
	gui = screenGui
	w = gui.Window
	ctx = context
	local cv = w.Canvas
	-- Also configure copies already baked into StarterGui.
	gui.ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets
	gui.SafeAreaCompatibility = Enum.SafeAreaCompatibility.None
	mountScenery(gui, w)
	cv.NamePlate.AnchorPoint = Vector2.new(1, 0)
	cv.NamePlate.Position = UDim2.fromOffset(1256, 520)
	for _, name in { "RatesPopup", "MilestonesPopup", "Summary" } do
		w[name].BackgroundTransparency = 1 -- transparent input shields, including older bakes
	end
	rescale()
	w:GetPropertyChangedSignal("AbsoluteSize"):Connect(rescale)
	gui:GetPropertyChangedSignal("Enabled"):Connect(function()
		if gui.Enabled then
			rescale()
		end
	end)

	cv.TopBar.Back.Activated:Connect(function()
		GachaPage.Stop()
		ctx.back()
	end)
	local function store()
		if ctx.openStore then
			GachaPage.Stop()
			ctx.openStore("Gems")
		else
			ctx.notify("Store is not available here", T.SubText)
		end
	end
	cv.TopBar.Chips.Gems.Activated:Connect(store) -- no "+" on the chip: tapping it is the Top Up
	cv.TopBar.Chips.StarTokens.Activated:Connect(function()
		ctx.notify("Star Tokens come from duplicate auras", T.GoldLip)
	end)
	cv.SmallButtons.Shop.Activated:Connect(store)
	cv.SmallButtons.Rates.Activated:Connect(function()
		w.RatesPopup.Visible = true
	end)
	cv.PayToggle.Gems.Activated:Connect(function()
		state.pay = "Gems"
		refresh()
	end)
	cv.PayToggle.Tokens.Activated:Connect(function()
		ctx.notify("Rolling with Star Tokens is coming soon", T.SubText)
	end)
	cv.RollBar.Roll1.Activated:Connect(function()
		GachaPage.Pull(1)
	end)
	cv.RollBar.Roll10.Activated:Connect(function()
		GachaPage.Pull(10)
	end)
	cv.Options.Skip.Activated:Connect(function()
		state.skip = not state.skip
		refresh()
	end)
	cv.Options.Auto.Activated:Connect(function()
		GachaPage.SetAuto(not state.auto)
	end)
	cv.Milestones.View.Activated:Connect(function()
		w.MilestonesPopup.Visible = true
	end)
	popup(w.RatesPopup)
	popup(w.MilestonesPopup)
	-- x10 summary (Figma G6)
	local sum = w.Summary
	local buttons = sum.Panel.Buttons
	buttons.Close.Activated:Connect(function()
		sum.Visible = false
	end)
	buttons.EquipBest.Activated:Connect(function()
		local res = state.lastResults
		sum.Visible = false
		if res and #res > 0 then
			local top = best(res).Aura
			local ok, msg = ctx.invoke("EquipAura", top)
			ctx.notify(if ok then `Equipped {Registry.Auras[top].Name}` else tostring(msg), if ok then T.Good else T.Bad)
		end
	end)
	buttons.Again.Activated:Connect(function()
		sum.Visible = false
		GachaPage.Pull(10)
	end)
end

return GachaPage
