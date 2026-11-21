--!strict
-- Fish Hotspots (C26): bubbling patches of water that pop up near players standing by fishable water,
-- and fade after a while (GameConfig.Hotspot). A manual cast landing inside one gets LuckBonus for that
-- roll (FishingService.onCast -> Claim). Parts live in Workspace.Hotspots so everyone sees them; the
-- client tints its aim marker gold over one (attribute Radius).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Registry = require(Shared.Registry)
local FishingSpot = require(Shared.FishingSpot)

local CFG = Registry.GameConfig.Hotspot
local GOLD = Color3.fromRGB(242, 181, 68)

local HotspotService = {}

type Spot = { Part: BasePart, EndsAt: number, Uses: number }
local spots: { Spot } = {}
local rng = Random.new()

local function flatDist(a: Vector3, b: Vector3): number
	return Vector3.new(a.X - b.X, 0, a.Z - b.Z).Magnitude
end

local function folder(): Folder
	local f = Workspace:FindFirstChild("Hotspots")
	if not f then
		f = Instance.new("Folder")
		f.Name = "Hotspots"
		f.Parent = Workspace
	end
	return f :: Folder
end

local function build(point: Vector3): BasePart
	local disc = Instance.new("Part")
	disc.Name = "Hotspot"
	disc.Shape = Enum.PartType.Cylinder
	disc.Size = Vector3.new(0.2, CFG.Radius * 2, CFG.Radius * 2)
	disc.CFrame = CFrame.new(point + Vector3.new(0, 0.1, 0)) * CFrame.Angles(0, 0, math.pi / 2)
	disc.Color = GOLD
	disc.Material = Enum.Material.Neon
	disc.Transparency = 0.75
	disc.Anchored = true
	disc.CanCollide = false
	disc.CanQuery = false
	disc.CanTouch = false
	disc:SetAttribute("Radius", CFG.Radius)
	local att = Instance.new("Attachment")
	att.Parent = disc
	local pe = Instance.new("ParticleEmitter")
	pe.Color = ColorSequence.new(Color3.new(1, 1, 1))
	pe.Rate = 25
	pe.Lifetime = NumberRange.new(0.6, 1.2)
	pe.Speed = NumberRange.new(2, 4)
	pe.Size = NumberSequence.new(0.45, 0)
	pe.Transparency = NumberSequence.new(0.2, 1)
	pe.Shape = Enum.ParticleEmitterShape.Cylinder
	pe.EmissionDirection = Enum.NormalId.Right -- disc is rotated: +X = up
	pe.Parent = att
	disc.Parent = folder()
	return disc
end

local function free(point: Vector3): boolean
	for _, s in spots do
		if flatDist(s.Part.Position, point) < CFG.Radius * 3 then
			return false
		end
	end
	return true
end

local function remove(i: number)
	spots[i].Part:Destroy()
	table.remove(spots, i)
end

-- One new spot in the water near a random player who is by fishable water.
local function trySpawn()
	if #spots >= CFG.Max then
		return
	end
	local roots = {}
	for _, p in Players:GetPlayers() do
		local char = p.Character
		local root = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
		if root and FishingSpot.NearWater(root) then
			table.insert(roots, root)
		end
	end
	if #roots == 0 then
		return
	end
	local root = roots[rng:NextInteger(1, #roots)]
	for _ = 1, 10 do
		local a = rng:NextNumber() * math.pi * 2
		local point = FishingSpot.WaterAt(root, Vector3.new(math.cos(a), 0, math.sin(a)), rng:NextNumber(CFG.Distance[1], CFG.Distance[2]))
		if point and free(point) then
			table.insert(spots, { Part = build(point), EndsAt = os.clock() + rng:NextNumber(CFG.Lifetime[1], CFG.Lifetime[2]), Uses = CFG.Uses })
			return
		end
	end
end

-- Luck bonus for a manual cast landing at `point` (0 outside every spot). Uses up one charge of the spot.
function HotspotService.Claim(point: Vector3): number
	for i, s in spots do
		if flatDist(s.Part.Position, point) <= CFG.Radius then
			s.Uses -= 1
			if s.Uses <= 0 then
				remove(i)
			end
			return CFG.LuckBonus
		end
	end
	return 0
end

function HotspotService.Init()
	task.spawn(function()
		while true do
			task.wait(CFG.SpawnEvery)
			local t = os.clock()
			for i = #spots, 1, -1 do
				if t >= spots[i].EndsAt then
					remove(i)
				end
			end
			trySpawn()
		end
	end)
end

return HotspotService
