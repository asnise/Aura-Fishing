--!strict
-- Where can a player fish? Shared by the server (authoritative cast point) and the client
-- (hide CAST / DEPTH / AUTO when no fishable water is in reach).
-- Fishable water = Terrain/parts with Material Water inside a Part tagged "FishingZone"
-- (attribute LocationId, see Config/Locations.luau).

local CollectionService = game:GetService("CollectionService")
local Workspace = game:GetService("Workspace")

local Registry = require(script.Parent.Registry)

local GameConfig = Registry.GameConfig

local FishingSpot = {}

FishingSpot.Tag = "FishingZone"

-- Tagged parts that are part of the live world. CollectionService also returns tagged parts stored
-- outside Workspace (e.g. a map backup in ServerStorage): those must never count as fishable water,
-- authorise a cast, or host a tide event.
function FishingSpot.ActiveTagged(tag: string): { BasePart }
	local out = {}
	for _, inst in CollectionService:GetTagged(tag) do
		if inst:IsA("BasePart") and inst:IsDescendantOf(Workspace) then
			table.insert(out, inst)
		end
	end
	return out
end

-- Active FishingZone parts (in Workspace only).
function FishingSpot.Zones(): { BasePart }
	return FishingSpot.ActiveTagged(FishingSpot.Tag)
end

function FishingSpot.ZoneAt(point: Vector3): string?
	for _, zone in FishingSpot.Zones() do
		local localPos = zone.CFrame:PointToObjectSpace(point)
		local half = zone.Size / 2
		if math.abs(localPos.X) <= half.X and math.abs(localPos.Y) <= half.Y and math.abs(localPos.Z) <= half.Z then
			return zone:GetAttribute("LocationId") :: string?
		end
	end
	return nil
end

-- Water point + location id at `distance` studs from root along the flat direction `dir`.
function FishingSpot.WaterAt(root: BasePart, dir: Vector3, distance: number?): (Vector3?, string?)
	local flat = dir * Vector3.new(1, 0, 1)
	if flat.Magnitude < 0.01 then
		return nil, nil
	end
	local target = root.Position + flat.Unit * (distance or GameConfig.CastDistance)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { root.Parent :: Instance }
	params.IgnoreWater = false
	local hit = Workspace:Raycast(target + Vector3.new(0, 20, 0), Vector3.new(0, -60, 0), params)
	if not hit or hit.Material ~= Enum.Material.Water then
		return nil, nil
	end
	local loc = FishingSpot.ZoneAt(hit.Position)
	if not loc or not Registry.Locations[loc] then
		return nil, nil
	end
	return hit.Position, loc
end

-- Where the bobber lands if the player casts now (straight ahead).
function FishingSpot.CastPoint(root: BasePart): (Vector3?, string?)
	return FishingSpot.WaterAt(root, root.CFrame.LookVector)
end

-- True when the player could cast after turning to face some direction (8 directions, 2 ranges).
local DIRS = {}
for i = 0, 7 do
	local a = math.rad(i * 45)
	table.insert(DIRS, Vector3.new(math.cos(a), 0, math.sin(a)))
end
function FishingSpot.NearWater(root: BasePart): boolean
	if FishingSpot.CastPoint(root) then
		return true
	end
	for _, d in DIRS do
		if FishingSpot.WaterAt(root, d) or FishingSpot.WaterAt(root, d, GameConfig.CastDistance * 0.6) then
			return true
		end
	end
	return false
end

return FishingSpot
