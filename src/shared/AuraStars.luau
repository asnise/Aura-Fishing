--!strict
-- Aura star maths (C17), shared by server and client. Numbers: Config/AuraStars.
--   profile.Auras.Stars[auraId] = 0..MaxStars, profile.Auras.StarTokens = n
-- Requires only Registry (Stats requires this module).

local Registry = require(script.Parent.Registry)

local CFG = Registry.AuraStars

local AuraStars = {}

AuraStars.MaxStars = CFG.MaxStars

function AuraStars.Stars(profile: any, auraId: string): number
	local s = profile.Auras.Stars
	return (s and s[auraId]) or 0
end

function AuraStars.ScaledStats(stats: { [string]: number }, stars: number): { [string]: number }
	if stars <= 0 then
		return stats
	end
	local mult = 1 + CFG.StatPerStar * stars
	local out: { [string]: number } = {}
	for stat, v in stats do
		out[stat] = v * mult
	end
	return out
end

-- Tokens a duplicate of this aura gives.
function AuraStars.TokensFor(auraId: string): number
	local aura = Registry.Auras[auraId]
	return if aura then CFG.TokensPerDuplicate[aura.Rarity] or 1 else 0
end

-- Tokens for going from `stars` to stars + 1; nil at max.
function AuraStars.Cost(auraId: string, stars: number): number?
	local aura = Registry.Auras[auraId]
	if not aura or stars >= CFG.MaxStars then
		return nil
	end
	return CFG.StarCost[stars + 1] * (CFG.RarityCostMult[aura.Rarity] or 1)
end

return AuraStars
