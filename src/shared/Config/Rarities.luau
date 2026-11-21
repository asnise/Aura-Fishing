--!strict
-- Rarity tiers. `Tier` drives how strongly Luck boosts the tier (higher tier = more luck benefit).
-- `Weight` is the base roll weight for fish of this rarity (before luck).
-- Colours follow docs/UI_STYLE.md (Cozy Lake): readable on cream panels.
-- To add a tier: add an entry with a unique Tier number. Fish reference rarities by key.

export type Rarity = {
	Name: string,
	Tier: number,
	Weight: number,
	Color: Color3,
	XP: number,
}

local Rarities: { [string]: Rarity } = {
	Common = { Name = "Common", Tier = 1, Weight = 1000, Color = Color3.fromRGB(154, 165, 177), XP = 5 },
	Uncommon = { Name = "Uncommon", Tier = 2, Weight = 400, Color = Color3.fromRGB(92, 201, 138), XP = 10 },
	Rare = { Name = "Rare", Tier = 3, Weight = 120, Color = Color3.fromRGB(90, 169, 240), XP = 25 },
	Epic = { Name = "Epic", Tier = 4, Weight = 30, Color = Color3.fromRGB(176, 124, 240), XP = 60 },
	Legendary = { Name = "Legendary", Tier = 5, Weight = 6, Color = Color3.fromRGB(242, 169, 59), XP = 150 },
	Mythic = { Name = "Mythic", Tier = 6, Weight = 1, Color = Color3.fromRGB(242, 102, 139), XP = 400 },
}

return Rarities
