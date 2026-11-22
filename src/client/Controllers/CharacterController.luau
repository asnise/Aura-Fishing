--!nonstrict
-- Character window (B21, Figma 17 v2). Layout baked into StarterGui.Character (UI/Screens/Character).
--   Open: HUD.CharacterRequested (key C, Main Menu avatar) -> Toggle.
--   Left: avatar (clone of the player's character in a ViewportFrame, drag to spin), name + level,
--         equipped Rod / Line / Bait / Aura slots, key stats from DataController.Stats.
--   Right: tab chips Rods / Lines / Baits / Auras over a grid of OWNED items (UI/ItemSlots + VirtualGrid).
--   Pressing an equipped slot or a grid item opens UI/ItemDetail (Item Card); all actions live there.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Registry = require(Shared.Registry)
local Inventory = require(Shared.Inventory)
local Format = require(Shared.Util.Format)

local UI = script.Parent.Parent.UI
local New = require(UI.New)
local Baked = require(UI.Baked)
local MenuManager = require(UI.MenuManager)
local VirtualGrid = require(UI.VirtualGrid)
local ItemDetail = require(UI.ItemDetail)
local ItemSlots = require(UI.ItemSlots)
local SetItemSlot = (require(UI.Screens:WaitForChild("Components")) :: any).SetItemSlot
local CharacterScreen = require(UI.Screens:WaitForChild("Character")) :: any
local HUD = require(script.Parent.HUDController)
local DataController = require(script.Parent.DataController)

local T = New.Theme

local CharacterController = {}

-- key stats shown under the equipped slots (StatDefs keys)
local STATS = { "Luck", "ReelPower", "CatchBarSize", "MaxDepth", "AutoSpeed" }

local gui: any = nil
local refs: any = nil
local isOpen = false
local tab = "Rods"
local selected: string? = nil
local grid: any = nil
local model: Model? = nil
local yaw = 0
local dragging = false

local function statValue(key: string, v: number): string
	local def = Registry.StatDefs[key]
	if key == "MaxDepth" then
		return `{math.floor(v)}m`
	elseif def and def.Percent then
		local pct = Format.Percent(v)
		return if def.Reduces then "-" .. string.sub(pct, 2) else pct
	end
	return string.format("x%.2f", v)
end

local function entries(profile: any): { any }
	if tab == "Baits" then
		return ItemSlots.Baits(profile)
	elseif tab == "Auras" then
		return ItemSlots.Auras(profile)
	end
	return ItemSlots.Gear(profile, tab)
end

-- Equipped slot -> { Kind, Id, Icon, Name, Rarity?, Color?, Count? } or nil
local function equippedItem(profile: any, kind: string): any
	if kind == "Rod" or kind == "Line" then
		local cat = if kind == "Rod" then "Rods" else "Lines"
		local id = Inventory.EquippedId(profile, cat)
		local item = id and Registry.Equipment[cat].Items[id]
		return item and { Kind = kind, Id = id, UUID = profile.Equipped[cat], Icon = `equipment/{id}`, Name = item.Name, Rarity = ItemSlots.GearRarity(cat, id) }
	elseif kind == "Bait" then
		local id = profile.Equipped.Baits
		local item = id and Registry.Equipment.Baits.Items[id]
		local n = id and profile.Consumables.Baits[id] or 0
		return item and n > 0 and { Kind = "Bait", Id = id, Icon = `equipment/{id}`, Name = item.Name, Color = T.Gold, Count = n }
	else
		local id = profile.Auras.Equipped
		local a = id and Registry.Auras[id]
		return a and { Kind = "Aura", Id = id, Icon = `auras/{id}`, Name = a.Name, Rarity = a.Rarity }
	end
end

-- Avatar -------------------------------------------------------------------------------------------

local function placeCamera()
	if not model or not refs then
		return
	end
	local cf, size = model:GetBoundingBox()
	local cam = refs.Camera
	local dist = math.max(size.Y, size.X) * 1.9 + 2
	-- look a little above the middle: the model sits lower in the frame, under the name tag
	local center = cf.Position + Vector3.new(0, size.Y * 0.12, 0)
	local dir = CFrame.Angles(0, math.rad(yaw), 0) * Vector3.new(0, 0.15, -1)
	cam.CFrame = CFrame.lookAt(center + dir.Unit * dist, center)
end

local function buildAvatar()
	if model then
		model:Destroy()
		model = nil
	end
	local char = Players.LocalPlayer.Character
	if not char then
		return
	end
	local was = char.Archivable
	char.Archivable = true
	local ok, copy = pcall(function()
		return char:Clone()
	end)
	char.Archivable = was
	if not ok or not copy then
		return
	end
	for _, d in copy:GetDescendants() do
		if d:IsA("Script") or d:IsA("LocalScript") or d:IsA("Sound") or d:IsA("ParticleEmitter") or d:IsA("BillboardGui") then
			d:Destroy()
		elseif d:IsA("BasePart") then
			d.Anchored = true
		end
	end
	local root = copy:FindFirstChild("HumanoidRootPart")
	if root then
		copy.PrimaryPart = root
		copy:PivotTo(CFrame.new(0, 0, 0)) -- faces -Z = towards the camera at yaw 0
	end
	copy.Parent = refs.World
	model = copy
	placeCamera()
end

-- Window -------------------------------------------------------------------------------------------

local function show(item: any, anchor: GuiObject, key: string)
	if selected == key and ItemDetail.IsShowing() then
		selected = nil
		ItemDetail.Hide()
	else
		selected = key
		ItemDetail.Show({ Kind = item.Kind, Id = item.Id, UUID = item.UUID }, anchor)
	end
	if grid then
		grid:Refresh()
	end
end

local function ensure()
	if gui then
		return
	end
	gui = Baked.Get("Character")
	gui.Enabled = false
	local w = Baked.Find(gui, "Window")
	local avatar = Baked.Find(w, "Left/Avatar")
	refs = {
		Window = w,
		Avatar = avatar,
		Name = Baked.Find(avatar, "NameTag/Name"),
		Level = Baked.Find(avatar, "NameTag/Level"),
		Equipped = Baked.Find(w, "Left/Equipped"),
		Stats = Baked.Find(w, "Left/Stats"),
		Tabs = Baked.Find(w, "Right/Tabs"),
		Grid = Baked.Find(w, "Right/Grid"),
		Empty = Baked.Find(w, "Right/Empty"),
	}
	New.FitWindow(w, Vector2.new(720, 520))
	for _, c in refs.Grid:GetChildren() do
		if c:IsA("GuiObject") then
			c:Destroy()
		end
	end
	Baked.Find(w, "Header/Close").Activated:Connect(CharacterController.Close)
	refs.Skills = Baked.Find(w, "Header"):FindFirstChild("Skills") -- nil on an older bake
	if refs.Skills then
		refs.Skills.Activated:Connect(function()
			HUD.SkillsRequested:Fire() -- stacks on this window (MenuManager StackOn); closing Skills comes back here
		end)
	end

	-- viewport: camera + world model for the avatar clone
	local cam = Instance.new("Camera")
	cam.FieldOfView = 40
	cam.Parent = avatar
	avatar.CurrentCamera = cam
	local world = Instance.new("WorldModel")
	world.Parent = avatar
	refs.Camera, refs.World = cam, world
	avatar.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
		end
	end)
	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = false
		end
	end)
	UserInputService.InputChanged:Connect(function(input)
		if dragging and isOpen and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			yaw += input.Delta.X * 0.6
			placeCamera()
		end
	end)

	for _, t in CharacterScreen.Tabs do
		local name = t[1]
		Baked.Find(refs.Tabs, name).Activated:Connect(function()
			if tab ~= name then
				tab = name
				selected = nil
				ItemDetail.Hide()
				refs.Grid.CanvasPosition = Vector2.zero
				CharacterController.Refresh()
			end
		end)
	end
	for _, e in CharacterScreen.Equipped do
		local kind = e[1]
		local slot = Baked.Find(refs.Equipped, kind .. "/Slot")
		slot.Activated:Connect(function()
			local profile = DataController.Profile
			local item = profile and equippedItem(profile, kind)
			if item then
				show(item, slot, "eq|" .. kind)
			end
		end)
	end

	grid = VirtualGrid.new(refs.Grid, {
		Create = function()
			return ItemSlots.NewCell(function(holder)
				local e = grid:ItemOf(holder)
				if e then
					show(e, holder, e.Key)
				end
			end)
		end,
		Bind = function(holder, e)
			ItemSlots.Bind(holder, e, selected)
		end,
	})
end

function CharacterController.Refresh()
	if not isOpen or not gui then
		return
	end
	local profile = DataController.Profile
	if not profile then
		return
	end
	local player = Players.LocalPlayer
	refs.Name.Text = player.DisplayName
	refs.Level.Text = `Lv.{profile.Level}`
	if refs.Skills then
		local pts = profile.Skills and profile.Skills.Points or 0
		refs.Skills.Text = if pts > 0 then `SKILLS  {pts}` else "SKILLS"
	end

	for _, e in CharacterScreen.Equipped do
		local kind = e[1]
		local slot = Baked.Find(refs.Equipped, kind .. "/Slot")
		local item = equippedItem(profile, kind)
		if item then
			local rarity = item.Rarity and Registry.Rarities[item.Rarity]
			local color = item.Color or (if rarity then rarity.Color else T.Track)
			SetItemSlot(slot, {
				Icon = item.Icon,
				IconColor = color,
				IconText = string.upper(string.sub(item.Name, 1, 1)),
				CornerColor = color,
				Count = item.Count,
				Selected = selected == "eq|" .. kind,
			})
			slot.Count.Visible = item.Count ~= nil
		else
			SetItemSlot(slot, { Empty = true })
		end
	end

	local stats = DataController.Stats
	for i = 1, CharacterScreen.StatRows do
		local row = refs.Stats:FindFirstChild("Row" .. i)
		local key = STATS[i]
		if row then
			row.Visible = key ~= nil and stats ~= nil
			if key and stats then
				local def = Registry.StatDefs[key]
				row.Key.Text = if def then def.Display else key
				row.Value.Text = statValue(key, stats.Values[key] or 0)
				row.Value.TextColor3 = if def and def.Highlight then T.GoldLip else T.Text
			end
		end
	end

	for _, t in CharacterScreen.Tabs do
		local chip = refs.Tabs[t[1]]
		local on = t[1] == tab
		chip.BackgroundColor3 = if on then T.Accent else T.PanelLight
		chip.Label.TextColor3 = if on then T.OnAccent else T.Text
	end

	local list = entries(profile)
	if selected and string.sub(selected, 1, 3) ~= "eq|" then
		local found = false
		for _, e in list do
			if e.Key == selected then
				found = true
			end
		end
		if not found then
			selected = nil
		end
	end
	refs.Empty.Visible = #list == 0
	grid:SetItems(list)
	ItemDetail.Refresh()
end

function CharacterController.IsOpen(): boolean
	return isOpen
end

function CharacterController.Open()
	ensure()
	if isOpen then
		return
	end
	MenuManager.WillOpen("Character")
	isOpen = true
	selected = nil
	gui.Enabled = true
	refs.Grid.CanvasPosition = Vector2.zero
	yaw = 0
	buildAvatar()
	CharacterController.Refresh()
end

function CharacterController.Close()
	if not isOpen then
		return
	end
	isOpen = false
	selected = nil
	ItemDetail.Hide()
	if gui then
		gui.Enabled = false
	end
	if model then
		model:Destroy()
		model = nil
	end
	MenuManager.Closed("Character")
end

function CharacterController.Toggle()
	if isOpen then
		CharacterController.Close()
	else
		CharacterController.Open()
	end
end

function CharacterController.Init()
	HUD.CharacterRequested:Connect(CharacterController.Toggle)
	UserInputService.InputBegan:Connect(function(input, processed)
		if not processed and input.KeyCode == Enum.KeyCode.C then
			CharacterController.Toggle()
		end
	end)
	DataController.Changed:Connect(CharacterController.Refresh)
	ItemDetail.Hidden:Connect(function()
		if selected and isOpen then
			selected = nil
			CharacterController.Refresh()
		end
	end)
	task.spawn(ensure)
end

MenuManager.Register("Character", { Layer = "Main", Open = CharacterController.Open, Close = CharacterController.Close, IsOpen = CharacterController.IsOpen, Gui = function()
	return gui
end })

return CharacterController
