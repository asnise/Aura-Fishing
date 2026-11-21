--!strict
-- Daily quest pool (C7, GDD 7.3). Every day (Features.Quests.ResetHourUTC) each player gets
-- Features.Quests.PerDay different quests picked by Weight from the ones their level allows.
-- Each quest pays Features.Quests.RewardGems unless it sets its own RewardGems.
--
-- Kind (what counts, see QuestService):
--   "Catch"        any catch (Manual or Auto)              Target = fish
--   "CatchManual"  manual catches                          Target = fish
--   "CatchRarity"  catches of Rarity or rarer              Target = fish, Rarity = rarity id
--   "CatchMutated" catches with any mutation               Target = fish
--   "Streak"       reach a Hot Streak of Target             Target = streak
--   "SellFish"     fish sold (Sell All / Sell stack)       Target = fish
--   "PullAura"     aura pulls on any banner (x10 = 10)     Target = pulls
-- Text: "{n}" = Target. Add a quest = add an entry.

export type Quest = {
	Text: string,
	Kind: string,
	Target: number,
	Weight: number,
	Rarity: string?,
	MinLevel: number?,
	RewardGems: number?,
	Icon: string?, -- UIAssets key (UI session)
}

local Quests: { [string]: Quest } = {
	Catch25 = { Text = "Catch {n} fish", Kind = "Catch", Target = 25, Weight = 10 },
	Catch60 = { Text = "Catch {n} fish", Kind = "Catch", Target = 60, Weight = 5, MinLevel = 10 },
	Manual15 = { Text = "Reel in {n} fish by hand", Kind = "CatchManual", Target = 15, Weight = 10 },
	Rare3 = { Text = "Catch {n} Rare or better fish", Kind = "CatchRarity", Rarity = "Rare", Target = 3, Weight = 8 },
	Epic1 = { Text = "Catch an Epic or better fish", Kind = "CatchRarity", Rarity = "Epic", Target = 1, Weight = 4, MinLevel = 8 },
	Mutated2 = { Text = "Catch {n} mutated fish", Kind = "CatchMutated", Target = 2, Weight = 5, MinLevel = 5 },
	Streak5 = { Text = "Reach a Hot Streak of x{n}", Kind = "Streak", Target = 5, Weight = 8 },
	Streak10 = { Text = "Reach a Hot Streak of x{n}", Kind = "Streak", Target = 10, Weight = 4, MinLevel = 8 },
	Sell30 = { Text = "Sell {n} fish", Kind = "SellFish", Target = 30, Weight = 8 },
	Pull3 = { Text = "Roll {n} auras", Kind = "PullAura", Target = 3, Weight = 6 },
}

return Quests
