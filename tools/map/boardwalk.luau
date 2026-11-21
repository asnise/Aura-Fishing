--!nonstrict
-- The game map "Stilt Boardwalk": raised wooden boardwalk on stilts over a wide open sea (no houses).
-- Run in Studio EDIT mode:  node tools/studio-mcp/scripts/run-file.mjs tools/map/boardwalk.luau --timeout=300
-- Builds workspace.Map (+ terrain sea) around ORIGIN. Re-running rebuilds it from scratch, but KEEPS the
-- gameplay buildings (BUILDINGS below: MerchantStall with "Merchant"+SellPrompt, AuraShrine with
-- "AuraAltar"+RollPrompt — ShopService/AuraService look them up by name) and moves them onto their slots.
-- Fishing: a FishingZone (LocationId StarterBay) covers the sea. Sea edge: Edge.PlayArea (Shared/PlayArea).

local CollectionService = game:GetService("CollectionService")

local ORIGIN = Vector3.new(0, 0, 0)
local DECK = 3 -- top of the boardwalk (water surface = 0); was 9 (too high above the water)
local SEA = 1000 -- half size of the sea (2000 x 2000 studs)
local LAGOON_TOP = -14 -- shallow sandy floor under the boardwalk
local SOFT = 560 -- buoy line: past this a current pushes swimmers back (Shared/PlayArea)
local HARD = 680 -- reef: the current beats swimming speed here

local WOOD = Color3.fromRGB(196, 152, 104)
local WOOD_DARK = Color3.fromRGB(122, 88, 60)
local WOOD_RAIL = Color3.fromRGB(165, 122, 82)
local ROPE = Color3.fromRGB(214, 190, 140)
local LANTERN = Color3.fromRGB(255, 196, 110)

local rng = Random.new(7)

-- rebuild ---------------------------------------------------------------------------------------
-- buildings carried over between rebuilds: name -> { slot x, z, rotation }
local BUILDINGS = {
	MerchantStall = { 13, -14, math.pi },
	AuraShrine = { -14, -14, 0 },
}
local kept = {}
for name in BUILDINGS do
	for _, mapName in { "Map", "Map_Boardwalk" } do
		local m = workspace:FindFirstChild(mapName)
		local b = m and m:FindFirstChild(name, true)
		if b and not kept[name] then
			b.Parent = nil
			kept[name] = b
		end
	end
end
for _, mapName in { "Map", "Map_Boardwalk" } do
	local m = workspace:FindFirstChild(mapName)
	if m then
		m:Destroy()
	end
end
local root = Instance.new("Model")
root.Name = "Map"

local folders = {}
local function folder(name: string): Folder
	if not folders[name] then
		local f = Instance.new("Folder")
		f.Name = name
		f.Parent = root
		folders[name] = f
	end
	return folders[name]
end

local function P(o: Vector3): Vector3
	return ORIGIN + o
end

local function part(props: { [string]: any }, parent: Instance): BasePart
	local p = Instance.new(props.ClassName or "Part")
	p.Anchored = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Material = Enum.Material.Wood
	for k, v in props do
		if k ~= "ClassName" then
			p[k] = v
		end
	end
	p.Parent = parent
	return p
end

local function vary(c: Color3, amt: number): Color3
	local h, s, v = c:ToHSV()
	return Color3.fromHSV(h, s, math.clamp(v + rng:NextNumber(-amt, amt), 0, 1))
end

-- vertical cylinder from y0 to y1
local function post(x: number, z: number, y0: number, y1: number, d: number, color: Color3, parent: Instance, name: string?)
	local h = y1 - y0
	return part({
		Name = name or "Stilt",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(h, d, d),
		CFrame = CFrame.new(P(Vector3.new(x, y0 + h / 2, z))) * CFrame.Angles(0, 0, math.pi / 2),
		Color = color,
	}, parent)
end

-- terrain: wide sea ------------------------------------------------------------------------------
local T = workspace.Terrain
local function fill(cx: number, cz: number, sx: number, sz: number, y0: number, y1: number, mat: Enum.Material)
	T:FillBlock(CFrame.new(P(Vector3.new(cx, (y0 + y1) / 2, cz))), Vector3.new(sx, y1 - y0, sz), mat)
end
local TILE = 500
-- clear a margin beyond the sea too (old island terrain reached ~1022 studs out)
local CLEAR = SEA + 100
for x = -CLEAR, CLEAR - 1, 2 * CLEAR / 4 do
	for z = -CLEAR, CLEAR - 1, 2 * CLEAR / 4 do
		fill(x + CLEAR / 4, z + CLEAR / 4, CLEAR / 2, CLEAR / 2, -80, 160, Enum.Material.Air)
		task.wait()
	end
end
for x = -SEA, SEA - TILE, TILE do
	for z = -SEA, SEA - TILE, TILE do
		fill(x + TILE / 2, z + TILE / 2, TILE, TILE, -64, -48, Enum.Material.Sand) -- deep floor
		fill(x + TILE / 2, z + TILE / 2, TILE, TILE, -48, 0, Enum.Material.Water)
		task.wait()
	end
end
-- shallow turquoise lagoon under the boardwalk, sloping down to the deep sea
for i, ring in { { 360, -40 }, { 300, -30 }, { 250, -20 }, { 215, LAGOON_TOP } } do
	local r, top = ring[1], ring[2]
	T:FillCylinder(CFrame.new(P(Vector3.new(0, (-48 + top) / 2, 0))), top + 48, r, Enum.Material.Sand)
	task.wait()
end
-- sand dunes + a few rocks on the lagoon floor
for _ = 1, 40 do
	local a, d = rng:NextNumber(0, math.pi * 2), rng:NextNumber(30, 330)
	T:FillBall(P(Vector3.new(math.cos(a) * d, LAGOON_TOP - 6, math.sin(a) * d)), rng:NextNumber(6, 14), Enum.Material.Sand)
end
for _ = 1, 14 do
	local a, d = rng:NextNumber(0, math.pi * 2), rng:NextNumber(120, 340)
	T:FillBall(P(Vector3.new(math.cos(a) * d, LAGOON_TOP - 2, math.sin(a) * d)), rng:NextNumber(3, 7), Enum.Material.Rock)
end
-- distant sandbar islets on the horizon
local islets = { Vector3.new(520, 0, -420), Vector3.new(-640, 0, -260), Vector3.new(-380, 0, 560), Vector3.new(700, 0, 380) }
for _, c in islets do
	T:FillCylinder(CFrame.new(P(c + Vector3.new(0, -24, 0))), 50, 46, Enum.Material.Sand)
	T:FillBall(P(c + Vector3.new(0, -12, 0)), 30, Enum.Material.Sand)
	T:FillBall(P(c + Vector3.new(8, -6, 4)), 16, Enum.Material.Grass)
end
-- sea rocks poking out of the water
for _ = 1, 10 do
	local a, d = rng:NextNumber(0, math.pi * 2), rng:NextNumber(380, 900)
	T:FillBall(P(Vector3.new(math.cos(a) * d, -2, math.sin(a) * d)), rng:NextNumber(6, 12), Enum.Material.Rock)
end
task.wait()

-- boardwalk -------------------------------------------------------------------------------------
local deckF, stiltF, railF = folder("Deck"), folder("Stilts"), folder("Rails")
local STILT_BOTTOM = LAGOON_TOP - 4

-- a deck rectangle (center x,z / size sx,sz) on stilts with trim beams
local function deck(name: string, cx: number, cz: number, sx: number, sz: number, y: number?)
	local top = y or DECK
	part({
		Name = name,
		Material = Enum.Material.WoodPlanks,
		Size = Vector3.new(sx, 1, sz),
		CFrame = CFrame.new(P(Vector3.new(cx, top - 0.5, cz))),
		Color = vary(WOOD, 0.04),
	}, deckF)
	-- edge trim (darker beam under the deck edge)
	for _, e in { { 0, -sz / 2, sx, 0.8 }, { 0, sz / 2, sx, 0.8 }, { -sx / 2, 0, 0.8, sz }, { sx / 2, 0, 0.8, sz } } do
		part({
			Name = "Trim",
			Size = Vector3.new(e[3], 1, e[4]),
			CFrame = CFrame.new(P(Vector3.new(cx + e[1], top - 1.3, cz + e[2]))),
			Color = WOOD_DARK,
		}, deckF)
	end
	-- stilts every ~10 studs along the edges + cross beams
	local nx, nz = math.max(1, math.round(sx / 10)), math.max(1, math.round(sz / 10))
	for i = 0, nx do
		for j = 0, nz do
			if i == 0 or j == 0 or i == nx or j == nz then
				local x = cx - sx / 2 + 0.8 + (sx - 1.6) * i / nx
				local z = cz - sz / 2 + 0.8 + (sz - 1.6) * j / nz
				post(x, z, STILT_BOTTOM, top - 1, 1.6, vary(WOOD_DARK, 0.05), stiltF)
			end
		end
	end
	for j = 0, nz do
		local z = cz - sz / 2 + 0.8 + (sz - 1.6) * j / nz
		part({ Name = "Brace", Size = Vector3.new(sx - 1, 0.7, 0.7), CFrame = CFrame.new(P(Vector3.new(cx, math.min(2.2, top - 1.8), z))), Color = WOOD_DARK }, stiltF)
	end
end

-- rail along a straight edge (a -> b, deck height), skipping gaps {from, to} measured along the edge
local function rail(ax: number, az: number, bx: number, bz: number, gaps: { { number } }?, top: number?)
	local y = top or DECK
	local a, b = Vector3.new(ax, 0, az), Vector3.new(bx, 0, bz)
	local len = (b - a).Magnitude
	local dir = (b - a).Unit
	local pieces = { { 0, len } }
	for _, g in gaps or {} do
		local nextPieces = {}
		for _, pc in pieces do
			if g[2] <= pc[1] or g[1] >= pc[2] then
				table.insert(nextPieces, pc)
			else
				if g[1] > pc[1] then
					table.insert(nextPieces, { pc[1], g[1] })
				end
				if g[2] < pc[2] then
					table.insert(nextPieces, { g[2], pc[2] })
				end
			end
		end
		pieces = nextPieces
	end
	for _, pc in pieces do
		local l = pc[2] - pc[1]
		if l >= 1 then
			local s = a + dir * pc[1]
			local n = math.max(1, math.round(l / 8))
			for i = 0, n do
				local p = s + dir * (l * i / n)
				part({ Name = "RailPost", Size = Vector3.new(0.6, 3, 0.6), CFrame = CFrame.new(P(Vector3.new(p.X, y + 1.5, p.Z))), Color = WOOD_RAIL }, railF)
			end
			local mid = s + dir * (l / 2)
			local cf = CFrame.lookAt(P(Vector3.new(mid.X, y + 2.9, mid.Z)), P(Vector3.new(mid.X, y + 2.9, mid.Z) + dir))
			part({ Name = "Handrail", Size = Vector3.new(0.5, 0.35, l), CFrame = cf, Color = WOOD_RAIL }, railF)
			part({ Name = "Rope", Material = Enum.Material.Fabric, Size = Vector3.new(0.25, 0.25, l), CFrame = cf - Vector3.new(0, 1.3, 0), Color = ROPE }, railF)
		end
	end
end

-- rails around a rectangle; openings = { N = {{from,to}}, S = ..., E = ..., W = ... } in local edge coords (0..size)
local function railRect(cx: number, cz: number, sx: number, sz: number, openings: { [string]: { { number } } }, top: number?)
	local x0, x1, z0, z1 = cx - sx / 2 + 0.3, cx + sx / 2 - 0.3, cz - sz / 2 + 0.3, cz + sz / 2 - 0.3
	rail(x0, z0, x1, z0, openings.N, top)
	rail(x0, z1, x1, z1, openings.S, top)
	rail(x1, z0, x1, z1, openings.E, top)
	rail(x0, z0, x0, z1, openings.W, top)
end

local W = 8 -- walkway width
local function centreGap(size: number): { { number } }
	return { { size / 2 - W / 2, size / 2 + W / 2 } }
end

-- HUB (spawn plaza)
local HUB = 44
deck("Hub", 0, 0, HUB, HUB)
railRect(0, 0, HUB, HUB, { N = centreGap(HUB), S = centreGap(HUB), E = centreGap(HUB), W = centreGap(HUB) })

-- straight walkways + platforms. walkway(name, from, to) along an axis; rails on both long sides
local function walkway(name: string, x0: number, z0: number, x1: number, z1: number, sideGaps: { [string]: { { number } } }?)
	local cx, cz = (x0 + x1) / 2, (z0 + z1) / 2
	local alongX = math.abs(x1 - x0) > math.abs(z1 - z0)
	local len = if alongX then math.abs(x1 - x0) else math.abs(z1 - z0)
	local sx, sz = if alongX then len else W, if alongX then W else len
	deck(name, cx, cz, sx, sz)
	local g = sideGaps or {}
	if alongX then
		rail(cx - len / 2, cz - W / 2 + 0.3, cx + len / 2, cz - W / 2 + 0.3, g.A)
		rail(cx - len / 2, cz + W / 2 - 0.3, cx + len / 2, cz + W / 2 - 0.3, g.B)
	else
		rail(cx - W / 2 + 0.3, cz - len / 2, cx - W / 2 + 0.3, cz + len / 2, g.A)
		rail(cx + W / 2 - 0.3, cz - len / 2, cx + W / 2 - 0.3, cz + len / 2, g.B)
	end
end

local END = 28 -- end fishing platform size
local SIDE = 16 -- side fishing platform size

-- North: hub -> long pier -> North Point, with a side platform on the east
walkway("Walk_N", 0, -HUB / 2, 0, -150, { B = { { 150 - 86 - SIDE / 2, 150 - 86 + SIDE / 2 } } })
deck("NorthPoint", 0, -150 - END / 2, END, END)
railRect(0, -150 - END / 2, END, END, { S = centreGap(END) })
deck("Spot_N1", W / 2 + SIDE / 2, -86, SIDE, SIDE)
railRect(W / 2 + SIDE / 2, -86, SIDE, SIDE, { W = { { SIDE / 2 - W / 2 - 4, SIDE / 2 + W / 2 + 4 } } })

-- East: hub -> East Point, side platform to the south
walkway("Walk_E", HUB / 2, 0, 140, 0, { B = { { 82 - 22 - SIDE / 2, 82 - 22 + SIDE / 2 } } })
deck("EastPoint", 140 + END / 2, 0, END, END)
railRect(140 + END / 2, 0, END, END, { W = centreGap(END) })
deck("Spot_E1", 82, W / 2 + SIDE / 2, SIDE, SIDE)
railRect(82, W / 2 + SIDE / 2, SIDE, SIDE, { N = { { SIDE / 2 - W / 2 - 4, SIDE / 2 + W / 2 + 4 } } })

-- West: hub -> West Point, side platform to the north
walkway("Walk_W", -HUB / 2, 0, -140, 0, { A = { { 140 - 82 - SIDE / 2, 140 - 82 + SIDE / 2 } } })
deck("WestPoint", -140 - END / 2, 0, END, END)
railRect(-140 - END / 2, 0, END, END, { E = centreGap(END) })
deck("Spot_W1", -82, -W / 2 - SIDE / 2, SIDE, SIDE)
railRect(-82, -W / 2 - SIDE / 2, SIDE, SIDE, { S = { { SIDE / 2 - W / 2 - 4, SIDE / 2 + W / 2 + 4 } } })

-- South: short walk -> landing -> stairs down to a floating raft at water level
walkway("Walk_S", 0, HUB / 2, 0, 74)
local LAND = 20
deck("Landing", 0, 74 + LAND / 2, LAND, LAND)
railRect(0, 74 + LAND / 2, LAND, LAND, { N = centreGap(LAND), S = centreGap(LAND) })
local stairF = folder("Stairs")
local steps = 8
for i = 1, steps do
	local y = DECK - i * (DECK - 1.6) / steps
	part({
		Name = "Step",
		Material = Enum.Material.WoodPlanks,
		Size = Vector3.new(W, 0.6, 2.2),
		CFrame = CFrame.new(P(Vector3.new(0, y - 0.3, 74 + LAND + (i - 0.5) * 2))),
		Color = vary(WOOD, 0.04),
	}, stairF)
end
local stairEnd = 74 + LAND + steps * 2
for _, sx in { -W / 2 + 0.3, W / 2 - 0.3 } do
	local a = P(Vector3.new(sx, DECK + 2.9, 74 + LAND))
	local b = P(Vector3.new(sx, 1.6 + 2.9, stairEnd))
	part({ Name = "StairRail", Size = Vector3.new(0.5, 0.35, (b - a).Magnitude), CFrame = CFrame.lookAt((a + b) / 2, b), Color = WOOD_RAIL }, stairF)
	post(sx, 74 + LAND + 0.5, STILT_BOTTOM, DECK, 1.4, WOOD_DARK, stairF)
	post(sx, stairEnd - 0.5, STILT_BOTTOM, 1.6, 1.4, WOOD_DARK, stairF)
end
-- floating log raft
local raftF = folder("Raft")
local RAFT_Z = stairEnd + 7
for i = -4, 4 do
	part({
		Name = "Log",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(14, 1.6, 1.6),
		CFrame = CFrame.new(P(Vector3.new(i * 1.6, 0.6, RAFT_Z))) * CFrame.Angles(0, math.pi / 2, 0),
		Color = vary(WOOD, 0.06),
	}, raftF)
end
part({ Name = "RaftTop", Material = Enum.Material.WoodPlanks, Size = Vector3.new(14.4, 0.4, 14), CFrame = CFrame.new(P(Vector3.new(0, 1.4, RAFT_Z))), Color = WOOD, Transparency = 1 }, raftF)

-- lanterns ----------------------------------------------------------------------------------------
local lampF = folder("Lamps")
local function lantern(x: number, z: number, top: number?)
	local y = top or DECK
	post(x, z, y, y + 7, 0.5, WOOD_DARK, lampF, "LampPost")
	local l = part({ Name = "Lantern", Material = Enum.Material.Neon, Size = Vector3.new(1, 1.3, 1), CFrame = CFrame.new(P(Vector3.new(x, y + 7.3, z))), Color = LANTERN }, lampF)
	part({ Name = "Cap", Size = Vector3.new(1.4, 0.3, 1.4), CFrame = CFrame.new(P(Vector3.new(x, y + 8.1, z))), Color = WOOD_DARK }, lampF)
	local light = Instance.new("PointLight")
	light.Color = LANTERN
	light.Range = 16
	light.Brightness = 1.2
	light.Parent = l
end
for i, z in { -48, -80, -112, -144 } do
	lantern(if i % 2 == 0 then W / 2 - 0.3 else -W / 2 + 0.3, z)
end
for i, x in { 48, 80, 112 } do
	lantern(x, if i % 2 == 0 then W / 2 - 0.3 else -W / 2 + 0.3)
	lantern(-x, if i % 2 == 0 then -W / 2 + 0.3 else W / 2 - 0.3)
end
for _, c in { { -HUB / 2 + 1, -HUB / 2 + 1 }, { HUB / 2 - 1, -HUB / 2 + 1 }, { -HUB / 2 + 1, HUB / 2 - 1 }, { HUB / 2 - 1, HUB / 2 - 1 } } do
	lantern(c[1], c[2])
end
for _, c in { { -END / 2 + 1, -150 - END + 1 }, { END / 2 - 1, -150 - END + 1 } } do
	lantern(c[1], c[2])
end
lantern(140 + END - 1, -END / 2 + 1)
lantern(-140 - END + 1, END / 2 - 1)

-- props ---------------------------------------------------------------------------------------------
local propF = folder("Props")
local function barrel(x: number, z: number)
	part({
		Name = "Barrel",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(2.6, 2.2, 2.2),
		CFrame = CFrame.new(P(Vector3.new(x, DECK + 1.3, z))) * CFrame.Angles(0, 0, math.pi / 2),
		Color = vary(Color3.fromRGB(150, 98, 60), 0.05),
	}, propF)
end
local function crate(x: number, z: number, s: number?)
	local k = s or 2.4
	part({ Name = "Crate", Material = Enum.Material.WoodPlanks, Size = Vector3.new(k, k, k), CFrame = CFrame.new(P(Vector3.new(x, DECK + k / 2, z))) * CFrame.Angles(0, rng:NextNumber(-0.3, 0.3), 0), Color = vary(Color3.fromRGB(176, 128, 80), 0.05) }, propF)
end
local function bench(x: number, z: number, rotY: number)
	local cf = CFrame.new(P(Vector3.new(x, DECK, z))) * CFrame.Angles(0, rotY, 0)
	part({ Name = "BenchSeat", Material = Enum.Material.WoodPlanks, Size = Vector3.new(6, 0.4, 1.6), CFrame = cf * CFrame.new(0, 1.5, 0), Color = WOOD_RAIL }, propF)
	for _, dx in { -2.5, 2.5 } do
		part({ Name = "BenchLeg", Size = Vector3.new(0.4, 1.3, 1.4), CFrame = cf * CFrame.new(dx, 0.65, 0), Color = WOOD_DARK }, propF)
	end
end
local function umbrella(x: number, z: number, color: Color3)
	post(x, z, DECK, DECK + 8, 0.4, WOOD_DARK, propF, "UmbrellaPole")
	-- stepped canopy (reads as a cone): 3 stacked discs, white rim at the bottom
	for i, d in { 11, 8, 4.5 } do
		local h, s, v = color:ToHSV()
		part({
			Name = "Canopy",
			Material = Enum.Material.Fabric,
			Shape = Enum.PartType.Cylinder,
			Size = Vector3.new(0.7, d, d),
			CFrame = CFrame.new(P(Vector3.new(x, DECK + 7.6 + i * 0.55, z))) * CFrame.Angles(0, 0, math.pi / 2),
			Color = if i == 2 then Color3.new(1, 1, 1) else Color3.fromHSV(h, s, math.min(1, v + 0.1)),
		}, propF)
	end
	part({ Name = "CanopyTop", Material = Enum.Material.Fabric, Shape = Enum.PartType.Ball, Size = Vector3.new(1.4, 1.4, 1.4), CFrame = CFrame.new(P(Vector3.new(x, DECK + 8.5, z))), Color = Color3.new(1, 1, 1) }, propF)
end
local function rodRack(x: number, z: number, rotY: number)
	local cf = CFrame.new(P(Vector3.new(x, DECK, z))) * CFrame.Angles(0, rotY, 0)
	part({ Name = "RackBase", Size = Vector3.new(4, 0.5, 1), CFrame = cf * CFrame.new(0, 0.25, 0), Color = WOOD_DARK }, propF)
	for i = -1, 1 do
		part({ Name = "Rod", Shape = Enum.PartType.Cylinder, Size = Vector3.new(6, 0.18, 0.18), CFrame = cf * CFrame.new(i * 1.2, 3, 0) * CFrame.Angles(0, 0, math.pi / 2 - 0.15), Color = Color3.fromRGB(70, 50, 40) }, propF)
	end
end
local function rope(x: number, z: number)
	part({ Name = "RopeCoil", Material = Enum.Material.Fabric, Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.6, 2.4, 2.4), CFrame = CFrame.new(P(Vector3.new(x, DECK + 0.3, z))) * CFrame.Angles(0, 0, math.pi / 2), Color = ROPE }, propF)
end

-- hub dressing: compass inlay, umbrellas, benches
part({ Name = "Compass", Material = Enum.Material.Wood, Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.1, 14, 14), CFrame = CFrame.new(P(Vector3.new(0, DECK + 0.02, 0))) * CFrame.Angles(0, 0, math.pi / 2), Color = WOOD_DARK }, propF)
for k = 0, 3 do -- 4 long points (N/E/S/W) + 4 short diagonals
	local wedge = part({ ClassName = "WedgePart", Name = "CompassPoint", Material = Enum.Material.Wood, Size = Vector3.new(1.6, 0.12, 6), Color = Color3.fromRGB(240, 206, 150) }, propF)
	wedge.CFrame = CFrame.new(P(Vector3.new(0, DECK + 0.06, 0))) * CFrame.Angles(0, k * math.pi / 2, 0) * CFrame.new(0, 0, -3) * CFrame.Angles(0, 0, 0)
	part({ Name = "CompassDiag", Material = Enum.Material.Wood, Size = Vector3.new(0.9, 0.1, 7), CFrame = CFrame.new(P(Vector3.new(0, DECK + 0.05, 0))) * CFrame.Angles(0, k * math.pi / 2 + math.pi / 4, 0), Color = Color3.fromRGB(214, 172, 118) }, propF)
end
part({ Name = "CompassN", Material = Enum.Material.Neon, Shape = Enum.PartType.Ball, Size = Vector3.new(1.2, 0.3, 1.2), CFrame = CFrame.new(P(Vector3.new(0, DECK + 0.1, -6.4))), Color = Color3.fromRGB(240, 96, 80) }, propF)
-- north half of the hub = stall (NE) + altar (NW); south half = seating
umbrella(-14, 14, Color3.fromRGB(242, 128, 120))
umbrella(14, 14, Color3.fromRGB(110, 190, 220))
bench(-14, 9, 0)
bench(14, 9, 0)
barrel(19, 18)
barrel(19, 15.5)
crate(-19, 18)
crate(-19, 15.5, 1.8)
-- fishing platforms dressing
umbrella(0, -150 - END + 6, Color3.fromRGB(250, 214, 110))
bench(-8, -150 - END / 2, math.pi / 2)
rodRack(8, -150 - END / 2 + 6, math.pi / 2)
barrel(10, -150 - 6)
umbrella(140 + END - 6, 0, Color3.fromRGB(180, 150, 230))
bench(140 + END / 2, -9, 0)
crate(140 + 6, 10)
rope(140 + 10, 10)
umbrella(-140 - END + 6, 0, Color3.fromRGB(130, 210, 170))
bench(-140 - END / 2, 9, math.pi)
rodRack(-140 - END / 2, -9, 0)
barrel(W / 2 + SIDE - 3, -86 - 4)
rope(82 + 4, W / 2 + SIDE - 3)
crate(-82 - 4, -W / 2 - SIDE + 3, 2)
rope(4, 74 + LAND - 4)

-- buoys + mooring posts in the water
local waterF = folder("Water")
for i = 1, 16 do
	local a = (i / 16) * math.pi * 2
	local d = 220 + (i % 3) * 18
	local c = if i % 2 == 0 then Color3.fromRGB(240, 96, 80) else Color3.new(1, 1, 1)
	part({ Name = "Buoy", Material = Enum.Material.SmoothPlastic, Shape = Enum.PartType.Ball, Size = Vector3.new(2.2, 2.2, 2.2), CFrame = CFrame.new(P(Vector3.new(math.cos(a) * d, 0.4, math.sin(a) * d))), Color = c }, waterF)
end
for _, c in { { -30, -40 }, { 34, 40 }, { 60, -30 }, { -64, 34 }, { 30, -120 }, { -110, -40 } } do
	post(c[1], c[2], STILT_BOTTOM, 3, 1.4, WOOD_DARK, waterF, "MooringPost")
end

-- palms on the islets (simple: segmented trunk + leaves)
local palmF = folder("Palms")
local function palm(base: Vector3, lean: number)
	local p = P(base)
	local cf = CFrame.new(p) * CFrame.Angles(lean, rng:NextNumber(0, math.pi * 2), 0)
	for i = 0, 5 do
		part({ Name = "Trunk", Shape = Enum.PartType.Cylinder, Size = Vector3.new(3.2, 1.6 - i * 0.12, 1.6 - i * 0.12), CFrame = cf * CFrame.new(0, i * 3 + 1.5, 0) * CFrame.Angles(0, 0, math.pi / 2), Color = Color3.fromRGB(150, 112, 74) }, palmF)
		cf = cf * CFrame.Angles(lean * 0.25, 0, 0)
	end
	local top = cf * CFrame.new(0, 18, 0)
	for k = 0, 5 do
		part({ Name = "Leaf", Material = Enum.Material.Grass, Size = Vector3.new(2.4, 0.3, 11), CFrame = top * CFrame.Angles(0, k * math.pi / 3, 0) * CFrame.Angles(-0.35, 0, 0) * CFrame.new(0, 0, -5), Color = Color3.fromRGB(96, 170, 84) }, palmF)
	end
end
for _, c in islets do
	palm(c + Vector3.new(0, 6, 0), 0.12)
	palm(c + Vector3.new(10, 4, -8), -0.2)
	palm(c + Vector3.new(-9, 3, 6), 0.25)
end

-- placeholder slots for gameplay buildings (move the existing stall/altar here later)
local slotF = folder("Slots")
for _, s in {
	{ "ShopSlot", 13, -14, 14, 8 },
	{ "AuraAltarSlot", -14, -14, 14, 14 },
	{ "QuestBoardSlot", 20, 0, 1, 8 },
	{ "LeaderboardSlot", -20, 0, 1, 12 },
	{ "RebirthShrineSlot", 0, -150 - END / 2, 10, 10 },
	{ "BoatSlot", 0, RAFT_Z, 14, 14 },
	{ "BossArenaSlot", 0, -330, 90, 90 },
} do
	local slot = part({ Name = s[1], Material = Enum.Material.SmoothPlastic, Transparency = 1, CanCollide = false, CanQuery = false, Size = Vector3.new(s[4], 0.2, s[5]), CFrame = CFrame.new(P(Vector3.new(s[2], DECK + 0.1, s[3]))) }, slotF)
	slot:SetAttribute("Note", "placeholder: where this building goes on the boardwalk map")
end

-- fishing zone + (disabled) spawn
local zone = part({
	Name = "FishingZone_Boardwalk",
	Material = Enum.Material.SmoothPlastic,
	Transparency = 1,
	CanCollide = false,
	CanQuery = false,
	CanTouch = false,
	Size = Vector3.new(SEA * 2, 64, SEA * 2),
	CFrame = CFrame.new(P(Vector3.new(0, -17, 0))),
}, folder("FishingZones"))
zone:SetAttribute("LocationId", "StarterBay")
CollectionService:AddTag(zone, "FishingZone")

-- sea edge (Shared/PlayArea): buoy line at SOFT, reef ring near HARD, haze hides the far edge
local edgeF = folder("Edge")
local area = part({
	Name = "PlayArea",
	Material = Enum.Material.SmoothPlastic,
	Transparency = 1,
	CanCollide = false,
	CanQuery = false,
	CanTouch = false,
	Size = Vector3.new(4, 4, 4),
	CFrame = CFrame.new(P(Vector3.new(0, 0, 0))),
}, edgeF)
area:SetAttribute("Soft", SOFT)
area:SetAttribute("Hard", HARD)
area:SetAttribute("Reach", SEA)
area:SetAttribute("ReturnTo", P(Vector3.new(0, DECK, 10)))
CollectionService:AddTag(area, "PlayArea")

local nBuoys = math.floor(2 * math.pi * SOFT / 24)
local prev: Vector3? = nil
for i = 0, nBuoys do
	local a = i / nBuoys * math.pi * 2
	local pos = P(Vector3.new(math.cos(a) * SOFT, 0.5, math.sin(a) * SOFT))
	if i < nBuoys then
		part({ Name = "EdgeBuoy", Material = Enum.Material.SmoothPlastic, Shape = Enum.PartType.Ball, Size = Vector3.new(2, 2, 2), CFrame = CFrame.new(pos), Color = if i % 2 == 0 then Color3.fromRGB(240, 96, 80) else Color3.new(1, 1, 1), CanCollide = false }, edgeF)
	end
	if prev then
		local mid = (prev + pos) / 2
		part({ Name = "EdgeRope", Material = Enum.Material.Fabric, Size = Vector3.new(0.3, 0.3, (pos - prev).Magnitude), CFrame = CFrame.lookAt(mid, pos), Color = ROPE, CanCollide = false, CanQuery = false }, edgeF)
	end
	prev = pos
end
-- reef: rocks just under / breaking the surface between SOFT and HARD (whitewater look from Rock + waves)
for i = 1, math.floor(2 * math.pi * HARD / 30) do
	local a = i / math.floor(2 * math.pi * HARD / 30) * math.pi * 2 + rng:NextNumber(-0.01, 0.01)
	local d = rng:NextNumber(SOFT + 50, HARD - 10)
	T:FillBall(P(Vector3.new(math.cos(a) * d, rng:NextNumber(-7, -2), math.sin(a) * d)), rng:NextNumber(5, 9), Enum.Material.Rock)
	if i % 25 == 0 then
		task.wait()
	end
end

-- haze: the far sea fades into the sky so the edge never shows (affects the whole place's Lighting)
local L = game:GetService("Lighting")
local atmo = L:FindFirstChildOfClass("Atmosphere") or Instance.new("Atmosphere")
atmo.Density = 0.3
atmo.Offset = 0.35 -- haze mostly on the horizon, near water stays clear
atmo.Color = Color3.fromRGB(205, 230, 240)
atmo.Decay = Color3.fromRGB(120, 180, 205)
atmo.Glare = 0.2
atmo.Haze = 1.2
atmo.Parent = L

local spawn = Instance.new("SpawnLocation")
spawn.Name = "Spawn"
spawn.Anchored = true
spawn.Enabled = true
spawn.Neutral = true
spawn.Transparency = 1
spawn.CanCollide = false
spawn.Size = Vector3.new(8, 0.2, 8)
spawn.CFrame = CFrame.new(P(Vector3.new(0, DECK + 0.1, 10)))
local decal = spawn:FindFirstChildOfClass("Decal")
if decal then
	decal:Destroy()
end
spawn.Parent = root

-- gameplay buildings onto their slots (sitting on the deck, rotated to face the hub)
local bF = folder("Buildings")
for name, b in kept do
	local slot = BUILDINGS[name]
	local cf, size = b:GetBoundingBox()
	local rel = cf:ToObjectSpace(b:GetPivot())
	local target = CFrame.new(P(Vector3.new(slot[1], DECK + size.Y / 2, slot[2]))) * CFrame.Angles(0, slot[3], 0) * (cf - cf.Position)
	b:PivotTo(target * rel)
	b.Parent = bF
end

root.Parent = workspace

-- frame the camera on it
local cam = workspace.CurrentCamera
cam.CFrame = CFrame.lookAt(P(Vector3.new(150, 120, 190)), P(Vector3.new(0, 0, -30)))
cam.Focus = CFrame.new(P(Vector3.new(0, 0, -30)))

local n = 0
for _, d in root:GetDescendants() do
	if d:IsA("BasePart") then
		n += 1
	end
end
local names = {}
for k in kept do
	table.insert(names, k)
end
return `Map built: {n} parts, sea {SEA * 2}x{SEA * 2} at {ORIGIN}, buildings kept: {table.concat(names, ", ")}`
