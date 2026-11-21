--!strict
-- Every gameplay stat in one place. Items (rods, lines, baits, auras, gamepasses, skills...)
-- only declare additive bonuses: `Stats = { Luck = 0.15, CatchBarSize = 0.02 }`.
-- Stats.Compute() sums Base + all bonuses, then clamps to [Min, Max].
-- To add a new stat: add it here, then read it where it matters (e.g. FishingService).

export type StatDef = {
	Base: number,
	Min: number?,
	Max: number?,
	Display: string,
	Percent: boolean?,
	Reduces: boolean?, -- shown as a minus ("-20% Auto Wait"): the bonus shortens something
	Highlight: boolean?, -- selling-point stat: gold badge, listed first (shop, aura card, packages)
}

local StatDefs: { [string]: StatDef } = {
	Luck = { Base = 0, Min = 0, Display = "Luck", Percent = true }, -- +1.0 = +100% luck
	CatchBarSize = { Base = 0.22, Min = 0.08, Max = 0.6, Display = "Catch Bar", Percent = true }, -- fraction of bar height
	ReelPower = { Base = 1, Min = 0.2, Display = "Reel Power" }, -- progress gain multiplier
	Resilience = { Base = 0, Min = 0, Max = 0.9, Display = "Resilience", Percent = true }, -- reduces progress loss
	FishStability = { Base = 0, Min = 0, Max = 0.8, Display = "Fish Stability", Percent = true }, -- calms fish movement
	MaxDepth = { Base = 0, Min = 0, Display = "Max Depth" }, -- metres, set by Line
	CastRange = { Base = 14, Min = 6, Display = "Cast Range" }, -- studs, longest cast (C25); rods add more
	BiteSpeed = { Base = 0, Min = 0, Max = 0.8, Display = "Bite Speed", Percent = true }, -- shortens bite wait
	AutoMultiplier = { Base = 1.0, Min = 0, Display = "Auto Sell Mult" },
	-- Auto Fishing wait per catch = GameConfig.AutoCycleTime * (1 - AutoSpeed). Highlighted: use it on
	-- rods/baits/auras and future gamepasses/packages (C6), e.g. Stats = { AutoSpeed = 0.2 } -> "-20% Auto Wait".
	AutoSpeed = { Base = 0, Min = 0, Max = 0.75, Display = "Auto Wait", Percent = true, Reduces = true, Highlight = true },
	MutationChance = { Base = 0, Min = 0, Display = "Mutation Chance", Percent = true }, -- added to every mutation
	SellMultiplier = { Base = 1, Min = 0, Display = "Sell Mult" },
	XPMultiplier = { Base = 1, Min = 0, Display = "XP Mult" },
	PearlRate = { Base = 1, Min = 0, Display = "Pearl Rate" }, -- Aquarium Pearls multiplier (Mastery C15)
	OfflineCapHours = { Base = 4, Min = 0, Max = 48, Display = "Offline Cap" }, -- hours of offline Pearls (VIP +8)
	ExtraLines = { Base = 0, Min = 0, Max = 9, Display = "Extra Lines" }, -- reserved for Multi-Cast (Phase 3)
}

return StatDefs
