--!strict
-- Tide events (C5): a random glowing patch of sea every :00 / :30 (UTC). Config: Config/TideEvents.
-- FishingService asks TideEventService.At(point) for every roll; inside the patch it adds LuckBonus
-- and may swap the fish for a special catch (RollSpecial). Crowd bonus = more players fishing there.
--
-- Remote "TideEvent" (server -> all): { Active, Id, Name, Center, Radius, EndsAt, NextStart, Anglers,
--   LuckBonus, Catches = { {Fish, Chance} } }   times = workspace:GetServerTimeNow() clock.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Registry = require(Shared.Registry)
local Remotes = require(Shared.Remotes)
local Signal = require(Shared.Util.Signal)
local FishingSpot = require(Shared.FishingSpot)

local CFG = Registry.TideEvents
local INTERVAL = Registry.Features.Events.IntervalMinutes * 60

local TideEventService = {}
TideEventService.SpecialCaught = Signal.new() -- (player, eventId, fishId)
TideEventService.Ended = Signal.new() -- (eventId)

type Active = {
	Id: string,
	Def: any,
	Center: Vector3,
	EndsAt: number,
	Model: Model,
	Anglers: { [Player]: number }, -- last time (os.clock) this player cast into the patch
}

local active: Active? = nil
local lastPeriod = -1
local warnedPeriod = -1
local rng = Random.new()
local stateEvent: RemoteEvent

local ANGLER_TIMEOUT = 30 -- seconds: a player counts as "fishing here" this long after a cast in the patch

local function now(): number
	return Workspace:GetServerTimeNow()
end

local function period(t: number): number
	return math.floor((t - CFG.OffsetSeconds) / INTERVAL)
end

local function nextStart(t: number): number
	return (period(t) + 1) * INTERVAL + CFG.OffsetSeconds
end

local function eventIdFor(p: number): string
	return CFG.Rotation[(p % #CFG.Rotation) + 1]
end

local function flat(v: Vector3): Vector3
	return Vector3.new(v.X, 0, v.Z)
end

local function anglerCount(a: Active): number
	local n = 0
	local t = os.clock()
	for p, last in a.Anglers do
		if p.Parent and t - last <= ANGLER_TIMEOUT then
			n += 1
		end
	end
	return n
end

local function snapshot(): any
	local a = active
	if not a then
		return { Active = false, NextStart = nextStart(now()) }
	end
	return {
		Active = true,
		Id = a.Id,
		Name = a.Def.Name,
		Center = a.Center,
		Radius = a.Def.Radius,
		EndsAt = a.EndsAt,
		NextStart = nextStart(now()),
		Anglers = anglerCount(a),
		LuckBonus = a.Def.LuckBonus,
		Catches = a.Def.Catches,
	}
end

local function broadcast()
	stateEvent:FireAllClients(snapshot())
end

-- Random open water: inside a FishingZone of def.Location, not under the boardwalk.
local function pickSpot(def: any): Vector3?
	local spawn = Workspace:FindFirstChildWhichIsA("SpawnLocation", true)
	local origin = if spawn then spawn.Position else Vector3.zero
	local params = RaycastParams.new()
	params.IgnoreWater = false
	for _ = 1, 60 do
		local a = rng:NextNumber() * math.pi * 2
		local d = rng:NextNumber(def.MinDistance, def.MaxDistance)
		local target = origin + Vector3.new(math.cos(a) * d, 0, math.sin(a) * d)
		local hit = Workspace:Raycast(Vector3.new(target.X, 120, target.Z), Vector3.new(0, -240, 0), params)
		if hit and hit.Material == Enum.Material.Water then
			for _, zone in FishingSpot.Zones() do -- Workspace only: a backup map in ServerStorage must not host the event
				if zone:GetAttribute("LocationId") == def.Location then
					local lp = zone.CFrame:PointToObjectSpace(hit.Position)
					local half = zone.Size / 2
					if math.abs(lp.X) <= half.X and math.abs(lp.Z) <= half.Z then
						return hit.Position
					end
				end
			end
		end
	end
	return nil
end

-- Glowing ring on the water (+ light and bubbles) so players can see it from the boardwalk.
local function buildMarker(def: any, center: Vector3): Model
	local m = Instance.new("Model")
	m.Name = "TideEvent"
	local disc = Instance.new("Part")
	disc.Name = "Glow"
	disc.Shape = Enum.PartType.Cylinder
	disc.Size = Vector3.new(0.3, def.Radius * 2, def.Radius * 2)
	disc.CFrame = CFrame.new(center + Vector3.new(0, 0.1, 0)) * CFrame.Angles(0, 0, math.pi / 2)
	disc.Color = def.Color
	disc.Material = Enum.Material.Neon
	disc.Transparency = 0.85
	disc.Anchored = true
	disc.CanCollide = false
	disc.CanQuery = false
	disc.CanTouch = false
	disc.Parent = m
	local beacon = Instance.new("Part")
	beacon.Name = "Beacon"
	beacon.Size = Vector3.new(1.5, 60, 1.5)
	beacon.CFrame = CFrame.new(center + Vector3.new(0, 30, 0))
	beacon.Color = def.Color
	beacon.Material = Enum.Material.Neon
	beacon.Transparency = 0.6
	beacon.Anchored = true
	beacon.CanCollide = false
	beacon.CanQuery = false
	beacon.CanTouch = false
	beacon.Parent = m
	local att = Instance.new("Attachment")
	att.Parent = disc
	local pe = Instance.new("ParticleEmitter")
	pe.Color = ColorSequence.new(def.Color)
	pe.Rate = 40
	pe.Lifetime = NumberRange.new(1.5, 2.5)
	pe.Speed = NumberRange.new(2, 5)
	pe.Size = NumberSequence.new(0.6, 0)
	pe.LightEmission = 1
	pe.Shape = Enum.ParticleEmitterShape.Cylinder
	pe.EmissionDirection = Enum.NormalId.Right -- disc is rotated: +X = up
	pe.Parent = att
	local light = Instance.new("PointLight")
	light.Color = def.Color
	light.Range = 60
	light.Brightness = 2
	light.Parent = beacon
	m.PrimaryPart = disc
	m.Parent = Workspace
	return m
end

local function compass(from: Vector3, to: Vector3): string
	local d = flat(to - from)
	local ang = math.deg(math.atan2(d.X, -d.Z)) % 360 -- 0 = north (-Z)
	local names = { "N", "NE", "E", "SE", "S", "SW", "W", "NW" }
	return names[(math.floor((ang + 22.5) / 45) % 8) + 1]
end

function TideEventService.Start(id: string?): (boolean, string)
	if active then
		return false, "An event is already active"
	end
	local eventId = id or eventIdFor(period(now()))
	local def = CFG.Events[eventId]
	if not def then
		return false, `unknown event {tostring(eventId)}`
	end
	local center = pickSpot(def)
	if not center then
		warn(`[TideEventService] no open water for {eventId}`)
		return false, "No open water found"
	end
	active = {
		Id = eventId,
		Def = def,
		Center = center,
		EndsAt = now() + def.Duration,
		Model = buildMarker(def, center),
		Anglers = {},
	}
	local spawn = Workspace:FindFirstChildWhichIsA("SpawnLocation", true)
	local where = if spawn then ` {math.floor(flat(center - spawn.Position).Magnitude)} studs {compass(spawn.Position, center)} of the plaza` else ""
	Remotes.Event("Notify"):FireAllClients(`{def.Name}! Glowing water{where} - fish there for a Naga!`, def.Color)
	broadcast()
	return true, `{eventId} at {math.floor(center.X)}, {math.floor(center.Z)}`
end

function TideEventService.Stop()
	local a = active
	if not a then
		return
	end
	active = nil
	a.Model:Destroy()
	Remotes.Event("Notify"):FireAllClients(`The {a.Def.Name} fades away...`, Color3.fromRGB(122, 138, 153))
	TideEventService.Ended:Fire(a.Id)
	broadcast()
end

function TideEventService.IsActive(): boolean
	return active ~= nil
end

-- Event at a bobber point, or nil. Also marks `player` as fishing there (crowd bonus).
function TideEventService.At(player: Player, point: Vector3?): any
	local a = active
	if not a or not point then
		return nil
	end
	if flat(point - a.Center).Magnitude > a.Def.Radius then
		return nil
	end
	a.Anglers[player] = os.clock()
	return a.Def
end

-- Luck bonus for a roll at `point` (0 outside).
function TideEventService.LuckBonus(player: Player, point: Vector3?): number
	local def = TideEventService.At(player, point)
	return if def then def.LuckBonus else 0
end

-- Maybe swap the fish for a special catch. Returns fishId or nil.
function TideEventService.RollSpecial(player: Player, point: Vector3?): string?
	local a = active
	local def = TideEventService.At(player, point)
	if not a or not def then
		return nil
	end
	local others = math.max(0, anglerCount(a) - 1)
	local crowd = 1 + math.min(def.CrowdBonusMax, others * def.CrowdBonusPerPlayer)
	for _, c in def.Catches do
		if rng:NextNumber() < c.Chance * crowd then
			TideEventService.SpecialCaught:Fire(player, a.Id, c.Fish)
			Remotes.Event("Notify"):FireAllClients(`{player.DisplayName} caught a {Registry.Fish[c.Fish].Name} in the {def.Name}!`, def.Color)
			return c.Fish
		end
	end
	return nil
end

function TideEventService.Init()
	stateEvent = Remotes.Event("TideEvent")
	Remotes.Event("ClientReady").OnServerEvent:Connect(function(player)
		stateEvent:FireClient(player, snapshot())
	end)
	Players.PlayerRemoving:Connect(function(player)
		if active then
			active.Anglers[player] = nil
		end
	end)

	task.spawn(function()
		lastPeriod = period(now()) -- do not start one that is already half over when the server boots
		local sinceBroadcast = 0
		while true do
			task.wait(1)
			sinceBroadcast += 1
			local t = now()
			local p = period(t)
			local ns = nextStart(t)
			if not active and ns - t <= CFG.WarnSeconds and warnedPeriod ~= p + 1 then
				warnedPeriod = p + 1
				local def = CFG.Events[eventIdFor(p + 1)]
				Remotes.Event("Notify"):FireAllClients(`The {def.Name} rises in {math.ceil(ns - t)} seconds...`, def.Color)
			end
			if not active and p ~= lastPeriod then
				lastPeriod = p
				if t - (p * INTERVAL + CFG.OffsetSeconds) < 10 then
					TideEventService.Start()
				end
			end
			if active then
				if t >= active.EndsAt then
					TideEventService.Stop()
				elseif sinceBroadcast >= 5 then
					sinceBroadcast = 0
					broadcast() -- angler count
				end
			end
		end
	end)
end

return TideEventService
