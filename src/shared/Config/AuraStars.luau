--!strict
-- Aura stars (C17). A duplicate aura becomes Star Tokens (one shared token wallet:
-- profile.Auras.StarTokens). Spend tokens to raise an owned aura Star 0 -> Star MaxStars.
-- Each star multiplies that aura's Stats by (1 + StatPerStar * stars). Mutation bonuses are not scaled.
-- Cost of the next star = StarCost[next star] * RarityCostMult[aura rarity].

local AuraStars = {
	MaxStars = 5,
	StatPerStar = 0.2,
	-- tokens for one duplicate, by aura rarity
	TokensPerDuplicate = { Common = 1, Uncommon = 2, Rare = 4, Epic = 10, Legendary = 25, Mythic = 60 } :: { [string]: number },
	-- base tokens for Star 1 .. Star 5
	StarCost = { 2, 4, 8, 15, 30 },
	RarityCostMult = { Common = 1, Uncommon = 2, Rare = 4, Epic = 10, Legendary = 30, Mythic = 80 } :: { [string]: number },
}

return AuraStars
