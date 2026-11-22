--!strict
-- Global tuning numbers. Balance the game from here.

local GameConfig = {
	-- Data
	DataStoreName = "AuraFishing_Player_v1",
	AutosaveInterval = 120,
	StartingCoins = 500, -- enough to buy the first item right away (BALANCE_PLAN 2)
	StartingGems = 15,

	-- Casting
	CastDistance = 14, -- studs: "is there water in reach" check (FishingSpot.NearWater) = base CastRange
	-- C25 hold-to-cast. Power 0..1 maps to MinDistance..CastRange (stat). Perfect = released inside the gold zone.
	Cast = {
		HoldCharge = true, -- false = tap only (every cast uses TapPower), to compare the two feels
		TapTime = 0.15, -- seconds: a shorter press is a tap
		TapPower = 0.55, -- tap / Auto cast power
		ChargeCycle = 1.1, -- seconds for the needle to go 0 -> 1 (then back down)
		MinDistance = 6, -- studs at power 0
		PerfectMin = 0.78, -- gold zone on the power bar
		PerfectMax = 0.9,
		PerfectBiteBonus = 0.3, -- Perfect cast: bite wait x (1 - this)
		FlightTime = 0.35, -- seconds the bobber flies before it lands
	},
	-- C26 Fish Hotspots: bubbling patches that pop up in the water near anglers (HotspotService).
	-- A manual cast landing inside adds LuckBonus to that roll; each spot takes Uses casts, then moves on.
	Hotspot = {
		Max = 4, -- in the whole server
		SpawnEvery = 6, -- seconds between spawn attempts
		Lifetime = { 35, 55 }, -- seconds
		Radius = 4, -- studs
		Distance = { 9, 26 }, -- studs from the angler it spawns near: far ones need a longer CastRange
		LuckBonus = 0.5,
		Uses = 2,
	},
	BiteWait = { 2.5, 6 }, -- seconds, random range, reduced by BiteSpeed
	BiteWindow = 2.2, -- seconds the player has to click "!" before the fish escapes
	CastCooldown = 0.6,

	-- Manual vs Auto (GDD 3.3)
	ManualMultiplier = 1.5,
	PerfectCatchBonus = 0.25, -- extra multiplier if the fish never left the catch bar
	AutoCycleTime = 14, -- seconds per auto catch, reduced by AutoSpeed
	AutoGemMultiplier = 0.5, -- Auto catches give this share of rarity Gems (fraction = chance of +1)
	AutoTreasureMultiplier = 0.5, -- Auto catches roll treasure chests at this share of the chance

	-- Hot Streak (manual only): each manual catch in a row adds PerCatch to the coin value, up to Max.
	-- A snapped line or a missed bite resets it; Auto catches neither count nor reset.
	HotStreak = {
		PerCatch = 0.05,
		Max = 0.5, -- reached at x10
	},
	AutoNeedsWater = true,

	-- Reel minigame (shared by client simulation and server validation)
	Minigame = {
		StartProgress = 0.25,
		GainPerSecond = 0.32, -- x ReelPower
		LossPerSecond = 0.22, -- x (1 - Resilience)
		DifficultySpeedScale = 0.18, -- fish speed = pattern.Speed * (1 + (Difficulty-1) * this)
		MaxDuration = 60,
		ValidationSlack = 0.8, -- server accepts finishing at 80% of theoretical minimum time
		-- Pond Card (chosen reel UI, Figma 03): catch bar physics in "water heights" (0..1)
		BarGravity = 2.2, -- catch bar sinks when released
		BarLift = 3.6, -- catch bar rises while holding
		SnapWarning = 0.2, -- progress below this while off the fish shows "SNAP!" instead of "LOOSE"
		-- Start: the catch bar opens centred on the fish; for StartGrace seconds the fish holds still
		-- and the bar only moves if the player holds (no gravity), so the first moment is never a miss.
		StartGrace = 0.6,
		StartFishRange = { 0.3, 0.7 }, -- where the fish appears (0 = bottom, 1 = top)
	},

	-- Inventory (bag, Item rework): capacity = number of SLOTS (Bags.Capacity). One slot = one item.
	-- Fish and Rods/Lines never stack (each has its own UUID, weight, mutation, mods); only chests stack.
	-- Fish, rods, lines (the worn ones too), chests and bait types (one slot per type) all use a slot. Auras and Bags do not.
	Inventory = {
		TreasureStackMax = 5,
		TreasureLuckScale = 0.5, -- drop chance *= 1 + Luck * this
		InfiniteBagSlots = 999, -- capacity with the Infinite Bag pass (C6); UI shows it as "Inf"
		GearSellFraction = 0.4, -- selling a Rod/Line pays this share of (buy price + coins spent on Enhance)
		MaxPrefixes = 2, -- Rod mods
		MaxSuffixes = 2,
		-- A mod adds this share of the rod's base sell-back value (before the 40%), by rarity.
		ModSellBonus = { Common = 0, Uncommon = 0.05, Rare = 0.15, Epic = 0.4, Legendary = 0.9, Mythic = 2 } :: { [string]: number },
	},

	-- Rods found while fishing (Items/RodDrop): chance per catch, raised by Luck; Auto catches roll AutoTreasureMultiplier
	-- of it. Deep water (DeepDepth m) or a hotspot uses the DeepSea mod table, otherwise Fishing.
	RodDrop = {
		Chance = 0.004,
		LuckScale = 0.5,
		DeepDepth = 200,
	},

	-- Rod Fusion (docs/ROD_FUSION_COST.md): move one mod from a Material rod onto a Base rod (same model).
	-- Coins = rod Price * FeeFraction * RarityMult[mod] * (CapBreakerMult if Cap Breaker) * slot factor
	-- (CursedDiscount when the replaced mod is negative, EmptySlotMult for a free slot). Pearls: Epic and up.
	-- FailChance: only the Material rod is lost (nothing is charged).
	Fusion = {
		FeeFraction = 0.25,
		RarityMult = { Common = 1, Uncommon = 1.5, Rare = 2.5, Epic = 4, Legendary = 7, Mythic = 12 } :: { [string]: number },
		CapBreakerMult = 1.5,
		CursedDiscount = 0.5,
		EmptySlotMult = 0.6,
		PearlCost = { Epic = 300, Legendary = 1500, Mythic = 8000 } :: { [string]: number },
		FailChance = 0.05,
		GuardGems = { Rare = 20, Epic = 40, Legendary = 80, Mythic = 150 } :: { [string]: number }, -- optional: pay Gems for a sure success
		NpcRange = 40, -- studs from Old Marlin
	},

	-- Boosts (C19, Dev Products): profile.Boosts[id] = os.time() when it ends. Real time (keeps
	-- running offline). Buying again adds Seconds on top of what is left.
	Boosts = {
		Coins = { Name = "2x Coins", Multiplier = 2 }, -- selling fish
		Pearls = { Name = "2x Pearls", Multiplier = 2 }, -- Aquarium (online + the boosted part of offline)
	} :: { [string]: { Name: string, Multiplier: number } },

	-- Aquarium (C14): fish put in the tank make Pearls every minute, also while offline.
	-- Pearls/min = RatePerMinute[rarity] * mutation ValueMultiplier * PearlRate stat.
	-- Offline: credited on join for min(time away, OfflineCapHours stat) (VIP adds hours).
	Aquarium = {
		StartSlots = 3,
		-- price of slot 4, 5, 6 ... (Coins). MaxSlots = StartSlots + #SlotPrices.
		SlotPrices = { 5000, 20000, 80000, 300000, 1000000, 3500000, 12000000, 40000000, 140000000 },
		RatePerMinute = { Common = 0.2, Uncommon = 0.5, Rare = 1.5, Epic = 4, Legendary = 12, Mythic = 40 } :: { [string]: number },
		MinOfflineSeconds = 60, -- shorter absences give nothing (and no popup)
		SettleInterval = 5, -- seconds between server Pearl ticks
		SyncInterval = 30, -- seconds between profile snapshots for Pearls only (client counts up from Rate)
	},

	-- Gear Enhance (C16): owned Rods/Lines go +1 ... +MaxLevel. Each level multiplies the item's
	-- stats by (1 + StatPerLevel * level), except ExcludeStats (MaxDepth: depth is the line's tier).
	-- Coins for level L -> L+1 = floor(item Price * CostFraction * CostGrowth ^ L).
	-- PearlCosts[L+1] (optional) = extra Pearls for that level (phase 2; empty = Coins only).
	Enhance = {
		Categories = { "Rods", "Lines" },
		MaxLevel = 10,
		StatPerLevel = 0.04,
		CostFraction = 0.1,
		CostGrowth = 1.5,
		ExcludeStats = { MaxDepth = true } :: { [string]: boolean },
		PearlCosts = {} :: { [number]: number },
	},

	-- Hot fish at the Merchant (C18): every IntervalMinutes the shop picks Count[1]..Count[2] species
	-- (from Rarities) that sell for one of Mults. Picked from the UTC hour, so every server agrees.
	HotFish = {
		IntervalMinutes = 60,
		Count = { 1, 2 },
		Mults = { 2, 2.5, 3 },
		Rarities = { "Common", "Uncommon", "Rare", "Epic" },
		Seed = 7319, -- change to reshuffle the whole schedule
	},

	-- Rolling
	LuckTierExponent = 0.6, -- weight *= (1 + Luck) ^ ((Tier - 1) * this)

	-- Progression
	XPBase = 60,
	XPExponent = 1.3,
	GemsPerLevel = 5,
	NewSpeciesGems = 3, -- first catch of a species (Fishdex entry)
	GemsByRarityTier = { [3] = 1, [4] = 3, [5] = 10, [6] = 30 } :: { [number]: number },

	-- Auras
	AuraRollCost = 5,
	AuraRollCurrency = "Gems",
}

function GameConfig.XPForLevel(level: number): number
	return math.floor(GameConfig.XPBase * level ^ GameConfig.XPExponent)
end

return GameConfig
