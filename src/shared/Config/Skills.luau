--!strict
-- Skills (C4, GDD 7.1). Permanent: every level-up gives PointsPerLevel skill point(s), also when
-- the level is gained again after a Rebirth, so rebirthing never loses skills - it earns more points.
-- Cost of the next level = Costs[next] if Costs is set, else CostBase + floor(level / CostStep).
-- Each level adds PerLevel to Stat (one stat source, Stats.Collect).
--
-- Multi-Cast: Stat = ExtraLines. Every extra line has MultiCast.ExtraLineChance to hook a bonus fish
-- on each catch (manual or auto). Bonus fish go to the bag like Auto catches (Auto multiplier, no Hot
-- Streak, Auto Gems share) and show on the main catch card (CatchResult.Bonus).

export type Skill = {
	Name: string,
	Stat: string,
	Order: number,
	PerLevel: number,
	MaxLevel: number,
	CostBase: number?,
	CostStep: number?,
	Costs: { number }?, -- explicit cost per level (1..MaxLevel)
	Description: string,
	Icon: string?, -- UIAssets key (UI session)
}

local Skills: { PointsPerLevel: number, MultiCast: { ExtraLineChance: number }, List: { [string]: Skill } } = {
	PointsPerLevel = 1,
	MultiCast = {
		ExtraLineChance = 0.35, -- per extra line, per catch
	},
	List = {
		KeenEye = {
			Name = "Keen Eye",
			Stat = "Luck",
			Order = 1,
			PerLevel = 0.01,
			MaxLevel = 50,
			CostBase = 1,
			CostStep = 10, -- 1 point for Lv1-10, 2 for Lv11-20 ...
			Description = "+1% Luck per level",
		},
		QuickHands = {
			Name = "Quick Hands",
			Stat = "BiteSpeed",
			Order = 2,
			PerLevel = 0.01,
			MaxLevel = 30,
			CostBase = 1,
			CostStep = 10,
			Description = "Fish bite 1% faster per level",
		},
		MultiCast = {
			Name = "Multi-Cast",
			Stat = "ExtraLines",
			Order = 3,
			PerLevel = 1,
			MaxLevel = 9, -- 1 + 9 = 10 lines (GDD 7.1)
			Costs = { 5, 10, 15, 20, 30, 40, 50, 65, 80 },
			Description = "+1 extra line: 35% chance of a bonus fish on every catch",
		},
	},
}

return Skills
