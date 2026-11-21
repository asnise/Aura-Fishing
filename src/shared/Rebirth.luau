--!strict
-- Rebirth maths (C3, GDD 7.2), shared by server and client. Config: Features.Rebirth.
--   profile.Rebirths = n
-- Stats.Collect adds Rebirth.Source(profile). Requires only Registry (Stats requires this module).

local Registry = require(script.Parent.Registry)

local CFG = Registry.Features.Rebirth

local Rebirth = {}

function Rebirth.Count(profile: any): number
	return profile.Rebirths or 0
end

-- Level needed for the next rebirth.
function Rebirth.RequiredLevel(profile: any): number
	return math.min(CFG.MaxRequiredLevel, CFG.RequiredLevel + CFG.LevelStep * Rebirth.Count(profile))
end

function Rebirth.CanRebirth(profile: any): boolean
	return CFG.Enabled and profile.Level >= Rebirth.RequiredLevel(profile)
end

-- Permanent multiplier bonus for `count` rebirths (+0.25 each).
function Rebirth.Bonus(count: number): number
	return CFG.MultiplierPerRebirth * count
end

-- Title for `count` rebirths (nil before the first one).
function Rebirth.Title(count: number): string?
	local best: string? = nil
	for _, t in CFG.Titles do
		if count >= t.Rebirths then
			best = t.Title
		end
	end
	return best
end

function Rebirth.Source(profile: any): { Stats: { [string]: number } }
	local b = Rebirth.Bonus(Rebirth.Count(profile))
	local stats: { [string]: number } = {}
	if b > 0 then
		for _, stat in CFG.MultiplierStats do
			stats[stat] = b
		end
	end
	return { Stats = stats }
end

return Rebirth
