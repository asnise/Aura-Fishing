--!strict
-- The bag (Item rework). Shared by server (authoritative) and client (UI). Replaces the old stack model.
--
--   profile.Bag = { Item, ... }            one entry = one slot (Items/ItemTypes). Plain records with a UUID.
--   Fish, Rods and Lines never stack: every one keeps its own weight / mutation / tags / value / mods.
--   Treasure chests stack up to GameConfig.Inventory.TreasureStackMax (same Id + same Bound).
--   Baits stay in profile.Consumables.Baits (one slot per bait type you have). Bags (profile.Owned.Bags) and
--   Auras do not use slots.
--
--   Everything counts: fish, rods, lines (the worn ones too), chests and bait types. Only Auras are outside the bag.
--   profile.Equipped.Rods / .Lines = UUID of a bag entry. Equipped.Bags / .Baits = Config/Equipment item id.
--
-- Capacity = equipped bag's Capacity (slots), or the Infinite Bag pass. The bag is a permanent upgrade ladder.

local HttpService = game:GetService("HttpService")

local Registry = require(script.Parent.Parent.Registry)
local HotFish = require(script.Parent.Parent.HotFish)
local Enhance = require(script.Parent.Parent.Enhance)
local ItemTypes = require(script.Parent.ItemTypes)
local ModifierRoll = require(script.Parent.ModifierRoll)

export type Item = ItemTypes.Item

local CFG = Registry.GameConfig.Inventory

local GEAR_KIND = { Rods = "Rod", Lines = "Line" } :: { [string]: string }
local GEAR_CATEGORY = { Rod = "Rods", Line = "Lines" } :: { [string]: string }

local Inventory = {}

-- Rods and Lines are bag items; Bags and Baits are not.
function Inventory.IsGearCategory(categoryId: string): boolean
	return GEAR_KIND[categoryId] ~= nil
end

function Inventory.GearKind(categoryId: string): string?
	return GEAR_KIND[categoryId]
end

function Inventory.GearCategory(kind: string): string?
	return GEAR_CATEGORY[kind]
end

-- Creation ----------------------------------------------------------------------------------------

function Inventory.MarkNew(item: Item)
	item.New = HttpService:GenerateGUID(false)
end

-- A stale acknowledgement must never clear a newer addition to the same item.
function Inventory.MarkSeen(profile: any, tokens: any): boolean
	if type(tokens) ~= "table" then
		return false
	end
	local seen = {}
	for i = 1, math.min(#tokens, 64) do
		local token = tokens[i]
		if type(token) == "string" then
			seen[token] = true
		end
	end
	if next(seen) == nil then
		return false
	end
	local changed = false
	for _, item in profile.Bag do
		if item.New and seen[item.New] then
			item.New = nil
			changed = true
		end
	end
	return changed
end

function Inventory.NewUUID(): string
	return HttpService:GenerateGUID(false)
end

-- value = Roll.Value(entry, 1). tags = { "Perfect", "Hotspot", "Manual" | "Auto" }
function Inventory.NewFish(fishId: string, mutation: string?, weight: number, value: number, tags: { string }?): Item
	return { UUID = Inventory.NewUUID(), Id = fishId, Kind = "Fish", Mutation = mutation, Weight = weight, Value = value, Tags = tags }
end

function Inventory.NewTreasure(treasureId: string): Item
	return { UUID = Inventory.NewUUID(), Id = treasureId, Kind = "Treasure", Count = 1 }
end

-- A fresh Rod or Line. Gifts (Exclusive) are Bound: no trade, no sell. dropProfile (Config/ModifierDefs.Profiles)
-- rolls the Prefix / Suffix mods of an Uncommon or better rod or line; none = empty lists (starter rods, gifts).
function Inventory.NewGear(categoryId: string, itemId: string, dropProfile: string?): Item
	local def = Registry.Equipment[categoryId].Items[itemId]
	local item: Item = { UUID = Inventory.NewUUID(), Id = itemId, Kind = GEAR_KIND[categoryId], Enhance = 0 }
	if def.Exclusive then
		item.Bound = "Bound"
		item.Tradable = false
		item.Sellable = false
	end
	if categoryId == "Rods" or categoryId == "Lines" then
		item.Prefixes = {}
		item.Suffixes = {}
		if dropProfile and not def.Exclusive and Registry.Rarities[Registry.GearRarity(categoryId, itemId)].Tier >= 2 then
			local rolled = ModifierRoll.RollModifiers(dropProfile)
			item.Prefixes = rolled.Prefixes
			item.Suffixes = rolled.Suffixes
		end
	end
	return item
end

-- Capacity ----------------------------------------------------------------------------------------

-- Infinite Bag pass (C6): capacity = GameConfig.Inventory.InfiniteBagSlots, shown as "Inf".
function Inventory.IsInfinite(profile: any): boolean
	return profile.Passes ~= nil and profile.Passes.InfiniteBag ~= nil
end

function Inventory.Capacity(profile: any): number
	if Inventory.IsInfinite(profile) then
		return CFG.InfiniteBagSlots
	end
	local bag = Registry.Equipment.Bags.Items[profile.Equipped.Bags]
	return bag and bag.Capacity or 10
end

-- Bags are upgrades (B21): the ladder is every shop bag by Capacity (exclusive bags excluded); the
-- player always uses the biggest one they own and can never go back to a smaller one.
function Inventory.BagLadder(): { string }
	local items = Registry.Equipment.Bags.Items
	local out = {}
	for id, item in items do
		if not item.Exclusive then
			table.insert(out, id)
		end
	end
	table.sort(out, function(a, b)
		local ca, cb = items[a].Capacity or 0, items[b].Capacity or 0
		if ca ~= cb then
			return ca < cb
		end
		return items[a].Order < items[b].Order
	end)
	return out
end

function Inventory.BagCapacity(bagId: string?): number
	local bag = if bagId then Registry.Equipment.Bags.Items[bagId] else nil
	return if bag then bag.Capacity or 0 else 0
end

-- Next bag on the ladder after the equipped one; nil at the top (only the Infinite Bag pass is left).
function Inventory.NextBag(profile: any): string?
	local cap = Inventory.BagCapacity(profile.Equipped.Bags)
	for _, id in Inventory.BagLadder() do
		if Inventory.BagCapacity(id) > cap then
			return id
		end
	end
	return nil
end

-- Lookup ------------------------------------------------------------------------------------------

function Inventory.Find(profile: any, uuid: any): (Item?, number?)
	if type(uuid) ~= "string" then
		return nil, nil
	end
	for i, item in profile.Bag do
		if item.UUID == uuid then
			return item, i
		end
	end
	return nil, nil
end

-- True for the rod / line that is being worn (it cannot be sold).
function Inventory.IsWorn(profile: any, item: Item): boolean
	local cat = GEAR_CATEGORY[item.Kind]
	return cat ~= nil and profile.Equipped[cat] == item.UUID
end

-- The worn Rod / Line item, or nil.
function Inventory.Worn(profile: any, categoryId: string): Item?
	if not GEAR_KIND[categoryId] then
		return nil
	end
	return (Inventory.Find(profile, profile.Equipped[categoryId]))
end

-- Config id of what is equipped in a category (works for every category), or nil.
function Inventory.EquippedId(profile: any, categoryId: string): string?
	if GEAR_KIND[categoryId] then
		local worn = Inventory.Worn(profile, categoryId)
		return if worn then worn.Id else nil
	end
	return profile.Equipped[categoryId]
end

-- How many items of this Rod / Line config id you own (bag, worn one included).
function Inventory.CountGear(profile: any, categoryId: string, itemId: string): number
	local kind = GEAR_KIND[categoryId]
	local n = 0
	for _, item in profile.Bag do
		if item.Kind == kind and item.Id == itemId then
			n += 1
		end
	end
	return n
end

-- Bait types you hold (count > 0): each one is a slot, however many you carry.
function Inventory.BaitTypes(profile: any): number
	local n = 0
	for _, count in (profile.Consumables and profile.Consumables.Baits) or {} do
		if count > 0 then
			n += 1
		end
	end
	return n
end

function Inventory.Used(profile: any): number
	return #profile.Bag + Inventory.BaitTypes(profile)
end

function Inventory.Free(profile: any): number
	return math.max(0, Inventory.Capacity(profile) - Inventory.Used(profile))
end

-- True when no new item can go in. Fish never stack, so this is just "no free slot".
function Inventory.IsFull(profile: any): boolean
	return Inventory.Free(profile) <= 0
end

-- Adding -------------------------------------------------------------------------------------------

local function stackRoom(profile: any, item: Item): Item?
	local def = Registry.Items[item.Id]
	if not def or not def.IsStackable then
		return nil
	end
	for _, s in profile.Bag do
		if s.Kind == item.Kind and s.Id == item.Id and s.Bound == item.Bound and (s.Count or 1) < def.MaxStack then
			return s
		end
	end
	return nil
end

function Inventory.CanAdd(profile: any, kind: string, id: string): boolean
	if kind == "Treasure" and stackRoom(profile, Inventory.NewTreasure(id)) then
		return true
	end
	return Inventory.Free(profile) > 0
end

-- Puts an item in the bag. force = skip the capacity check (purchases and gifts are never lost).
-- Returns the entry it ended up in (a stack for chests), or nil when the bag is full.
function Inventory.Add(profile: any, item: Item, force: boolean?): Item?
	local room = stackRoom(profile, item)
	if room then
		room.Count = (room.Count or 1) + (item.Count or 1)
		Inventory.MarkNew(room)
		return room
	end
	if not force and Inventory.Free(profile) <= 0 then
		return nil
	end
	Inventory.MarkNew(item)
	table.insert(profile.Bag, item)
	return item
end

function Inventory.AddFish(profile: any, fishId: string, mutation: string?, weight: number, value: number, tags: { string }?): Item?
	return Inventory.Add(profile, Inventory.NewFish(fishId, mutation, weight, value, tags))
end

function Inventory.AddTreasure(profile: any, treasureId: string): Item?
	return Inventory.Add(profile, Inventory.NewTreasure(treasureId))
end

-- Removes the whole entry (returns it) or nil.
function Inventory.Remove(profile: any, uuid: any): Item?
	local item, index = Inventory.Find(profile, uuid)
	if item and index then
		table.remove(profile.Bag, index)
		return item
	end
	return nil
end

-- Rules ---------------------------------------------------------------------------------------------

function Inventory.IsBound(item: Item): boolean
	local def = Registry.Items[item.Id]
	return (item.Bound or (def and def.Bound) or "Unbound") ~= "Unbound"
end

function Inventory.CanTrade(profile: any, item: Item): (boolean, string?)
	local def = Registry.Items[item.Id]
	if not def or not def.IsTradable or item.Tradable == false then
		return false, "This item cannot be traded."
	end
	if Inventory.IsBound(item) then
		return false, "Bound items cannot be traded."
	end
	if Inventory.IsWorn(profile, item) then
		return false, "Take the item off before trading."
	end
	return true, nil
end

-- Selling -------------------------------------------------------------------------------------------

-- Coins already paid to Enhance a rod/line (for the sell-back price).
local function enhanceSpent(item: Item): number
	local cat = GEAR_CATEGORY[item.Kind]
	local total = 0
	for lv = 0, (item.Enhance or 0) - 1 do
		total += Enhance.Cost(cat, item.Id, lv) or 0
	end
	return total
end

-- Coins for selling one bag entry (0 = cannot be sold). Fish: Value * sellMultiplier * hot fish bonus
-- (noHot skips it). Rod/Line: fixed share of what was paid, no multiplier (no money printer).
function Inventory.SellValue(item: Item, sellMultiplier: number, noHot: boolean?): number
	if item.Kind == "Fish" then
		local hot = if noHot then 1 else HotFish.Mult(item.Id)
		return math.floor((item.Value or 0) * sellMultiplier * hot + 0.5)
	end
	local cat = GEAR_CATEGORY[item.Kind]
	local def = cat and Registry.Equipment[cat].Items[item.Id]
	local meta = Registry.Items[item.Id]
	if not def or not meta or not meta.IsSellable or item.Sellable == false or def.Currency ~= "Coins" then
		return 0
	end
	-- mods add value by rarity (CFG.ModSellBonus, share of the base price)
	local modBonus = 0
	local function addBonus(list: { ItemTypes.ModEntry }?)
		if list then
			for _, mod in list do
				modBonus += CFG.ModSellBonus[mod.Rarity or "Common"] or 0
			end
		end
	end
	addBonus(item.Prefixes)
	addBonus(item.Suffixes)
	return math.floor((def.Price * (1 + modBonus) + enhanceSpent(item)) * CFG.GearSellFraction)
end

-- Gear you have put work into (Enhance, mods) is never sold or destroyed without asking first.
-- Returns what would be lost ("+10", "2 mods", "+3 and 1 mod"), or nil for plain items.
function Inventory.Investment(item: Item): string?
	local mods = #(item.Prefixes or {}) + #(item.Suffixes or {})
	local plus = item.Enhance or 0
	if plus <= 0 and mods <= 0 then
		return nil
	end
	local parts = {}
	if plus > 0 then
		table.insert(parts, `+{plus}`)
	end
	if mods > 0 then
		table.insert(parts, `{mods} mod{if mods == 1 then "" else "s"}`)
	end
	return table.concat(parts, " and ")
end

-- nil = can be sold, otherwise the reason (worn gear, bound, chests...).
function Inventory.SellBlock(profile: any, item: Item): string?
	if Inventory.IsWorn(profile, item) then
		return "Take it off first"
	end
	-- free starter Rods / Lines can be thrown away for 0 coins; everything else needs a sell value
	local gearKind = item.Kind == "Rod" or item.Kind == "Line"
	if item.Kind ~= "Fish" and Inventory.SellValue(item, 1) <= 0 and not (gearKind and item.Sellable ~= false) then
		return "This item can't be sold"
	end
	return nil
end

-- Extra coins the hot fish give in SELL ALL (for the "Hot fish bonus +N" line).
function Inventory.HotBonus(profile: any, sellMultiplier: number): number
	local bonus = 0
	for _, s in profile.Bag do
		if s.Kind == "Fish" then
			bonus += Inventory.SellValue(s, sellMultiplier) - Inventory.SellValue(s, sellMultiplier, true)
		end
	end
	return bonus
end

-- Total for SELL ALL (fish only; chests, rods and lines stay) -> coins, fishCount, mutatedCount
function Inventory.SellAllPreview(profile: any, sellMultiplier: number): (number, number, number)
	local total, count, mutated = 0, 0, 0
	for _, s in profile.Bag do
		if s.Kind == "Fish" then
			total += Inventory.SellValue(s, sellMultiplier)
			count += 1
			if s.Mutation then
				mutated += 1
			end
		end
	end
	return total, count, mutated
end

-- Stats --------------------------------------------------------------------------------------------

-- Sum of Prefix / Suffix stats of a rod (Stats.Collect adds this as one more source).
function Inventory.ModStats(item: Item): { [string]: number }
	local out: { [string]: number } = {}
	local function add(list: { ItemTypes.ModEntry }?)
		if list then
			for _, mod in list do
				out[mod.Stat] = (out[mod.Stat] or 0) + mod.Value
			end
		end
	end
	add(item.Prefixes)
	add(item.Suffixes)
	return out
end

-- Stats of one rod/line item: base stats scaled by its own Enhance level.
function Inventory.GearStats(item: Item): { [string]: number }
	local cat = GEAR_CATEGORY[item.Kind]
	local def = cat and Registry.Equipment[cat].Items[item.Id]
	if not def then
		return {}
	end
	return Enhance.ScaledStats(def.Stats, item.Enhance or 0)
end

-- Display ---------------------------------------------------------------------------------------------

-- name, rarity id, icon key for one bag entry.
function Inventory.Describe(item: Item): (string, string, string)
	local def = Registry.Items[item.Id]
	local name = if def then def.Name else item.Id
	if item.Kind == "Fish" then
		local mut = item.Mutation and Registry.Mutations[item.Mutation]
		if mut then
			name = `{mut.Name} {name}`
		end
	end
	return name, if def then def.Rarity else "Common", if def then def.Icon else `fish/{item.Id}`
end

return Inventory
