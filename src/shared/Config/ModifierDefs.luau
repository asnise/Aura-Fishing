--!strict
-- Rod modifiers (docs/MODIFIER_SYSTEM_SPEC.md). A rod holds up to 2 Prefix + 2 Suffix mods (GameConfig.Inventory).
-- Each mod: Stat gets a value rolled in [Min, Max] (negative = "cursed"). A Cap Breaker mod targets "Max<Stat>":
-- it raises that stat's maximum instead of the stat itself (Stats.Compute, never above its absolute ceiling).
-- Adding a mod = adding a line here; Registry validates it.

export type ModDef = {
	Id: string,
	Name: string,
	Stat: string, -- StatDefs key, or Max<StatDefs key> for a Cap Breaker
	Rarity: string,
	Min: number,
	Max: number,
}

-- Where a rod came from decides its slots and mod grade.
--   PrefixSlots / SuffixSlots = weights for 0, 1, 2 slots.  Floor / Ceiling = lowest / highest mod rarity.
--   CapBreakerChance = chance that a mod is a Cap Breaker.  GuaranteeCapBreaker = at least one.
--   Pure = values never negative (Pure Blessing).
export type Profile = {
	PrefixSlots: { number },
	SuffixSlots: { number },
	Floor: string,
	Ceiling: string,
	CapBreakerChance: number,
	GuaranteeCapBreaker: boolean?,
	Pure: boolean?,
}

local function d(id: string, name: string, stat: string, rarity: string, min: number, max: number): ModDef
	return { Id = id, Name = name, Stat = stat, Rarity = rarity, Min = min, Max = max }
end

local Prefixes: { ModDef } = {
	d("p_swift", "Swift", "BiteSpeed", "Common", -0.04, 0.08),
	d("p_firm", "Firm", "ReelPower", "Common", -0.10, 0.20),
	d("p_long", "Reaching", "CastRange", "Common", -2, 5),
	d("p_keen", "Keen", "BiteSpeed", "Uncommon", -0.06, 0.14),
	d("p_sturdy", "Sturdy", "ReelPower", "Uncommon", -0.15, 0.35),
	d("p_fortunate", "Fortunate", "Luck", "Uncommon", -0.05, 0.12),
	d("p_lucky", "Lucky", "Luck", "Rare", -0.08, 0.22),
	d("p_mighty", "Mighty", "ReelPower", "Rare", -0.20, 0.55),
	d("p_brisk", "Brisk", "AutoSpeed", "Rare", -0.04, 0.10),
	d("p_limitless_bite", "Uncapped", "MaxBiteSpeed", "Rare", -0.02, 0.04), -- Cap Breaker
	d("p_blessed", "Blessed", "Luck", "Epic", -0.10, 0.38),
	d("p_rapid", "Rapid", "AutoSpeed", "Epic", -0.06, 0.18),
	d("p_overclock", "Overclocked", "MaxAutoSpeed", "Epic", -0.03, 0.05), -- Cap Breaker
	d("p_celestial", "Celestial", "Luck", "Legendary", -0.12, 0.65),
	d("p_hyper", "Hyper", "AutoSpeed", "Legendary", -0.08, 0.25),
	d("p_transcendent_speed", "Warp", "MaxAutoSpeed", "Legendary", -0.04, 0.08), -- Cap Breaker
	d("p_divine", "Divine", "Luck", "Mythic", -0.15, 1.00),
	d("p_singularity", "Singularity", "MaxAutoSpeed", "Mythic", -0.04, 0.10), -- Cap Breaker
}

local Suffixes: { ModDef } = {
	d("s_of_grip", "of Grip", "CatchBarSize", "Common", -0.02, 0.04),
	d("s_of_ease", "of Calm", "FishStability", "Common", -0.04, 0.08),
	d("s_of_bargain", "of Commerce", "SellMultiplier", "Common", -0.05, 0.10),
	d("s_of_tension", "of Tension", "Resilience", "Uncommon", -0.05, 0.12),
	d("s_of_width", "of Scope", "CatchBarSize", "Uncommon", -0.03, 0.07),
	d("s_of_wisdom", "of Insight", "XPMultiplier", "Uncommon", -0.05, 0.15),
	d("s_of_iron", "of Iron", "Resilience", "Rare", -0.08, 0.20),
	d("s_of_stillness", "of Stillness", "FishStability", "Rare", -0.07, 0.18),
	d("s_of_wealth", "of Prosperity", "SellMultiplier", "Rare", -0.08, 0.25),
	d("s_of_expansion", "of Extension", "MaxCatchBarSize", "Rare", -0.02, 0.04), -- Cap Breaker
	d("s_of_mutation", "of Anomaly", "MutationChance", "Epic", -0.01, 0.03),
	d("s_of_pearls", "of Tides", "PearlRate", "Epic", -0.08, 0.30),
	d("s_of_unyielding", "of the Unbroken", "MaxResilience", "Epic", -0.02, 0.04), -- Cap Breaker
	d("s_of_deep_calm", "of Serenity", "MaxFishStability", "Epic", -0.03, 0.06), -- Cap Breaker
	d("s_of_radiance", "of Radiance", "MutationChance", "Legendary", -0.015, 0.06),
	d("s_of_the_abyss", "of the Abyss", "PearlRate", "Legendary", -0.12, 0.60),
	d("s_of_the_titan", "of the Titan", "MaxCatchBarSize", "Legendary", -0.03, 0.08), -- Cap Breaker
	d("s_of_eternity", "of Eternity", "MutationChance", "Mythic", -0.02, 0.12),
	d("s_of_the_leviathan", "of the Leviathan", "MaxCatchBarSize", "Mythic", -0.04, 0.12), -- Cap Breaker
	d("s_of_adamant", "of Adamant", "MaxResilience", "Mythic", -0.02, 0.05), -- Cap Breaker
}

local Profiles: { [string]: Profile } = {
	Shop = { PrefixSlots = { 50, 45, 5 }, SuffixSlots = { 50, 45, 5 }, Floor = "Common", Ceiling = "Rare", CapBreakerChance = 0 },
	Fishing = { PrefixSlots = { 25, 60, 15 }, SuffixSlots = { 25, 60, 15 }, Floor = "Common", Ceiling = "Epic", CapBreakerChance = 0.05 },
	DeepSea = { PrefixSlots = { 10, 60, 30 }, SuffixSlots = { 10, 60, 30 }, Floor = "Uncommon", Ceiling = "Legendary", CapBreakerChance = 0.15 },
	BossRaid = { PrefixSlots = { 0, 50, 50 }, SuffixSlots = { 0, 50, 50 }, Floor = "Rare", Ceiling = "Mythic", CapBreakerChance = 0.35 },
	-- Quest / season reward: all 4 slots, Pure Blessing, one Cap Breaker guaranteed
	QuestPure = { PrefixSlots = { 0, 0, 1 }, SuffixSlots = { 0, 0, 1 }, Floor = "Rare", Ceiling = "Legendary", CapBreakerChance = 0, GuaranteeCapBreaker = true, Pure = true },
}

return {
	Prefixes = Prefixes,
	Suffixes = Suffixes,
	Profiles = Profiles,
}
