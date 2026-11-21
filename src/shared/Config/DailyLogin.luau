--!strict
-- Daily login rewards configuration (7-day calendar).
-- Rewards supported:
--   { Kind = "Coins", Amount = number }
--   { Kind = "Gems", Amount = number }
--   { Kind = "Pearls", Amount = number }
--   { Kind = "Bait", Id = string, Amount = number }

export type Reward = {
	Kind: "Coins" | "Gems" | "Pearls" | "Bait",
	Amount: number,
	Id: string?, -- for Bait
	Icon: string, -- UIAssets key
	Title: string,
}

export type DailyLoginDay = {
	Day: number,
	Title: string,
	Reward: Reward,
}

local DailyLogin: {
	ResetHourUTC: number,
	Days: { DailyLoginDay },
} = {
	ResetHourUTC = 0, -- 00:00 UTC = 07:00 Thai time
	Days = {
		{
			Day = 1,
			Title = "Day 1",
			Reward = { Kind = "Coins", Amount = 1000, Icon = "ui/status/coin", Title = "1,000 Coins" },
		},
		{
			Day = 2,
			Title = "Day 2",
			Reward = { Kind = "Bait", Id = "Worm", Amount = 15, Icon = "equipment/Worm", Title = "15 Worms" },
		},
		{
			Day = 3,
			Title = "Day 3",
			Reward = { Kind = "Gems", Amount = 15, Icon = "ui/status/gem", Title = "15 Gems" },
		},
		{
			Day = 4,
			Title = "Day 4",
			Reward = { Kind = "Bait", Id = "GlowGrub", Amount = 10, Icon = "equipment/GlowGrub", Title = "10 Glow Grubs" },
		},
		{
			Day = 5,
			Title = "Day 5",
			Reward = { Kind = "Pearls", Amount = 500, Icon = "ui/status/pearl", Title = "500 Pearls" },
		},
		{
			Day = 6,
			Title = "Day 6",
			Reward = { Kind = "Bait", Id = "SquidBait", Amount = 10, Icon = "equipment/SquidBait", Title = "10 Squid Baits" },
		},
		{
			Day = 7,
			Title = "Day 7",
			Reward = { Kind = "Gems", Amount = 50, Icon = "ui/status/gem", Title = "50 Gems" },
		},
	},
}

return DailyLogin
