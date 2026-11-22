--!strict
-- Rolls the Prefix / Suffix mods of a new rod from a drop profile (Config/ModifierDefs.Profiles).
-- Server side only in practice (the server creates items); lives in shared with the other item rules.

local Registry = require(script.Parent.Parent.Registry)
local ItemTypes = require(script.Parent.ItemTypes)

local Defs = Registry.ModifierDefs
local CFG = Registry.GameConfig.Inventory

local ModifierRoll = {}

local defaultRng = Random.new()

local function isCapBreaker(def: any): boolean
	return string.sub(def.Stat, 1, 3) == "Max" and Registry.StatDefs[string.sub(def.Stat, 4)] ~= nil
end

local function pickIndex(weights: { number }, rng: Random): number
	local total = 0
	for _, w in weights do
		total += w
	end
	local roll = rng:NextNumber() * total
	for i, w in weights do
		roll -= w
		if roll <= 0 then
			return i
		end
	end
	return #weights
end

-- Number of Prefix and Suffix slots this profile gives -> prefixCount, suffixCount (each 0..2).
function ModifierRoll.RollSlots(profileName: string, rng: Random?): (number, number)
	local profile = Defs.Profiles[profileName]
	if not profile then
		return 0, 0
	end
	local r = rng or defaultRng
	return math.min(pickIndex(profile.PrefixSlots, r) - 1, CFG.MaxPrefixes), math.min(pickIndex(profile.SuffixSlots, r) - 1, CFG.MaxSuffixes)
end

-- One mod for a slot. taken = stats already on the rod (no two mods on the same stat).
local function rollOne(list: { any }, profile: any, wantCap: boolean, taken: { [string]: boolean }, rng: Random): ItemTypes.ModEntry?
	local floor = Registry.Rarities[profile.Floor].Tier
	local ceil = Registry.Rarities[profile.Ceiling].Tier
	local pool, weights = {}, {}
	for _, def in list do
		local tier = Registry.Rarities[def.Rarity].Tier
		if tier >= floor and tier <= ceil and not taken[def.Stat] and isCapBreaker(def) == wantCap then
			table.insert(pool, def)
			table.insert(weights, Registry.Rarities[def.Rarity].Weight)
		end
	end
	if #pool == 0 then
		return nil
	end
	local def = pool[pickIndex(weights, rng)]
	local lo = if profile.Pure then math.max(0, def.Min) else def.Min
	local step = if def.Max - def.Min >= 1 then 10 else 1000 -- whole studs get 0.1 steps, fractions 0.001
	local value = math.floor((lo + (def.Max - lo) * rng:NextNumber()) * step + 0.5) / step
	taken[def.Stat] = true
	return { Id = def.Id, Name = def.Name, Stat = def.Stat, Value = value, Rarity = def.Rarity }
end

-- Rolls a full set -> { Prefixes, Suffixes } (empty lists for an unknown profile).
function ModifierRoll.RollModifiers(profileName: string, rng: Random?): { Prefixes: { ItemTypes.ModEntry }, Suffixes: { ItemTypes.ModEntry } }
	local out = { Prefixes = {} :: { ItemTypes.ModEntry }, Suffixes = {} :: { ItemTypes.ModEntry } }
	local profile = Defs.Profiles[profileName]
	if not profile then
		return out
	end
	local r = rng or defaultRng
	local nP, nS = ModifierRoll.RollSlots(profileName, r)
	local taken: { [string]: boolean } = {}
	local capGiven = false
	local total = nP + nS
	local slot = 0
	local function fill(list: { any }, dest: { ItemTypes.ModEntry }, count: number)
		for _ = 1, count do
			slot += 1
			-- the last slot is forced to a Cap Breaker when the profile guarantees one and none came up yet
			local forced = profile.GuaranteeCapBreaker == true and not capGiven and slot == total
			local wantCap = forced or r:NextNumber() < profile.CapBreakerChance
			local mod = rollOne(list, profile, wantCap, taken, r) or (if wantCap then rollOne(list, profile, false, taken, r) else nil)
			if mod then
				capGiven = capGiven or (string.sub(mod.Stat, 1, 3) == "Max" and Registry.StatDefs[string.sub(mod.Stat, 4)] ~= nil)
				table.insert(dest, mod)
			end
		end
	end
	fill(Defs.Prefixes, out.Prefixes, nP)
	fill(Defs.Suffixes, out.Suffixes, nS)
	return out
end

return ModifierRoll
