--!strict
-- Rod Fusion rules (docs/ROD_FUSION_COST.md). Shared by the server (authoritative) and the Fusion window (preview).
-- Move ONE mod from a Material rod to a slot of a Base rod of the same model. The Material rod is destroyed.
-- 5% of the time the fusion fails: only the Material rod is lost, nothing is charged, the Base rod is unchanged.

local Registry = require(script.Parent.Parent.Registry)
local ItemTypes = require(script.Parent.ItemTypes)
local Inventory = require(script.Parent.ItemContainer)

local CFG = Registry.GameConfig.Fusion

export type Plan = {
	Kind: string, -- "Prefixes" | "Suffixes"
	BaseIndex: number, -- slot of the Base rod that is replaced (or the next free slot)
	Mod: ItemTypes.ModEntry, -- the mod taken from the Material rod
	Replaced: ItemTypes.ModEntry?, -- what it replaces (nil = empty slot)
	Coins: number,
	Pearls: number,
	GuardGems: number, -- 0 = no Guard offered for this mod
}

local Fusion = {}

Fusion.FailChance = CFG.FailChance

function Fusion.MaxSlots(kind: string): number
	return if kind == "Prefixes" then Registry.GameConfig.Inventory.MaxPrefixes else Registry.GameConfig.Inventory.MaxSuffixes
end

local function isCapBreaker(stat: string): boolean
	return string.sub(stat, 1, 3) == "Max" and Registry.StatDefs[string.sub(stat, 4)] ~= nil
end

-- Materials a Base rod can use: same rod model, not the same item, not worn.
function Fusion.CanUseAsMaterial(profile: any, base: ItemTypes.Item, material: ItemTypes.Item): boolean
	return base.Kind == "Rod" and material.Kind == "Rod" and base.Id == material.Id and base.UUID ~= material.UUID and not Inventory.IsWorn(profile, material)
end

function Fusion.ModList(rod: ItemTypes.Item, kind: string): { ItemTypes.ModEntry }
	return (if kind == "Prefixes" then rod.Prefixes else rod.Suffixes) or {}
end

-- Coins and Pearls for taking `mod` (replacing `replaced`, nil = empty slot) onto a rod of this model.
function Fusion.Cost(rodId: string, mod: ItemTypes.ModEntry, replaced: ItemTypes.ModEntry?): (number, number)
	local rarity = mod.Rarity or "Common"
	local price = Registry.Equipment.Rods.Items[rodId].Price
	local cap = if isCapBreaker(mod.Stat) then CFG.CapBreakerMult else 1
	local slot = 1
	if replaced == nil then
		slot = CFG.EmptySlotMult
	elseif replaced.Value < 0 then
		slot = CFG.CursedDiscount
	end
	local coins = math.floor(price * CFG.FeeFraction * (CFG.RarityMult[rarity] or 1) * cap * slot)
	local pearls = math.floor((CFG.PearlCost[rarity] or 0) * cap)
	return math.max(1, coins), pearls
end

-- Gems for the optional Guard (a sure success). 0 = not offered (Common / Uncommon mods never fail meaningfully).
function Fusion.GuardGems(mod: ItemTypes.ModEntry): number
	return CFG.GuardGems[mod.Rarity or "Common"] or 0
end

-- Validates a request and prices it. Returns the plan, or nil + the reason.
function Fusion.Plan(profile: any, base: ItemTypes.Item, material: ItemTypes.Item, kind: any, baseIndex: any, materialIndex: any): (Plan?, string?)
	if kind ~= "Prefixes" and kind ~= "Suffixes" then
		return nil, "Choose Prefix or Suffix"
	end
	if not Fusion.CanUseAsMaterial(profile, base, material) then
		return nil, "The Material rod must be the same rod and not worn"
	end
	if type(baseIndex) ~= "number" or baseIndex % 1 ~= 0 or baseIndex < 1 or baseIndex > Fusion.MaxSlots(kind) then
		return nil, "Pick a slot on the Base rod"
	end
	local mats = Fusion.ModList(material, kind)
	if type(materialIndex) ~= "number" or materialIndex % 1 ~= 0 or not mats[materialIndex] then
		return nil, "Pick a mod on the Material rod"
	end
	local baseList = Fusion.ModList(base, kind)
	if baseIndex > #baseList + 1 then
		return nil, "Pick a slot on the Base rod"
	end
	local mod = mats[materialIndex]
	local replaced = baseList[baseIndex]
	for i, m in baseList do
		if i ~= baseIndex and m.Stat == mod.Stat then
			return nil, "The Base rod already has that stat"
		end
	end
	local coins, pearls = Fusion.Cost(base.Id, mod, replaced)
	local plan: Plan = { Kind = kind :: string, BaseIndex = baseIndex, Mod = mod, Replaced = replaced, Coins = coins, Pearls = pearls, GuardGems = Fusion.GuardGems(mod) }
	return plan, nil
end

return Fusion
