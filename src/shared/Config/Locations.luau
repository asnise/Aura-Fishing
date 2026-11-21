--!strict
-- Fishing locations. In the world, a location is one or more Parts tagged "FishingZone"
-- with attribute LocationId = <key>. Fish may restrict themselves with `Locations = {...}`.
-- To add an island/lake: build it, drop a FishingZone part over its water, add an entry here.

export type Location = {
	Name: string,
	MaxDepth: number, -- physical depth of this water; caps the depth slider
	LuckBonus: number?,
}

local Locations: { [string]: Location } = {
	StarterBay = { Name = "Starter Bay", MaxDepth = 1000 }, -- 2026-11-18: 300 -> 1000 for Abyss Line (600m) / Star Line (1000m)
}

return Locations
