--!strict
-- Bag = inventory slots (C2 data model, 2026-11-17). Shared by server (authoritative) and client (UI).
--
--   profile.Bag = { Stack, ... }   one entry = one slot
--   Stack (Fish)     = { Kind = "Fish", Id = fishId, Mutation = mutId?, Count, Value, Best, New? }
--        Value = sum of each fish's base value (Roll.Value(entry, 1): size, mutation, Manual x1.5,
--                Perfect). Selling pays floor(Value * SellMultiplier), so stacking loses no money.
--        Best  = heaviest weight in the stack (kg).
--   Stack (Treasure) = { Kind = "Treasure", Id = treasureId, Count }
--   Baits stay in profile.Consumables.Baits (they never use a slot).
--
-- Capacity = equipped bag's Capacity (slots). Fish of the same species + mutation stack up to
-- GameConfig.Inventory.FishStackMax, chests up to TreasureStackMax.

local HttpService = game:GetService("HttpService")

local Registry = require(script.Parent.Registry)
local HotFish = require(script.Parent.HotFish)

local CFG = Registry.GameConfig.Inventory

export type Stack = {
	Kind: string,
	Id: string,
	Mutation: string?,
	Count: number,
	Value: number?,
	Best: number?,
	New: string?, -- identifies the most recent addition to this stack
}

local Inventory = {}

function Inventory.MarkNew(stack: Stack)
	stack.New = HttpService:GenerateGUID(false)
end

-- A stale acknowledgement must never clear a newer addition to the same stack.
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
	for _, stack in profile.Bag do
		if stack.New and seen[stack.New] then
			stack.New = nil
			changed = true
		end
	end
	return changed
end

-- Infinite Bag pass (C6): capacity = GameConfig.Inventory.InfiniteBagSlots, shown as "∞".
function Inventory.IsInfinite(profile: any): boolean
	return profile.Passes ~= nil and profile.Passes.InfiniteBag ~= nil
end

function Inventory.Capacity(profile: any): number
	if Inventory.IsInfinite(profile) then
		return CFG.InfiniteBagSlots
	end
	local bag = Registry.Equipment.Bags.Items[profile.Equipped.Bags]
	return bag and bag.Capacity or 6
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

function Inventory.Used(profile: any): number
	return #profile.Bag
end

function Inventory.StackMax(kind: string): number
	return if kind == "Treasure" then CFG.TreasureStackMax else CFG.FishStackMax
end

local function sameKey(s: Stack, kind: string, id: string, mutation: string?): boolean
	return s.Kind == kind and s.Id == id and s.Mutation == mutation
end

-- Stack that can take one more of this item, or nil.
function Inventory.FindRoom(profile: any, kind: string, id: string, mutation: string?): Stack?
	local max = Inventory.StackMax(kind)
	for _, s in profile.Bag do
		if sameKey(s, kind, id, mutation) and s.Count < max then
			return s
		end
	end
	return nil
end

function Inventory.CanAdd(profile: any, kind: string, id: string, mutation: string?): boolean
	return Inventory.FindRoom(profile, kind, id, mutation) ~= nil or #profile.Bag < Inventory.Capacity(profile)
end

-- True when nothing new can go in: every slot is used and every fish stack is full.
-- (Used before casting; the exact species is only known when the fish bites.)
function Inventory.IsFull(profile: any): boolean
	if #profile.Bag < Inventory.Capacity(profile) then
		return false
	end
	for _, s in profile.Bag do
		if s.Kind == "Fish" and s.Count < CFG.FishStackMax then
			return false
		end
	end
	return true
end

-- Adds one fish. value = Roll.Value(entry, 1). Returns the stack, or nil if the bag is full.
function Inventory.AddFish(profile: any, fishId: string, mutation: string?, weight: number, value: number): Stack?
	local s = Inventory.FindRoom(profile, "Fish", fishId, mutation)
	if not s then
		if #profile.Bag >= Inventory.Capacity(profile) then
			return nil
		end
		s = { Kind = "Fish", Id = fishId, Mutation = mutation, Count = 0, Value = 0, Best = 0 }
		table.insert(profile.Bag, s)
	end
	local stack = s :: Stack
	stack.Count += 1
	stack.Value = (stack.Value or 0) + value
	stack.Best = math.max(stack.Best or 0, weight)
	Inventory.MarkNew(stack)
	return stack
end

function Inventory.AddTreasure(profile: any, treasureId: string): Stack?
	local s = Inventory.FindRoom(profile, "Treasure", treasureId, nil)
	if not s then
		if #profile.Bag >= Inventory.Capacity(profile) then
			return nil
		end
		s = { Kind = "Treasure", Id = treasureId, Count = 0 }
		table.insert(profile.Bag, s)
	end
	local stack = s :: Stack
	stack.Count += 1
	Inventory.MarkNew(stack)
	return stack
end

-- Coins for selling a fish stack (0 for anything else). Includes the hot fish bonus (C18) unless
-- noHot; sellMultiplier = SellMultiplier stat (x 2x Coins boost where it applies).
function Inventory.SellValue(stack: Stack, sellMultiplier: number, noHot: boolean?): number
	if stack.Kind ~= "Fish" then
		return 0
	end
	local hot = if noHot then 1 else HotFish.Mult(stack.Id)
	return math.floor((stack.Value or 0) * sellMultiplier * hot + 0.5)
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

-- Total for SELL ALL (fish only; chests stay) -> coins, fishCount, mutatedCount
function Inventory.SellAllPreview(profile: any, sellMultiplier: number): (number, number, number)
	local total, count, mutated = 0, 0, 0
	for _, s in profile.Bag do
		if s.Kind == "Fish" then
			total += Inventory.SellValue(s, sellMultiplier)
			count += s.Count
			if s.Mutation then
				mutated += s.Count
			end
		end
	end
	return total, count, mutated
end

-- Display info for a stack: name, rarity id, icon key.
function Inventory.Describe(stack: Stack): (string, string, string)
	if stack.Kind == "Treasure" then
		local t = Registry.Treasures[stack.Id]
		return if t then t.Name else stack.Id, if t then t.Rarity else "Common", if t then t.Icon else "ui/status/treasure_chest"
	end
	local f = Registry.Fish[stack.Id]
	local name = if f then f.Name else stack.Id
	local mut = stack.Mutation and Registry.Mutations[stack.Mutation]
	if mut then
		name = `{mut.Name} {name}`
	end
	return name, if f then f.Rarity else "Common", `fish/{stack.Id}`
end

-- Old saves (schema 1): Bag = list of single fish { Fish, Weight, Mutation, Mult }. Converts in place.
-- valueOf(entry) must return Roll.Value(entry, 1).
function Inventory.MigrateV1(profile: any, valueOf: (any) -> number)
	local old = profile.Bag
	profile.Bag = {}
	for _, e in old do
		if e.Kind ~= nil then
			table.insert(profile.Bag, e) -- already a stack
		elseif Registry.Fish[e.Fish] then
			-- ignore capacity here: never delete fish the player already owned
			local s = Inventory.FindRoom(profile, "Fish", e.Fish, e.Mutation)
			if not s then
				s = { Kind = "Fish", Id = e.Fish, Mutation = e.Mutation, Count = 0, Value = 0, Best = 0 }
				table.insert(profile.Bag, s)
			end
			local stack = s :: Stack
			stack.Count += 1
			stack.Value = (stack.Value or 0) + valueOf(e)
			stack.Best = math.max(stack.Best or 0, e.Weight or 0)
		end
	end
end

return Inventory
