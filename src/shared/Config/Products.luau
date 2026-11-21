--!strict
-- Robux purchases (C13). Ids come from the Roblox website (Creator Hub → Monetization).
-- 0 = not created yet: the item still works through Dev commands (`grant pass <id>`,
-- `receipt <product>`), but cannot be bought for real.
--
-- Passes   : one-time Game Passes. Owned passes are a stat source (Stats.Collect), so
--            server and client compute the same stats. `Price` is display only (set it on the site).
-- Products : Developer Products (can be bought many times unless `OncePerPlayer`).
--            Rewards are granted by MonetizationService.ProcessReceipt, exactly once per receipt.
--   Reward Kind = "Gems" | "Coins" : Amount
--   Reward Kind = "Bait"           : Id (Equipment.Baits) x Amount
--   Reward Kind = "Item"           : Category + Id (permanent Equipment item, owned forever)
--   Reward Kind = "Boost"          : Id (GameConfig.Boosts) for Amount seconds (stacks on what is left)
-- Add a product: add an entry, create it on the site, paste the id.

export type Reward = { Kind: string, Amount: number?, Id: string?, Category: string? }

export type Pass = {
	Name: string,
	PassId: number,
	Price: number, -- Robux, display only
	Order: number,
	Description: string,
	Stats: { [string]: number }?,
	Mutations: { [string]: number }?,
}

export type Product = {
	Name: string,
	ProductId: number,
	Price: number, -- Robux, display only
	Order: number,
	Description: string?,
	OncePerPlayer: boolean?,
	Rewards: { Reward },
}

local Products: { Passes: { [string]: Pass }, Products: { [string]: Product } } = {
	Passes = {
		VIP = {
			Name = "VIP",
			PassId = 2094074714,
			Price = 149,
			Order = 1,
			Description = "+15% Luck, gold name tag, 12h offline Aquarium cap",
			Stats = { Luck = 0.15, OfflineCapHours = 8 },
		},
		AutoFishPro = {
			Name = "Auto-Fish Pro",
			PassId = 2094398695,
			Price = 249,
			Order = 2,
			Description = "-25% Auto Wait and x1.25 Auto value (still below Manual x1.5)",
			Stats = { AutoSpeed = 0.25, AutoMultiplier = 0.25 },
		},
		InfiniteBag = {
			Name = "Infinite Bag",
			PassId = 2094482688,
			Price = 349,
			Order = 3,
			Description = "Never fill your bag again", -- effect: C6
		},
		ExtraCast = {
			Name = "Extra Cast",
			PassId = 0,
			Price = 199,
			Order = 4,
			Description = "Fish with two lines at once.",
		},
	},
	Products = {
		GemsSmall = {
			Name = "25 Gems",
			ProductId = 3732771844,
			Price = 25,
			Order = 1,
			Rewards = { { Kind = "Gems", Amount = 25 } },
		},
		GemsMedium = {
			Name = "110 Gems",
			ProductId = 3732772008,
			Price = 99,
			Order = 2,
			Rewards = { { Kind = "Gems", Amount = 110 } },
		},
		GemsLarge = {
			Name = "300 Gems",
			ProductId = 3732772134,
			Price = 249,
			Order = 3,
			Rewards = { { Kind = "Gems", Amount = 300 } },
		},
		StarterPack = {
			Name = "Starter Pack",
			ProductId = 3733362354,
			Price = 49,
			Order = 4,
			OncePerPlayer = true,
			Description = "100 Gems, 50 Shrimp and the Sweetheart Rod",
			Rewards = {
				{ Kind = "Gems", Amount = 100 },
				{ Kind = "Bait", Id = "Shrimp", Amount = 50 },
				{ Kind = "Item", Category = "Rods", Id = "SweetheartRod" },
			},
		},
		BoostCoins = {
			Name = "2x Coins",
			ProductId = 3733362467,
			Price = 39,
			Order = 5,
			Rewards = { { Kind = "Boost", Id = "Coins", Amount = 7200 } },
		},
		BoostPearls = {
			Name = "2x Pearls",
			ProductId = 3733362542,
			Price = 39,
			Order = 6,
			Rewards = { { Kind = "Boost", Id = "Pearls", Amount = 7200 } },
		},
	},
}

return Products
