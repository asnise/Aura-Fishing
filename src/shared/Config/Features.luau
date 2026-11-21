--!strict
-- Feature switches + numbers for systems that are planned but not built yet (Main Menu hub tiles).
-- Turn a feature on (Enabled = true) once its system exists; until then the hub shows Notice.
-- Numbers here are the agreed GDD values so the real systems can read them later.

export type Feature = {
	Enabled: boolean,
	Notice: string, -- shown while Enabled = false
	[string]: any,
}

local Features: { [string]: Feature } = {
	-- GDD 7.3 daily quests (TASKS C7)
	Quests = {
		Enabled = true,
		Notice = "Daily Quests are coming soon!",
		PerDay = 3,
		RewardGems = 5,
		ResetHourUTC = 0,
	},
	-- GDD 7.2 rebirth (TASKS C3). Logic: Shared/Rebirth + RebirthService.
	-- Resets Level/XP/Coins (to StartingCoins) and removes the fish in the bag (chests stay).
	-- Keeps gear (+Enhance), baits, auras (+stars), Fishdex, Mastery, Aquarium, Pearls, Gems, passes.
	-- Each rebirth: +MultiplierPerRebirth to every stat in MultiplierStats (1 rebirth = 1.25x).
	Rebirth = {
		Enabled = true,
		Notice = "Rebirth is coming soon!",
		RequiredLevel = 50, -- first rebirth
		LevelStep = 10, -- each later rebirth needs this many more levels (50, 60, 70 ...)
		MaxRequiredLevel = 100,
		MultiplierPerRebirth = 0.25,
		MultiplierStats = { "SellMultiplier", "PearlRate" },
		ResetsCoins = true,
		ResetsLevel = true,
		-- Title over the head from this many rebirths (highest reached wins)
		Titles = {
			{ Rebirths = 1, Title = "Novice Angler" },
			{ Rebirths = 2, Title = "Tide Walker" },
			{ Rebirths = 3, Title = "Abyssal Conqueror" },
			{ Rebirths = 5, Title = "Naga Whisperer" },
			{ Rebirths = 10, Title = "Fisher of Gods" },
		},
	},
	-- Events hub (Config/Events cards). The Naga boss (GDD 6, TASKS C5) is one card there.
	Events = {
		Enabled = true,
		Notice = "Events are coming soon!",
		IntervalMinutes = 30,
	},
	-- In-game settings window (Low FX already lives in the Auras window)
	Settings = {
		Enabled = true, -- C10: opens "Settings & Credits" (UI/Credits) until real settings exist
		Notice = "Settings are coming soon. Low FX is in the Auras window.",
	},
	-- Roblox friend invite prompt (works now)
	Friends = {
		Enabled = true,
		Notice = "Invites only work in a live game, not in Studio.",
	},
}

return Features
