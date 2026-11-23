--!strict
-- Player save data: load, reconcile with template, autosave, save on leave / shutdown,
-- and replicate a snapshot to the owning client.
--
-- Other services mutate `DataService.Get(player)` directly, then call
-- `DataService.MarkDirty(player)` so the client gets a fresh snapshot.
--
-- Adding a new saved field: add it to TEMPLATE. Existing saves get it automatically (Reconcile).

local DataStoreService = game:GetService("DataStoreService")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Registry = require(Shared.Registry)
local Inventory = require(Shared.Inventory)
local BaitBinding = require(Shared.Items.BaitBinding)
local Remotes = require(Shared.Remotes)
local Signal = require(Shared.Util.Signal)
local ProfileLease = require(script.Parent.ProfileLease)
local TradeJournal = require(script.Parent.TradeJournal)

local GameConfig = Registry.GameConfig

local DataService = {}
DataService.ProfileLoaded = Signal.new() -- (player, profile)

local SCHEMA_VERSION = 7 -- 7: bound bait counts; 6: UUID items; 5: retrospective skill points.

local function buildTemplate()
	-- Rods and Lines are bag items (granted per profile by ensureGear: every item needs its own UUID).
	local owned = {}
	local equipped = {}
	local consumables = {}
	for catId, cat in Registry.Equipment do
		if cat.Kind == "Permanent" then
			if not Inventory.IsGearCategory(catId) then
				local starter = Registry.StarterItem(catId)
				owned[catId] = {}
				if starter then
					owned[catId][starter] = true
					equipped[catId] = starter
				end
			end
		else
			consumables[catId] = {}
		end
	end
	return {
		Version = SCHEMA_VERSION,
		Coins = GameConfig.StartingCoins,
		Gems = GameConfig.StartingGems,
		Level = 1,
		XP = 0,
		Skills = { Points = 0, Levels = {} }, -- C4: permanent; +PointsPerLevel on every level-up (Shared/Skills)
		Rebirths = 0, -- C3: permanent multiplier + title (Features.Rebirth, Shared/Rebirth)
		Owned = owned,
		Equipped = equipped,
		Consumables = consumables,
		BoundBaits = {}, -- bound portion of each Consumables.Baits stack
		Auras = { Owned = {}, Equipped = nil, TotalRolls = 0, Stars = {}, StarTokens = 0 }, -- Owned[id] = 1 (dupes -> StarTokens)
		Gacha = { Pity = {}, PityHard = {}, Pulls = {}, Claimed = {} }, -- per banner id (Config/AuraBanners)
		Bag = {}, -- Items (shared/Items/ItemContainer): fish, spare + worn rods/lines, chests
		Fishdex = {},
		Settings = { LowFX = false, TargetDepth = 10, AutoDepth = false, MusicVolume = Registry.Sounds.Buses.Music.Default, SFXVolume = Registry.Sounds.Buses.SFX.Default },
		Lifetime = { Caught = 0, CoinsEarned = 0, PearlsEarned = 0 },
		NextUid = 1,
		Pearls = 0, -- Aquarium currency (float; UI floors it)
		Boosts = {}, -- [boostId] = os.time() it ends (GameConfig.Boosts, Shared/Boosts)
		Quests = { Day = -1, List = {}, Unclaimed = false }, -- daily quests (QuestService, Shared/Quests)
		DailyLogin = { Streak = 0, LastClaimDay = -1, Day = 1 }, -- 7-day daily login calendar
		Mastery = {}, -- [trackId] = level (Config/Mastery); kept through Rebirth
		Aquarium = { Slots = GameConfig.Aquarium.StartSlots, Fish = {} }, -- Fish = bag fish items (same record, UUID kept)
		LastOnline = 0, -- os.time() at the last save (offline Pearls on next join); 0 = never
		-- Robux (MonetizationService): Passes[id] = "Owned" (Roblox says so) | "Dev" (granted by a dev command)
		Passes = {},
		Purchases = { Receipts = {}, Once = {}, Count = {} }, -- Receipts = recent PurchaseIds (dedupe)
	}
end

local TEMPLATE = buildTemplate()

local function deepCopy(t: any): any
	if type(t) ~= "table" then
		return t
	end
	local c = {}
	for k, v in t do
		c[k] = deepCopy(v)
	end
	return c
end

-- Fill missing keys from template (recursively), never overwriting existing data.
local function reconcile(data: any, template: any)
	for k, v in template do
		if data[k] == nil then
			data[k] = deepCopy(v)
		elseif type(v) == "table" and type(data[k]) == "table" then
			reconcile(data[k], v)
		end
	end
end

-- Content can be removed from config later; drop references to things that no longer exist.
-- Renamed content ids (old -> new). Applied to Fishdex keys and bag entries on load.
local RENAMED_FISH = {
	SunScaleSardine = "SunscaleSardine", -- 2026-11-17: id now matches its art key fish/SunscaleSardine
}

-- Every profile wears one rod and one line (bag items with their own UUID). Starter ones are created
-- per profile because the template is shared by every new player.
local function ensureGear(data: any)
	for _, catId in { "Rods", "Lines" } do
		if not Inventory.Worn(data, catId) then
			local starter = Registry.StarterItem(catId)
			if starter then
				local item = Inventory.NewGear(catId, starter)
				table.insert(data.Bag, item)
				data.Equipped[catId] = item.UUID
			end
		end
	end
end

-- Item rework (schema 6): the old stack bag, owned/equipped ids and tank fish cannot be converted
-- (fish lost their per-fish data in stacks). Coins, Gems, Pearls, levels, skills, rebirths, Fishdex and
-- Game Passes stay. Gifts that cost Robux (Exclusive gear) are given back as Bound items.
local function resetItemsV6(data: any)
	local regrant = {}
	for _, catId in { "Rods", "Lines" } do
		for itemId in (data.Owned and data.Owned[catId]) or {} do
			local def = Registry.Equipment[catId].Items[itemId]
			if def and def.Exclusive then
				table.insert(regrant, { catId, itemId })
			end
		end
	end
	local baitEquipped = data.Equipped and data.Equipped.Baits
	data.Bag = {}
	data.Owned = deepCopy(TEMPLATE.Owned)
	data.Equipped = deepCopy(TEMPLATE.Equipped)
	if baitEquipped and Registry.Equipment.Baits.Items[baitEquipped] then
		data.Equipped.Baits = baitEquipped
	end
	data.Enhance = nil
	data.Aquarium.Fish = {}
	ensureGear(data)
	for _, g in regrant do
		table.insert(data.Bag, Inventory.NewGear(g[1], g[2]))
	end
end

local function sanitize(data: any)
	for old, new in RENAMED_FISH do
		if data.Fishdex[old] then
			local a, b = data.Fishdex[old], data.Fishdex[new]
			data.Fishdex[new] = if b then { Count = a.Count + b.Count, Best = math.max(a.Best, b.Best) } else a
			data.Fishdex[old] = nil
		end
		for _, e in data.Bag do
			if e.Id == old then
				e.Id = new
			end
		end
		for _, e in data.Aquarium.Fish do
			if e.Id == old then
				e.Id = new
			end
		end
	end
	if (data.Version or 1) < 3 then
		-- Balance Pass 1: every coin value/price is x10. Scale what the player already has, once.
		data.Coins = math.floor((data.Coins or 0) * 10)
		data.Lifetime.CoinsEarned = math.floor((data.Lifetime.CoinsEarned or 0) * 10)
		data.Version = 3
	end
	if data.Version < 4 then
		-- C17: extra copies of an aura become Star Tokens (once); Owned is just "have it" (1).
		for id, n in data.Auras.Owned do
			local aura = Registry.Auras[id]
			if aura and type(n) == "number" and n > 1 then
				data.Auras.StarTokens += (n - 1) * (Registry.AuraStars.TokensPerDuplicate[aura.Rarity] or 1)
				data.Auras.Owned[id] = 1
			end
		end
		-- Old single pity counted towards Mythic: keep it for the new Mythic counter, start Legendary from it too.
		for bannerId, n in data.Gacha.Pity do
			local b = Registry.AuraBanners[bannerId]
			if type(n) == "number" and b then
				data.Gacha.PityHard[bannerId] = n
				data.Gacha.Pity[bannerId] = math.min(n, b.PityPulls - 1)
			end
		end
		data.Version = 4
	end
	if data.Version < 5 then
		-- C4: skills arrived after these levels were earned - grant their points once.
		data.Skills.Points += math.max(0, (data.Level or 1) - 1) * Registry.Skills.PointsPerLevel
		data.Version = 5
	end
	if data.Version < 6 then
		resetItemsV6(data)
		data.Version = 6
	end
	if data.Version < 7 then
		BaitBinding.Migrate(data)
		-- Existing fishing and milestone chests could have merged into the same stack.
		for _, item in data.Bag do
			if item.Kind == "Treasure" and not Inventory.IsBound(item) then
				item.Bound = "Bound"
			end
		end
		data.Version = 7
	end
	if data.Auras.Equipped and not Registry.Auras[data.Auras.Equipped] then
		data.Auras.Equipped = nil
	end
	for id in data.Skills.Levels do
		if not Registry.Skills.List[id] then
			data.Skills.Levels[id] = nil
		end
	end
	for id in data.Mastery do
		if not Registry.Mastery.Tracks[id] then
			data.Mastery[id] = nil
		end
	end

	-- Bag items: keep only ones whose content still exists; fix up fields a hand edit could break.
	local seen: { [string]: boolean } = {}
	local function validFish(f: any): boolean
		return type(f) == "table" and Registry.Fish[f.Id] ~= nil and (f.Mutation == nil or Registry.Mutations[f.Mutation] ~= nil)
	end
	local function claimUUID(item: any)
		if type(item.UUID) ~= "string" or seen[item.UUID] then
			item.UUID = Inventory.NewUUID()
		end
		seen[item.UUID] = true
	end
	local tank = {}
	for _, f in data.Aquarium.Fish do
		if validFish(f) and f.Kind == "Fish" then
			claimUUID(f)
			table.insert(tank, f)
		end
	end
	data.Aquarium.Fish = tank
	local bag = {}
	for _, s in data.Bag do
		local known = false
		if s.Kind == "Fish" then
			known = validFish(s)
		elseif s.Kind == "Treasure" then
			known = Registry.Treasures[s.Id] ~= nil and (s.Count or 0) > 0
		elseif s.Kind == "Rod" or s.Kind == "Line" then
			local cat = Inventory.GearCategory(s.Kind)
			known = cat ~= nil and Registry.Equipment[cat].Items[s.Id] ~= nil
			if known then
				s.Enhance = math.clamp(math.floor(s.Enhance or 0), 0, Registry.GameConfig.Enhance.MaxLevel)
			end
		end
		if known then
			claimUUID(s)
			table.insert(bag, s)
		end
	end
	data.Bag = bag
	for catId, cat in Registry.Equipment do
		if not Inventory.IsGearCategory(catId) and data.Equipped[catId] and not cat.Items[data.Equipped[catId]] then
			data.Equipped[catId] = Registry.StarterItem(catId)
		end
	end
	ensureGear(data)
	if data.Equipped.Baits then
		BaitBinding.Bind(data, data.Equipped.Baits)
	end
end

local function getStore(name: string): DataStore?
	local ok, store = pcall(function()
		return DataStoreService:GetDataStore(name)
	end)
	if not ok then
		warn("[DataService] DataStore unavailable:", store)
		return nil
	end
	return store
end

local store = getStore(GameConfig.DataStoreName)
local journalStore = getStore(GameConfig.DataStoreName .. "_Trade_v1")
local inStudio = RunService:IsStudio()
local studioMemory = false
local realStorageUsed = false
local probingStudioStorage = false
local memoryProfiles: { [string]: any } = {}
local memoryJournal: { [string]: any } = {}
local closing = false

local SAVE_INTERVAL = math.min(GameConfig.AutosaveInterval, 45)
local LEASE_DURATION = SAVE_INTERVAL * 3
local MAX_TRADE_PROFILE_BYTES = 4_000_000 -- Leave room below the DataStore value limit.
type Session = {
	Token: string,
	Data: any,
	Dirty: boolean,
	Trade: string?,
	Writes: number,
	Saving: boolean,
	Leaving: boolean,
}
local sessions: { [Player]: Session } = {}

local function key(player: Player): string
	return "Player_" .. player.UserId
end

local function update(dataStore: DataStore?, memory: { [string]: any }, id: string, transform: (any) -> any): (boolean, any)
	if studioMemory then
		local ok, value = pcall(transform, deepCopy(memory[id]))
		if not ok then
			warn(`[DataService] In-memory update failed for {id}: {value}`)
			return false, nil
		end
		if value ~= nil then
			memory[id] = deepCopy(value)
		end
		return true, deepCopy(value)
	end
	if not dataStore then
		return false, nil
	end
	for attempt = 1, 3 do
		local ok, result = pcall(function()
			return dataStore:UpdateAsync(id, transform)
		end)
		if ok then
			realStorageUsed = true
			return true, result
		end
		warn(`[DataService] UpdateAsync failed for {id}: {result}`)
		if inStudio and not realStorageUsed and dataStore == store then
			break
		end
		if attempt < 3 then
			task.wait(attempt)
		end
	end
	return false, nil
end

function DataService.UpdateTradeJournal(id: string, transform: (any) -> any): (boolean, any)
	return update(journalStore, memoryJournal, id, transform)
end

local function updateProfile(player: Player, transform: (any) -> any): (boolean, any)
	return update(store, memoryProfiles, key(player), transform)
end

local function releaseLease(player: Player, token: string)
	updateProfile(player, function(current)
		if ProfileLease.Owns(current, token) then
			current.ServerLease = nil
			return current
		end
		return nil
	end)
end

local function renew(data: any, token: string): any
	data.ServerLease = { Token = token, ExpiresAt = os.time() + LEASE_DURATION }
	return data
end

local function currentData(data: any): any
	data.ServerLease = nil
	return data
end

local function save(player: Player, release: boolean?): boolean
	local session = sessions[player]
	if not session or session.Trade or (session.Leaving and not release) then
		return false
	end
	session.Writes += 1
	while session.Saving do
		task.wait()
	end
	session.Saving = true
	session.Data.LastOnline = os.time()
	local snapshot = deepCopy(session.Data)
	local ok, saved = updateProfile(player, function(current)
		if not ProfileLease.CanWrite(current, session.Token, nil) then
			return nil
		end
		if release then
			return snapshot
		end
		return renew(snapshot, session.Token)
	end)
	session.Saving = false
	session.Writes -= 1
	if ok and not saved and not session.Leaving then
		session.Leaving = true
		sessions[player] = nil
		player:Kick("Your save is active on another server. Please rejoin.")
	end
	return ok and saved ~= nil
end

local function releaseSession(player: Player)
	save(player, true)
	sessions[player] = nil
end

function DataService.Get(player: Player): any
	local session = sessions[player]
	return if session and not session.Trade and not session.Leaving then session.Data else nil
end

function DataService.WaitFor(player: Player): any
	while player.Parent and not DataService.Get(player) do
		task.wait()
	end
	return DataService.Get(player)
end

-- Saves right away (yields). true = the save is stored. Used before confirming a Robux receipt.
function DataService.SaveNow(player: Player): boolean
	return save(player)
end

function DataService.MarkDirty(player: Player)
	local session = sessions[player]
	if session then
		session.Dirty = true
	end
end

function DataService.TradeAvailable(): boolean
	return not closing and (studioMemory or (store ~= nil and journalStore ~= nil))
end

function DataService.LockTrade(first: Player, second: Player, record: TradeJournal.Record): (boolean, string?)
	local a, b = sessions[first], sessions[second]
	if not DataService.TradeAvailable() or not a or not b
		or a.Trade or a.Leaving or a.Writes > 0 or b.Trade or b.Leaving or b.Writes > 0
	then
		return false, "A save is in progress. Confirm again in a moment."
	end
	local committed = table.clone(record)
	committed.Status = "Committed"
	for i, session in { a, b } do
		local projected = deepCopy(session.Data)
		projected.PendingTrade = record.Id
		TradeJournal.Settle(projected, record.Offers[i].UserId, committed)
		renew(projected, session.Token)
		local ok, encoded = pcall(HttpService.JSONEncode, HttpService, projected)
		if not ok or #encoded > MAX_TRADE_PROFILE_BYTES then
			return false, "The resulting inventory exceeds the save limit."
		end
	end
	a.Trade = record.Id
	b.Trade = record.Id
	return true
end

function DataService.PrepareTrade(player: Player, id: string): boolean
	local session = sessions[player]
	if not session or session.Trade ~= id or session.Leaving then
		return false
	end
	local snapshot = deepCopy(session.Data)
	snapshot.PendingTrade = id
	snapshot.LastOnline = os.time()
	local ok, saved = updateProfile(player, function(current)
		if not ProfileLease.CanWrite(current, session.Token, nil) and not ProfileLease.CanWrite(current, session.Token, id) then
			return nil
		end
		return renew(snapshot, session.Token)
	end)
	return ok and saved ~= nil
end

local function settle(player: Player, token: string, record: TradeJournal.Record, abortedSnapshot: any?): (boolean, any)
	return updateProfile(player, function(current)
		if not ProfileLease.Owns(current, token) or (current.PendingTrade and current.PendingTrade ~= record.Id) then
			return nil
		end
		if record.Status == "Committed" and not current.PendingTrade and current.LastTrade ~= record.Id then
			return nil
		end
		-- In a live session, an abort also keeps progress that preceded a failed prepare.
		local data = if record.Status == "Aborted" and abortedSnapshot then abortedSnapshot else current
		if record.Status == "Aborted" then
			data.PendingTrade = record.Id
		end
		return renew(TradeJournal.Settle(data, player.UserId, record), token)
	end)
end

local function closeOfflineTrade(player: Player, session: Session, id: string)
	local snapshot = deepCopy(session.Data)
	snapshot.LastOnline = os.time()
	updateProfile(player, function(current)
		return ProfileLease.CloseTrade(current, session.Token, id, snapshot)
	end)
	sessions[player] = nil
end

function DataService.FinishTrade(player: Player, id: string, record: TradeJournal.Record?): boolean
	local session = sessions[player]
	if not session or session.Trade ~= id or session.Leaving then
		return true
	end
	if record then
		local ok, saved = settle(player, session.Token, record, deepCopy(session.Data))
		if session.Leaving then
			return true
		end
		if not ok then
			return false
		end
		if not saved then
			sessions[player] = nil
			if player.Parent then
				player:Kick("Your trade will be recovered on rejoin.")
			end
			return true
		end
		session.Data = currentData(saved)
	end
	session.Trade = nil
	session.Dirty = true
	return true
end

-- Dev tool (DevService "!reset"): replace the profile with a fresh template. Saved on the next autosave.
function DataService.Reset(player: Player)
	local session = sessions[player]
	if session and DataService.Get(player) and session.Writes == 0 then
		local fresh = deepCopy(TEMPLATE)
		sanitize(fresh) -- starter rod + line with their own UUIDs
		session.Data = fresh
		session.Dirty = true
	end
end

function DataService.NextUid(player: Player): string
	local data = DataService.Get(player)
	local uid = tostring(data.NextUid)
	data.NextUid += 1
	return uid
end

local function load(player: Player, token: string): any
	local function claim(current)
		return ProfileLease.Claim(current or deepCopy(TEMPLATE), token, os.time(), LEASE_DURATION)
	end
	for attempt = 1, 8 do
		if not player.Parent or closing then
			return nil
		end
		while probingStudioStorage do
			task.wait()
		end
		local probe = inStudio and not realStorageUsed and not studioMemory
		if probe then
			probingStudioStorage = true
		end
		local ok, saved = updateProfile(player, claim)
		if probe then
			if not ok then
				warn("[DataService] Studio API services unavailable. Using in-memory saves for this play session.")
				studioMemory = true
			end
			probingStudioStorage = false
			if studioMemory then
				ok, saved = updateProfile(player, claim)
			end
		end
		if ok and saved then
			return saved
		end
		if attempt < 8 then
			task.wait(2)
		end
	end
	return nil
end

function DataService.Init()
	local sync = Remotes.Event("DataSync")

	local function onPlayerAdded(player: Player)
		local token = Inventory.NewUUID()
		local data = load(player, token)
		if data and data.PendingTrade then
			local record = TradeJournal.Decide(DataService.UpdateTradeJournal, data.PendingTrade, false)
			if record then
				local _, recovered = settle(player, token, record, nil)
				data = recovered
			else
				data = nil
			end
		end
		if not data then
			if player.Parent then
				player:Kick("Could not load or recover your save. Please rejoin.")
			end
			task.spawn(releaseLease, player, token)
			return
		end
		if not player.Parent or closing then
			releaseLease(player, token)
			return
		end
		currentData(data)
		local version = data.Version or 1 -- read before reconcile fills Version from the template
		reconcile(data, TEMPLATE)
		data.Version = version
		sanitize(data)
		sessions[player] = { Token = token, Data = data, Dirty = true, Writes = 0, Saving = false, Leaving = false }

		local ls = Instance.new("Folder")
		ls.Name = "leaderstats"
		local coins = Instance.new("IntValue")
		coins.Name = "Coins"
		coins.Parent = ls
		local level = Instance.new("IntValue")
		level.Name = "Level"
		level.Parent = ls
		ls.Parent = player

		DataService.ProfileLoaded:Fire(player, data)
	end

	Remotes.Event("ClientReady").OnServerEvent:Connect(function(player)
		DataService.MarkDirty(player)
	end)

	Players.PlayerAdded:Connect(onPlayerAdded)
	for _, p in Players:GetPlayers() do
		task.spawn(onPlayerAdded, p)
	end

	local function leave(player: Player)
		local session = sessions[player]
		if session and not session.Leaving then
			session.Leaving = true
			if session.Trade then
				closeOfflineTrade(player, session, session.Trade)
			else
				releaseSession(player)
			end
		end
	end
	Players.PlayerRemoving:Connect(leave)

	game:BindToClose(function()
		closing = true
		for player in sessions do
			task.spawn(leave, player)
		end
		local deadline = os.clock() + 25
		while next(sessions) and os.clock() < deadline do
			task.wait(0.2)
		end
	end)

	-- Replicate dirty profiles (batched, max ~10 per second per player).
	task.spawn(function()
		while true do
			task.wait(0.1)
			for player, session in sessions do
				if session.Dirty and not session.Trade and not session.Leaving then
					session.Dirty = false
					local data = session.Data
					local ls = player:FindFirstChild("leaderstats")
					if ls then
						(ls:FindFirstChild("Coins") :: IntValue).Value = data.Coins;
						(ls:FindFirstChild("Level") :: IntValue).Value = data.Level
					end
					sync:FireClient(player, data)
				end
			end
		end
	end)

	-- Autosave
	task.spawn(function()
		while true do
			task.wait(SAVE_INTERVAL)
			for _, p in Players:GetPlayers() do
				task.spawn(save, p)
			end
		end
	end)
end

return DataService
