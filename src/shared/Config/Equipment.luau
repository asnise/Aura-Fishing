--!strict
-- Shop equipment. Every category uses the same shape so the shop UI and ShopService
-- handle new categories/items automatically.
--
-- Rods / Lines        : bought any number of times; every purchase is its own item (UUID) in the bag, one worn.
--                       Sell back for GameConfig.Inventory.GearSellFraction of the price (+ Enhance coins).
-- Bags                : permanent capacity upgrades (ladder), one equipped, never use a slot.
-- Baits               : consumable stacks (BuyAmount per purchase), one bait slot equipped,
--                       one unit consumed per successful catch.
-- Order               : sort order in the shop; first item (Price = 0) is the starter item.
-- Stats               : additive stat bonuses (see StatDefs).

export type Item = {
	Name: string,
	Price: number,
	Currency: string, -- "Coins" | "Gems"
	Order: number,
	Stats: { [string]: number },
	Description: string?,
	Capacity: number?, -- Bags only: number of inventory SLOTS (one slot = one item)
	BuyAmount: number?, -- Baits only
	RequiredLevel: number?,
	Exclusive: string?, -- not sold in the Shop; only from this source (e.g. "StarterPack"). Hidden until owned.
}

export type Category = {
	DisplayName: string,
	Kind: string, -- "Permanent" | "Consumable"
	Items: { [string]: Item },
}

local Equipment: { [string]: Category } = {
	Rods = {
		DisplayName = "Rods",
		Kind = "Permanent",
		Items = {
			DriftwoodRod = { Name = "Driftwood Rod", Price = 0, Currency = "Coins", Order = 1, Stats = {} },
			BambooRod = { Name = "Bamboo Rod", Price = 1500, Currency = "Coins", Order = 2, Stats = { CastRange = 3, CatchBarSize = 0.03, ReelPower = 0.15, Luck = 0.05 } },
			CoralRod = { Name = "Coral Rod", Price = 12000, Currency = "Coins", Order = 3, Stats = { CastRange = 5, CatchBarSize = 0.05, ReelPower = 0.3, Resilience = 0.15, Luck = 0.15 } },
			MoonsilverRod = { Name = "Moonsilver Rod", Price = 120000, Currency = "Coins", Order = 4, RequiredLevel = 10, Stats = { CastRange = 8, CatchBarSize = 0.08, ReelPower = 0.5, Resilience = 0.3, Luck = 0.35, FishStability = 0.1, AutoSpeed = 0.1 } },
			-- Starter Pack (C19): light stats so it does not skip the early buying ladder. Price = Enhance cost base.
			SweetheartRod = { Name = "Sweetheart Rod", Price = 1500, Currency = "Coins", Order = 6, Exclusive = "StarterPack", Description = "A gift from the Starter Pack.", Stats = { CastRange = 3, CatchBarSize = 0.04, ReelPower = 0.08, Luck = 0.03 } },
			NagaScaleRod = { Name = "Naga Scale Rod", Price = 900000, Currency = "Coins", Order = 5, RequiredLevel = 25, Stats = { CastRange = 11, CatchBarSize = 0.12, ReelPower = 0.8, Resilience = 0.45, Luck = 0.75, FishStability = 0.2, MutationChance = 0.02, AutoSpeed = 0.2 } },
			-- 2026-11-18 (art already uploaded): late-game rods for the deep / trench
			AbyssRod = { Name = "Abyss Rod", Price = 4500000, Currency = "Coins", Order = 7, RequiredLevel = 35, Description = "Mint runes glow along the handle in the dark.", Stats = { CastRange = 14, CatchBarSize = 0.14, ReelPower = 1.1, Resilience = 0.55, Luck = 1.1, FishStability = 0.25, MutationChance = 0.03, AutoSpeed = 0.25 } },
			CelestialRod = { Name = "Celestial Rod", Price = 20000000, Currency = "Coins", Order = 8, RequiredLevel = 50, Description = "White and gold, with a small star at the tip.", Stats = { CastRange = 18, CatchBarSize = 0.16, ReelPower = 1.5, Resilience = 0.65, Luck = 1.6, FishStability = 0.3, MutationChance = 0.05, AutoSpeed = 0.3 } },
		},
	},
	Lines = {
		DisplayName = "Lines",
		Kind = "Permanent",
		Items = {
			CottonLine = { Name = "Cotton Line (30m)", Price = 0, Currency = "Coins", Order = 1, Stats = { MaxDepth = 30 } },
			HempLine = { Name = "Hemp Line (80m)", Price = 1000, Currency = "Coins", Order = 2, Stats = { MaxDepth = 80 } },
			NylonLine = { Name = "Nylon Line (150m)", Price = 15000, Currency = "Coins", Order = 3, Stats = { MaxDepth = 150, Resilience = 0.05 } },
			SilkLine = { Name = "Spider-Silk Line (300m)", Price = 150000, Currency = "Coins", Order = 4, RequiredLevel = 12, Stats = { MaxDepth = 300, Resilience = 0.1 } },
			AbyssLine = { Name = "Abyss Line (600m)", Price = 1200000, Currency = "Coins", Order = 5, RequiredLevel = 30, Description = "Dark teal line that glows softly in deep water.", Stats = { MaxDepth = 600, Resilience = 0.15 } },
			StarLine = { Name = "Star Line (1000m)", Price = 6000000, Currency = "Coins", Order = 6, RequiredLevel = 45, Description = "Shimmering gold line with tiny stars. Reaches the trench.", Stats = { MaxDepth = 1000, Resilience = 0.2, Luck = 0.1 } },
		},
	},
	Bags = {
		DisplayName = "Bags",
		Kind = "Permanent",
		Items = {
			StarterPouch = { Name = "Starter Pouch", Price = 0, Currency = "Coins", Order = 1, Capacity = 10, Stats = {} },
			WovenBasket = { Name = "Woven Basket", Price = 800, Currency = "Coins", Order = 2, Capacity = 16, Stats = {} },
			Crate = { Name = "Fish Crate", Price = 6000, Currency = "Coins", Order = 3, Capacity = 24, Stats = {} },
			Coolbox = { Name = "Ice Coolbox", Price = 40000, Currency = "Coins", Order = 4, Capacity = 36, Stats = {} },
			Hold = { Name = "Ship's Hold", Price = 250000, Currency = "Coins", Order = 5, Capacity = 50, Stats = {} },
		},
	},
	Baits = {
		DisplayName = "Baits",
		Kind = "Consumable",
		Items = {
			Worm = { Name = "Worm", Price = 100, Currency = "Coins", Order = 1, BuyAmount = 10, Stats = { Luck = 0.1 } },
			Shrimp = { Name = "Shrimp", Price = 800, Currency = "Coins", Order = 2, BuyAmount = 10, Stats = { Luck = 0.3, BiteSpeed = 0.1 } },
			GlowGrub = { Name = "Glow Grub", Price = 6000, Currency = "Coins", Order = 3, BuyAmount = 10, Stats = { Luck = 0.75, MutationChance = 0.01, AutoSpeed = 0.1 } },
			-- 2026-11-18 (art already uploaded)
			SquidBait = { Name = "Squid Bait", Price = 40000, Currency = "Coins", Order = 4, BuyAmount = 10, RequiredLevel = 20, Description = "Deep fish love it. 1 used per catch.", Stats = { Luck = 1.2, BiteSpeed = 0.15 } },
			PearlBait = { Name = "Pearl Bait", Price = 250000, Currency = "Coins", Order = 5, BuyAmount = 10, RequiredLevel = 30, Description = "Lustrous beads: more mutations. 1 used per catch.", Stats = { Luck = 1.8, MutationChance = 0.02, AutoSpeed = 0.15 } },
			StormBait = { Name = "Storm Bait", Price = 1200000, Currency = "Coins", Order = 6, BuyAmount = 10, RequiredLevel = 40, Description = "A tiny storm cloud in a jar. Fish bite fast. 1 used per catch.", Stats = { Luck = 2.6, BiteSpeed = 0.3, MutationChance = 0.03 } },
			SummonBait = { Name = "Summon Bait", Price = 60, Currency = "Gems", Order = 7, BuyAmount = 3, RequiredLevel = 20, Description = "A glowing orb in seaweed. Calls the rarest fish. 1 used per catch.", Stats = { Luck = 4, MutationChance = 0.05, FishStability = 0.1 } },
		},
	},
}

return Equipment
