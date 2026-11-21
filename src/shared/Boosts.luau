--!strict
-- Timed boosts (C19), shared by server and client. Config: GameConfig.Boosts.
--   profile.Boosts[id] = os.time() when the boost ends (missing / past = off)

local Registry = require(script.Parent.Registry)

local CFG = Registry.GameConfig.Boosts

local Boosts = {}

-- Seconds left (0 = off).
function Boosts.Remaining(profile: any, id: string, now: number?): number
	local ends = profile.Boosts and profile.Boosts[id]
	if type(ends) ~= "number" then
		return 0
	end
	return math.max(0, ends - (now or os.time()))
end

function Boosts.Active(profile: any, id: string, now: number?): boolean
	return Boosts.Remaining(profile, id, now) > 0
end

-- Multiplier now (1 when off).
function Boosts.Multiplier(profile: any, id: string, now: number?): number
	local def = CFG[id]
	return if def and Boosts.Active(profile, id, now) then def.Multiplier else 1
end

-- Seconds of [from, to] during which the boost was on.
function Boosts.Overlap(profile: any, id: string, from: number, to: number): number
	local ends = profile.Boosts and profile.Boosts[id]
	if type(ends) ~= "number" then
		return 0
	end
	return math.clamp(math.min(ends, to) - from, 0, math.max(0, to - from))
end

-- Adds `seconds` on top of what is left (or from now). Returns the new end time.
function Boosts.Add(profile: any, id: string, seconds: number, now: number?): number
	local t = now or os.time()
	profile.Boosts = profile.Boosts or {}
	local ends = math.max(t, profile.Boosts[id] or 0) + seconds
	profile.Boosts[id] = ends
	return ends
end

return Boosts
