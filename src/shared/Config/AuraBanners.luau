--!strict
-- Aura gacha banners (B6 G1 Altar + E1 Event banner). Each banner has its own pity counter and
-- pull count in profile.Gacha. Rolling: Roll.Aura with the banner's RateUp multipliers.
--   Altar          always on (Aura Altar, Auras window ROLL, altar ProximityPrompt)
--   <event id>     limited time: StartsUTC..EndsUTC (os.time in UTC), milestone rewards by total pulls
--
-- Pity (C17, Balance Pass): every PityPulls pulls without a PityRarity-or-better aura, the next pull is
-- exactly that rarity (Legendary every 100). HardPity: after HardPity.Pulls pulls without that rarity
-- (Mythic at 300) the next pull is it. Counters per banner: profile.Gacha.Pity / .PityHard.
-- x10 costs Cost*10*(1-Ten.Discount) and guarantees at least one Ten.MinRarity (Rare+).
-- Milestone reward kinds: Gems {Amount}, Coins {Amount}, Bait {Id, Amount}, Treasure {Id, Amount},
-- Aura {Id}.

export type Milestone = { Pulls: number, Kind: string, Amount: number?, Id: string? }
export type Banner = {
	Name: string,
	Kind: string, -- "Standard" | "Event"
	Currency: string,
	Cost: number, -- per pull
	PityPulls: number,
	PityRarity: string,
	HardPity: { Rarity: string, Pulls: number }?,
	Ten: { Discount: number, MinRarity: string },
	RateUp: { [string]: number }?, -- auraId -> chance multiplier (2 = twice as likely)
	Featured: string?, -- aura id shown as the banner showcase
	StartsUTC: number?,
	EndsUTC: number?,
	Milestones: { Milestone }?,
}

local Banners: { [string]: Banner } = {
	Altar = {
		Name = "Aura Altar",
		Kind = "Standard",
		Currency = "Gems",
		Cost = 5,
		PityPulls = 100,
		PityRarity = "Legendary",
		HardPity = { Rarity = "Mythic", Pulls = 300 },
		Ten = { Discount = 0.1, MinRarity = "Rare" },
	},
	NeonTide = {
		Name = "Neon Tide Banner",
		Kind = "Event",
		Currency = "Gems",
		Cost = 5,
		PityPulls = 100,
		PityRarity = "Legendary",
		HardPity = { Rarity = "Mythic", Pulls = 300 },
		Ten = { Discount = 0.1, MinRarity = "Rare" },
		RateUp = { NeonWave = 2, AbyssalShadow = 2 },
		Featured = "AbyssalShadow",
		StartsUTC = 1794787200, -- 2026-11-16 00:00 UTC
		EndsUTC = 1795996800, -- 2026-11-30 00:00 UTC
		Milestones = ({
			{ Pulls = 10, Kind = "Gems", Amount = 20 },
			{ Pulls = 30, Kind = "Gems", Amount = 50 },
			{ Pulls = 50, Kind = "Bait", Id = "Shrimp", Amount = 10 },
			{ Pulls = 100, Kind = "Treasure", Id = "TreasureChest", Amount = 2 },
			{ Pulls = 200, Kind = "Gems", Amount = 150 },
			{ Pulls = 400, Kind = "Aura", Id = "AbyssalShadow" },
		} :: { Milestone }),
	},
}

return Banners
