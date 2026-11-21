--!strict
-- Player save data: load, reconcile with template, autosave, save on leave / shutdown,
-- and replicate a snapshot to the owning client.
--
-- Other services mutate `DataService.Get(player)` directly, then call
-- `DataService.MarkDirty(player)` so the client gets a fresh snapshot.
--
-- Adding a new saved field: add it to TEMPLATE. Existing saves get it automatically (Reconcile).

local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Registry = require(Shared.Registry)
local Inventory = require(Shared.Inventory)
local Roll = require(Shared.Roll)
local Remotes = require(Shared.Remotes)
local Signal = require(Shared.Util.Signal)

local GameConfig = Registry.GameConfig

local DataService = {}
DataService.ProfileLoaded = Signal.new() -- (player, profile)

local SCHEMA_VERSION = 5 -- 5: skill points for levels already reached; 2: Bag = inventory stacks (shared/Inventory.luau); 3: coin values x10 (Balance Pass 1); 4: aura dupes -> Star Tokens, 2 pity counters

local function buildTemplate()
	local owned = {}
	local equipped = {}
	local consumables = {}
	for catId, cat in Registry.Equipment do
		if cat.Kind == "Permanent" then
			local starter = Registry.StarterItem(catId)
			owned[catId] = {}
			if starter then
				owned[catId][starter] = true
				equipped[catId] = starter
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
		Auras = { Owned = {}, Equipped = nil, TotalRolls = 0, Stars = {}, StarTokens = 0 }, -- Owned[id] = 1 (dupes -> StarTokens)
		Gacha = { Pity = {}, PityHard = {}, Pulls = {}, Claimed = {} }, -- per banner id (Config/AuraBanners)
		Bag = {},
		Fishdex = {},
		Settings = { LowFX = false, TargetDepth = 10, AutoDepth = false },
		Lifetime = { Caught = 0, CoinsEarned = 0, PearlsEarned = 0 },
		NextUid = 1,
		Pearls = 0, -- Aquarium currency (float; UI floors it)
		Boosts = {}, -- [boostId] = os.time() it ends (GameConfig.Boosts, Shared/Boosts)
		Quests = { Day = -1, List = {}, Unclaimed = false }, -- daily quests (QuestService, Shared/Quests)
		DailyLogin = { Streak = 0, LastClaimDay = -1, Day = 1 }, -- 7-day daily login calendar
		Mastery = {}, -- [trackId] = level (Config/Mastery); kept through Rebirth
		Enhance = {}, -- [categoryId][itemId] = level (Gear Enhance, GameConfig.Enhance)
		Aquarium = { Slots = GameConfig.Aquarium.StartSlots, Fish = {} }, -- Fish = { {Uid, Id, Mutation, Weight, Value} }
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
			if e.Fish == old then
				e.Fish = new
			end
		end
	end
	for catId, cat in Registry.Equipment do
		if data.Equipped[catId] and not cat.Items[data.Equipped[catId]] then
			data.Equipped[catId] = Registry.StarterItem(catId)
		end
	end
	if data.Auras.Equipped and not Registry.Auras[data.Auras.Equipped] then
		data.Auras.Equipped = nil
	end
	local bagFromV1 = false
	if (data.Version or 1) < 2 then
		Inventory.MigrateV1(data, function(e)
			return Roll.Value(e, 1)
		end)
		data.Version = 2
		bagFromV1 = true -- stack values were just computed from the current (x10) config
	end
	if data.Version < 3 then
		-- Balance Pass 1: every coin value/price is x10. Scale what the player already has, once.
		data.Coins = math.floor((data.Coins or 0) * 10)
		data.Lifetime.CoinsEarned = math.floor((data.Lifetime.CoinsEarned or 0) * 10)
		if not bagFromV1 then
			for _, st in data.Bag do
				if st.Kind == "Fish" and st.Value then
					st.Value *= 10
				end
			end
		end
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
	for id in data.Skills.Levels do
		if not Registry.Skills.List[id] then
			data.Skills.Levels[id] = nil
		end
	end
	for catId, items in data.Enhance do
		local cat = Registry.Equipment[catId]
		for itemId in items do
			if not cat or not cat.Items[itemId] then
				items[itemId] = nil
			end
		end
	end
	for id in data.Mastery do
		if not Registry.Mastery.Tracks[id] then
			data.Mastery[id] = nil
		end
	end
	local tank = {}
	for _, f in data.Aquarium.Fish do
		if Registry.Fish[f.Id] and (f.Mutation == nil or Registry.Mutations[f.Mutation]) then
			table.insert(tank, f)
		end
	end
	data.Aquarium.Fish = tank
	local bag = {}
	for _, s in data.Bag do
		local known = if s.Kind == "Fish" then Registry.Fish[s.Id] ~= nil elseif s.Kind == "Treasure" then Registry.Treasures[s.Id] ~= nil else false
		if known and (s.Count or 0) > 0 then
			if s.New == true then
				Inventory.MarkNew(s) -- preserve unread items from older saves
			end
			table.insert(bag, s)
		end
	end
	data.Bag = bag
end

local store: DataStore? = nil
local storeOk, storeErr = pcall(function()
	store = DataStoreService:GetDataStore(GameConfig.DataStoreName)
end)
if not storeOk then
	warn("[DataService] DataStore unavailable, running without saves:", storeErr)
end

local profiles: { [Player]: any } = {}
local dirty: { [Player]: boolean } = {}
local loaded: { [Player]: boolean } = {}

local function key(player: Player): string
	return "Player_" .. player.UserId
end

local function load(player: Player): any
	if not store then
		return deepCopy(TEMPLATE)
	end
	for attempt = 1, 4 do
		local ok, result = pcall(function()
			return (store :: DataStore):GetAsync(key(player))
		end)
		if ok then
			return result or deepCopy(TEMPLATE)
		end
		warn(`[DataService] load attempt {attempt} failed for {player.Name}: {result}`)
		if RunService:IsStudio() then
			-- Usually "Studio access to API services" is off. Play without saving.
			warn("[DataService] Studio: enable Game Settings > Security > 'Studio Access to API Services' to test saving. Using a fresh profile.")
			store = nil
			return deepCopy(TEMPLATE)
		end
		task.wait(attempt)
	end
	return nil
end

local function save(player: Player): boolean
	local data = profiles[player]
	if not data or not loaded[player] then
		return false
	end
	data.LastOnline = os.time()
	if not store then
		return true -- Studio without API access: nothing to persist
	end
	local copy = deepCopy(data)
	for attempt = 1, 3 do
		local ok, err = pcall(function()
			(store :: DataStore):UpdateAsync(key(player), function()
				return copy
			end)
		end)
		if ok then
			return true
		end
		warn(`[DataService] save attempt {attempt} failed for {player.Name}: {err}`)
		task.wait(attempt)
	end
	return false
end

function DataService.Get(player: Player): any
	return profiles[player]
end

function DataService.WaitFor(player: Player): any
	while player.Parent and not profiles[player] do
		task.wait()
	end
	return profiles[player]
end

-- Saves right away (yields). true = the save is stored. Used before confirming a Robux receipt.
function DataService.SaveNow(player: Player): boolean
	return save(player)
end

function DataService.MarkDirty(player: Player)
	dirty[player] = true
end

-- Dev tool (DevService "!reset"): replace the profile with a fresh template. Saved on the next autosave.
function DataService.Reset(player: Player)
	if profiles[player] then
		profiles[player] = deepCopy(TEMPLATE)
		dirty[player] = true
	end
end

function DataService.NextUid(player: Player): string
	local data = profiles[player]
	local uid = tostring(data.NextUid)
	data.NextUid += 1
	return uid
end

function DataService.Init()
	local sync = Remotes.Event("DataSync")

	local function onPlayerAdded(player: Player)
		local data = load(player)
		if not player.Parent then
			return
		end
		if not data then
			player:Kick("Could not load your data. Please rejoin.")
			return
		end
		local version = data.Version or 1 -- read before reconcile fills Version from the template
		reconcile(data, TEMPLATE)
		data.Version = version
		sanitize(data)
		profiles[player] = data
		loaded[player] = true
		dirty[player] = true

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
		if profiles[player] then
			dirty[player] = true
		end
	end)

	Players.PlayerAdded:Connect(onPlayerAdded)
	for _, p in Players:GetPlayers() do
		task.spawn(onPlayerAdded, p)
	end

	Players.PlayerRemoving:Connect(function(player)
		save(player)
		profiles[player] = nil
		dirty[player] = nil
		loaded[player] = nil
	end)

	game:BindToClose(function()
		if RunService:IsStudio() and not store then
			return
		end
		local threads = {}
		for _, p in Players:GetPlayers() do
			table.insert(threads, task.spawn(save, p))
		end
		task.wait(3)
	end)

	-- Replicate dirty profiles (batched, max ~10 per second per player).
	task.spawn(function()
		while true do
			task.wait(0.1)
			for player, isDirty in dirty do
				if isDirty and profiles[player] then
					dirty[player] = false
					local data = profiles[player]
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
			task.wait(GameConfig.AutosaveInterval)
			for _, p in Players:GetPlayers() do
				task.spawn(save, p)
			end
		end
	end)
end

return DataService
