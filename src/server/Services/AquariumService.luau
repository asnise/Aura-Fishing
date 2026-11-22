--!strict
-- Aquarium + Pearls (C14). Shared rules/maths: Shared/Aquarium.luau. Numbers: GameConfig.Aquarium.
--
-- Online : every SettleInterval seconds Pearls += Rate * dt (server). The profile snapshot is only
--          re-sent every SyncInterval; the client counts up between snapshots from Aquarium.Rate.
-- Offline: on join, Pearls for min(time since LastOnline, OfflineCapHours) are added and the client
--          gets "OfflineReward" { Seconds, Credited, Pearls, Capped, CapHours } for the popup.
-- Remotes: PutInTank(list) / TakeFromTank(uid) / BuyTankSlot() -> { ok, reason?, Aquarium = State }

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Registry = require(Shared.Registry)
local Remotes = require(Shared.Remotes)
local Stats = require(Shared.Stats)
local Inventory = require(Shared.Inventory)
local Aquarium = require(Shared.Aquarium)
local Mastery = require(Shared.Mastery)
local Boosts = require(Shared.Boosts)
local Signal = require(Shared.Util.Signal)

local DataService = require(script.Parent.DataService)

local CFG = Registry.GameConfig.Aquarium

local AquariumService = {}
AquariumService.PearlsGained = Signal.new() -- (player, amount, source "Tank" | "Offline")

local lastSettle: { [Player]: number } = {}
local clientReady: { [Player]: boolean } = {}
local pendingOffline: { [Player]: any } = {}

type Result = { ok: boolean, reason: string?, Aquarium: Aquarium.State? }

local function fail(reason: string): Result
	return { ok = false, reason = reason }
end

local function okState(data: any): Result
	return { ok = true, Aquarium = Aquarium.State(data) }
end

-- Credits Pearls earned since the last settle. Call before anything that changes the rate
-- or spends Pearls.
local function settle(player: Player)
	local data = DataService.Get(player)
	local now = os.clock()
	local last = lastSettle[player]
	lastSettle[player] = now
	if not data or not last then
		return
	end
	local gained = Aquarium.CurrentRate(data) * (now - last) / 60
	if gained > 0 then
		data.Pearls += gained
		data.Lifetime.PearlsEarned = (data.Lifetime.PearlsEarned or 0) + gained
		AquariumService.PearlsGained:Fire(player, gained, "Tank")
	end
end

local function sendOffline(player: Player)
	local info = pendingOffline[player]
	if info and clientReady[player] then
		pendingOffline[player] = nil
		Remotes.Event("OfflineReward"):FireClient(player, info)
	end
end

-- Gives Pearls for `awaySeconds` offline (join, or Dev `offline`). Returns the popup info.
function AquariumService.GrantOffline(player: Player, awaySeconds: number): any
	local data = DataService.Get(player)
	if not data then
		return nil
	end
	local pearls, credited, capped = Aquarium.OfflineReward(data, awaySeconds)
	if pearls <= 0 then
		return nil
	end
	-- 2x Pearls boost (C19) runs in real time: the credited part [left, left + credited] that it covered
	-- gets the extra multiplier.
	local left = os.time() - awaySeconds
	local boosted = Boosts.Overlap(data, "Pearls", left, left + credited)
	local boostBonus = 0
	if boosted > 0 then
		local mult = Registry.GameConfig.Boosts.Pearls.Multiplier
		boostBonus = Aquarium.Rate(data) * boosted / 60 * (mult - 1)
		pearls += boostBonus
	end
	data.Pearls += pearls
	data.Lifetime.PearlsEarned = (data.Lifetime.PearlsEarned or 0) + pearls
	DataService.MarkDirty(player)
	AquariumService.PearlsGained:Fire(player, pearls, "Offline")
	local info = {
		Seconds = awaySeconds,
		Credited = credited,
		Pearls = pearls,
		Capped = capped,
		CapHours = Stats.Compute(data).Values.OfflineCapHours,
		BoostedSeconds = boosted, -- part of Credited that had 2x Pearls
		BoostPearls = boostBonus, -- extra Pearls from that boost (already in Pearls)
	}
	pendingOffline[player] = info
	sendOffline(player)
	return info
end

-- PUT IN TANK ----------------------------------------------------------------

-- Takes one fish (Id + Mutation) out of the bag and returns it with weight, mutation, tags and value intact.
-- The least valuable matching fish goes first, so the best ones stay for selling.
local function takeOneFromBag(data: any, fishId: string, mutation: string?): any?
	local pick, pickIndex
	for i, s in data.Bag do
		if s.Kind == "Fish" and s.Id == fishId and s.Mutation == mutation and (not pick or (s.Value or 0) < (pick.Value or 0)) then
			pick, pickIndex = s, i
		end
	end
	if pick then
		table.remove(data.Bag, pickIndex)
	end
	return pick
end

local function countInBag(data: any, fishId: string, mutation: string?): number
	local n = 0
	for _, s in data.Bag do
		if s.Kind == "Fish" and s.Id == fishId and s.Mutation == mutation then
			n += 1
		end
	end
	return n
end

-- list = { {Id, Mutation, Count}, ... }. All or nothing.
local function putInTank(player: Player, list: any): Result
	local data = DataService.Get(player)
	if not data then
		return fail("Profile not loaded")
	end
	if type(list) ~= "table" or #list == 0 or #list > 50 then
		return fail("Nothing selected")
	end
	-- Validate + merge duplicates (same Id + Mutation).
	local wanted: { [string]: { Id: string, Mutation: string?, Count: number } } = {}
	local order: { string } = {}
	local total = 0
	for _, e in list do
		if type(e) ~= "table" or type(e.Id) ~= "string" or not Registry.Fish[e.Id] then
			return fail("Unknown fish")
		end
		local mut = e.Mutation
		if mut ~= nil and (type(mut) ~= "string" or not Registry.Mutations[mut]) then
			return fail("Unknown mutation")
		end
		local count = e.Count
		if type(count) ~= "number" or count ~= count or count < 1 or count % 1 ~= 0 then
			return fail("Bad amount")
		end
		local key = e.Id .. "|" .. (mut or "")
		if not wanted[key] then
			wanted[key] = { Id = e.Id, Mutation = mut, Count = 0 }
			table.insert(order, key)
		end
		wanted[key].Count += count
		total += count
	end
	if total > Aquarium.Free(data) then
		return fail(`Not enough tank slots ({Aquarium.Free(data)} free)`)
	end
	for _, key in order do
		local w = wanted[key]
		if countInBag(data, w.Id, w.Mutation) < w.Count then
			return fail(`Not enough {Registry.Fish[w.Id].Name} in your bag`)
		end
	end

	settle(player)
	for _, key in order do
		local w = wanted[key]
		for _ = 1, w.Count do
			local fish = takeOneFromBag(data, w.Id, w.Mutation)
			if fish then
				fish.New = nil
				table.insert(data.Aquarium.Fish, fish)
			end
		end
	end
	DataService.MarkDirty(player)
	return okState(data)
end

local function takeFromTank(player: Player, uid: any): Result
	local data = DataService.Get(player)
	if not data then
		return fail("Profile not loaded")
	end
	local index
	for i, f in data.Aquarium.Fish do
		if f.UUID == uid then
			index = i
			break
		end
	end
	if not index then
		return fail("That fish is not in your tank")
	end
	local f = data.Aquarium.Fish[index]
	if Inventory.IsFull(data) then
		return fail("Your bag is full")
	end
	settle(player)
	table.remove(data.Aquarium.Fish, index)
	Inventory.Add(data, f)
	DataService.MarkDirty(player)
	return okState(data)
end

local function buyTankSlot(player: Player): Result
	local data = DataService.Get(player)
	if not data then
		return fail("Profile not loaded")
	end
	local price = Aquarium.NextSlotPrice(data)
	if not price then
		return fail("Your tank is already at max size")
	end
	if data.Coins < price then
		return fail(`Need {price} coins`)
	end
	data.Coins -= price
	data.Aquarium.Slots += 1
	DataService.MarkDirty(player)
	return okState(data)
end

-- MASTERY (C15) — Pearls are spent here, so it lives next to the Pearl ticker ------------------

local function upgradeMastery(player: Player, trackId: any): any
	local data = DataService.Get(player)
	if not data then
		return { ok = false, reason = "Profile not loaded" }
	end
	if type(trackId) ~= "string" or not Registry.Mastery.Tracks[trackId] then
		return { ok = false, reason = "Unknown upgrade" }
	end
	settle(player)
	local level = Mastery.Level(data, trackId)
	local price = Mastery.Price(trackId, level)
	if not price then
		return { ok = false, reason = "Already at max level", Tracks = Mastery.Tracks(data), Pearls = data.Pearls }
	end
	if data.Pearls < price then
		return { ok = false, reason = `Need {price} Pearls`, Tracks = Mastery.Tracks(data), Pearls = data.Pearls }
	end
	data.Pearls -= price
	data.Mastery[trackId] = level + 1
	DataService.MarkDirty(player)
	return { ok = true, Tracks = Mastery.Tracks(data), Pearls = data.Pearls }
end

AquariumService.Settle = settle

-- INIT ---------------------------------------------------------------------

local function onProfileLoaded(player: Player, data: any)
	-- Read LastOnline before anything saves (save() overwrites it with now).
	local last = data.LastOnline or 0
	lastSettle[player] = os.clock()
	if last > 0 then
		local away = os.time() - last
		if away >= CFG.MinOfflineSeconds then
			AquariumService.GrantOffline(player, away)
		end
	end
end

function AquariumService.Init()
	Remotes.Func("PutInTank").OnServerInvoke = putInTank
	Remotes.Func("TakeFromTank").OnServerInvoke = takeFromTank
	Remotes.Func("BuyTankSlot").OnServerInvoke = buyTankSlot
	Remotes.Func("UpgradeMastery").OnServerInvoke = upgradeMastery

	Remotes.Event("ClientReady").OnServerEvent:Connect(function(player)
		clientReady[player] = true
		sendOffline(player)
	end)

	DataService.ProfileLoaded:Connect(onProfileLoaded)
	for _, player in Players:GetPlayers() do
		local data = DataService.Get(player)
		if data and not lastSettle[player] then
			onProfileLoaded(player, data)
		end
	end

	Players.PlayerRemoving:Connect(function(player)
		settle(player)
		lastSettle[player] = nil
		clientReady[player] = nil
		pendingOffline[player] = nil
	end)

	task.spawn(function()
		local sinceSync = 0
		while true do
			task.wait(CFG.SettleInterval)
			sinceSync += CFG.SettleInterval
			local sync = sinceSync >= CFG.SyncInterval
			if sync then
				sinceSync = 0
			end
			for player in lastSettle do
				settle(player)
				if sync then
					local data = DataService.Get(player)
					if data and #data.Aquarium.Fish > 0 then
						DataService.MarkDirty(player)
					end
				end
			end
		end
	end)
end

return AquariumService
