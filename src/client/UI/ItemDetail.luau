--!nonstrict
-- Item Card popover (B21, Figma 18B option A). One card for every item kind, opened from any slot:
--   ItemDetail.Show(item, anchor)   item = { Kind = "Rod"|"Line"|"Aura"|"Fish"|"Bait"|"Treasure"|"Bag"|"Species", Id,
--                                   UUID?, Info? }  (Species = Fishdex entry; Info = opened from a catalogue)
--                                   (UUID = the bag item for Fish / Treasure / Rod / Line; a Rod or Line without
--                                   UUID is a catalogue card), anchor = the pressed GuiObject
--   ItemDetail.Hide(), ItemDetail.IsShowing(), ItemDetail.Refresh() (re-reads the profile; hides the card
--   if the item is gone, e.g. a stack was sold)
-- Placement: right of the anchor; flips to the left when there is no room; clamped to the screen.
-- Owned items get the Actions row (buttons per kind); not owned gear shows "Get from" (info only).
-- The baked ItemDetail layout is fitted to the viewport at runtime, with Actions below the scroll area.
-- Server calls use the existing remotes
-- (Equip, Enhance, EquipAura, StarUpAura, SellItem, PutInTank, OpenTreasure).
-- Needs ItemDetail.Init({ Profile, Stats, Notify, Changed }) once (from InventoryController) so this UI
-- module does not require controllers.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Registry = require(Shared.Registry)
local Remotes = require(Shared.Remotes)
local Inventory = require(Shared.Inventory)
local Enhance = require(Shared.Enhance)
local AuraStars = require(Shared.AuraStars)
local HotFish = require(Shared.HotFish)
local Format = require(Shared.Util.Format)
local Signal = require(Shared.Util.Signal)

local New = require(script.Parent.New)
local Baked = require(script.Parent.Baked)
local MenuManager = require(script.Parent.MenuManager)
local EnhancePopup = require(script.Parent.EnhancePopup)
local Modal = require(script.Parent.Modal)
local SetItemSlot = (require(script.Parent.Screens:WaitForChild("Components")) :: any).SetItemSlot

local T = New.Theme

local ItemDetail = {}
ItemDetail.Hidden = Signal.new() -- () card closed (any window that opened it clears its selection)

-- Info = true: opened from a catalogue (Shop / Fishdex), so a bait you have none of still shows (Get from).
export type Item = { Kind: string, Id: string, UUID: string?, Info: boolean? }

local Screen_INNER = 248 -- card width 280 minus padding
local CATEGORY = { Rod = "Rods", Line = "Lines", Bait = "Baits" }
local GAP = 12 -- card to slot
local MARGIN = 8

local deps: any = nil
local gui: any = nil
local refs: any = nil
local current: Item? = nil
local anchorObj: GuiObject? = nil
local centered = false
local compactMode = false -- small screen: the card is centred with an input shield behind it
local busy = false
local handlers: { [number]: (() -> ())? } = {}

-- Data helpers -------------------------------------------------------------------------------------

local function rarityColor(id: string?): Color3
	local r = id and Registry.Rarities[id]
	return if r then r.Color else T.Track
end

local function gearRarity(cat: string, id: string): string
	return Registry.GearRarity(cat, id)
end

local function statBadges(stats: { [string]: number }?, mutations: { [string]: number }?): { any }
	local out = {}
	if stats then
		local keys = {}
		for k in stats do
			if Registry.StatDefs[k] then
				table.insert(keys, k)
			end
		end
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
			if mut then
				table.insert(out, { Text = `{Format.Percent(v)} {mut.Name}`, Color = mut.Color })
			end
		end
	end
	return out
end

-- Short price for a 48px button (label + cost stay on one line): 950, 1.2K, 90K, 1.5M
local function short(n: number): string
	n = math.floor(n)
	if n < 1000 then
		return tostring(n)
	end
	for _, s in { { 1e9, "B" }, { 1e6, "M" }, { 1e3, "K" } } do
		if n >= s[1] then
			local v = n / s[1]
			local txt = if v < 10 then string.format("%.1f", v) else tostring(math.floor(v))
			return (string.gsub(txt, "%.0$", "")) .. s[2]
		end
	end
	return tostring(n)
end

local function sellMultiplier(): number
	local stats = deps.Stats()
	return stats and stats.Values.SellMultiplier or 1
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
		deps.Notify("Something went wrong, try again", T.Bad)
		return nil, nil, nil
	end
	return a, b, c
end

-- (ok, message) remotes: notify + refresh
local function simple(name: string, ...: any)
	local ok, msg = call(name, ...)
	if type(msg) == "string" and msg ~= "OK" then
		deps.Notify(msg, if ok then T.Good else T.Bad)
	end
	deps.Changed()
end

-- Card model per kind --------------------------------------------------------------------------------
-- Returns nil when the item no longer exists (sold stack, bad id).
-- { Icon, Rarity, RarityText, KindText, Name, Stats = badges, Desc, Meta = badges, Stars = n?, Modifiers,
--   Owned, Actions = { {Text, Color, Run?, CostIcon?, Cost?} }, GetFrom = { Icon, Text }? }
-- Action with CostIcon + Cost = label | icon value on one line (Figma 48px button).

-- "Shop - Lv.12 - 15,000" (or the exclusive source) for gear / baits the player does not have.
local function shopSource(def: any): any
	local parts = {}
	if def.Exclusive then
		table.insert(parts, if def.Exclusive == "StarterPack" then "Starter Pack" else def.Exclusive)
	else
		table.insert(parts, "Shop")
		if def.RequiredLevel then
			table.insert(parts, `Lv.{def.RequiredLevel}`)
		end
		table.insert(parts, if def.Price > 0 then Format.Number(def.Price) else "Free")
	end
	return { Icon = if def.Currency == "Gems" then "ui/status/gem" else "ui/status/coin", Text = table.concat(parts, " - ") }
end

local function gearModel(profile: any, item: Item): any
	local cat = CATEGORY[item.Kind]
	local def = Registry.Equipment[cat].Items[item.Id]
	if not def then
		return nil
	end
	-- item.UUID = a bag item; none = a catalogue card (Shop), which you may not own
	local gear = if item.UUID then Inventory.Find(profile, item.UUID) else nil
	if item.UUID and (not gear or gear.Id ~= item.Id) then
		return nil
	end
	local owned = gear ~= nil
	local equipped = gear ~= nil and profile.Equipped[cat] == gear.UUID
	local lv = Enhance.Level(gear)
	local rarity = gearRarity(cat, item.Id)
	local meta = {}
	if equipped then
		table.insert(meta, { Text = "Equipped", Color = T.Good })
	end
	if lv > 0 then
		table.insert(meta, { Text = `+{lv}`, Color = T.Gem })
	end
	if gear then
		if Inventory.IsBound(gear) then
			table.insert(meta, { Text = "Bound", TextColor = T.SubText })
		end
	end
	local m = {
		Icon = `equipment/{item.Id}`,
		Rarity = rarity,
		KindText = item.Kind,
		Name = def.Name,
		Stats = statBadges(Enhance.ScaledStats(def.Stats, lv)),
		Desc = def.Description,
		Meta = meta,
		Mods = if (item.Kind == "Rod" or item.Kind == "Line") and gear then { Prefixes = gear.Prefixes or {}, Suffixes = gear.Suffixes or {} } else nil,
		Owned = owned,
		Actions = {},
	}
	if gear then
		local uuid = gear.UUID
		table.insert(m.Actions, if equipped
			then { Text = "EQUIPPED", Color = T.Disabled }
			else { Text = "EQUIP", Color = T.Good, Run = function()
				simple("Equip", cat, uuid)
			end })
		if Enhance.CanEnhance(cat, item.Id) then
			local coins = Enhance.Cost(cat, item.Id, lv)
			table.insert(m.Actions, if coins
				then { Text = "ENHANCE", Color = T.Gem, Run = function()
					-- C16: preview +N -> +N+1 and the stat changes first (Figma Enhance popup)
					EnhancePopup.Open({ Name = def.Name, Icon = `equipment/{item.Id}`, State = Enhance.State(gear) }, function()
						simple("Enhance", uuid)
					end)
				end }
				else { Text = `MAX +{lv}`, Color = T.Disabled })
		end
		local value = Inventory.SellValue(gear, 1)
		if not equipped and (value > 0 or def.Price == 0) then
			table.insert(m.Actions, { Text = "SELL", CostIcon = "ui/status/coin", Cost = short(value), Color = T.Gold, Run = function()
				local invested = Inventory.Investment(gear)
				if not invested then
					simple("SellItem", uuid)
					return
				end
				-- Enhance or mods would be lost: ask first
				Modal.Confirm({
					Title = `Sell {def.Name} {invested}?`,
					Message = `You will get {New.Highlight(Format.Number(value) .. " coins", T.GoldLip)}. The {invested} on this {string.lower(item.Kind)} is lost for good.`,
					ConfirmText = "Sell",
					ConfirmColor = T.Gold,
					Icon = "ui/status/sell_bag",
					IconColor = T.Gold,
				}, function()
					simple("SellItem", uuid, true)
				end)
			end })
		end
	else
		m.GetFrom = shopSource(def)
	end
	return m
end

-- Bags are upgrades (Inventory capacity pill), so the card has no buttons.
local function bagModel(profile: any, item: Item): any
	local def = Registry.Equipment.Bags.Items[item.Id]
	if not def then
		return nil
	end
	local owned = profile.Owned.Bags and profile.Owned.Bags[item.Id] == true
	local meta = { { Text = `{def.Capacity or 0} slots` } }
	if profile.Equipped.Bags == item.Id then
		table.insert(meta, 1, { Text = "In use", Color = T.Good })
	end
	return {
		Icon = `equipment/{item.Id}`,
		Rarity = gearRarity("Bags", item.Id),
		KindText = "Bag",
		Name = def.Name,
		Stats = statBadges(def.Stats),
		Desc = def.Description or "Bags are upgrades: each one replaces the last.",
		Meta = meta,
		Owned = owned,
		Actions = {},
		GetFrom = if owned then nil else shopSource(def),
	}
end

-- Fishdex entry (species, not a bag stack). Not caught yet = mystery card.
local function speciesModel(profile: any, item: Item): any
	local f = Registry.Fish[item.Id]
	if not f then
		return nil
	end
	local dex = profile.Fishdex[item.Id]
	local depth = `{f.DepthMin}-{f.DepthMax}m`
	if not dex then
		return {
			Icon = "fish/MysteryFish",
			Rarity = f.Rarity,
			KindText = "Fish",
			Name = "???",
			NameColor = T.SubText,
			Stats = {},
			Desc = "Not caught yet.",
			Meta = {},
			Owned = false,
			Actions = {},
			GetFrom = { Icon = "ui/status/bobber", Text = `Fish at {depth}` },
		}
	end
	local meta = { { Text = `Caught x{dex.Count}` }, { Text = string.format("Best %.2f kg", dex.Best or 0), TextColor = T.SubText } }
	local hot = HotFish.Mult(item.Id)
	if hot > 1 then
		table.insert(meta, { Text = `HOT x{hot}`, Color = T.Bad })
	end
	return {
		Icon = `fish/{item.Id}`,
		Rarity = f.Rarity,
		KindText = "Fish",
		Name = f.Name,
		Stats = {},
		Desc = f.Description,
		Meta = meta,
		Owned = false,
		Actions = {},
		GetFrom = { Icon = "ui/status/bobber", Text = `Fish at {depth}` },
	}
end

local function auraModel(profile: any, item: Item): any
	local def = Registry.Auras[item.Id]
	if not def then
		return nil
	end
	local owned = profile.Auras.Owned[item.Id] ~= nil
	local equipped = profile.Auras.Equipped == item.Id
	local stars = AuraStars.Stars(profile, item.Id)
	local meta = { { Text = Format.Chance(def.Chance), TextColor = T.SubText } }
	if equipped then
		table.insert(meta, 1, { Text = "Equipped", Color = T.Good })
	end
	local stOwned = profile.Auras and profile.Auras.StarTokens or 0
	table.insert(meta, { Text = `{stOwned} Tokens`, Color = T.Gold, TextColor = T.Text })
	local m = {
		Icon = `auras/{item.Id}`,
		Rarity = def.Rarity,
		KindText = "Aura",
		Name = def.Name,
		Stats = statBadges(AuraStars.ScaledStats(def.Stats, stars), def.Mutations),
		Desc = def.Description,
		Meta = meta,
		Stars = stars,
		Owned = owned,
		Actions = {},
	}
	if owned then
		table.insert(m.Actions, if equipped
			then { Text = "UNEQUIP", Color = T.PanelLight, Run = function()
				simple("EquipAura", nil)
			end }
			else { Text = "EQUIP", Color = T.Good, Run = function()
				simple("EquipAura", item.Id)
			end })
		local cost = AuraStars.Cost(item.Id, stars)
		local starUp: any = if cost
			then { Text = "STAR UP", CostIcon = "ui/status/star_token", Cost = tostring(cost), Color = T.Sky, Run = function()
				simple("StarUpAura", item.Id)
			end }
			else { Text = "MAX STARS", Color = T.Disabled }
		table.insert(m.Actions, starUp)
	else
		m.GetFrom = { Icon = "ui/icons/auras", Text = "Aura Altar roll" }
	end
	return m
end

local function fishModel(profile: any, item: Item): any
	local s = item.UUID and Inventory.Find(profile, item.UUID)
	if not s or s.Kind ~= "Fish" or s.Id ~= item.Id then
		return nil
	end
	local f = Registry.Fish[s.Id]
	local name, rarity = Inventory.Describe(s)
	local value = Inventory.SellValue(s, sellMultiplier())
	local meta = {}
	if (s.Weight or 0) > 0 then
		table.insert(meta, { Text = string.format("%.2f kg", s.Weight) })
	end
	for _, tag in s.Tags or {} do
		table.insert(meta, { Text = tag, TextColor = T.SubText, Color = if tag == "Perfect" then T.Gold elseif tag == "Hotspot" then T.Sky else nil })
	end
	local hot = HotFish.Mult(s.Id)
	if hot > 1 then
		table.insert(meta, { Text = `HOT x{hot}`, Color = T.Bad })
	end
	local mut = s.Mutation and Registry.Mutations[s.Mutation]
	if mut then
		table.insert(meta, { Text = mut.Name, Color = mut.Color })
	end
	if Inventory.IsBound(s) then
		table.insert(meta, { Text = "Bound", TextColor = T.SubText })
	end
	local uuid = s.UUID
	return {
		Icon = `fish/{s.Id}`,
		Rarity = rarity,
		KindText = "Fish",
		Name = name,
		Stats = {},
		Desc = f and f.Description,
		Meta = meta,
		Owned = true,
		Actions = {
			{ Text = "SELL", CostIcon = "ui/status/coin", Cost = short(value), Color = T.Gold, Run = function()
				simple("SellItem", uuid)
			end },
			{ Text = "TANK", Color = T.Sky, Run = function()
				ItemDetail.Hide()
				deps.OpenTankPicker(s.Id, s.Mutation)
			end },
		},
	}
end

local function baitModel(profile: any, item: Item): any
	local def = Registry.Equipment.Baits.Items[item.Id]
	local count = profile.Consumables and profile.Consumables.Baits and profile.Consumables.Baits[item.Id] or 0
	if not def or (count <= 0 and not item.Info) then
		return nil
	end
	local owned = count > 0
	local equipped = profile.Equipped.Baits == item.Id
	local meta = if owned then { { Text = `x{count}` } } else {}
	if equipped then
		table.insert(meta, { Text = "Equipped", Color = T.Good })
	end
	return {
		Icon = `equipment/{item.Id}`,
		Rarity = nil,
		RarityText = "Bait",
		RarityColor = T.Gold,
		KindText = "Bait",
		Name = def.Name,
		NameColor = T.GoldLip,
		Stats = statBadges(def.Stats),
		Desc = def.Description or "1 used per catch.",
		Meta = meta,
		Owned = owned,
		GetFrom = if owned then nil else shopSource(def),
		Actions = {
			if equipped
				then { Text = "UNEQUIP", Color = T.PanelLight, Run = function()
					simple("Equip", "Baits", nil)
				end }
				else { Text = "EQUIP", Color = T.Good, Run = function()
					simple("Equip", "Baits", item.Id)
				end },
		},
	}
end

local function treasureModel(profile: any, item: Item): any
	local s = item.UUID and Inventory.Find(profile, item.UUID)
	if not s or s.Kind ~= "Treasure" or s.Id ~= item.Id then
		return nil
	end
	local def = Registry.Treasures[s.Id]
	local name, rarity, icon = Inventory.Describe(s)
	local uuid = s.UUID
	return {
		Icon = icon,
		Rarity = rarity,
		KindText = "Treasure",
		Name = name,
		Stats = {},
		Desc = if def and def.Rewards then "Coins, gems or a material inside." else nil,
		Meta = { { Text = `x{s.Count}` } },
		Owned = true,
		Actions = {
			{
				Text = "OPEN",
				Color = T.Accent,
				Run = function()
					local ok, msg = call("OpenTreasure", uuid)
					if msg then
						deps.Notify(tostring(msg), if ok then T.Gold else T.Bad)
					end
					deps.Changed()
				end,
			},
			{
				Text = "OPEN ALL",
				Color = T.Accent,
				Run = function()
					local ok, msg = call("OpenAllTreasure", uuid)
					if msg then
						deps.Notify(tostring(msg), if ok then T.Gold else T.Bad)
					end
					deps.Changed()
				end,
			},
		},
	}
end

local MODELS = {
	Rod = gearModel,
	Line = gearModel,
	Aura = auraModel,
	Fish = fishModel,
	Bait = baitModel,
	Bag = bagModel,
	Species = speciesModel,
	Treasure = treasureModel,
}

-- View ---------------------------------------------------------------------------------------------

local squeezedExtra = 0 -- height of Desc/Meta hidden on short screens (0 = shown)
local descWanted, metaWanted = false, false

local function fitBody()
	local screen = gui.AbsoluteSize
	if screen.X <= MARGIN * 2 or screen.Y <= MARGIN * 2 then
		return
	end
	local compact = screen.Y < 500 or screen.X < 600
	local height = math.min(screen.Y - MARGIN * 2, if compact then screen.Y * 0.78 else screen.Y)
	local availableWidth = screen.X - MARGIN * 2
	local displayedScale = refs.Scale.Scale
	local measured = math.round(refs.BodyLayout.AbsoluteContentSize.Y / displayedScale)
	local footer = if refs.Actions.Visible then refs.Actions.AbsoluteSize.Y / displayedScale + refs.CardLayout.Padding.Offset else 0
	local padding = refs.Padding.PaddingTop.Offset + refs.Padding.PaddingBottom.Offset
	-- The card never scrolls. Too tall: scale the whole card down (floor 0.5); if that would be unreadably small
	-- (under 0.7) the secondary text (description, badges) is dropped first so the rest stays large.
	local full = measured + squeezedExtra
	local fitFull = height / math.max(1, full + footer + padding)
	if squeezedExtra == 0 and fitFull < 0.7 and (descWanted or metaWanted) then
		local gap = refs.BodyLayout.Padding.Offset
		for _, pair in { { refs.Desc, descWanted }, { refs.Meta, metaWanted } } do
			if pair[2] then
				squeezedExtra += math.round(pair[1].AbsoluteSize.Y / displayedScale) + gap
				pair[1].Visible = false
			end
		end
	elseif squeezedExtra > 0 and fitFull >= 0.7 then
		refs.Desc.Visible = descWanted
		refs.Meta.Visible = metaWanted
		squeezedExtra = 0
	end
	local naturalHeight = full - squeezedExtra
	local fitScale = height / math.max(1, naturalHeight + footer + padding)
	local scale = math.max(0.5, math.min(if compact then 0.875 else 1, availableWidth / refs.Card.Size.X.Offset, fitScale))
	refs.Scale.Scale = scale
	refs.Body.Size = UDim2.new(1, 6, 0, naturalHeight)
end

-- Phones and short or narrow screens have no room beside the pressed slot: centre the card instead.
local function compactScreen(): boolean
	local camera = workspace.CurrentCamera
	local vp = if camera then camera.ViewportSize else Vector2.new(1280, 720)
	return vp.X < 900 or vp.Y < 480
end

local function ensure()
	if gui then
		return
	end
	gui = Baked.Get("ItemDetail")
	gui.Enabled = false
	gui.ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets
	local card = Baked.Find(gui, "Card")
	refs = {
		Card = card,
		Nub = Baked.Find(gui, "Nub"),
		Picture = Baked.Find(card, "Head/Picture"),
		Name = Baked.Find(card, "Head/Info/Name"),
		Tags = Baked.Find(card, "Head/Info/Tags"),
		Stars = Baked.Find(card, "Head/Info/Stars"),
		Stats = Baked.Find(card, "Stats"),
		Desc = Baked.Find(card, "Desc"),
		Meta = Baked.Find(card, "Meta"),
		Modifiers = Baked.Find(card, "Modifiers"),
		Actions = Baked.Find(card, "Actions"),
		Buttons = {},
		GetFrom = Baked.Find(card, "GetFrom"),
		GetIcon = Baked.Find(card, "GetFrom/Row/Icon"),
		GetLabel = Baked.Find(card, "GetFrom/Row/Label"),
	}
	-- transparent catcher behind the card (compact screens): tap outside the card closes it
	refs.Shield = New("TextButton", { Name = "Shield", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = "", AutoButtonColor = false, Visible = false, ZIndex = 0, Parent = gui })
	refs.Shield.Activated:Connect(function()
		ItemDetail.Hide()
	end)
	refs.CardLayout = card:FindFirstChildOfClass("UIListLayout")
	refs.Padding = card:FindFirstChildOfClass("UIPadding")
	refs.Scale = card:FindFirstChildOfClass("UIScale") or New("UIScale", { Parent = card })
	-- Modifiers block (Figma "Mod options" D, Chips): 2 prefix + 2 suffix pills that wrap; "+" = empty slot.
	-- Built here so an older bake works too.
	for _, c in refs.Modifiers:GetChildren() do
		c:Destroy()
	end
	refs.Modifiers.Size = UDim2.fromOffset(Screen_INNER, 0)
	refs.Modifiers.AutomaticSize = Enum.AutomaticSize.Y
	New("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Wraps = true, Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder, Parent = refs.Modifiers })
	refs.ModChips = { Prefix = {}, Suffix = {} }
	for si, kind in { "Prefix", "Suffix" } do
		for i = 1, 2 do
			refs.ModChips[kind][i] = New.Text({
				Name = kind .. i,
				Size = UDim2.fromOffset(0, 24),
				AutomaticSize = Enum.AutomaticSize.X,
				BackgroundTransparency = 0, -- New.Text is transparent by default: the chip colour must show
				BackgroundColor3 = T.PanelLight,
				Text = "",
				TextSize = 13,
				LayoutOrder = si * 10 + i,
				Parent = refs.Modifiers,
				[New.Children] = { New.Pill(), New("UIPadding", { PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10) }) },
			})
			refs.ModChips[kind][i].TextScaled = false
			refs.ModChips[kind][i].FontFace = T.FontBadge
			refs.ModChips[kind][i].AutomaticSize = Enum.AutomaticSize.X
		end
	end
	-- A plain Frame, not a ScrollingFrame: those always clip, which cut the corner of the picture slot.
	refs.Body = New("Frame", {
		Name = "Body",
		Size = UDim2.new(1, 6, 0, 0),
		LayoutOrder = 1,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Parent = card,
	})
	refs.BodyLayout = refs.CardLayout:Clone()
	refs.BodyLayout.Parent = refs.Body
	for _, name in { "Head", "Stats", "Desc", "Meta", "Modifiers", "GetFrom" } do
		card[name].Parent = refs.Body
	end
	refs.Picture.Count.Visible = false
	for i = 1, 3 do
		local b = Baked.Find(refs.Actions, "Buttons/A" .. i)
		refs.Buttons[i] = b
		local rowLayout = b.Parent:FindFirstChildOfClass("UIListLayout")
		if rowLayout then
			rowLayout.Wraps = true -- a third button drops to its own row
			b.Parent.AutomaticSize = Enum.AutomaticSize.Y
		end
		local face = b:FindFirstChild("Face")
		local lbl = face and face:FindFirstChild("Label")
		if lbl then
			lbl.TextWrapped = false -- one line: shrink the text instead (Figma: label + cost on one line)
		end
		b.Activated:Connect(function()
			local h = handlers[i]
			if h and not busy then
				h()
			end
		end)
	end
	-- press outside the card (and outside its own slot, which toggles) = close
	UserInputService.InputBegan:Connect(function(input)
		if not current or centered then
			return
		end
		local t = input.UserInputType
		if t ~= Enum.UserInputType.MouseButton1 and t ~= Enum.UserInputType.Touch then
			return
		end
		local p = Vector2.new(input.Position.X, input.Position.Y)
		local function inside(o: GuiObject?): boolean
			if not o or not o.Parent then
				return false
			end
			local ap, as = o.AbsolutePosition, o.AbsoluteSize
			return p.X >= ap.X and p.Y >= ap.Y and p.X <= ap.X + as.X and p.Y <= ap.Y + as.Y
		end
		-- InputObject.Position and AbsolutePosition are both below the top bar inset (IgnoreGuiInset = false)
		if not inside(refs.Card) and not inside(anchorObj) then
			ItemDetail.Hide()
		end
	end)
	local function onLayoutChanged()
		if current then
			fitBody()
		end
	end
	gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(onLayoutChanged)
	refs.Actions:GetPropertyChangedSignal("AbsoluteSize"):Connect(onLayoutChanged)
	refs.BodyLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(onLayoutChanged)
	refs.Card:GetPropertyChangedSignal("AbsoluteSize"):Connect(ItemDetail.Place)
	gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(ItemDetail.Place)
end

local function render(m: any)
	local color = m.RarityColor or rarityColor(m.Rarity)
	SetItemSlot(refs.Picture, { Icon = m.Icon, IconColor = color, IconText = string.upper(string.sub(m.Name, 1, 1)), CornerColor = color })
	refs.Picture.Count.Visible = false
	refs.Name.Text = m.Name
	refs.Name.TextColor3 = m.NameColor or color
	local rarityText = m.RarityText or (if m.Rarity then string.upper(m.Rarity) else "")
	New.SetBadges(refs.Tags, { { Text = rarityText, Color = color }, { Text = m.KindText } })
	refs.Stars.Visible = m.Stars ~= nil
	if m.Stars then
		for i = 1, 5 do
			refs.Stars["Star" .. i].ImageColor3 = if i <= m.Stars then Color3.new(1, 1, 1) else Color3.fromRGB(80, 80, 80)
			refs.Stars["Star" .. i].ImageTransparency = if i <= m.Stars then 0 else 0.6
		end
	end
	refs.Stats.Visible = #m.Stats > 0
	New.SetBadges(refs.Stats, m.Stats)
	squeezedExtra = 0
	descWanted = m.Desc ~= nil and m.Desc ~= ""
	metaWanted = #m.Meta > 0
	refs.Desc.Visible = descWanted
	refs.Desc.Text = m.Desc or ""
	refs.Meta.Visible = metaWanted
	New.SetBadges(refs.Meta, m.Meta)
	refs.Modifiers.Visible = m.Mods ~= nil and (#m.Mods.Prefixes + #m.Mods.Suffixes) > 0 -- no mods, no block
	if m.Mods then
		local limits = Registry.GameConfig.Inventory
		for kind, list in { Prefix = m.Mods.Prefixes, Suffix = m.Mods.Suffixes } do
			local tint = if kind == "Prefix" then T.Sky else T.Gem
			local max = if kind == "Prefix" then limits.MaxPrefixes else limits.MaxSuffixes
			for i, chip in refs.ModChips[kind] do
				local mod = list[i]
				chip.Visible = mod ~= nil and i <= max -- empty slots are not shown
				if mod then
					chip.BackgroundColor3 = if mod.Value < 0 then T.Bad else tint -- red = cursed (negative) roll
					chip.TextColor3 = Color3.new(1, 1, 1)
					chip.Text = `{mod.Name}  {Format.Mod(mod.Stat, Registry.StatDefs, mod.Value)}`
				end
			end
		end
	end
	refs.Actions.Visible = m.Owned and #m.Actions > 0
	for i, b in refs.Buttons do
		local a = m.Actions[i]
		b.Visible = a ~= nil and m.Owned
		handlers[i] = if a then a.Run else nil
		if a then
			New.SetButtonColor(b, a.Color, if a.Color == T.Disabled then T.DisabledText else nil)
			b.AutoButtonColor = a.Run ~= nil
			local face = b:FindFirstChild("Face")
			local cost = face and face:FindFirstChild("Cost")
			local withCost = cost ~= nil and a.Cost ~= nil
			b.Text = if withCost then "" else a.Text
			-- Rows of at most two buttons (never squeezed): 1 = full width, 2 = side by side, 3 = two then one full
			-- width. In a pair a button with a cost gets 1.6 shares, a plain one 1.
			local flex = b:FindFirstChildOfClass("UIFlexItem")
			if flex then
				flex.FlexMode = Enum.UIFlexMode.None
			end
			local n = #m.Actions
			local height = b.Size.Y.Offset
			if n == 1 or (n == 3 and i == 3) then
				b.Size = UDim2.new(1, 0, 0, height)
			else
				local wa = if m.Actions[1].Cost ~= nil then 1.6 else 1
				local wb = if m.Actions[2].Cost ~= nil then 1.6 else 1
				local f = (if i == 1 then wa else wb) / (wa + wb)
				b.Size = UDim2.new(f, -8 * f, 0, height)
			end
			if cost then
				cost.Visible = withCost
				if withCost then
					cost.Label.Text = a.Text
					cost.Value.Text = a.Cost
					cost.Label.TextColor3 = b.TextColor3
					cost.Value.TextColor3 = b.TextColor3
					New.SetImageKey(cost.Icon, a.CostIcon or "ui/status/coin", T.Gold)
				end
			elseif a.Cost then
				b.Text = `{a.Text}  {a.Cost}` -- screen baked before the Cost content existed
			end
		end
	end
	refs.GetFrom.Visible = not m.Owned and m.GetFrom ~= nil
	if m.GetFrom then
		New.SetImageKey(refs.GetIcon, m.GetFrom.Icon, T.Gold)
		refs.GetLabel.Text = m.GetFrom.Text
	end
end

-- Put the card beside the anchor (right, else left), nub pointing at the anchor's middle.
function ItemDetail.Place()
	local a = anchorObj
	if not a or not refs or not a.Parent then
		return
	end
	local screen = gui.AbsoluteSize
	local size = refs.Card.AbsoluteSize
	local ap, as = a.AbsolutePosition, a.AbsoluteSize
	if centered then
		refs.Nub.Visible = false
		local y = if compactMode then math.max(MARGIN, (screen.Y - size.Y) / 2) else math.max(MARGIN, math.min((screen.Y - size.Y) / 2, ap.Y - size.Y - GAP))
		refs.Card.Position = UDim2.fromOffset(math.max(MARGIN, (screen.X - size.X) / 2), y)
		return
	end
	local right = ap.X + as.X + GAP + size.X <= screen.X - MARGIN
	local left = ap.X - GAP - size.X >= MARGIN
	local x = if right then ap.X + as.X + GAP else ap.X - GAP - size.X
	x = math.clamp(x, MARGIN, math.max(MARGIN, screen.X - size.X - MARGIN))
	local y = math.clamp(ap.Y - 6, MARGIN, math.max(MARGIN, screen.Y - size.Y - MARGIN))
	refs.Card.Position = UDim2.fromOffset(x, y)
	refs.Nub.Visible = (right or left) and size.Y >= 40
	if refs.Nub.Visible then
		local nubY = math.clamp(ap.Y + as.Y / 2, y + 20, y + size.Y - 20)
		refs.Nub.Position = UDim2.fromOffset(if right then x else x + size.X, nubY)
	end
end

function ItemDetail.Refresh()
	if not current or not gui then
		return
	end
	local profile = deps.Profile()
	local build = MODELS[current.Kind]
	local m = profile and build and build(profile, current)
	if not m then
		ItemDetail.Hide()
		return
	end
	render(m)
	fitBody()
	ItemDetail.Place()
end

function ItemDetail.Show(item: Item, anchor: GuiObject, centerOnScreen: boolean?)
	MenuManager.WillOpen("ItemDetail")
	ensure()
	current = item
	anchorObj = anchor
	compactMode = centerOnScreen ~= true and compactScreen()
	centered = centerOnScreen == true or compactMode
	refs.Shield.Visible = compactMode
	gui.Enabled = true
	ItemDetail.Refresh()
end

function ItemDetail.Hide()
	current = nil
	anchorObj = nil
	centered = false
	compactMode = false
	if refs and refs.Shield then
		refs.Shield.Visible = false
	end
	if gui then
		gui.Enabled = false
	end
	if deps and deps.Hidden then
		deps.Hidden()
	end
	ItemDetail.Hidden:Fire()
	MenuManager.Closed("ItemDetail")
end

function ItemDetail.IsShowing(): boolean
	return current ~= nil
end

function ItemDetail.Current(): Item?
	return current
end

-- d = { Profile: () -> profile?, Stats: () -> stats?, Notify: (text, color?) -> (), Changed: () -> (), Hidden: (() -> ())? }
function ItemDetail.Init(d: any)
	deps = d
	task.spawn(ensure)
end

MenuManager.Register("ItemDetail", { Layer = "Popup", Close = ItemDetail.Hide, IsOpen = ItemDetail.IsShowing })

return ItemDetail
