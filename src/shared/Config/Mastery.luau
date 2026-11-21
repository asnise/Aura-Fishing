--!strict
-- Mastery (C15): permanent upgrades bought with Pearls (Aquarium). Kept through Rebirth.
-- One track = one stat. Price of the next level = floor(BasePrice * PriceGrowth ^ level).
--
-- Curve:
--   "Linear"      : bonus = PerLevel * level
--   "Diminishing" : bonus = MaxBonus * (1 - Decay ^ level)   (approaches MaxBonus, never reaches it)
-- MaxLevel (optional) stops a track where more would be wasted (e.g. the stat's own Max in StatDefs).
-- Add a track: add an entry (Stat must exist in StatDefs). The save + UI pick it up automatically.

export type Track = {
	Name: string,
	Stat: string,
	Order: number,
	BasePrice: number,
	Curve: string, -- "Linear" | "Diminishing"
	PerLevel: number?, -- Linear
	MaxBonus: number?, -- Diminishing
	Decay: number?, -- Diminishing, 0..1 (closer to 1 = slower)
	MaxLevel: number?,
	Icon: string?, -- UIAssets key shown on the card (Figma "Economy · 3 Mastery")
	IconTile: string?, -- New.Theme colour name behind a white vector icon; nil = white tile (full-colour art)
}

local Mastery: { PriceGrowth: number, Tracks: { [string]: Track } } = {
	PriceGrowth = 1.15,
	Tracks = {
		Luck = { Name = "Luck", Stat = "Luck", Order = 1, BasePrice = 15, Curve = "Diminishing", MaxBonus = 1.0, Decay = 0.98, Icon = "ui/mastery/luck" },
		CatchBar = { Name = "Catch Bar", Stat = "CatchBarSize", Order = 2, BasePrice = 10, Curve = "Linear", PerLevel = 0.002, MaxLevel = 50, Icon = "ui/mastery/catch_bar" },
		ReelPower = { Name = "Reel Power", Stat = "ReelPower", Order = 3, BasePrice = 10, Curve = "Linear", PerLevel = 0.01, Icon = "ui/mastery/reel_power" },
		AutoWait = { Name = "Auto Wait", Stat = "AutoSpeed", Order = 4, BasePrice = 12, Curve = "Linear", PerLevel = 0.005, MaxLevel = 40, Icon = "ui/mastery/auto_wait" },
		PearlRate = { Name = "Pearl Rate", Stat = "PearlRate", Order = 5, BasePrice = 8, Curve = "Linear", PerLevel = 0.02, Icon = "ui/mastery/pearl_rate" },
		OfflineCap = { Name = "Offline Cap", Stat = "OfflineCapHours", Order = 6, BasePrice = 20, Curve = "Linear", PerLevel = 0.25, MaxLevel = 32, Icon = "ui/mastery/offline_cap" },
		SellMult = { Name = "Sell Mult", Stat = "SellMultiplier", Order = 7, BasePrice = 15, Curve = "Linear", PerLevel = 0.01, Icon = "ui/mastery/sell_mult" },
	},
}

return Mastery
