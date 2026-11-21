-- Builds the Starter Bay map in edit mode (run via Studio Bridge: run_luau with this file's text,
-- or `node scripts/build-map.mjs`). Re-running replaces Workspace.Map and the terrain.
--
-- Contract with game code (src/server):
--   Workspace.Map exists          -> WorldBuilder skips its runtime greybox
--   Map..Merchant (BasePart) + SellPrompt  -> ShopService sell
--   Map..AuraAltar (BasePart) + RollPrompt -> AuraService roll
--   Part tagged "FishingZone" + attribute LocationId (Config/Locations) over terrain water
--   SpawnLocation
-- Future systems get marker parts in Map.FutureSlots (attribute System = "...").

local CollectionService = game:GetService("CollectionService")
local Terrain = workspace.Terrain

local WATER_Y = 0 -- water surface height
local GROUND_Y = 6 -- island grass top (measured terrain surface)
local SEA = 640 -- sea size (studs)
local SEA_DEPTH = 44

-- Cozy Lake palette
local C = {
	wood = Color3.fromHex("A0714F"),
	woodDark = Color3.fromHex("7A5238"),
	plank = Color3.fromHex("C69C72"),
	cream = Color3.fromHex("FFF8EC"),
	sand = Color3.fromHex("F3E9D8"),
	coral = Color3.fromHex("FF9E80"),
	sky = Color3.fromHex("9AD4F5"),
	mint = Color3.fromHex("7FD3B0"),
	gold = Color3.fromHex("F2B544"),
	gem = Color3.fromHex("B79CF2"),
	text = Color3.fromHex("3D4B5C"),
	leaf = Color3.fromHex("8CCB7E"),
	leaf2 = Color3.fromHex("A9DB8F"),
	rock = Color3.fromHex("B8B2A7"),
}
local FONT = Font.new("rbxasset://fonts/families/FredokaOne.json")

local old = workspace:FindFirstChild("Map")
if old then
	old:Destroy()
end
Terrain:Clear()

local map = Instance.new("Model")
map.Name = "Map"
map:SetAttribute("BuiltBy", "tools/studio-mcp/maps/StarterBay.luau")

local function folder(name: string, parent: Instance): Folder
	local f = Instance.new("Folder")
	f.Name = name
	f.Parent = parent
	return f
end

local function part(props: { [string]: any }, parent: Instance): Part
	local p = Instance.new("Part")
	p.Anchored = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Material = Enum.Material.SmoothPlastic
	for k, v in props do
		(p :: any)[k] = v
	end
	p.Parent = parent
	return p
end

local function label(parent: BasePart, text: string, color: Color3, height: number?)
	local bb = Instance.new("BillboardGui")
	bb.Name = "Label"
	bb.Size = UDim2.fromOffset(220, 46)
	bb.StudsOffset = Vector3.new(0, (height or parent.Size.Y / 2) + 2, 0)
	bb.MaxDistance = 90
	bb.LightInfluence = 0
	local t = Instance.new("TextLabel")
	t.Size = UDim2.fromScale(1, 1)
	t.BackgroundTransparency = 1
	t.Text = text
	t.TextColor3 = color
	t.TextStrokeColor3 = C.text
	t.TextStrokeTransparency = 0.4
	t.FontFace = FONT
	t.TextScaled = true
	t.Parent = bb
	bb.Parent = parent
end

local function prompt(parent: BasePart, action: string, object: string, name: string)
	local pp = Instance.new("ProximityPrompt")
	pp.Name = name
	pp.ActionText = action
	pp.ObjectText = object
	pp.HoldDuration = 0
	pp.MaxActivationDistance = 12
	pp.RequiresLineOfSight = false
	pp.Parent = parent
end

---------------------------------------------------------------- terrain
-- Terrain snaps to a 4-stud voxel grid; these fills give: grass top y=6 (GROUND_Y), beach ~y=2 out to r~76,
-- water from there (top y=0). Re-measure with maps/verify.luau if you change them.
Terrain:FillBlock(CFrame.new(0, WATER_Y - SEA_DEPTH - 4, 0), Vector3.new(SEA, 8, SEA), Enum.Material.Sand)
Terrain:FillBlock(CFrame.new(0, WATER_Y - SEA_DEPTH / 2, 0), Vector3.new(SEA, SEA_DEPTH, SEA), Enum.Material.Water)
-- underwater shelf so the shallows look turquoise, then beach, then grass
Terrain:FillCylinder(CFrame.new(0, WATER_Y - 26, 0), 40, 100, Enum.Material.Sand)
Terrain:FillCylinder(CFrame.new(0, WATER_Y - 20, 0), 41, 80, Enum.Material.Sand)
Terrain:FillCylinder(CFrame.new(0, -2, 0), 8, 62, Enum.Material.Grass)
-- dirt paths: repaint the grass surface (regions must be on the 4-stud grid)
local function path(x0: number, z0: number, x1: number, z1: number)
	Terrain:ReplaceMaterial(Region3.new(Vector3.new(x0, 0, z0), Vector3.new(x1, 8, z1)), 4, Enum.Material.Grass, Enum.Material.Ground)
end
path(-60, -4, 60, 4) -- west dock <-> east dock
path(-4, 0, 4, 60) -- plaza -> south harbor
path(-4, -28, 4, 0) -- plaza -> quest board
-- small rocky islet behind the future boss arena
Terrain:FillBall(Vector3.new(0, WATER_Y - 6, -250), 14, Enum.Material.Rock)
Terrain:FillBall(Vector3.new(10, WATER_Y - 4, -244), 8, Enum.Material.Rock)

---------------------------------------------------------------- spawn + plaza
local plaza = folder("Plaza", map)
local spawn = Instance.new("SpawnLocation")
spawn.Name = "Spawn"
spawn.Anchored = true
spawn.Size = Vector3.new(10, 1, 10)
spawn.Position = Vector3.new(0, GROUND_Y + 0.5, 0)
spawn.Color = C.sand
spawn.Material = Enum.Material.SmoothPlastic
spawn.Neutral = true
spawn.Duration = 0
spawn.Parent = plaza
local decal = spawn:FindFirstChildOfClass("Decal")
if decal then
	decal:Destroy()
end

local lamps = folder("Lamps", plaza)
local function lamp(pos: Vector3)
	part({ Name = "Pole", Size = Vector3.new(0.6, 9, 0.6), Position = pos + Vector3.new(0, 4.5, 0), Color = C.woodDark, Material = Enum.Material.Wood }, lamps)
	local head = part({ Name = "Lantern", Shape = Enum.PartType.Ball, Size = Vector3.new(1.8, 1.8, 1.8), Position = pos + Vector3.new(0, 9.4, 0), Color = Color3.fromHex("FFE3A8"), Material = Enum.Material.Neon }, lamps)
	local light = Instance.new("PointLight")
	light.Color = Color3.fromHex("FFD9A0")
	light.Range = 18
	light.Brightness = 1.2
	light.Parent = head
end
for _, p in { Vector3.new(10, GROUND_Y, 5), Vector3.new(-10, GROUND_Y, 5), Vector3.new(10, GROUND_Y, -5), Vector3.new(-10, GROUND_Y, -5), Vector3.new(38, GROUND_Y, 6), Vector3.new(-38, GROUND_Y, 6), Vector3.new(4, GROUND_Y, 40) } do
	lamp(p)
end

---------------------------------------------------------------- docks (fishing spots)
local docks = folder("Docks", map)
local function dock(name: string, startX: number, dir: number, z: number, length: number)
	local m = Instance.new("Model")
	m.Name = name
	m.Parent = docks
	local cx = startX + dir * length / 2
	part({ Name = "Deck", Size = Vector3.new(length, 1, 10), Position = Vector3.new(cx, GROUND_Y - 0.5, z), Color = C.plank, Material = Enum.Material.WoodPlanks }, m)
	for i = 0, math.floor(length / 10) do
		local x = startX + dir * (5 + i * 10)
		if math.abs(x - startX) <= length then
			for _, dz in { -4.6, 4.6 } do
				part({ Name = "Post", Size = Vector3.new(1, 18, 1), Position = Vector3.new(x, GROUND_Y - 9, z + dz), Color = C.woodDark, Material = Enum.Material.Wood }, m)
				part({ Name = "Rail", Size = Vector3.new(0.6, 3, 0.6), Position = Vector3.new(x, GROUND_Y + 1.5, z + dz), Color = C.wood, Material = Enum.Material.Wood }, m)
			end
		end
	end
	for _, dz in { -4.6, 4.6 } do
		part({ Name = "Handrail", Size = Vector3.new(length - 6, 0.4, 0.4), Position = Vector3.new(cx - dir * 3, GROUND_Y + 2.8, z + dz), Color = C.wood, Material = Enum.Material.Wood }, m)
	end
	-- fishing spot markers along the end of the dock (for future spot-based features)
	local spots = folder("FishingSpots", m)
	for i, dzz in { -3, 0, 3 } do
		local s = part({ Name = "Spot" .. i, Size = Vector3.new(2, 0.2, 2), Position = Vector3.new(startX + dir * (length - 1.5), GROUND_Y + 0.1, z + dzz), Color = C.sky, Transparency = 0.5, CanCollide = false, CanQuery = false, CanTouch = false }, spots)
		s.Orientation = Vector3.new(0, dir > 0 and -90 or 90, 0) -- face the water
	end
	return m
end
dock("EastDock", 54, 1, 0, 46)
dock("WestDock", -54, -1, 0, 36)
dock("SouthHarbor", 0, 1, 66, 1) -- placeholder, rebuilt below
-- South harbor: a pier pointing +Z (future boat to the next island)
local harbor = docks:FindFirstChild("SouthHarbor") :: Model
harbor:ClearAllChildren()
part({ Name = "Deck", Size = Vector3.new(12, 1, 36), Position = Vector3.new(0, GROUND_Y - 0.5, 72), Color = C.plank, Material = Enum.Material.WoodPlanks }, harbor)
for _, z in { 62, 72, 82 } do
	for _, x in { -5.6, 5.6 } do
		part({ Name = "Post", Size = Vector3.new(1, 18, 1), Position = Vector3.new(x, GROUND_Y - 9, z), Color = C.woodDark, Material = Enum.Material.Wood }, harbor)
	end
end

---------------------------------------------------------------- merchant (sell)
local stall = Instance.new("Model")
stall.Name = "MerchantStall"
stall.Parent = map
local sx, sz = 24, 16
local counter = part({ Name = "Merchant", Size = Vector3.new(10, 3.5, 4), Position = Vector3.new(sx, GROUND_Y + 1.75, sz), Color = C.wood, Material = Enum.Material.Wood }, stall)
counter.Orientation = Vector3.new(0, 30, 0)
label(counter, "Fish Merchant", C.gold, 7)
prompt(counter, "Sell All Fish", "Merchant", "SellPrompt")
for _, off in { Vector3.new(-4.5, 0, -3), Vector3.new(4.5, 0, -3), Vector3.new(-4.5, 0, 1.5), Vector3.new(4.5, 0, 1.5) } do
	local p = counter.CFrame * CFrame.new(off.X, 2.5, off.Z)
	part({ Name = "Pillar", Size = Vector3.new(0.6, 8.5, 0.6), CFrame = p, Color = C.woodDark, Material = Enum.Material.Wood }, stall)
end
for i = 0, 3 do
	part({ Name = "Awning", Size = Vector3.new(2.6, 0.4, 6.4), CFrame = counter.CFrame * CFrame.new(-3.9 + i * 2.6, 6.9, -0.8) * CFrame.Angles(math.rad(-12), 0, 0), Color = i % 2 == 0 and C.coral or C.cream }, stall)
end
local crate = part({ Name = "FishCrate", Size = Vector3.new(3, 2, 3), CFrame = counter.CFrame * CFrame.new(-7, -0.75, 1), Color = C.plank, Material = Enum.Material.WoodPlanks }, stall)
part({ Name = "Ice", Size = Vector3.new(2.6, 0.3, 2.6), CFrame = crate.CFrame * CFrame.new(0, 1, 0), Color = C.sky, Material = Enum.Material.Ice }, stall)

---------------------------------------------------------------- aura altar (roll)
local shrine = Instance.new("Model")
shrine.Name = "AuraShrine"
shrine.Parent = map
local ax, az = -24, 16
part({ Name = "Base", Shape = Enum.PartType.Cylinder, Size = Vector3.new(1, 14, 14), CFrame = CFrame.new(ax, GROUND_Y + 0.5, az) * CFrame.Angles(0, 0, math.rad(90)), Color = C.cream }, shrine)
part({ Name = "Step", Shape = Enum.PartType.Cylinder, Size = Vector3.new(1, 10, 10), CFrame = CFrame.new(ax, GROUND_Y + 1.5, az) * CFrame.Angles(0, 0, math.rad(90)), Color = C.sand }, shrine)
local altar = part({ Name = "AuraAltar", Shape = Enum.PartType.Cylinder, Size = Vector3.new(3, 5, 5), CFrame = CFrame.new(ax, GROUND_Y + 3.5, az) * CFrame.Angles(0, 0, math.rad(90)), Color = C.gem, Material = Enum.Material.Neon }, shrine)
label(altar, "Aura Altar", Color3.fromHex("E3D6FF"), 6)
prompt(altar, "Roll Aura", "Altar", "RollPrompt")
local crystal = part({ Name = "Crystal", Size = Vector3.new(2, 4, 2), CFrame = CFrame.new(ax, GROUND_Y + 8, az) * CFrame.Angles(0, math.rad(45), math.rad(45)), Color = C.gem, Material = Enum.Material.Glass, Transparency = 0.2, CanCollide = false }, shrine)
local glow = Instance.new("PointLight")
glow.Color = C.gem
glow.Range = 16
glow.Brightness = 1.5
glow.Parent = crystal
for i = 0, 5 do
	local a = math.rad(i * 60)
	part({ Name = "Pillar", Size = Vector3.new(0.8, 5, 0.8), Position = Vector3.new(ax + math.cos(a) * 6, GROUND_Y + 3.5, az + math.sin(a) * 6), Color = C.cream }, shrine)
end

---------------------------------------------------------------- fishing zone
local zones = folder("FishingZones", map)
local zone = part({
	Name = "FishingZone_StarterBay",
	Size = Vector3.new(SEA, SEA_DEPTH + 20, SEA),
	Position = Vector3.new(0, WATER_Y - SEA_DEPTH / 2 + 5, 0),
	Transparency = 1,
	CanCollide = false,
	CanQuery = false,
	CanTouch = false,
	Locked = true,
}, zones)
zone:SetAttribute("LocationId", "StarterBay")
CollectionService:AddTag(zone, "FishingZone")

---------------------------------------------------------------- future system slots
local future = folder("FutureSlots", map)
local function slot(name: string, system: string, pos: Vector3, size: Vector3, color: Color3, text: string)
	local s = part({ Name = name, Size = size, Position = pos, Color = color, Transparency = 0.35, CanCollide = false, CanQuery = false, CanTouch = false }, future)
	s:SetAttribute("System", system)
	s:SetAttribute("Placeholder", true)
	label(s, text, color, size.Y / 2)
	return s
end
slot("ShopSlot", "Shop", Vector3.new(24, GROUND_Y + 0.25, -16), Vector3.new(12, 0.5, 8), C.coral, "Rod Shop (soon)")
slot("QuestBoardSlot", "Quests", Vector3.new(0, GROUND_Y + 0.25, -30), Vector3.new(8, 0.5, 4), C.mint, "Quest Board (soon)")
slot("RebirthShrineSlot", "Rebirth", Vector3.new(-24, GROUND_Y + 0.25, -16), Vector3.new(10, 0.5, 10), C.gold, "Rebirth Shrine (soon)")
slot("LeaderboardSlot", "Leaderboards", Vector3.new(-6, GROUND_Y + 0.25, -46), Vector3.new(14, 0.5, 3), C.sky, "Leaderboards (soon)")
slot("BoatSlot", "Travel", Vector3.new(0, WATER_Y + 0.5, 92), Vector3.new(10, 1, 18), C.sky, "Boat to next island (soon)")
local arena = slot("BossArenaSlot", "Boss", Vector3.new(0, WATER_Y + 0.25, -190), Vector3.new(90, 0.5, 90), C.coral, "Boss Arena (soon)")
arena.Transparency = 0.85
-- buoy ring around the arena
for i = 0, 11 do
	local a = math.rad(i * 30)
	local b = part({ Name = "Buoy", Shape = Enum.PartType.Ball, Size = Vector3.new(2.4, 2.4, 2.4), Position = Vector3.new(math.cos(a) * 45, WATER_Y + 0.6, -190 + math.sin(a) * 45), Color = i % 2 == 0 and C.coral or C.cream }, future)
	b:SetAttribute("Decoration", true)
end

---------------------------------------------------------------- nature
local nature = folder("Nature", map)
local rng = Random.new(7)
local function tree(pos: Vector3, scale: number)
	local m = Instance.new("Model")
	m.Name = "Tree"
	m.Parent = nature
	local h = 9 * scale
	part({ Name = "Trunk", Size = Vector3.new(1.4 * scale, h, 1.4 * scale), Position = pos + Vector3.new(0, h / 2, 0), Color = C.wood, Material = Enum.Material.Wood }, m)
	for i = 1, 3 do
		local r = (5 - i) * 1.6 * scale
		part({ Name = "Leaves", Shape = Enum.PartType.Ball, Size = Vector3.new(r * 2, r * 2, r * 2), Position = pos + Vector3.new(rng:NextNumber(-1, 1), h + (i - 1) * 2.2 * scale, rng:NextNumber(-1, 1)), Color = i % 2 == 0 and C.leaf2 or C.leaf, Material = Enum.Material.SmoothPlastic }, m)
	end
end
local function clearOf(p: Vector3): boolean
	if math.abs(p.Z) < 9 then return false end -- east/west path
	if math.abs(p.X) < 9 and p.Z > 0 then return false end -- harbor path
	for _, c in { Vector3.new(24, 0, 16), Vector3.new(-24, 0, 16), Vector3.new(24, 0, -16), Vector3.new(-24, 0, -16), Vector3.new(0, 0, -30), Vector3.new(0, 0, 0), Vector3.new(-6, 0, -46) } do
		if (Vector3.new(p.X, 0, p.Z) - c).Magnitude < 14 then return false end
	end
	return true
end
local placed = 0
local tries = 0
while placed < 26 and tries < 400 do
	tries += 1
	local a = rng:NextNumber(0, math.pi * 2)
	local r = rng:NextNumber(26, 50)
	local p = Vector3.new(math.cos(a) * r, GROUND_Y, math.sin(a) * r)
	if clearOf(p) then
		tree(p, rng:NextNumber(0.8, 1.3))
		placed += 1
	end
end
for _ = 1, 14 do
	local a = rng:NextNumber(0, math.pi * 2)
	local r = rng:NextNumber(70, 80)
	local p = Vector3.new(math.cos(a) * r, WATER_Y + 1, math.sin(a) * r)
	if math.abs(p.Z) > 8 and not (math.abs(p.X) < 9 and p.Z > 0) then
		local s = rng:NextNumber(2, 4.5)
		local rock = part({ Name = "Rock", Shape = Enum.PartType.Ball, Size = Vector3.new(s * 1.4, s, s * 1.2), Position = p, Color = C.rock, Material = Enum.Material.Slate }, nature)
		rock.Orientation = Vector3.new(0, rng:NextNumber(0, 360), 0)
	end
end
local flowerColors = { C.coral, C.gold, C.gem, C.cream }
for _ = 1, 40 do
	local a = rng:NextNumber(0, math.pi * 2)
	local r = rng:NextNumber(14, 50)
	local p = Vector3.new(math.cos(a) * r, GROUND_Y + 0.3, math.sin(a) * r)
	if clearOf(p) then
		part({ Name = "Flower", Shape = Enum.PartType.Ball, Size = Vector3.new(0.8, 0.8, 0.8), Position = p, Color = flowerColors[rng:NextInteger(1, #flowerColors)], CanCollide = false, CanQuery = false }, nature)
	end
end

map.PrimaryPart = spawn
map.Parent = workspace

local count = #map:GetDescendants()
return string.format("Map built: %d instances, %d trees, sea %dx%d, water top y=%d", count, placed, SEA, SEA, WATER_Y)
