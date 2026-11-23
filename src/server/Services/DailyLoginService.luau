--!strict
-- Daily Login Service (Server). Handles 7-day login calendar rewards and streaks.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Registry = require(Shared.Registry)
local Remotes = require(Shared.Remotes)
local DailyLogin = require(Shared.DailyLogin)
local BaitBinding = require(Shared.Items.BaitBinding)

local DataService = require(script.Parent.DataService)

local DailyLoginService = {}

function DailyLoginService.Claim(player: Player): (boolean, string, any?)
	local profile = DataService.Get(player)
	if not profile then
		return false, "Save data not loaded"
	end

	local state = DailyLogin.GetState(profile)
	if not state.CanClaim then
		return false, "Already claimed today", state
	end

	local dayIndex = state.CurrentDay
	local dayDef = Registry.DailyLogin.Days[dayIndex]
	if not dayDef then
		return false, "Invalid reward day", state
	end

	local reward = dayDef.Reward

	-- Grant the reward
	if reward.Kind == "Coins" then
		profile.Coins = (profile.Coins or 0) + reward.Amount
		profile.Lifetime.CoinsEarned = (profile.Lifetime.CoinsEarned or 0) + reward.Amount
	elseif reward.Kind == "Gems" then
		profile.Gems = (profile.Gems or 0) + reward.Amount
	elseif reward.Kind == "Pearls" then
		profile.Pearls = (profile.Pearls or 0) + reward.Amount
		profile.Lifetime.PearlsEarned = (profile.Lifetime.PearlsEarned or 0) + reward.Amount
	elseif reward.Kind == "Bait" then
		if reward.Id then
			BaitBinding.Add(profile, reward.Id, reward.Amount, true)
		end
	end

	-- Update login streak and progression
	local today = DailyLogin.DayKey()
	local last = profile.DailyLogin.LastClaimDay or -1
	local currentStreak = profile.DailyLogin.Streak or 0

	if last == today - 1 then
		profile.DailyLogin.Streak = currentStreak + 1
		profile.DailyLogin.Day = (dayIndex % #Registry.DailyLogin.Days) + 1
	else
		profile.DailyLogin.Streak = 1
		profile.DailyLogin.Day = (dayIndex % #Registry.DailyLogin.Days) + 1
	end
	profile.DailyLogin.LastClaimDay = today

	DataService.MarkDirty(player)

	Remotes.Event("Notify"):FireClient(
		player,
		`Claimed {dayDef.Title}: {reward.Title}!`,
		Color3.fromRGB(79, 175, 138)
	)

	local newState = DailyLogin.GetState(profile)
	return true, `Claimed {reward.Title}`, newState
end

function DailyLoginService.Init()
	Remotes.Func("ClaimDailyLogin").OnServerInvoke = function(player)
		return DailyLoginService.Claim(player)
	end
end

return DailyLoginService
