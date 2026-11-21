--!strict
-- All random rolls and value formulas. Server-only callers for rolls (never trust the client),
-- but value formulas are shared so the UI can show prices.

local Registry = require(script.Parent.Registry)

local Roll = {}

local function weightedPick<T>(entries: { { item: T, weight: number } }, rng: Random): T?
	local total = 0
	for _, e in entries do
		total += e.weight
	end
	if total <= 0 then
		return nil
	end
	local r = rng:NextNumber() * total
	for _, e in entries do
		r -= e.weight
		if r <= 0 then
			return e.item
		end
	end
	return entries[#entries].item
end

-- Fish that can bite at this depth + location.
function Roll.Candidates(depth: number, locationId: string?): { string }
	local list = {}
	for id, f in Registry.Fish do
		if depth >= f.DepthMin and depth <= f.DepthMax then
			local ok = true
			if f.Locations and locationId then
				ok = table.find(f.Locations, locationId) ~= nil
			end
			if ok then
				table.insert(list, id)
			end
		end
	end
	table.sort(list) -- deterministic order
	return list
end

function Roll.Fish(depth: number, locationId: string?, luck: number, rng: Random): string?
	local exponent = Registry.GameConfig.LuckTierExponent
	local entries = {}
	for _, id in Roll.Candidates(depth, locationId) do
		local f = Registry.Fish[id]
		local rarity = Registry.Rarities[f.Rarity]
		local base = f.RollWeight or rarity.Weight
		local w = base * (1 + luck) ^ ((rarity.Tier - 1) * exponent)
		table.insert(entries, { item = id, weight = w })
	end
	return weightedPick(entries, rng)
end

-- Skewed toward lighter fish: big ones are rarer.
function Roll.Weight(fishId: string, rng: Random): number
	local f = Registry.Fish[fishId]
	local t = rng:NextNumber() ^ 1.8
	local kg = f.Weight[1] + (f.Weight[2] - f.Weight[1]) * t
	return math.floor(kg * 100 + 0.5) / 100
end

function Roll.Mutation(mutationChance: number, auraBonus: { [string]: number }, rng: Random): string?
	local ids = {}
	for id in Registry.Mutations do
		table.insert(ids, id)
	end
	table.sort(ids, function(a, b)
		return Registry.Mutations[a].Priority > Registry.Mutations[b].Priority
	end)
	for _, id in ids do
		local m = Registry.Mutations[id]
		local bonus = auraBonus[id] or 0
		-- Global MutationChance only boosts mutations that can occur naturally or via the aura.
		local chance = m.BaseChance + bonus
		if chance > 0 then
			chance += mutationChance
		end
		if chance > 0 and rng:NextNumber() < chance then
			return id
		end
	end
	return nil
end

-- Returns aura id. Rarest auras are checked first ("1 in N" each); fallback = most common.
-- rateUp: auraId -> chance multiplier (banner rate-up). minTier: re-roll result upward so the
-- aura is at least this rarity tier (pity / x10 guarantee): picks among auras of tier >= minTier
-- by their relative odds.
-- Real chance of each aura for one normal pull (no pity / x10 guarantee). Matches Roll.Aura: auras
-- are tried rarest first, each succeeds with its 1/Chance; the most common one takes what is left.
function Roll.AuraRates(luck: number, rateUp: { [string]: number }?): { [string]: number }
	local ids = Registry.SortedAuras()
	table.sort(ids, function(a, b)
		return Registry.Auras[a].Chance > Registry.Auras[b].Chance
	end)
	local rates: { [string]: number } = {}
	local left = 1
	for i, id in ids do
		if i == #ids then
			rates[id] = left
		else
			local c = math.min(1, (1 + luck) * ((rateUp and rateUp[id]) or 1) / Registry.Auras[id].Chance)
			rates[id] = left * c
			left -= left * c
		end
	end
	return rates
end

-- minTier/maxTier: pity + x10 guarantee pick only from that rarity range (weighted by 1/Chance).
function Roll.Aura(luck: number, rng: Random, rateUp: { [string]: number }?, minTier: number?, maxTier: number?): string
	if minTier and minTier > 1 then
		local ids: { string } = {}
		local total = 0
		for id, a in Registry.Auras do
			local tier = Registry.Rarities[a.Rarity].Tier
			if tier >= minTier and (maxTier == nil or tier <= maxTier) then
				table.insert(ids, id)
				total += (1 + luck) * ((rateUp and rateUp[id]) or 1) / a.Chance
			end
		end
		if total > 0 then
			table.sort(ids)
			local pick = rng:NextNumber() * total
			for _, id in ids do
				pick -= (1 + luck) * ((rateUp and rateUp[id]) or 1) / Registry.Auras[id].Chance
				if pick <= 0 then
					return id
				end
			end
			return ids[#ids]
		end
	end
	local ids = Registry.SortedAuras()
	table.sort(ids, function(a, b)
		return Registry.Auras[a].Chance > Registry.Auras[b].Chance
	end)
	for _, id in ids do
		local chance = (1 + luck) * ((rateUp and rateUp[id]) or 1) / Registry.Auras[id].Chance
		if rng:NextNumber() < chance then
			return id
		end
	end
	return ids[#ids]
end

export type CatchEntry = {
	Uid: string,
	Fish: string,
	Weight: number,
	Mutation: string?,
	Mult: number, -- manual/auto/perfect multiplier captured at catch time
}

-- Sell value of one caught fish.
function Roll.Value(entry: CatchEntry, sellMultiplier: number): number
	local f = Registry.Fish[entry.Fish]
	if not f then
		return 0
	end
	local avg = (f.Weight[1] + f.Weight[2]) / 2
	local sizeFactor = math.clamp((entry.Weight / avg) ^ 0.7, 0.4, 3)
	local mut = entry.Mutation and Registry.Mutations[entry.Mutation]
	local mutMult = mut and mut.ValueMultiplier or 1
	return math.max(1, math.floor(f.BaseValue * sizeFactor * mutMult * entry.Mult * sellMultiplier + 0.5))
end

return Roll
