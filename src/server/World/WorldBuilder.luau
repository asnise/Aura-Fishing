--!strict
-- Builds a greybox prototype map ONLY if Workspace has no "Map" model. Once you build a real map
-- in Studio, name it "Map" and this script does nothing. Fishing needs:
--   * Terrain water (or any water) where the bobber lands
--   * Part(s) tagged "FishingZone" with attribute LocationId (see Config/Locations)
-- Optional props it also creates: SpawnLocation, "Merchant" (sell prompt), "AuraAltar" (roll prompt).

local CollectionService = game:GetService("CollectionService")
local Workspace = game:GetService("Workspace")

local WorldBuilder = {}

local function part(props: { [string]: any }, parent: Instance): Part
	local p = Instance.new("Part")
	p.Anchored = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	for k, v in props do
		(p :: any)[k] = v
	end
	p.Parent = parent
	return p
end

local function prompt(parent: Instance, action: string, object: string, name: string)
	local pp = Instance.new("ProximityPrompt")
	pp.Name = name
	pp.ActionText = action
	pp.ObjectText = object
	pp.HoldDuration = 0
	pp.MaxActivationDistance = 12
	pp.RequiresLineOfSight = false
	pp.Parent = parent
end

local function label(parent: BasePart, text: string, color: Color3)
	local bb = Instance.new("BillboardGui")
	bb.Size = UDim2.fromOffset(200, 50)
	bb.StudsOffset = Vector3.new(0, parent.Size.Y / 2 + 2, 0)
	bb.AlwaysOnTop = true
	bb.MaxDistance = 80
	local t = Instance.new("TextLabel")
	t.Size = UDim2.fromScale(1, 1)
	t.BackgroundTransparency = 1
	t.Text = text
	t.TextColor3 = color
	t.TextStrokeTransparency = 0.3
	t.Font = Enum.Font.GothamBold
	t.TextScaled = true
	t.Parent = bb
	bb.Parent = parent
end

function WorldBuilder.Init()
	if Workspace:FindFirstChild("Map") then
		return
	end
	local map = Instance.new("Model")
	map.Name = "Map"

	local terrain = Workspace.Terrain
	-- Sea floor, sea, island
	terrain:FillBlock(CFrame.new(0, -46, 0), Vector3.new(512, 8, 512), Enum.Material.Sand)
	terrain:FillBlock(CFrame.new(0, -21, 0), Vector3.new(512, 42, 512), Enum.Material.Water)
	terrain:FillCylinder(CFrame.new(0, -12, 0), 22, 56, Enum.Material.Sand)
	terrain:FillCylinder(CFrame.new(0, -6, 0), 12, 48, Enum.Material.Grass)

	-- Spawn
	local spawn = Instance.new("SpawnLocation")
	spawn.Anchored = true
	spawn.Size = Vector3.new(8, 1, 8)
	spawn.Position = Vector3.new(0, 0.5, 0)
	spawn.Transparency = 0.5
	spawn.Neutral = true
	spawn.Duration = 0
	spawn.Parent = map

	-- Dock (pointing +X)
	local wood = Color3.fromRGB(120, 85, 55)
	part({ Name = "Dock", Size = Vector3.new(40, 1, 10), Position = Vector3.new(60, 1, 0), Color = wood, Material = Enum.Material.WoodPlanks }, map)
	for _, x in { 45, 60, 75 } do
		for _, z in { -4.5, 4.5 } do
			part({ Name = "Post", Size = Vector3.new(1, 12, 1), Position = Vector3.new(x, -4.5, z), Color = wood, Material = Enum.Material.Wood }, map)
		end
	end

	-- Merchant (sell)
	local merchant = part({ Name = "Merchant", Size = Vector3.new(4, 6, 4), Position = Vector3.new(14, 4, 14), Color = Color3.fromRGB(240, 200, 80), Material = Enum.Material.SmoothPlastic }, map)
	label(merchant, "Fish Merchant", Color3.fromRGB(255, 230, 120))
	prompt(merchant, "Sell All Fish", "Merchant", "SellPrompt")

	-- Aura altar (roll)
	local altar = part({ Name = "AuraAltar", Shape = Enum.PartType.Cylinder, Size = Vector3.new(2, 8, 8), CFrame = CFrame.new(-14, 2, 14) * CFrame.Angles(0, 0, math.rad(90)), Color = Color3.fromRGB(150, 90, 255), Material = Enum.Material.Neon }, map)
	label(altar, "Aura Altar", Color3.fromRGB(210, 170, 255))
	prompt(altar, "Roll Aura", "Altar", "RollPrompt")

	-- Fishing zone covering the sea
	local zone = part({
		Name = "FishingZone_StarterBay",
		Size = Vector3.new(512, 60, 512),
		Position = Vector3.new(0, -15, 0),
		Transparency = 1,
		CanCollide = false,
		CanQuery = false,
		CanTouch = false,
	}, map)
	zone:SetAttribute("LocationId", "StarterBay")
	CollectionService:AddTag(zone, "FishingZone")

	map.Parent = Workspace
end

return WorldBuilder
