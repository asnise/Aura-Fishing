-- Verifies Workspace.Map against what the game code expects (mirrors FishingService/ShopService/AuraService lookups).
local CollectionService = game:GetService("CollectionService")
local CAST = 14 -- GameConfig.CastDistance
local out, ok = {}, true
local function check(cond, msg) table.insert(out, (cond and "PASS " or "FAIL ") .. msg); if not cond then ok = false end end

local map = workspace:FindFirstChild("Map")
check(map ~= nil, "Workspace.Map exists (WorldBuilder will skip)")
local merchant = map and map:FindFirstChild("Merchant", true)
check(merchant and merchant:IsA("BasePart") and merchant:FindFirstChild("SellPrompt") and merchant.SellPrompt:IsA("ProximityPrompt"), "Merchant part + SellPrompt")
local altar = map and map:FindFirstChild("AuraAltar", true)
check(altar and altar:IsA("BasePart") and altar:FindFirstChild("RollPrompt") and altar.RollPrompt:IsA("ProximityPrompt"), "AuraAltar part + RollPrompt")
local spawns = 0
for _, d in map:GetDescendants() do if d:IsA("SpawnLocation") then spawns += 1 end end
check(spawns == 1, "one SpawnLocation")

local function zoneAt(point)
	for _, zone in CollectionService:GetTagged("FishingZone") do
		if zone:IsA("BasePart") then
			local l = zone.CFrame:PointToObjectSpace(point)
			local h = zone.Size / 2
			if math.abs(l.X) <= h.X and math.abs(l.Y) <= h.Y and math.abs(l.Z) <= h.Z then return zone:GetAttribute("LocationId") end
		end
	end
end
local function castFrom(pos, look)
	local target = pos + look.Unit * CAST
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = {}
	params.IgnoreWater = false
	local hit = workspace:Raycast(target + Vector3.new(0, 20, 0), Vector3.new(0, -60, 0), params)
	if not hit then return "no hit" end
	if hit.Material ~= Enum.Material.Water then return "hit " .. hit.Material.Name .. " (" .. hit.Instance.Name .. ")" end
	return zoneAt(hit.Position) or "water but no zone"
end
-- standing spots: end of each dock facing out, and the beach
local spots = {
	{ "EastDock end", Vector3.new(98, 8, 0), Vector3.new(1, 0, 0) },
	{ "WestDock end", Vector3.new(-88, 8, 0), Vector3.new(-1, 0, 0) },
	{ "SouthHarbor end", Vector3.new(0, 8, 88), Vector3.new(0, 0, 1) },
	{ "north beach", Vector3.new(0, 4, -74), Vector3.new(0, 0, -1) },
	{ "east beach (NE)", Vector3.new(52, 4, -52), Vector3.new(1, 0, -1) },
}
for _, s in spots do
	local r = castFrom(s[2], s[3])
	check(r == "StarterBay", s[1] .. " cast -> " .. tostring(r))
end
-- inland should NOT be fishable
local inland = castFrom(Vector3.new(0, 9, -10), Vector3.new(0, 0, -1))
check(inland ~= "StarterBay", "plaza is not fishable -> " .. tostring(inland))
-- spawn not buried
local sp = map.Plaza.Spawn
local up = workspace:Raycast(sp.Position + Vector3.new(0, 1, 0), Vector3.new(0, 10, 0))
check(up == nil, "nothing above spawn")
-- placeholders not buried in terrain
for _, s in map.FutureSlots:GetChildren() do
	if s:GetAttribute("Placeholder") then
		local r = workspace:Raycast(s.Position + Vector3.new(0, 30, 0), Vector3.new(0, -40, 0), RaycastParams.new())
		check(r == nil or r.Instance == s or r.Instance == workspace.Terrain and r.Position.Y <= s.Position.Y + 0.6 or r.Instance:IsDescendantOf(map), s.Name .. " on surface")
	end
end
return ok, table.concat(out, "\n")
