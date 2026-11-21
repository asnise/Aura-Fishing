--!strict
-- Shared helpers for Daily Login (7-day calendar).

local Registry = require(script.Parent.Registry)

local CFG = Registry.DailyLogin

export type DailyLoginState = {
	CurrentDay: number, -- 1..7
	CanClaim: boolean,
	Streak: number,
	ResetsIn: number,
	LastClaimDay: number,
}

local DailyLogin = {}

function DailyLogin.DayKey(now: number?): number
	return math.floor(((now or os.time()) - CFG.ResetHourUTC * 3600) / 86400)
end

function DailyLogin.ResetsIn(now: number?): number
	local t = now or os.time()
	local nextReset = (DailyLogin.DayKey(t) + 1) * 86400 + CFG.ResetHourUTC * 3600
	return math.max(0, nextReset - t)
end

function DailyLogin.GetState(profile: any): DailyLoginState
	local data = profile and profile.DailyLogin or { Streak = 0, LastClaimDay = -1, Day = 1 }
	local today = DailyLogin.DayKey()
	local last = data.LastClaimDay or -1
	local day = data.Day or 1
	if day < 1 or day > #CFG.Days then
		day = 1
	end

	local canClaim = false
	if last == -1 then
		canClaim = true
	elseif last == today then
		canClaim = false
	elseif last == today - 1 then
		canClaim = true
	else
		-- Missed at least one full day: resets streak and resets back to Day 1
		canClaim = true
		day = 1
	end

	return {
		CurrentDay = day,
		CanClaim = canClaim,
		Streak = data.Streak or 0,
		ResetsIn = DailyLogin.ResetsIn(),
		LastClaimDay = last,
	}
end

return DailyLogin
