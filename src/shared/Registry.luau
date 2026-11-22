--!strict
-- Single entry point to all content. Validates every config table once at require-time so a
-- typo in new content fails loudly in Output instead of breaking gameplay silently.

local Config = script.Parent:WaitForChild("Config")

local Rarities = require(Config.Rarities)
local StatDefs = require(Config.StatDefs)
local Fish = require(Config.Fish)
local Equipment = require(Config.Equipment)
local Auras = require(Config.Auras)
local Mutations = require(Config.Mutations)
local Locations = require(Config.Locations)
local DepthZones = require(Config.DepthZones)
local MinigamePatterns = require(Config.MinigamePatterns)
local GameConfig = require(Config.GameConfig)
local Treasures = require(Config.Treasures)
local Features = require(Config.Features)
local AuraBanners = require(Config.AuraBanners)
local Events = require(Config.Events)
local Dev = require(Config.Dev)
local Products = require(Config.Products)
local MasteryCfg = require(Config.Mastery)
local AuraStarsCfg = require(Config.AuraStars)
local QuestsCfg = require(Config.Quests)
local SkillsCfg = require(Config.Skills)
local TideEventsCfg = require(Config.TideEvents)
local Credits = require(Config.Credits)
local Dialogues = require(Config.Dialogues)
local DailyLoginCfg = require(Config.DailyLogin)

local Registry = {
	Rarities = Rarities,
	StatDefs = StatDefs,
	Fish = Fish,
	Equipment = Equipment,
	Auras = Auras,
	Mutations = Mutations,
	Locations = Locations,
	DepthZones = DepthZones,
	MinigamePatterns = MinigamePatterns,
	GameConfig = GameConfig,
	Treasures = Treasures,
	Features = Features,
	AuraBanners = AuraBanners,
	Events = Events,
	Dev = Dev,
	Products = Products,
	Mastery = MasteryCfg,
	AuraStars = AuraStarsCfg,
	Quests = QuestsCfg,
	Skills = SkillsCfg,
	TideEvents = TideEventsCfg,
	Credits = Credits,
	Dialogues = Dialogues,
	DailyLogin = DailyLoginCfg,
}

local errors: { string } = {}
local function check(cond: any, msg: string)
	if not cond then
		table.insert(errors, msg)
	end
end

local function checkStats(where: string, stats: { [string]: number }?)
	if stats == nil then
		return
	end
	for stat, value in stats do
		check(StatDefs[stat] ~= nil, `{where}: unknown stat '{stat}'`)
		check(type(value) == "number", `{where}: stat '{stat}' must be a number`)
	end
end

for id, f in Fish do
	local w = `Fish.{id}`
	check(Rarities[f.Rarity] ~= nil, `{w}: unknown Rarity '{f.Rarity}'`)
	check(MinigamePatterns[f.Pattern] ~= nil, `{w}: unknown Pattern '{f.Pattern}'`)
	check(f.DepthMin <= f.DepthMax, `{w}: DepthMin > DepthMax`)
	check(f.Weight[1] > 0 and f.Weight[1] <= f.Weight[2], `{w}: bad Weight range`)
	check(f.Difficulty >= 1 and f.Difficulty <= 10, `{w}: Difficulty must be 1..10`)
	check(f.BaseValue > 0, `{w}: BaseValue must be > 0`)
	if f.Locations then
		for _, loc in f.Locations do
			check(Locations[loc] ~= nil, `{w}: unknown Location '{loc}'`)
		end
	end
end

for catId, cat in Equipment do
	check(cat.Kind == "Permanent" or cat.Kind == "Consumable", `Equipment.{catId}: Kind must be Permanent|Consumable`)
	local hasStarter = false
	for itemId, item in cat.Items do
		local w = `Equipment.{catId}.{itemId}`
		checkStats(w, item.Stats)
		check(item.Currency == "Coins" or item.Currency == "Gems", `{w}: Currency must be Coins|Gems`)
		if item.Price == 0 then
			hasStarter = true
		end
		if catId == "Bags" then
			check(type(item.Capacity) == "number", `{w}: Bags need Capacity`)
		end
		if cat.Kind == "Consumable" then
			check(type(item.BuyAmount) == "number", `{w}: consumables need BuyAmount`)
		end
	end
	if cat.Kind == "Permanent" then
		check(hasStarter, `Equipment.{catId}: needs one free (Price = 0) starter item`)
	end
end

for id, a in Auras do
	local w = `Auras.{id}`
	check(Rarities[a.Rarity] ~= nil, `{w}: unknown Rarity '{a.Rarity}'`)
	check(a.Chance >= 1, `{w}: Chance must be >= 1`)
	checkStats(w, a.Stats)
	if a.Mutations then
		for m in a.Mutations do
			check(Mutations[m] ~= nil, `{w}: unknown Mutation '{m}'`)
		end
	end
end

for id, t in Treasures do
	local w = `Treasures.{id}`
	check(Rarities[t.Rarity] ~= nil, `{w}: unknown Rarity '{t.Rarity}'`)
	check(t.DropChance >= 0 and t.DropChance < 1, `{w}: DropChance must be 0..1`)
	check(#t.Rewards > 0, `{w}: needs Rewards`)
	for i, r in t.Rewards do
		check(r.Kind == "Coins" or r.Kind == "Gems" or r.Kind == "Bait", `{w}.Rewards[{i}]: Kind must be Coins|Gems|Bait`)
		check(r.Weight > 0, `{w}.Rewards[{i}]: Weight must be > 0`)
		if r.Kind == "Bait" then
			check(r.Id ~= nil and Equipment.Baits.Items[r.Id] ~= nil, `{w}.Rewards[{i}]: unknown bait '{tostring(r.Id)}'`)
		else
			check(type(r.Min) == "number" and type(r.Max) == "number" and r.Min <= r.Max, `{w}.Rewards[{i}]: needs Min <= Max`)
		end
	end
end

for id, b in AuraBanners do
	local w = `AuraBanners.{id}`
	check(b.Currency == "Gems" or b.Currency == "Coins", `{w}: Currency must be Gems|Coins`)
	check(Rarities[b.PityRarity] ~= nil, `{w}: unknown PityRarity`)
	check(Rarities[b.Ten.MinRarity] ~= nil, `{w}: unknown Ten.MinRarity`)
	if b.HardPity then
		check(Rarities[b.HardPity.Rarity] ~= nil, `{w}: unknown HardPity.Rarity`)
		check(Rarities[b.HardPity.Rarity] ~= nil and Rarities[b.HardPity.Rarity].Tier > Rarities[b.PityRarity].Tier, `{w}: HardPity.Rarity must be rarer than PityRarity`)
		check(b.HardPity.Pulls > b.PityPulls, `{w}: HardPity.Pulls must be > PityPulls`)
	end
	if b.RateUp then
		for auraId in b.RateUp do
			check(Auras[auraId] ~= nil, `{w}: RateUp unknown aura '{auraId}'`)
		end
	end
	check(b.Featured == nil or Auras[b.Featured] ~= nil, `{w}: unknown Featured aura`)
	for i, m in (b.Milestones or {}) :: { any } do
		check(m.Kind == "Gems" or m.Kind == "Coins" or m.Kind == "Bait" or m.Kind == "Treasure" or m.Kind == "Aura", `{w}.Milestones[{i}]: bad Kind`)
		if m.Kind == "Aura" then
			check(m.Id ~= nil and Auras[m.Id] ~= nil, `{w}.Milestones[{i}]: unknown aura`)
		elseif m.Kind == "Bait" then
			check(m.Id ~= nil and Equipment.Baits.Items[m.Id] ~= nil, `{w}.Milestones[{i}]: unknown bait`)
		elseif m.Kind == "Treasure" then
			check(m.Id ~= nil and Treasures[m.Id] ~= nil, `{w}.Milestones[{i}]: unknown treasure`)
		end
	end
end

for id, e in Events do
	local w = `Events.{id}`
	local k = e.Action and e.Action.Kind
	check(k == "Gacha" or k == "Menu" or k == "Teleport" or k == "Info" or k == "DailyLogin", `{w}: Action.Kind must be Gacha|Menu|Teleport|Info|DailyLogin (new kind = new UI/EventActions module + add it here)`)
	if k == "Gacha" then
		check(AuraBanners[e.Action.Banner] ~= nil, `{w}: Action.Banner must be an AuraBanners id`)
	elseif k == "Teleport" then
		check(Locations[e.Action.Location] ~= nil, `{w}: Action.Location must be a Locations id`)
	end
end

-- Daily login (7-day calendar)
check(#DailyLoginCfg.Days == 7, "DailyLogin: Days must have exactly 7 entries")
for i, d in DailyLoginCfg.Days do
	local w = `DailyLogin.Days[{i}]`
	check(d.Day == i, `{w}: Day must be {i}`)
	local r = d.Reward
	check(r ~= nil, `{w}: missing Reward`)
	if r then
		check(r.Kind == "Coins" or r.Kind == "Gems" or r.Kind == "Pearls" or r.Kind == "Bait", `{w}: Reward.Kind must be Coins|Gems|Pearls|Bait`)
		check(r.Amount > 0, `{w}: Reward.Amount must be > 0`)
		if r.Kind == "Bait" then
			check(r.Id ~= nil and Equipment.Baits.Items[r.Id] ~= nil, `{w}: unknown bait '{tostring(r.Id)}'`)
		end
	end
end

-- B7 NPC dialogue
local DIALOGUE_KINDS = { SellAll = true, HotFish = true, Banner = true, Menu = true, Say = true, Talk = true }
for id, npc in Dialogues do
	local w = `Dialogues.{id}`
	check(type(npc.Name) == "string" and npc.Name ~= "", `{w}: needs Name`)
	check(type(npc.Prompt) == "string", `{w}: needs Prompt (ProximityPrompt name)`)
	check(#npc.Greetings > 0, `{w}: needs at least one Greetings line`)
	check(#npc.Talk > 0, `{w}: needs at least one Talk line`)
	check(#npc.Choices >= 1 and #npc.Choices <= 4, `{w}: 1..4 Choices (the screen has 4 bubbles)`)
	for i, c in npc.Choices do
		local cw = `{w}.Choices[{i}]`
		local k = c.Action and c.Action.Kind
		check(DIALOGUE_KINDS[k or ""] == true, `{cw}: Action.Kind must be SellAll|HotFish|Banner|Menu|Say|Talk`)
		if k == "Banner" then
			check(AuraBanners[c.Action.Banner or ""] ~= nil, `{cw}: Action.Banner must be an AuraBanners id`)
		elseif k == "Menu" then
			local m = c.Action.Menu
			check(m == "Shop" or m == "Auras" or m == "Fishdex", `{cw}: Action.Menu must be Shop|Auras|Fishdex`)
		elseif k == "Say" then
			check(type(c.Action.Line) == "string", `{cw}: Say needs Line`)
		end
	end
end

local function checkUniqueIds(kind: string, tbl: { [string]: any }, field: string)
	local seen: { [number]: string } = {}
	for id, e in tbl do
		local n = e[field]
		check(type(n) == "number" and n >= 0 and n % 1 == 0, `Products.{kind}.{id}: {field} must be a whole number (0 = not created yet)`)
		if type(n) == "number" and n > 0 then
			check(seen[n] == nil, `Products.{kind}.{id}: {field} {n} is also used by {tostring(seen[n])}`)
			seen[n] = id
		end
	end
end
checkUniqueIds("Passes", Products.Passes, "PassId")
checkUniqueIds("Products", Products.Products, "ProductId")
for id, pass in Products.Passes do
	checkStats(`Products.Passes.{id}`, pass.Stats)
	if pass.Mutations then
		for m in pass.Mutations do
			check(Mutations[m] ~= nil, `Products.Passes.{id}: unknown Mutation '{m}'`)
		end
	end
end
for id, prod in Products.Products do
	local w = `Products.Products.{id}`
	check(#prod.Rewards > 0, `{w}: needs Rewards`)
	for i, r in prod.Rewards do
		local k = r.Kind
		if k == "Gems" or k == "Coins" then
			check(type(r.Amount) == "number" and (r.Amount :: number) > 0, `{w}.Rewards[{i}]: needs Amount > 0`)
		elseif k == "Bait" then
			check(r.Id ~= nil and Equipment.Baits.Items[r.Id :: string] ~= nil, `{w}.Rewards[{i}]: unknown bait '{tostring(r.Id)}'`)
			check(type(r.Amount) == "number" and (r.Amount :: number) > 0, `{w}.Rewards[{i}]: needs Amount > 0`)
		elseif k == "Boost" then
			check(r.Id ~= nil and GameConfig.Boosts[r.Id :: string] ~= nil, `{w}.Rewards[{i}]: unknown boost '{tostring(r.Id)}' (GameConfig.Boosts)`)
			check(type(r.Amount) == "number" and (r.Amount :: number) > 0, `{w}.Rewards[{i}]: needs Amount (seconds) > 0`)
		elseif k == "Item" then
			local cat = r.Category and Equipment[r.Category :: string]
			check(cat ~= nil and cat.Kind == "Permanent", `{w}.Rewards[{i}]: Category must be a Permanent Equipment category`)
			check(cat ~= nil and r.Id ~= nil and cat.Items[r.Id :: string] ~= nil, `{w}.Rewards[{i}]: unknown item '{tostring(r.Id)}'`)
		else
			check(false, `{w}.Rewards[{i}]: Kind must be Gems|Coins|Bait|Item|Boost`)
		end
	end
end

do
	local rb = Features.Rebirth
	for _, stat in rb.MultiplierStats do
		check(StatDefs[stat] ~= nil, `Features.Rebirth.MultiplierStats: unknown stat '{stat}'`)
	end
	local last = 0
	for i, t in rb.Titles do
		check(t.Rebirths > last, `Features.Rebirth.Titles[{i}]: Rebirths must go up`)
		last = t.Rebirths
	end
end

for id, sk in SkillsCfg.List do
	local w = `Skills.{id}`
	check(StatDefs[sk.Stat] ~= nil, `{w}: unknown Stat '{sk.Stat}'`)
	check(sk.MaxLevel >= 1, `{w}: MaxLevel must be >= 1`)
	if sk.Costs then
		check(#sk.Costs == sk.MaxLevel, `{w}: Costs needs one entry per level (MaxLevel = {sk.MaxLevel})`)
	else
		check(type(sk.CostBase) == "number" and type(sk.CostStep) == "number", `{w}: needs Costs or CostBase + CostStep`)
	end
end
check(SkillsCfg.MultiCast.ExtraLineChance >= 0 and SkillsCfg.MultiCast.ExtraLineChance <= 1, "Skills.MultiCast.ExtraLineChance must be 0..1")

check(#TideEventsCfg.Rotation > 0, "TideEvents.Rotation needs at least one event id")
for i, id in TideEventsCfg.Rotation do
	check(TideEventsCfg.Events[id] ~= nil, `TideEvents.Rotation[{i}]: unknown event '{id}'`)
end
for id, e in TideEventsCfg.Events do
	local w = `TideEvents.Events.{id}`
	check(Locations[e.Location] ~= nil, `{w}: unknown Location '{e.Location}'`)
	check(e.Duration > 0 and e.Radius > 0, `{w}: Duration / Radius must be > 0`)
	check(e.MinDistance < e.MaxDistance, `{w}: MinDistance must be < MaxDistance`)
	for i, c in e.Catches do
		check(Fish[c.Fish] ~= nil, `{w}.Catches[{i}]: unknown fish '{c.Fish}'`)
		check(c.Chance > 0 and c.Chance < 1, `{w}.Catches[{i}]: Chance must be 0..1`)
	end
end

local QUEST_KINDS = { Catch = true, CatchManual = true, CatchRarity = true, CatchMutated = true, Streak = true, SellFish = true, PullAura = true }
local questCount = 0
for id, q in QuestsCfg do
	local w = `Quests.{id}`
	questCount += 1
	check(QUEST_KINDS[q.Kind] == true, `{w}: unknown Kind '{q.Kind}' (new kind = count it in QuestService + add it here)`)
	check(q.Target >= 1, `{w}: Target must be >= 1`)
	check(q.Weight > 0, `{w}: Weight must be > 0`)
	if q.Kind == "CatchRarity" then
		check(q.Rarity ~= nil and Rarities[q.Rarity :: string] ~= nil, `{w}: CatchRarity needs a valid Rarity`)
	end
end
check(questCount >= Features.Quests.PerDay, `Quests: need at least Features.Quests.PerDay ({Features.Quests.PerDay}) quests`)

check(#AuraStarsCfg.StarCost == AuraStarsCfg.MaxStars, "AuraStars.StarCost needs one entry per star (MaxStars)")
for r in Rarities do
	check(AuraStarsCfg.TokensPerDuplicate[r] ~= nil, `AuraStars.TokensPerDuplicate: missing rarity '{r}'`)
	check(AuraStarsCfg.RarityCostMult[r] ~= nil, `AuraStars.RarityCostMult: missing rarity '{r}'`)
end

check(MasteryCfg.PriceGrowth > 1, "Mastery.PriceGrowth must be > 1")
for id, t in MasteryCfg.Tracks do
	local w = `Mastery.Tracks.{id}`
	check(StatDefs[t.Stat] ~= nil, `{w}: unknown Stat '{t.Stat}'`)
	check(t.BasePrice > 0, `{w}: BasePrice must be > 0`)
	if t.Curve == "Linear" then
		check(type(t.PerLevel) == "number", `{w}: Linear needs PerLevel`)
	elseif t.Curve == "Diminishing" then
		check(type(t.MaxBonus) == "number", `{w}: Diminishing needs MaxBonus`)
		check(type(t.Decay) == "number" and (t.Decay :: number) > 0 and (t.Decay :: number) < 1, `{w}: Decay must be 0..1`)
	else
		check(false, `{w}: Curve must be Linear|Diminishing`)
	end
	check(t.MaxLevel == nil or (t.MaxLevel :: number) >= 1, `{w}: MaxLevel must be >= 1`)
	check(t.IconTile == nil or t.Icon ~= nil, `{w}: IconTile needs Icon`)
end

if #errors > 0 then
	error("[Registry] Content errors:\n  " .. table.concat(errors, "\n  "))
end

-- Helpers ---------------------------------------------------------------

-- Returns item ids of a category sorted by Order.
function Registry.SortedItems(categoryId: string): { string }
	local cat = Equipment[categoryId]
	local ids = {}
	for id in cat.Items do
		table.insert(ids, id)
	end
	table.sort(ids, function(a, b)
		return cat.Items[a].Order < cat.Items[b].Order
	end)
	return ids
end

function Registry.StarterItem(categoryId: string): string?
	for id, item in Equipment[categoryId].Items do
		if item.Price == 0 and item.Exclusive == nil then
			return id
		end
	end
	return nil
end

function Registry.SortedAuras(): { string }
	local ids = {}
	for id in Auras do
		table.insert(ids, id)
	end
	table.sort(ids, function(a, b)
		return Auras[a].Order < Auras[b].Order
	end)
	return ids
end

function Registry.DepthZoneFor(depth: number)
	for _, z in DepthZones do
		if depth >= z.Min and depth <= z.Max then
			return z
		end
	end
	return DepthZones[#DepthZones]
end

-- Item definitions (Layer 1, Items/ItemTypes) ---------------------------------------------------
-- Built once from Config/Fish, Config/Equipment and Config/Treasures. Plain tables, never saved.
-- Gear has no Rarity in config: it is ranked by shop order (Exclusive = Rare).
local GEAR_LADDER = { "Common", "Uncommon", "Rare", "Epic", "Legendary" }
local EQUIPMENT_CATEGORY = { Rods = "Rod", Lines = "Line", Bags = "Bag", Baits = "Bait" }

function Registry.GearRarity(categoryId: string, itemId: string): string
	local item = Equipment[categoryId].Items[itemId]
	if item.Exclusive then
		return "Rare"
	end
	local rank = table.find(Registry.SortedItems(categoryId), itemId) or 1
	return GEAR_LADDER[math.clamp(rank, 1, #GEAR_LADDER)]
end

local defs: { [string]: any } = {}
Registry.Items = defs

local function addDef(def: any)
	check(defs[def.Id] == nil, `Items: id '{def.Id}' is used by two items`)
	defs[def.Id] = def
end

for id, f in Fish do
	addDef({ Id = id, Name = f.Name, Description = "", Category = "Fish", Rarity = f.Rarity, Icon = `fish/{id}`, BasePrice = f.BaseValue, IsStackable = false, MaxStack = 1, IsTradable = true, IsSellable = true, Bound = "Unbound" })
end
for id, t in Treasures do
	addDef({ Id = id, Name = t.Name, Description = "", Category = "Treasure", Rarity = t.Rarity, Icon = t.Icon, BasePrice = 0, IsStackable = true, MaxStack = GameConfig.Inventory.TreasureStackMax, IsTradable = true, IsSellable = false, Bound = "Unbound" })
end
for catId, cat in Equipment do
	for id, item in cat.Items do
		local gift = item.Exclusive ~= nil
		local sellable = catId == "Rods" or catId == "Lines"
		addDef({
			Id = id,
			Name = item.Name,
			Description = item.Description or "",
			Category = EQUIPMENT_CATEGORY[catId] or catId,
			Rarity = if cat.Kind == "Permanent" then Registry.GearRarity(catId, id) else "Common",
			Icon = `equipment/{id}`,
			BasePrice = item.Price,
			IsStackable = cat.Kind == "Consumable",
			MaxStack = if cat.Kind == "Consumable" then 9999 else 1,
			IsTradable = not gift,
			IsSellable = sellable and not gift and item.Currency == "Coins" and item.Price > 0,
			Bound = if gift then "Bound" else "Unbound",
			Equipment = catId,
		})
	end
end
if #errors > 0 then
	error("[Registry] Content errors:\n  " .. table.concat(errors, "\n  "))
end

function Registry.GetItem(id: string): any?
	return defs[id]
end

function Registry.GetItemsByCategory(category: string): { any }
	local out = {}
	for _, def in defs do
		if def.Category == category then
			table.insert(out, def)
		end
	end
	return out
end

return Registry
