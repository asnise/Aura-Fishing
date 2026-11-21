--!strict
-- Tide events (C5, replaces the co-op tug-of-war boss): every Features.Events.IntervalMinutes
-- (UTC :00 / :30) a glowing patch of water appears at a random spot in the sea for Duration seconds.
-- Fishing with the bobber INSIDE the patch (manual or Auto):
--   + LuckBonus luck
--   + each Catches entry: Chance to catch that fish instead (any depth), x crowd bonus
-- Crowd bonus: Chance x (1 + CrowdBonusPerPlayer x other players fishing in the patch), capped at
-- 1 + CrowdBonusMax -> the whole server wants to fish at the same spot.
-- Spot: random water inside a FishingZone of Location, MinDistance..MaxDistance studs (flat) from the
-- map's SpawnLocation, not under the boardwalk.

export type SpecialCatch = { Fish: string, Chance: number }
export type TideEvent = {
	Name: string,
	Location: string, -- Config/Locations id
	Duration: number,
	Radius: number,
	MinDistance: number,
	MaxDistance: number,
	LuckBonus: number,
	Catches: { SpecialCatch },
	CrowdBonusPerPlayer: number,
	CrowdBonusMax: number,
	Color: Color3,
}

local TideEvents: { OffsetSeconds: number, WarnSeconds: number, Rotation: { string }, Events: { [string]: TideEvent } } = {
	OffsetSeconds = 0, -- seconds after each :00 / :30
	WarnSeconds = 60, -- "The Naga stirs..." message before it starts
	Rotation = { "NagaTide" }, -- event n uses Rotation[(n % #Rotation) + 1]
	Events = {
		NagaTide = {
			Name = "Naga Tide",
			Location = "StarterBay",
			Duration = 300,
			Radius = 40,
			MinDistance = 45,
			MaxDistance = 220,
			LuckBonus = 0.5,
			-- ~25 catches in 5 min: solo ≈ 10% to see a Naga per event, a full crowd ≈ 20%
			Catches = {
				{ Fish = "NagaHatchling", Chance = 0.004 },
				{ Fish = "CoralSeahorse", Chance = 0.015 },
			},
			CrowdBonusPerPlayer = 0.25,
			CrowdBonusMax = 1.0,
			Color = Color3.fromRGB(60, 196, 140),
		},
	},
}

return TideEvents
