--!strict
-- Daily quests (C7). Pool: Config/Quests. Numbers: Features.Quests. Shared maths/UI: Shared/Quests.
-- On join (and when the day changes while online) the player gets PerDay quests picked by Weight.
-- Progress comes from service signals: FishingService.FishCaught, ShopService.FishSold,
-- AuraService.Pulled. Rewards are claimed with ClaimQuest(index).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Registry = require(Shared.Registry)
local Remotes = require(Shared.Remotes)
local Quests = require(Shared.Quests)
local Signal = require(Shared.Util.Signal)

local DataService = require(script.Parent.DataService)
local FishingService = require(script.Parent.FishingService)
local ShopService = require(script.Parent.ShopService)
local AuraService = require(script.Parent.AuraService)

local CFG = Registry.Features.Quests

local QuestService = {}
QuestService.Completed = Signal.new() -- (player, questId)

local rng = Random.new()

local function refreshUnclaimed(data: any)
	local any = false
	for _, e in data.Quests.List do
		local q = Registry.Quests[e.Id]
		if q and not e.Claimed and e.Progress >= q.Target then
			any = true
		end
	end
	data.Quests.Unclaimed = any
end

-- Picks today's quests (weighted, no repeats, level-gated).
local function roll(data: any): { any }
	local pool: { string } = {}
	for id, q in Registry.Quests do
		if (q.MinLevel or 1) <= data.Level then
			table.insert(pool, id)
		end
	end
	table.sort(pool) -- stable order before weighted picks
	local list = {}
	for _ = 1, math.min(CFG.PerDay, #pool) do
		local total = 0
		for _, id in pool do
			total += Registry.Quests[id].Weight
		end
		local pick = rng:NextNumber() * total
		for i, id in pool do
			pick -= Registry.Quests[id].Weight
			if pick <= 0 or i == #pool then
				table.insert(list, { Id = id, Progress = 0, Claimed = false })
				table.remove(pool, i)
				break
			end
		end
	end
	return list
end

-- New day -> new quests. Returns true if it rolled.
local function ensureDay(player: Player, data: any): boolean
	local today = Quests.DayKey()
	if data.Quests.Day == today then
		return false
	end
	data.Quests.Day = today
	data.Quests.List = roll(data)
	data.Quests.Unclaimed = false
	DataService.MarkDirty(player)
	return true
end

-- Adds progress to every unclaimed quest of `kind` that `match` accepts.
-- mode "add" = +amount, "max" = progress = max(progress, amount) (Streak).
local function progress(player: Player, kind: string, amount: number, match: ((any) -> boolean)?, mode: string?)
	local data = DataService.Get(player)
	if not data or amount <= 0 then
		return
	end
	ensureDay(player, data)
	local changed = false
	for _, e in data.Quests.List do
		local q = Registry.Quests[e.Id]
		if q and q.Kind == kind and not e.Claimed and e.Progress < q.Target and (match == nil or match(q)) then
			local before = e.Progress
			e.Progress = if mode == "max" then math.max(e.Progress, amount) else e.Progress + amount
			e.Progress = math.min(e.Progress, q.Target)
			if e.Progress ~= before then
				changed = true
				if e.Progress >= q.Target then
					QuestService.Completed:Fire(player, e.Id)
					Remotes.Event("Notify"):FireClient(player, `Quest done: {Quests.Text(e.Id)} — claim your reward!`, Color3.fromRGB(79, 175, 138))
				end
			end
		end
	end
	if changed then
		refreshUnclaimed(data)
		DataService.MarkDirty(player)
	end
end

function QuestService.Add(player: Player, kind: string, amount: number)
	progress(player, kind, amount)
end

function QuestService.Claim(player: Player, index: any): (boolean, string, any)
	local data = DataService.Get(player)
	if not data then
		return false, "Invalid request", nil
	end
	ensureDay(player, data)
	local e = if type(index) == "number" then data.Quests.List[index] else nil
	local q = e and Registry.Quests[e.Id]
	if not e or not q then
		return false, "Unknown quest", Quests.State(data)
	end
	if e.Claimed then
		return false, "Already claimed", Quests.State(data)
	end
	if e.Progress < q.Target then
		return false, "Not finished yet", Quests.State(data)
	end
	e.Claimed = true
	local gems = Quests.Reward(e.Id)
	data.Gems += gems
	refreshUnclaimed(data)
	DataService.MarkDirty(player)
	return true, `+{gems} Gems`, Quests.State(data)
end

-- Dev: reroll today's quests / fill progress.
function QuestService.Reroll(player: Player)
	local data = DataService.Get(player)
	if data then
		data.Quests.Day = -1
		ensureDay(player, data)
	end
end

function QuestService.Init()
	Remotes.Func("ClaimQuest").OnServerInvoke = QuestService.Claim

	FishingService.FishCaught:Connect(function(player: Player, entry: any, mode: string, streak: number?)
		progress(player, "Catch", 1)
		if mode == "Manual" then
			progress(player, "CatchManual", 1)
		end
		local fish = Registry.Fish[entry.Fish]
		local tier = fish and Registry.Rarities[fish.Rarity].Tier or 0
		progress(player, "CatchRarity", 1, function(q)
			return tier >= Registry.Rarities[q.Rarity].Tier
		end)
		if entry.Mutation then
			progress(player, "CatchMutated", 1)
		end
		if streak and streak > 0 then
			progress(player, "Streak", streak, nil, "max")
		end
	end)
	ShopService.FishSold:Connect(function(player: Player, count: number)
		progress(player, "SellFish", count)
	end)
	AuraService.Pulled:Connect(function(player: Player, _, results: { any })
		progress(player, "PullAura", #results)
	end)

	DataService.ProfileLoaded:Connect(function(player, data)
		ensureDay(player, data)
	end)
	for _, player in Players:GetPlayers() do
		local data = DataService.Get(player)
		if data then
			ensureDay(player, data)
		end
	end

	-- Day change while online.
	task.spawn(function()
		while true do
			task.wait(60)
			for _, player in Players:GetPlayers() do
				local data = DataService.Get(player)
				if data then
					ensureDay(player, data)
				end
			end
		end
	end)
end

return QuestService
