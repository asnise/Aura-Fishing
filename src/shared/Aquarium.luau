--!strict
-- Aquarium (C14). Shared by server (authoritative) and client (UI), like Inventory.
--
--   profile.Aquarium = { Slots = n, Fish = { TankFish, ... } }   one fish = one slot
--   TankFish = { Uid, Id, Mutation?, Weight, Value }   Value = coins it is worth when taken back out
--   profile.Pearls   = float, grows by Aquarium.Rate(profile) per minute (also offline, capped)
--
-- Numbers: GameConfig.Aquarium. Stats: PearlRate (multiplier), OfflineCapHours.

local Registry = require(script.Parent.Registry)
local Stats = require(script.Parent.Stats)
local Boosts = require(script.Parent.Boosts)
local Format = require(script.Parent.Util.Format)

local CFG = Registry.GameConfig.Aquarium

export type TankFish = { Uid: string, Id: string, Mutation: string?, Weight: number, Value: number }

-- What the UI shows (contract agreed with the UI session, docs/HANDOFF_ECONOMY_UI.md).
export type State = {
	Slots: number,
	MaxSlots: number,
	NextSlotPrice: number?, -- nil = all slots bought
	Fish: { { Uid: string, Id: string, Mutation: string?, Weight: number, Rate: number } },
	Rate: number, -- Pearls per minute right now, total (includes an active 2x Pearls boost)
	Boost: number, -- current Pearls boost multiplier (1 = none); per-fish Rate excludes it
	OfflineCapHours: number,
}

local Aquarium = {}

Aquarium.MaxSlots = CFG.StartSlots + #CFG.SlotPrices

-- Pearls per minute for one fish.
function Aquarium.FishRate(fishId: string, mutation: string?, pearlRate: number): number
	local fish = Registry.Fish[fishId]
	if not fish then
		return 0
	end
	local base = CFG.RatePerMinute[fish.Rarity] or 0
	local mut = mutation and Registry.Mutations[mutation]
	return base * (if mut then mut.ValueMultiplier else 1) * pearlRate
end

-- Total Pearls per minute. Pass `stats` if you already computed them.
function Aquarium.Rate(profile: any, stats: Stats.ComputedStats?): number
	local pr = (stats or Stats.Compute(profile)).Values.PearlRate
	local total = 0
	for _, f in profile.Aquarium.Fish do
		total += Aquarium.FishRate(f.Id, f.Mutation, pr)
	end
	return total
end

function Aquarium.Free(profile: any): number
	return math.max(0, profile.Aquarium.Slots - #profile.Aquarium.Fish)
end

-- Coins for the next slot, nil when maxed.
function Aquarium.NextSlotPrice(profile: any): number?
	return CFG.SlotPrices[profile.Aquarium.Slots - CFG.StartSlots + 1]
end

function Aquarium.State(profile: any, stats: Stats.ComputedStats?): State
	local s = stats or Stats.Compute(profile)
	local pr = s.Values.PearlRate
	local fish = {}
	local total = 0
	for _, f in profile.Aquarium.Fish do
		local rate = Aquarium.FishRate(f.Id, f.Mutation, pr)
		total += rate
		table.insert(fish, { Uid = f.Uid, Id = f.Id, Mutation = f.Mutation, Weight = f.Weight, Rate = rate })
	end
	return {
		Slots = profile.Aquarium.Slots,
		MaxSlots = Aquarium.MaxSlots,
		NextSlotPrice = Aquarium.NextSlotPrice(profile),
		Fish = fish,
		Rate = total * Boosts.Multiplier(profile, "Pearls"),
		Boost = Boosts.Multiplier(profile, "Pearls"),
		OfflineCapHours = s.Values.OfflineCapHours,
	}
end

-- Pearls per minute right now (with an active 2x Pearls boost).
function Aquarium.CurrentRate(profile: any, stats: Stats.ComputedStats?): number
	return Aquarium.Rate(profile, stats) * Boosts.Multiplier(profile, "Pearls")
end

-- Offline Pearls for `awaySeconds` (without boost; AquariumService adds the boosted part):
-- returns pearls, credited seconds, capped?
function Aquarium.OfflineReward(profile: any, awaySeconds: number, stats: Stats.ComputedStats?): (number, number, boolean)
	local s = stats or Stats.Compute(profile)
	local cap = s.Values.OfflineCapHours * 3600
	local credited = math.clamp(awaySeconds, 0, cap)
	return Aquarium.Rate(profile, s) * credited / 60, credited, awaySeconds > cap
end

-- Display helpers (UI shows idle income per SECOND and the total ticking live; Figma Economy 2).
-- perMinute -> "+0.045/s": >= 1 one decimal, >= 0.1 two, else three.
function Aquarium.FormatRate(perMinute: number): string
	local v = perMinute / 60
	if v <= 0 then
		return "+0/s"
	end
	local s = if v >= 1 then string.format("%.1f", v) elseif v >= 0.1 then string.format("%.2f", v) else string.format("%.3f", v)
	return `+{s}/s`
end

-- Pearls total formatted as a whole integer (e.g. "1,250", "45,000", "1.23M") matching other currencies.
function Aquarium.FormatPearls(v: number): string
	return Format.Number(v)
end

return Aquarium
