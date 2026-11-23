--!strict
local ProfileLease = {}

function ProfileLease.Claim(profile: any, token: string, now: number, duration: number): any
	local lease = profile.ServerLease
	-- A prepared profile is frozen. A reconnect can fence its old owner and recover immediately.
	if lease and lease.Token ~= token and lease.ExpiresAt > now and not profile.PendingTrade then
		return nil
	end
	profile.ServerLease = { Token = token, ExpiresAt = now + duration }
	return profile
end

function ProfileLease.Owns(profile: any, token: string): boolean
	return profile ~= nil and profile.ServerLease ~= nil and profile.ServerLease.Token == token
end

function ProfileLease.CanWrite(profile: any, token: string, pendingTrade: string?): boolean
	return ProfileLease.Owns(profile, token) and profile.PendingTrade == pendingTrade
end

function ProfileLease.CloseTrade(current: any, token: string, id: string, snapshot: any): any
	if not ProfileLease.Owns(current, token) or (current.PendingTrade and current.PendingTrade ~= id) then
		return nil
	end
	-- Keep an acknowledged prepare or a settlement that succeeded before a lost acknowledgment.
	local data = if not current.PendingTrade and current.LastTrade ~= id then snapshot else current
	data.ServerLease = nil
	return data
end

return ProfileLease
