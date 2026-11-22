--!strict
-- Server-authoritative fishing loop (GDD 2, 3, 10.1).
--
-- Manual:  Cast(depth, dir, power, perfect) -> wait -> Bite(!) -> Hook -> StartMinigame -> ReelResult -> award (x1.5)
-- Auto:    SetAuto(true, dir) -> every AutoCycleTime: roll + award (x AutoMultiplier, Gems/chests x0.5)
-- C25: the client aims (camera direction) and charges the cast; the server checks the landing point is water in reach.
-- Hot Streak: consecutive manual catches add GameConfig.HotStreak bonus to coin value.
--
-- The server rolls the fish when it bites and never trusts the client with outcomes. The client
-- only reports whether it won the minigame; the server rejects results that finish faster than
-- the theoretical minimum for that fish + rod.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local HttpService = game:GetService("HttpService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Registry = require(Shared.Registry)
local Remotes = require(Shared.Remotes)
local Stats = require(Shared.Stats)
local Roll = require(Shared.Roll)
local Inventory = require(Shared.Inventory)
local FishingSpot = require(Shared.FishingSpot)
local HotFish = require(Shared.HotFish)
local Signal = require(Shared.Util.Signal)

local DataService = require(script.Parent.DataService)
local ProgressionService = require(script.Parent.ProgressionService)
local TideEventService = require(script.Parent.TideEventService)
local HotspotService = require(script.Parent.HotspotService)

local GameConfig = Registry.GameConfig
local MG = GameConfig.Minigame

local FishingService = {}
FishingService.FishCaught = Signal.new() -- (player, entry, mode, streak) hook for quests/boss/events (streak = Hot Streak after this catch, 0 for Auto)

type State = {
	Phase: string, -- "Idle" | "Waiting" | "Bite" | "Reeling" | "Auto"
	Token: string,
	Fish: string?,
	Depth: number,
	LocationId: string?,
	Origin: Vector3?,
	ReelStart: number,
	MinDuration: number,
	LastCast: number,
	AutoGen: number,
	AutoDir: Vector3?,
	Bobber: Instance?,
	Streak: number, -- Hot Streak: manual catches in a row (session only)
	HotLuck: number, -- C26: luck bonus of the hotspot this cast landed in (0 = none)
}

local states: { [Player]: State } = {}
local rng = Random.new()

local notify: RemoteEvent
local stateEvent: RemoteEvent

local function getState(player: Player): State
	local s = states[player]
	if not s then
		s = { Phase = "Idle", Token = "", Depth = 0, ReelStart = 0, MinDuration = 0, LastCast = 0, AutoGen = 0, Streak = 0, HotLuck = 0 }
		states[player] = s
	end
	return s
end

local function setPhase(player: Player, phase: string, info: any?)
	local s = getState(player)
	s.Phase = phase
	stateEvent:FireClient(player, phase, info)
end

local function clearBobber(s: State)
	if s.Bobber then
		s.Bobber:Destroy()
		s.Bobber = nil
	end
end

local function reset(player: Player, keepAuto: boolean?)
	local s = getState(player)
	clearBobber(s)
	s.Token = ""
	s.Fish = nil
	s.HotLuck = 0
	if keepAuto and s.Phase == "Auto" then
		return
	end
	setPhase(player, "Idle")
end

local function bagCapacity(data: any): number
	return Inventory.Capacity(data)
end

-- Bonus treasure chest on a catch (Config/Treasures). Returns the chest id or nil.
local function rollTreasure(data: any, depth: number, luck: number, chanceMult: number): string?
	local scale = (1 + luck * GameConfig.Inventory.TreasureLuckScale) * chanceMult
	for id, t in Registry.Treasures do
		if (t.MinDepth == nil or depth >= t.MinDepth) and rng:NextNumber() < t.DropChance * scale then
			if Inventory.AddTreasure(data, id) then
				return id
			end
		end
	end
	return nil
end

local function rootOf(player: Player): BasePart?
	local char = player.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if not char or not hum or hum.Health <= 0 then
		return nil
	end
	return char:FindFirstChild("HumanoidRootPart") :: BasePart?
end

-- C25: where a cast with this direction + power lands (nil = not fishable water). Same math as the client's aim marker.
local function castPoint(root: BasePart, stats: Stats.ComputedStats, dir: Vector3, power: number): (Vector3?, string?)
	local c = GameConfig.Cast
	local range = math.max(c.MinDistance, stats.Values.CastRange)
	return FishingSpot.WaterAt(root, dir, c.MinDistance + (range - c.MinDistance) * math.clamp(power, 0, 1))
end

-- Client direction: flat unit vector or nil (trust boundary).
local function flatDir(dir: any): Vector3?
	if typeof(dir) ~= "Vector3" or dir.X ~= dir.X or dir.Z ~= dir.Z then
		return nil
	end
	local flat = Vector3.new(dir.X, 0, dir.Z)
	return if flat.Magnitude > 0.01 then flat.Unit else nil
end

local function spawnBobber(player: Player, point: Vector3): Instance
	local folder = Workspace:FindFirstChild("Bobbers") or Instance.new("Folder")
	folder.Name = "Bobbers"
	folder.Parent = Workspace

	local bobber = Instance.new("Part")
	bobber.Name = player.Name
	bobber.Shape = Enum.PartType.Ball
	bobber.Size = Vector3.new(0.8, 0.8, 0.8)
	bobber.Color = Color3.fromRGB(255, 60, 60)
	bobber.Material = Enum.Material.SmoothPlastic
	bobber.Anchored = true
	bobber.CanCollide = false
	bobber.CanQuery = false
	bobber.Position = point + Vector3.new(0, 0.2, 0)

	local a1 = Instance.new("Attachment")
	a1.Parent = bobber
	local char = player.Character
	local hand = char and (char:FindFirstChild("RightHand") or char:FindFirstChild("Right Arm"))
	if hand then
		local a0 = Instance.new("Attachment")
		a0.Name = "FishingLineAttachment"
		a0.Parent = hand
		bobber.Destroying:Connect(function()
			a0:Destroy()
		end)
		local beam = Instance.new("Beam")
		beam.Attachment0 = a0
		beam.Attachment1 = a1
		beam.Width0 = 0.05
		beam.Width1 = 0.05
		beam.CurveSize0 = 2
		beam.Color = ColorSequence.new(Color3.fromRGB(240, 240, 240))
		beam.FaceCamera = true
		beam.Parent = bobber
	end
	bobber.Parent = folder
	return bobber
end

local function allowedDepth(data: any, stats: Stats.ComputedStats, locationId: string?): number
	local cap = stats.Values.MaxDepth
	local loc = locationId and Registry.Locations[locationId]
	if loc then
		cap = math.min(cap, loc.MaxDepth)
	end
	return cap
end

-- Theoretical fastest win: progress from StartProgress to 1 with no losses.
local function minDuration(stats: Stats.ComputedStats): number
	local gain = MG.GainPerSecond * stats.Values.ReelPower
	return (1 - MG.StartProgress) / gain
end

local function consumeBait(data: any)
	local baitId = data.Equipped.Baits
	if not baitId then
		return
	end
	local stack = data.Consumables.Baits
	if stack[baitId] and stack[baitId] > 0 then
		stack[baitId] -= 1
	end
end

-- Hot Streak -------------------------------------------------------------

local function streakBonus(streak: number): number
	local hs = GameConfig.HotStreak
	return math.min(hs.Max, streak * hs.PerCatch)
end

local function fireStreak(player: Player, streak: number, lost: boolean)
	Remotes.Event("Streak"):FireClient(player, { Streak = streak, Bonus = streakBonus(streak), Lost = lost })
end

-- Manual fail (snapped line / missed bite): streak back to 0.
local function loseStreak(player: Player)
	local s = getState(player)
	if s.Streak > 0 then
		s.Streak = 0
		fireStreak(player, 0, true)
	end
end

-- Whole Gems from a fractional amount (0.5 = 50% chance of 1).
local function roundGems(amount: number): number
	local whole = math.floor(amount)
	if rng:NextNumber() < amount - whole then
		whole += 1
	end
	return whole
end

-- Gives the fish to the player. mode = "Manual" | "Auto" | "Bonus" (Multi-Cast extra line, C4).
-- "Bonus" is silent (no catch card of its own, no bait used, no chest roll) and is paid like Auto;
-- it returns a short summary that the main catch puts in CatchResult.Bonus.
local function award(player: Player, fishId: string, mult: number, mode: string, perfect: boolean?, depth: number?, locationId: string?, hotspot: boolean?): any
	local data = DataService.Get(player)
	if not data then
		return nil
	end
	local stats = Stats.Compute(data)
	local fish = Registry.Fish[fishId]
	local rarity = Registry.Rarities[fish.Rarity]
	local isAuto = mode ~= "Manual"
	local isBonus = mode == "Bonus"

	local streak = 0
	if mode == "Manual" then
		local s = getState(player)
		s.Streak += 1
		streak = s.Streak
		mult *= 1 + streakBonus(streak)
	end

	local entry: Roll.CatchEntry = {
		Uid = DataService.NextUid(player),
		Fish = fishId,
		Weight = Roll.Weight(fishId, rng),
		Mutation = Roll.Mutation(stats.Values.MutationChance, stats.MutationBonus, rng),
		Mult = mult,
	}
	local tags = { if isAuto then "Auto" else "Manual" }
	if perfect then
		table.insert(tags, "Perfect")
	end
	if hotspot then
		table.insert(tags, "Hotspot")
	end
	-- Fish never stack: one fish = one bag slot with its own weight, mutation, tags and value (nil = bag full).
	local stack = Inventory.AddFish(data, fishId, entry.Mutation, entry.Weight, Roll.Value(entry, 1), tags)
	if not isBonus then
		consumeBait(data)
	end
	local treasure = if stack and not isBonus then rollTreasure(data, depth or 0, stats.Values.Luck, if isAuto then GameConfig.AutoTreasureMultiplier else 1) else nil

	local dex = data.Fishdex[fishId]
	local isNew = dex == nil
	if not dex then
		dex = { Count = 0, Best = 0 }
		data.Fishdex[fishId] = dex
	end
	dex.Count += 1
	dex.Best = math.max(dex.Best, entry.Weight)
	data.Lifetime.Caught += 1

	local gems = GameConfig.GemsByRarityTier[rarity.Tier] or 0
	if isAuto then
		gems = roundGems(gems * GameConfig.AutoGemMultiplier)
	end
	local newGems = if isNew then GameConfig.NewSpeciesGems else 0
	gems += newGems
	data.Gems += gems

	local xp = rarity.XP * stats.Values.XPMultiplier * (mode == "Manual" and GameConfig.ManualMultiplier or 1)
	local levels = ProgressionService.AddXP(player, xp)

	if isBonus then
		DataService.MarkDirty(player)
		FishingService.FishCaught:Fire(player, entry, mode, 0)
		return {
			Entry = entry,
			Value = math.floor(Roll.Value(entry, stats.Values.SellMultiplier) * HotFish.Mult(fishId) + 0.5),
			New = isNew,
			Gems = gems,
			Kept = stack ~= nil,
			LevelsGained = levels,
		}
	end

	-- Multi-Cast (C4): every extra line may hook a bonus fish at the same depth.
	local bonus = {}
	local lines = math.floor(stats.Values.ExtraLines)
	if lines > 0 and locationId then
		local chance = Registry.Skills.MultiCast.ExtraLineChance
		for _ = 1, lines do
			if rng:NextNumber() < chance then
				local bonusId = Roll.Fish(depth or 0, locationId, stats.Values.Luck, rng)
				local r = bonusId and award(player, bonusId, stats.Values.AutoMultiplier, "Bonus", nil, depth, locationId)
				if r then
					table.insert(bonus, r)
					levels += r.LevelsGained
					gems += r.Gems
				end
			end
		end
	end

	DataService.MarkDirty(player)
	Remotes.Event("CatchResult"):FireClient(player, {
		Entry = entry,
		Value = math.floor(Roll.Value(entry, stats.Values.SellMultiplier) * HotFish.Mult(fishId) + 0.5), -- incl. hot fish
		Hot = HotFish.Mult(fishId), -- > 1 = hot fish at the Merchant right now (C18)
		Mode = mode,
		Perfect = perfect == true,
		Hotspot = hotspot == true, -- C26: landed in a fish hotspot (luck bonus already applied)
		New = isNew,
		Gems = gems, -- total, includes NewGems
		NewGems = newGems, -- first catch of this species
		Streak = streak, -- Hot Streak count after this catch (0 for Auto)
		StreakBonus = streakBonus(streak), -- e.g. 0.15 = +15% coin value (already in Entry.Mult / Value)
		LevelsGained = levels,
		BagCount = Inventory.Used(data),
		BagCapacity = bagCapacity(data),
		Kept = stack ~= nil, -- false: bag full, the fish was released (still counts for Fishdex/XP)
		Treasure = treasure, -- bonus chest id or nil
		Bonus = bonus, -- Multi-Cast bonus fish: { {Entry, Value, New, Gems, Kept} } (their Gems are in Gems too)
	})
	if streak > 0 then
		fireStreak(player, streak, false)
	end
	FishingService.FishCaught:Fire(player, entry, mode, streak)
	return nil
end

-- MANUAL -----------------------------------------------------------------

local function onCast(player: Player, depth: any, dir: any, power: any, perfect: any)
	dir = flatDir(dir)
	if type(depth) ~= "number" or depth ~= depth or not dir or type(power) ~= "number" or power ~= power then
		return
	end
	local data = DataService.Get(player)
	local s = getState(player)
	if not data or s.Phase ~= "Idle" then
		return
	end
	local now = os.clock()
	if now - s.LastCast < GameConfig.CastCooldown then
		return
	end
	s.LastCast = now

	if Inventory.IsFull(data) then
		notify:FireClient(player, "Your bag is full! Sell your fish at the Merchant.", Color3.fromRGB(224, 100, 60))
		return
	end
	local root = rootOf(player)
	if not root then
		return
	end
	local stats = Stats.Compute(data)
	local point, locationId = castPoint(root, stats, dir, power)
	if not point then
		notify:FireClient(player, "Cast into the water!", Color3.fromRGB(224, 140, 60))
		return
	end

	local maxDepth = allowedDepth(data, stats, locationId)
	depth = math.clamp(math.floor(depth), 0, maxDepth)
	data.Settings.TargetDepth = depth

	local token = HttpService:GenerateGUID(false)
	s.Token = token
	s.Depth = depth
	s.LocationId = locationId
	s.Origin = root.Position
	s.HotLuck = HotspotService.Claim(point)
	setPhase(player, "Waiting", { Depth = depth })
	if s.HotLuck > 0 then
		notify:FireClient(player, `HOTSPOT!  +{math.floor(s.HotLuck * 100 + 0.5)}% luck on this cast`, Color3.fromRGB(201, 139, 30))
	end
	-- the client draws the bobber flying; the real one appears where it lands
	task.delay(GameConfig.Cast.FlightTime, function()
		if s.Token == token and not s.Bobber then
			s.Bobber = spawnBobber(player, point)
		end
	end)

	-- shortcut: the client reports Perfect (only shortens the bite wait); server-timed charge if it gets abused
	local perfectMult = if perfect == true then 1 - GameConfig.Cast.PerfectBiteBonus else 1
	local wait = rng:NextNumber(GameConfig.BiteWait[1], GameConfig.BiteWait[2]) * (1 - stats.Values.BiteSpeed) * perfectMult
	task.delay(wait, function()
		if s.Token ~= token or (s.Phase :: string) ~= "Waiting" then
			return
		end
		-- Tide event (C5): bobber inside the glowing patch = more luck + a chance at the event fish
		local luck = stats.Values.Luck + TideEventService.LuckBonus(player, point) + s.HotLuck
		local fishId = TideEventService.RollSpecial(player, point) or Roll.Fish(depth, locationId, luck, rng)
		if not fishId then
			notify:FireClient(player, `Nothing lives at {depth}m here. Try another depth.`, Color3.fromRGB(110, 120, 200))
			reset(player)
			return
		end
		s.Fish = fishId
		setPhase(player, "Bite", { Rarity = Registry.Fish[fishId].Rarity })
		Remotes.Event("Bite"):FireClient(player, token, { Rarity = Registry.Fish[fishId].Rarity })
		task.delay(GameConfig.BiteWindow, function()
			if s.Token == token and (s.Phase :: string) == "Bite" then
				notify:FireClient(player, "It got away... click faster when you see '!'", Color3.fromRGB(220, 100, 100))
				loseStreak(player)
				reset(player)
			end
		end)
	end)
end

local function onHook(player: Player, token: any)
	local s = getState(player)
	if s.Phase ~= "Bite" or token ~= s.Token or not s.Fish then
		return
	end
	local data = DataService.Get(player)
	local stats = Stats.Compute(data)
	local fish = Registry.Fish[s.Fish]
	local pattern = Registry.MinigamePatterns[fish.Pattern]

	s.ReelStart = os.clock()
	s.MinDuration = minDuration(stats)
	setPhase(player, "Reeling")
	Remotes.Event("StartMinigame"):FireClient(player, token, {
		FishName = "???",
		Rarity = fish.Rarity,
		Depth = s.Depth,
		Difficulty = fish.Difficulty,
		Pattern = fish.Pattern,
		PatternDef = pattern,
		CatchBarSize = stats.Values.CatchBarSize,
		ReelPower = stats.Values.ReelPower,
		Resilience = stats.Values.Resilience,
		FishStability = stats.Values.FishStability,
	})
end

local function onReelResult(player: Player, token: any, success: any, perfect: any)
	local s = getState(player)
	if s.Phase ~= "Reeling" or token ~= s.Token or not s.Fish then
		return
	end
	local elapsed = os.clock() - s.ReelStart
	local fishId = s.Fish :: string
	local depth = s.Depth
	local locationId = s.LocationId
	local hotspot = s.HotLuck > 0
	local legit = elapsed >= s.MinDuration * MG.ValidationSlack and elapsed <= MG.MaxDuration + 5
	reset(player)
	if success == true and legit then
		local mult = GameConfig.ManualMultiplier + (perfect == true and GameConfig.PerfectCatchBonus or 0)
		award(player, fishId, mult, "Manual", perfect == true, depth, locationId, hotspot)
	else
		if success == true and not legit then
			warn(`[FishingService] rejected suspicious reel from {player.Name} ({elapsed}s)`)
		end
		notify:FireClient(player, "The line snapped!", Color3.fromRGB(220, 90, 90))
		loseStreak(player)
	end
end

-- AUTO -------------------------------------------------------------------

local function autoLoop(player: Player, gen: number)
	local s = getState(player)
	local function running()
		return s.Phase == "Auto" and s.AutoGen == gen and player.Parent ~= nil
	end
	while running() do
		local data = DataService.Get(player)
		local root = rootOf(player)
		if not data or not root then
			break
		end
		if Inventory.IsFull(data) then
			notify:FireClient(player, "Bag full - Auto Fishing stopped. Sell your fish!", Color3.fromRGB(224, 100, 60))
			break
		end
		local stats = Stats.Compute(data)
		local point, locationId = castPoint(root, stats, s.AutoDir or root.CFrame.LookVector, GameConfig.Cast.TapPower)
		if not point then
			notify:FireClient(player, "Auto Fishing stopped: face the water.", Color3.fromRGB(224, 140, 60))
			break
		end
		local maxDepth = allowedDepth(data, stats, locationId)
		local depth = math.clamp(data.Settings.TargetDepth or 0, 0, maxDepth)
		clearBobber(s)
		s.Bobber = spawnBobber(player, point)

		local cycle = GameConfig.AutoCycleTime * (1 - stats.Values.AutoSpeed) * (1 - stats.Values.BiteSpeed * 0.5)
		task.wait(cycle)
		if not running() then
			return
		end
		local luck = stats.Values.Luck + TideEventService.LuckBonus(player, point)
		local fishId = TideEventService.RollSpecial(player, point) or Roll.Fish(depth, locationId, luck, rng)
		if fishId then
			award(player, fishId, stats.Values.AutoMultiplier, "Auto", nil, depth, locationId)
		end
	end
	if running() then
		s.Phase = "Idle"
		reset(player)
	end
end

local function onSetAuto(player: Player, enabled: any, dir: any)
	local s = getState(player)
	if enabled == true and s.Phase == "Idle" then
		local root = rootOf(player)
		local data = DataService.Get(player)
		dir = flatDir(dir) or (root and root.CFrame.LookVector)
		if not root or not data or not castPoint(root, Stats.Compute(data), dir, GameConfig.Cast.TapPower) then
			notify:FireClient(player, "Face the water to start Auto Fishing.", Color3.fromRGB(224, 140, 60))
			setPhase(player, "Idle") -- turns the client's AUTO button back off
			return
		end
		s.AutoDir = dir
		s.Origin = root.Position
		s.AutoGen += 1
		setPhase(player, "Auto")
		task.spawn(autoLoop, player, s.AutoGen)
	elseif enabled ~= true and s.Phase == "Auto" then
		s.Phase = "Idle"
		reset(player)
	end
end

-- Updates TargetDepth without casting (auto mode reads it).
function FishingService.SetTargetDepth(player: Player, depth: number)
	local data = DataService.Get(player)
	if data then
		data.Settings.TargetDepth = math.max(0, math.floor(depth))
	end
end

function FishingService.Init()
	notify = Remotes.Event("Notify")
	stateEvent = Remotes.Event("FishingState")

	Remotes.Event("Cast").OnServerEvent:Connect(onCast)
	Remotes.Event("Hook").OnServerEvent:Connect(onHook)
	Remotes.Event("ReelResult").OnServerEvent:Connect(onReelResult)
	Remotes.Event("CancelFishing").OnServerEvent:Connect(function(player)
		local s = getState(player)
		if s.Phase ~= "Auto" then
			reset(player)
		end
	end)
	Remotes.Event("SetAuto").OnServerEvent:Connect(onSetAuto)

	Players.PlayerRemoving:Connect(function(player)
		local s = states[player]
		if s then
			clearBobber(s)
			s.Phase = "Gone"
		end
		states[player] = nil
	end)

	-- Walking away cancels a manual cast and stops Auto.
	task.spawn(function()
		while true do
			task.wait(0.5)
			for player, s in states do
				if s.Phase == "Waiting" or s.Phase == "Bite" or s.Phase == "Auto" then
					local root = rootOf(player)
					if not root or (s.Origin and (root.Position - s.Origin).Magnitude > 8) then
						reset(player)
					end
				end
			end
		end
	end)
end

return FishingService
