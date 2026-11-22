--!strict
-- Dev / test commands (spawn currency, items, auras, set level/pity...). Allowed users: Config/Dev.
-- Use: chat "!give gems 1000" (Config/Dev.ChatPrefix) or the Dev panel (F2) which sends the same line.
-- Every command is checked here on the server and logged to Output. "help" lists them.
-- Add a command: add an entry to COMMANDS (usage text + function(player, data, args) -> message).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Registry = require(Shared.Registry)
local Remotes = require(Shared.Remotes)
local Roll = require(Shared.Roll)
local Inventory = require(Shared.Inventory)

local DataService = require(script.Parent.DataService)
local ProgressionService = require(script.Parent.ProgressionService)
local MonetizationService = require(script.Parent.MonetizationService)
local AquariumService = require(script.Parent.AquariumService)
local AuraService = require(script.Parent.AuraService)
local QuestService = require(script.Parent.QuestService)
local ShopService = require(script.Parent.ShopService)
local RebirthService = require(script.Parent.RebirthService)
local TideEventService = require(script.Parent.TideEventService)

local Dev = Registry.Dev

local DevService = {}

function DevService.IsDev(player: Player): boolean
	if Dev.AllowInStudio and RunService:IsStudio() then
		return true
	end
	if table.find(Dev.Admins, player.UserId) then
		return true
	end
	if Dev.AllowPlaceOwner then
		if game.CreatorType == Enum.CreatorType.User then
			return player.UserId == game.CreatorId
		end
		local ok, rank = pcall(function()
			return player:GetRankInGroupAsync(game.CreatorId)
		end)
		return ok and rank >= Dev.OwnerGroupRank
	end
	return false
end

-- case-insensitive id lookup ("glowEel" -> "GlowEel")
local function findId(tbl: { [string]: any }, name: string?): string?
	if not name then
		return nil
	end
	if tbl[name] then
		return name
	end
	local lower = string.lower(name)
	for id in tbl do
		if string.lower(id) == lower then
			return id
		end
	end
	return nil
end

local function num(s: string?, default: number): number
	local n = tonumber(s)
	return if n then math.floor(n) else default
end

type Command = { Usage: string, Run: (Player, any, { string }) -> string }

local COMMANDS: { [string]: Command } = {}

COMMANDS.give = {
	Usage = "give gems|coins|pearls <n> | give rods <id> [profile] | give bait <id> <n> | give chest <id> <n> | give fish <id> <n> [mutation] | give aura <id> [n]",
	Run = function(player, data, a)
		local kind = string.lower(a[1] or "")
		if kind == "gems" or kind == "coins" or kind == "pearls" then
			local n = num(a[2], 1000)
			local key = if kind == "gems" then "Gems" elseif kind == "pearls" then "Pearls" else "Coins"
			data[key] += n
			return `+{n} {key}`
		elseif kind == "bait" then
			local id = findId(Registry.Equipment.Baits.Items, a[2])
			if not id then
				return "unknown bait"
			end
			local n = num(a[3], 10)
			data.Consumables.Baits[id] = (data.Consumables.Baits[id] or 0) + n
			return `+{n} {id}`
		elseif kind == "chest" or kind == "treasure" then
			local id = findId(Registry.Treasures, a[2] or "TreasureChest")
			if not id then
				return "unknown treasure"
			end
			local n, given = num(a[3], 1), 0
			for _ = 1, n do
				if Inventory.AddTreasure(data, id) then
					given += 1
				end
			end
			return `+{given} {id}` .. (if given < n then " (bag full)" else "")
		elseif kind == "rods" or kind == "rod" or kind == "lines" or kind == "line" then
			-- give Rods|Lines <id> [Shop|Fishing|DeepSea|BossRaid|QuestPure]: a rod / line with rolled mods (not equipped)
			local gearCat = if string.sub(kind, 1, 4) == "line" then "Lines" else "Rods"
			local id = findId(Registry.Equipment[gearCat].Items, a[2])
			local profile = findId(Registry.ModifierDefs.Profiles, a[3]) or "Shop"
			if not id then
				return "unknown item"
			end
			local rod = Inventory.NewGear(gearCat, id, profile)
			Inventory.Add(data, rod, true)
			local parts = {}
			local function describe(list: { any }?)
				if list then
					for _, m in list do
						table.insert(parts, `{m.Name} {string.format("%+.3f", m.Value)} {m.Stat}`)
					end
				end
			end
			describe(rod.Prefixes)
			describe(rod.Suffixes)
			return `+1 {id} ({profile}): ` .. (if #parts > 0 then table.concat(parts, ", ") else "no mods")
		elseif kind == "fish" then
			local id = findId(Registry.Fish, a[2])
			if not id then
				return "unknown fish"
			end
			local mut = findId(Registry.Mutations, a[4])
			local n, given = num(a[3], 1), 0
			local rng = Random.new()
			for _ = 1, n do
				local entry = { Uid = "dev", Fish = id, Weight = Roll.Weight(id, rng), Mutation = mut, Mult = 1 }
				if Inventory.AddFish(data, id, mut, entry.Weight, Roll.Value(entry, 1), { "Manual" }) then
					given += 1
					local dex = data.Fishdex[id] or { Count = 0, Best = 0 }
					dex.Count += 1
					dex.Best = math.max(dex.Best, entry.Weight)
					data.Fishdex[id] = dex
				end
			end
			return `+{given} {id}` .. (if mut then ` ({mut})` else "") .. (if given < n then " (bag full)" else "")
		elseif kind == "aura" then
			local id = findId(Registry.Auras, a[2])
			if not id then
				return "unknown aura"
			end
			local n, newCount, tokens = num(a[3], 1), 0, 0
			for _ = 1, n do
				local isNew, t = AuraService.GiveAura(data, id)
				newCount += if isNew then 1 else 0
				tokens += t
			end
			return `+{n} aura {id}` .. (if tokens > 0 then ` ({tokens} Star Tokens from duplicates)` else "")
		end
		return COMMANDS.give.Usage
	end,
}

COMMANDS.level = {
	Usage = "level <n>",
	Run = function(_, data, a)
		data.Level = math.max(1, num(a[1], 1))
		data.XP = 0
		return `Level = {data.Level}`
	end,
}

COMMANDS.xp = {
	Usage = "xp <n>",
	Run = function(player, _, a)
		local levels = ProgressionService.AddXP(player, num(a[1], 100))
		return `+XP (levels gained: {levels})`
	end,
}

COMMANDS.pity = {
	Usage = "pity <bannerId> <n> [mythic]   (pity Altar 99 -> next = Legendary; pity Altar 299 mythic -> next = Mythic)",
	Run = function(_, data, a)
		local id = findId(Registry.AuraBanners, a[1] or "Altar")
		if not id then
			return "unknown banner"
		end
		local b = Registry.AuraBanners[id]
		if string.lower(a[3] or "") == "mythic" or string.lower(a[3] or "") == "hard" then
			if not b.HardPity then
				return `{id} has no HardPity`
			end
			data.Gacha.PityHard[id] = num(a[2], 0)
			return `{id} {b.HardPity.Rarity} pity = {data.Gacha.PityHard[id]} / {b.HardPity.Pulls}`
		end
		data.Gacha.Pity[id] = num(a[2], 0)
		return `{id} {b.PityRarity} pity = {data.Gacha.Pity[id]} / {b.PityPulls}`
	end,
}

-- Aura stars (C17): "stars SparklingDew 3" sets Stars (owns it too); "stars tokens 100" adds Star Tokens
COMMANDS.stars = {
	Usage = "stars <auraId> <0-5> | stars tokens <n>",
	Run = function(_, data, a)
		if string.lower(a[1] or "") == "tokens" then
			local n = num(a[2], 100)
			data.Auras.StarTokens += n
			return `+{n} Star Tokens ({data.Auras.StarTokens})`
		end
		local id = findId(Registry.Auras, a[1])
		if not id then
			return COMMANDS.stars.Usage
		end
		local n = math.clamp(num(a[2], 1), 0, Registry.AuraStars.MaxStars)
		data.Auras.Owned[id] = 1
		data.Auras.Stars[id] = if n > 0 then n else nil
		return `{id} Star {n}`
	end,
}

COMMANDS.pulls = {
	Usage = "pulls <bannerId> <n>   (banner pull count for milestones)",
	Run = function(_, data, a)
		local id = findId(Registry.AuraBanners, a[1] or "NeonTide")
		if not id then
			return "unknown banner"
		end
		data.Gacha.Pulls[id] = num(a[2], 0)
		return `{id} pulls = {data.Gacha.Pulls[id]}`
	end,
}

COMMANDS.unclaim = {
	Usage = "unclaim <bannerId>   (milestones claimable again)",
	Run = function(_, data, a)
		local id = findId(Registry.AuraBanners, a[1] or "NeonTide")
		if not id then
			return "unknown banner"
		end
		data.Gacha.Claimed[id] = {}
		return `{id} milestones reset`
	end,
}

COMMANDS.equip = {
	Usage = "equip <category> <itemId>   (gives + equips, e.g. equip Bags Coolbox)",
	Run = function(_, data, a)
		local cat = findId(Registry.Equipment, a[1])
		if not cat then
			return "unknown category"
		end
		local id = findId(Registry.Equipment[cat].Items, a[2])
		if not id then
			return "unknown item"
		end
		if Inventory.IsGearCategory(cat) then
			local gear = Inventory.NewGear(cat, id) -- a new item each time (own UUID)
			Inventory.Add(data, gear, true)
			data.Equipped[cat] = gear.UUID
			return `Equipped {cat}.{id} (new item)`
		end
		if data.Owned[cat] then
			data.Owned[cat][id] = true
		end
		data.Equipped[cat] = id
		return `Equipped {cat}.{id}`
	end,
}

-- Robux testing without buying (C13)
COMMANDS.grant = {
	Usage = "grant pass <VIP|AutoFishPro|InfiniteBag>",
	Run = function(player, data, args)
		local key = findId(Registry.Products.Passes, args[2])
		if string.lower(args[1] or "") ~= "pass" or not key then
			return "usage: grant pass <id>"
		end
		if data.DevMutedPasses then
			data.DevMutedPasses[key] = nil
		end
		MonetizationService.SetPass(player, key, "Dev")
		return `{key} granted (Dev)`
	end,
}

COMMANDS.revoke = {
	Usage = "revoke pass <id>",
	Run = function(player, data, args)
		local key = findId(Registry.Products.Passes, args[2])
		if string.lower(args[1] or "") ~= "pass" or not key then
			return "usage: revoke pass <id>"
		end
		-- muted: a pass you really bought is not switched back on at the next join ("grant pass" lifts it)
		data.DevMutedPasses = data.DevMutedPasses or {}
		data.DevMutedPasses[key] = true
		MonetizationService.SetPass(player, key, nil)
		return `{key} revoked (stays off after rejoin; grant pass to restore)`
	end,
}

COMMANDS.receipt = {
	Usage = "receipt <product> [purchaseId]   (fake Robux receipt; same id twice = no double grant)",
	Run = function(player, _, args)
		local key = findId(Registry.Products.Products, args[1])
		if not key then
			local ids = {}
			for id in Registry.Products.Products do
				table.insert(ids, id)
			end
			table.sort(ids)
			return "products: " .. table.concat(ids, ", ")
		end
		local purchaseId = args[2] or ("dev-" .. HttpService:GenerateGUID(false))
		local decision, reason = MonetizationService.Grant(player, key, purchaseId)
		return `{key} [{purchaseId}] -> {decision.Name}: {reason}`
	end,
}

-- Aquarium (C14): pretend you were away, e.g. "offline 2h", "offline 30m", "offline 90" (seconds)
COMMANDS.offline = {
	Usage = "offline <2h|30m|seconds>   (gives offline Pearls now + popup, capped like a real rejoin)",
	Run = function(player, _, a)
		local s = string.lower(a[1] or "1h")
		local n, unit = string.match(s, "^(%d+%.?%d*)([hms]?)$")
		if not n then
			return COMMANDS.offline.Usage
		end
		local secs = tonumber(n) :: number * (if unit == "h" then 3600 elseif unit == "m" then 60 else 1)
		local info = AquariumService.GrantOffline(player, secs)
		if not info then
			return "no Pearls (tank empty?)"
		end
		return string.format("away %.0fs, credited %.0fs%s -> +%.1f Pearls", secs, info.Credited, if info.Capped then " (capped)" else "", info.Pearls)
	end,
}

-- Mastery (C15): set a track level without paying, e.g. "mastery Luck 10"
COMMANDS.mastery = {
	Usage = "mastery <track> <level>   (Luck|CatchBar|ReelPower|AutoWait|PearlRate|OfflineCap|SellMult; 'mastery reset' = all 0)",
	Run = function(_, data, a)
		if string.lower(a[1] or "") == "reset" then
			data.Mastery = {}
			return "Mastery reset"
		end
		local id = findId(Registry.Mastery.Tracks, a[1])
		if not id then
			return COMMANDS.mastery.Usage
		end
		local t = Registry.Mastery.Tracks[id]
		local lv = math.max(0, num(a[2], 1))
		if t.MaxLevel then
			lv = math.min(lv, t.MaxLevel)
		end
		data.Mastery[id] = if lv > 0 then lv else nil
		return `{id} = Lv.{lv}`
	end,
}

-- Gear Enhance (C16): "enhance Rods BambooRod 5" sets the level (owns the item too)
COMMANDS.enhance = {
	Usage = "enhance <Rods|Lines> <itemId> <level 0-10>",
	Run = function(_, data, a)
		local catId = findId(Registry.Equipment, a[1])
		local cat = catId and Registry.Equipment[catId]
		local itemId = cat and findId(cat.Items, a[2])
		if not catId or not itemId then
			return COMMANDS.enhance.Usage
		end
		local lv = math.clamp(num(a[3], 1), 0, Registry.GameConfig.Enhance.MaxLevel)
		local kind = Inventory.GearKind(catId)
		if not kind then
			return COMMANDS.enhance.Usage
		end
		local gear
		for _, s in data.Bag do
			if s.Kind == kind and s.Id == itemId then
				gear = s
				break
			end
		end
		if not gear then
			gear = Inventory.NewGear(catId, itemId)
			Inventory.Add(data, gear, true)
		end
		gear.Enhance = lv
		return `{itemId} +{lv}`
	end,
}

-- Daily quests (C7)
COMMANDS.quests = {
	Usage = "quests reroll | quests done   (finish all of today's quests) | quests list",
	Run = function(player, data, a)
		local sub = string.lower(a[1] or "list")
		if sub == "reroll" then
			QuestService.Reroll(player)
		elseif sub == "done" then
			for _, e in data.Quests.List do
				local q = Registry.Quests[e.Id]
				if q then
					e.Progress = q.Target
				end
			end
			data.Quests.Unclaimed = true
		end
		local parts = {}
		for i, e in data.Quests.List do
			local q = Registry.Quests[e.Id]
			table.insert(parts, `{i}. {e.Id} {e.Progress}/{q and q.Target or "?"}{if e.Claimed then " (claimed)" else ""}`)
		end
		return table.concat(parts, " | ")
	end,
}

-- Boosts (C19): "boost coins 2h", "boost pearls 30m", "boost coins off"
COMMANDS.boost = {
	Usage = "boost <coins|pearls> <2h|30m|seconds|off>",
	Run = function(_, data, a)
		local id = findId(Registry.GameConfig.Boosts, a[1])
		if not id then
			return COMMANDS.boost.Usage
		end
		local arg = string.lower(a[2] or "2h")
		if arg == "off" then
			data.Boosts[id] = nil
			return `{id} boost off`
		end
		local n, unit = string.match(arg, "^(%d+%.?%d*)([hms]?)$")
		if not n then
			return COMMANDS.boost.Usage
		end
		local secs = tonumber(n) :: number * (if unit == "h" then 3600 elseif unit == "m" then 60 else 1)
		data.Boosts[id] = math.max(os.time(), data.Boosts[id] or 0) + secs
		return `{id} boost: {data.Boosts[id] - os.time()}s left`
	end,
}

-- Robux: forget that a OncePerPlayer product was bought (so Starter Pack can be tested again)
COMMANDS.unbuy = {
	Usage = "unbuy <product>   (e.g. unbuy StarterPack -> can buy it again; items already given stay)",
	Run = function(_, data, a)
		local key = findId(Registry.Products.Products, a[1])
		if not key then
			return COMMANDS.unbuy.Usage
		end
		data.Purchases.Once[key] = nil
		return `{key} can be bought again`
	end,
}

-- Hot fish (C18): "hotfish StripeBass 3" (1 hour), "hotfish StripeBass 3 5m", "hotfish off", "hotfish" = show
COMMANDS.hotfish = {
	Usage = "hotfish <fishId> <mult> [time] | hotfish off | hotfish   (show the current list)",
	Run = function(_, _, a)
		local HotFish = require(Shared.HotFish)
		local sub = string.lower(a[1] or "")
		if sub == "off" then
			ShopService.SetHotFishOverride(nil)
		elseif sub ~= "" then
			local id = findId(Registry.Fish, a[1])
			if not id then
				return "unknown fish"
			end
			local secs = 3600
			local n, unit = string.match(string.lower(a[3] or ""), "^(%d+)([hms]?)$")
			if n then
				secs = tonumber(n) :: number * (if unit == "h" then 3600 elseif unit == "m" then 60 else 1)
			end
			ShopService.SetHotFishOverride(id, tonumber(a[2]) or 3, secs)
		end
		local parts = {}
		for _, e in HotFish.Current() do
			table.insert(parts, `{e.FishId} x{e.Mult} ({e.EndsAt - os.time()}s left)`)
		end
		return "hot fish: " .. table.concat(parts, ", ")
	end,
}

-- Rebirth (C3): "rebirths 3" sets the count (title + multiplier) without resetting
COMMANDS.rebirths = {
	Usage = "rebirths <n>   (sets rebirth count; real rebirth = Main Menu > Rebirth at the level shown)",
	Run = function(player, _, a)
		RebirthService.SetCount(player, num(a[1], 1))
		return `rebirths = {num(a[1], 1)}`
	end,
}

-- Skills (C4): "skillpoints 50", "skill MultiCast 3", "skill reset" (refunds nothing)
COMMANDS.skillpoints = {
	Usage = "skillpoints <n>   (adds skill points)",
	Run = function(_, data, a)
		local n = num(a[1], 10)
		data.Skills.Points += n
		return `+{n} skill points ({data.Skills.Points})`
	end,
}
COMMANDS.skill = {
	Usage = "skill <KeenEye|QuickHands|MultiCast> <level> | skill reset",
	Run = function(_, data, a)
		if string.lower(a[1] or "") == "reset" then
			data.Skills.Levels = {}
			return "skills reset"
		end
		local id = findId(Registry.Skills.List, a[1])
		if not id then
			return COMMANDS.skill.Usage
		end
		local lv = math.clamp(num(a[2], 1), 0, Registry.Skills.List[id].MaxLevel)
		data.Skills.Levels[id] = if lv > 0 then lv else nil
		return `{id} Lv.{lv}`
	end,
}

-- Tide event (C5): "event start", "event stop"
COMMANDS.event = {
	Usage = "event start [id] | event stop",
	Run = function(_, _, a)
		local sub = string.lower(a[1] or "start")
		if sub == "start" then
			local _, msg = TideEventService.Start(a[2])
			return msg
		elseif sub == "stop" then
			TideEventService.Stop()
			return "event stopped"
		end
		return COMMANDS.event.Usage
	end,
}

COMMANDS.clearbag = {
	Usage = "clearbag",
	Run = function(_, data)
		local keep = {}
		for _, s in data.Bag do
			if Inventory.IsWorn(data, s) then
				table.insert(keep, s)
			end
		end
		data.Bag = keep
		return "Bag cleared (worn rod and line stay)"
	end,
}

COMMANDS.reset = {
	Usage = "reset   (wipes YOUR save back to a new player)",
	Run = function(player)
		DataService.Reset(player)
		return "Profile reset"
	end,
}

COMMANDS.help = {
	Usage = "help",
	Run = function()
		local lines = {}
		for _, c in COMMANDS do
			table.insert(lines, c.Usage)
		end
		table.sort(lines)
		return table.concat(lines, "\n")
	end,
}

-- Players matching a name: "all", or one exact / prefix match on Name or DisplayName (case-insensitive).
local function findTargets(who: string): ({ Player }, string?)
	if string.lower(who) == "all" then
		return Players:GetPlayers(), nil
	end
	local lower = string.lower(who)
	local prefix: { Player } = {}
	for _, p in Players:GetPlayers() do
		if string.lower(p.Name) == lower or string.lower(p.DisplayName) == lower then
			return { p }, nil
		end
		if string.sub(string.lower(p.Name), 1, #lower) == lower or string.sub(string.lower(p.DisplayName), 1, #lower) == lower then
			table.insert(prefix, p)
		end
	end
	if #prefix == 1 then
		return prefix, nil
	end
	return {}, if #prefix == 0 then `no player matches "{who}"` else `"{who}" matches {#prefix} players, be more exact`
end

local NOT_FOR_OTHERS = { to = true, reset = true, help = true, ping = true } -- reset would wipe someone else's save

-- "to <player|all> <command...>": runs any other command on another player (their save, their UI).
local function runForOthers(caller: Player, args: { string }, line: string): (boolean, string)
	local who = table.remove(args, 1)
	local sub = string.lower(table.remove(args, 1) or "")
	if not who or sub == "" then
		return false, "usage: to <player|all> <command...>   e.g. to Bob give gems 500"
	end
	local cmd = COMMANDS[sub]
	if not cmd or NOT_FOR_OTHERS[sub] then
		return false, `"{sub}" cannot be sent to other players`
	end
	local targets, err = findTargets(who)
	if err then
		return false, err
	end
	local results = {}
	for _, target in targets do
		local data = DataService.Get(target)
		if not data then
			table.insert(results, `{target.Name}: profile not loaded`)
			continue
		end
		local ok, msg = pcall(cmd.Run, target, data, table.clone(args))
		if ok then
			DataService.MarkDirty(target)
			print(`[Dev] {caller.Name} ({caller.UserId}) -> {target.Name} ({target.UserId}): {line} -> {msg}`)
			if target ~= caller then
				Remotes.Event("Notify"):FireClient(target, "A developer gave you something: " .. tostring(msg), Color3.fromRGB(79, 175, 138))
			end
			table.insert(results, `{target.Name}: {msg}`)
		else
			warn(`[Dev] {caller.Name} -> {target.Name} "{line}" failed: {msg}`)
			table.insert(results, `{target.Name}: failed ({msg})`)
		end
	end
	return true, table.concat(results, "\n")
end

COMMANDS.to = {
	Usage = "to <player|all> <command...>   (run give / equip / boost / level ... on another player, e.g. to Bob give gems 500)",
	Run = function()
		return "usage: to <player|all> <command...>"
	end,
}

-- Runs one command line ("give gems 1000"). Returns ok, message.
function DevService.Run(player: Player, line: any): (boolean, string)
	if type(line) ~= "string" or #line > 200 then
		return false, "bad command"
	end
	if not DevService.IsDev(player) then
		return false, "not allowed"
	end
	local args = string.split(string.gsub(line, "^%s*(.-)%s*$", "%1"), " ")
	local name = string.lower(table.remove(args, 1) or "")
	if name == "ping" then
		return true, "dev"
	end
	if name == "to" then
		return runForOthers(player, args, line)
	end
	local cmd = COMMANDS[name]
	if not cmd then
		return false, `unknown command "{name}" (try: help)`
	end
	local data = DataService.Get(player)
	if not data then
		return false, "profile not loaded"
	end
	local ok, msg = pcall(cmd.Run, player, data, args)
	if not ok then
		warn(`[Dev] {player.Name} "{line}" failed: {msg}`)
		return false, tostring(msg)
	end
	DataService.MarkDirty(player)
	print(`[Dev] {player.Name} ({player.UserId}): {line} -> {msg}`)
	return true, msg
end

function DevService.Init()
	Remotes.Func("DevCommand").OnServerInvoke = function(player, line)
		return DevService.Run(player, line)
	end
	local function hook(player: Player)
		player.Chatted:Connect(function(message)
			if string.sub(message, 1, #Dev.ChatPrefix) == Dev.ChatPrefix and DevService.IsDev(player) then
				local ok, msg = DevService.Run(player, string.sub(message, #Dev.ChatPrefix + 1))
				Remotes.Event("Notify"):FireClient(player, `[Dev] {msg}`, if ok then Color3.fromRGB(79, 175, 138) else Color3.fromRGB(204, 84, 84))
			end
		end)
	end
	Players.PlayerAdded:Connect(hook)
	for _, p in Players:GetPlayers() do
		hook(p)
	end
end

return DevService
