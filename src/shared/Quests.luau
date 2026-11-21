--!strict
-- Daily quests (C7), shared by server and client. Pool: Config/Quests. Numbers: Features.Quests.
--   profile.Quests = { Day = dayKey, List = { {Id, Progress, Claimed} }, Unclaimed = bool }
--   Unclaimed = some quest is done but not claimed (Main Menu red dot).

local Registry = require(script.Parent.Registry)

local CFG = Registry.Features.Quests

export type QuestState = {
	Index: number,
	Id: string,
	Text: string,
	Progress: number,
	Target: number,
	Done: boolean,
	Claimed: boolean,
	RewardGems: number,
	Icon: string?,
}

local Quests = {}

-- Day number that changes at ResetHourUTC.
function Quests.DayKey(now: number?): number
	return math.floor(((now or os.time()) - CFG.ResetHourUTC * 3600) / 86400)
end

-- Seconds until the next reset.
function Quests.ResetsIn(now: number?): number
	local t = now or os.time()
	local nextReset = (Quests.DayKey(t) + 1) * 86400 + CFG.ResetHourUTC * 3600
	return math.max(0, nextReset - t)
end

function Quests.Reward(questId: string): number
	local q = Registry.Quests[questId]
	return (q and q.RewardGems) or CFG.RewardGems
end

function Quests.Text(questId: string): string
	local q = Registry.Quests[questId]
	if not q then
		return "?"
	end
	return (string.gsub(q.Text, "{n}", tostring(q.Target)))
end

-- What the UI shows. Empty list if today's quests were not rolled yet (server does that on join).
function Quests.State(profile: any): { QuestState }
	local out = {}
	local pq = profile.Quests
	if not pq or pq.Day ~= Quests.DayKey() then
		return out
	end
	for i, e in pq.List do
		local q = Registry.Quests[e.Id]
		if q then
			table.insert(out, {
				Index = i,
				Id = e.Id,
				Text = Quests.Text(e.Id),
				Progress = math.min(e.Progress, q.Target),
				Target = q.Target,
				Done = e.Progress >= q.Target,
				Claimed = e.Claimed == true,
				RewardGems = Quests.Reward(e.Id),
				Icon = q.Icon,
			})
		end
	end
	return out
end

return Quests
