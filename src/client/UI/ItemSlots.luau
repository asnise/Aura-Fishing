--!nonstrict
-- Shared item lists + 72px grid cells for the Inventory (B21) and Character (17 v2) windows.
--   ItemSlots.GearRarity(cat, id)     rarity id for a Rod/Line/Bag (equipment has none: rank by shop order)
--   ItemSlots.Gear(profile, cat)      Rods / Lines in the bag as entries (Kind "Rod" / "Line", one per item)
--   ItemSlots.Auras(profile)          owned auras (Kind "Aura") - auras are normal items, no locked slots
--   ItemSlots.Baits(profile)          baits with count > 0 (Kind "Bait")
--   entry extras (Responsive menu plan): Upgrade (better than the worn gear), GodRoll (a mod rolled near its max),
--     Tier (rarity tier, 5+ gets a glow border). ItemSlots.IsUpgrade / IsGodRoll compute them for gear.
--   entry = { Key, Kind, Id, UUID?, Name, Rarity?, Icon, Order, Count?, Equipped?, Color?, Stack?, Mutation?, Value?, Plus? }
--   ItemSlots.NewCell(onPress)        holder Frame with the Components ItemSlot (84px) scaled to 72;
--                                     onPress(holder) on click. Use as VirtualGrid Create.
--   ItemSlots.Bind(holder, entry, selectedKey, isNew?)   fill a cell (Empty entries -> bubbles)

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Registry = require(ReplicatedStorage:WaitForChild("Shared").Registry)
local Inventory = require(ReplicatedStorage.Shared.Inventory)
local Stats = require(ReplicatedStorage.Shared.Stats)
local TweenService = game:GetService("TweenService")
local HotFish = require(ReplicatedStorage.Shared.HotFish)

local New = require(script.Parent.New)
local Components = require(script.Parent.Components)
local SetItemSlot = (require(script.Parent.Screens:WaitForChild("Components")) :: any).SetItemSlot

local T = New.Theme

local ItemSlots = {}

ItemSlots.Size = 72
local COMPONENT_SLOT = 84 -- Components sheet ItemSlot size

function ItemSlots.GearRarity(cat: string, id: string): string
	return Registry.GearRarity(cat, id)
end

-- Notability --------------------------------------------------------------------------------------------

local modDefs: any = nil
local function modDef(id: string): any
	if not modDefs then
		modDefs = {}
		for _, d in Registry.ModifierDefs.Prefixes do
			modDefs[d.Id] = d
		end
		for _, d in Registry.ModifierDefs.Suffixes do
			modDefs[d.Id] = d
		end
	end
	return modDefs[id]
end

-- A mod whose value sits in the top 10% of its range.
function ItemSlots.IsGodRoll(item: any): boolean
	local function top(list: any): boolean
		for _, mod in list or {} do
			local d = modDef(mod.Id)
			if d and d.Max > d.Min and mod.Value > 0 and mod.Value >= d.Min + (d.Max - d.Min) * 0.9 then
				return true
			end
		end
		return false
	end
	return top(item.Prefixes) or top(item.Suffixes)
end

local UPGRADE_STATS = { "Luck", "CatchBarSize", "ReelPower", "Resilience", "CastRange", "AutoSpeed", "FishStability", "BiteSpeed", "MutationChance", "MaxDepth" }

-- True when wearing this spare Rod / Line would raise the player's stats more than it lowers them.
-- baseValues = Stats.Compute(profile).Values (pass it when checking many items).
function ItemSlots.IsUpgrade(profile: any, item: any, baseValues: any?): boolean
	local cat = Inventory.GearCategory(item.Kind)
	if not cat or Inventory.IsWorn(profile, item) or not Inventory.Worn(profile, cat) then
		return false
	end
	local old = baseValues or Stats.Compute(profile).Values
	local probe = table.clone(profile)
	probe.Equipped = table.clone(profile.Equipped)
	probe.Equipped[cat] = item.UUID
	local new = Stats.Compute(probe).Values
	local score = 0
	for _, k in UPGRADE_STATS do
		local a, b = old[k] or 0, new[k] or 0
		score += (b - a) / math.max(0.1, math.abs(a))
	end
	return score > 0.02
end

function ItemSlots.Tier(rarityId: string?): number
	local r = rarityId and Registry.Rarities[rarityId]
	return if r then r.Tier else 0
end

-- Highlights shelf (docs/RESPONSIVE_MENU_PLAN.md 8.3): one place decides what counts as notable.
-- 0 = ordinary; higher = show first. An unseen item (isNew) only ranks higher, it never makes a plain item notable.
function ItemSlots.NotablePriority(e: any, isNew: boolean): number
	local base = 0
	if (e.Tier or 0) >= 4 then
		base += e.Tier * 10
	end
	if e.Mutation then
		base += 25
	end
	if e.GodRoll then
		base += 30
	end
	if e.Upgrade then
		base += 35
	end
	if base == 0 then
		return 0
	end
	return base + (if isNew then 100 else 0)
end

function ItemSlots.Gear(profile: any, cat: string): { any }
	local out = {}
	local kind = Inventory.GearKind(cat)
	local baseValues = Stats.Compute(profile).Values
	for i, gear in profile.Bag do
		local item = if gear.Kind == kind then Registry.Equipment[cat].Items[gear.Id] else nil
		if item then
			table.insert(out, {
				Key = `{kind}|{gear.UUID}`,
				Kind = kind,
				Id = gear.Id,
				UUID = gear.UUID,
				Stack = gear,
				Name = item.Name,
				Rarity = ItemSlots.GearRarity(cat, gear.Id),
				Icon = `equipment/{gear.Id}`,
				Order = item.Order * 1000 + i,
				Equipped = profile.Equipped[cat] == gear.UUID,
				Plus = gear.Enhance or 0, -- C16: +N badge
				Upgrade = ItemSlots.IsUpgrade(profile, gear, baseValues),
				GodRoll = ItemSlots.IsGodRoll(gear),
				Tier = ItemSlots.Tier(ItemSlots.GearRarity(cat, gear.Id)),
			})
		end
	end
	return out
end

function ItemSlots.Auras(profile: any): { any }
	local out = {}
	for _, id in Registry.SortedAuras() do
		if profile.Auras.Owned[id] ~= nil then
			local a = Registry.Auras[id]
			table.insert(out, {
				Key = `Aura|{id}`,
				Kind = "Aura",
				Id = id,
				Name = a.Name,
				Rarity = a.Rarity,
				Icon = `auras/{id}`,
				Order = a.Order,
				Equipped = profile.Auras.Equipped == id,
			})
		end
	end
	return out
end

function ItemSlots.Baits(profile: any): { any }
	local cat = Registry.Equipment.Baits
	local owned = profile.Consumables and profile.Consumables.Baits or {}
	local out = {}
	for id, count in owned do
		local item = cat.Items[id]
		if item and count > 0 then
			table.insert(out, {
				Key = `bait|{id}`,
				Kind = "Bait",
				Id = id,
				Count = count,
				Name = item.Name,
				Order = 1000 + item.Order,
				Icon = `equipment/{id}`,
				Color = T.Gold,
				Equipped = profile.Equipped.Baits == id,
			})
		end
	end
	table.sort(out, function(a, b)
		return a.Order < b.Order
	end)
	return out
end

-- C16 "+N" Enhance badge (Figma Economy 4: sky pill on the picture's bottom-left). Created once per
-- picture/cell; ItemSlots.SetPlus shows it.
function ItemSlots.PlusBadge(parent: Instance, size: number): TextLabel
	local old = parent:FindFirstChild("Plus")
	if old then
		return old :: TextLabel
	end
	return New("TextLabel", {
		Name = "Plus",
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.fromOffset(math.round(size * 0.06), size - math.round(size * 0.05)),
		Size = UDim2.fromOffset(0, 16),
		AutomaticSize = Enum.AutomaticSize.X,
		BackgroundColor3 = T.SkyLip,
		Text = "+1",
		TextColor3 = T.OnAccent,
		FontFace = T.FontBadge,
		TextSize = New.FigmaSize(T.FontBadge, 11),
		Visible = false,
		ZIndex = 8,
		Parent = parent,
		[New.Children] = { New.Pill(), New("UIPadding", { PaddingLeft = UDim.new(0, 5), PaddingRight = UDim.new(0, 5) }) },
	}) :: TextLabel
end

function ItemSlots.SetPlus(parent: Instance, level: number?)
	local b = parent:FindFirstChild("Plus")
	if b then
		b.Visible = level ~= nil and level > 0
		b.Text = `+{level or 0}`
	end
end

local pulses: { [Instance]: Tween } = {}

-- "TOP" / "UP" tags, rarity glow (Legendary and above) and a soft pulse on items you have not looked at yet.
function ItemSlots.SetNotable(holder: Instance, e: any?, isNew: boolean)
	local glow, tags = holder:FindFirstChild("Glow"), holder:FindFirstChild("Tags")
	if not glow or not tags then
		return
	end
	local oldPulse = pulses[holder]
	if oldPulse then
		oldPulse:Cancel()
		pulses[holder] = nil
	end
	local edge = glow.Edge
	local tier = if e then e.Tier or 0 else 0
	local show = e ~= nil and isNew -- rarity glow and UP/TOP tags removed by request; only unseen items pulse
	glow.Visible = show
	if show then
		local rarity = e.Rarity and Registry.Rarities[e.Rarity]
		edge.Color = if tier >= 5 and rarity then rarity.Color else T.SkyLip
		edge.Transparency = 0.15
		if isNew then
			local tween = TweenService:Create(edge, TweenInfo.new(0.9, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), { Transparency = 0.75 })
			pulses[holder] = tween
			tween:Play()
		end
	end
	tags.Top.Visible = false
	tags.Up.Visible = false
end

function ItemSlots.NewCell(onPress: (Frame) -> ()): Frame
	local holder = Instance.new("Frame")
	holder.Name = "Cell"
	holder.BackgroundTransparency = 1
	local slot = Components.Clone("ItemSlot")
	slot.AnchorPoint = Vector2.zero
	slot.Position = UDim2.fromOffset(0, 0)
	slot.Size = UDim2.fromOffset(COMPONENT_SLOT, COMPONENT_SLOT)
	local scale = Instance.new("UIScale")
	scale.Scale = ItemSlots.Size / COMPONENT_SLOT
	scale.Parent = slot
	slot.Parent = holder
	slot.Activated:Connect(function()
		onPress(holder)
	end)
	ItemSlots.PlusBadge(holder, ItemSlots.Size)
	-- rare items glow; "UP" / "TOP" tags sit bottom-right
	New("Frame", {
		Name = "Glow",
		Size = UDim2.fromOffset(ItemSlots.Size, ItemSlots.Size),
		BackgroundTransparency = 1,
		Visible = false,
		ZIndex = 7,
		Parent = holder,
		[New.Children] = { New.Corner(18), New("UIStroke", { Name = "Edge", Thickness = 3, Color = T.Gold, Transparency = 0.15 }) },
	})
	local tags = New("Frame", {
		Name = "Tags",
		AnchorPoint = Vector2.new(1, 1),
		Position = UDim2.fromOffset(ItemSlots.Size - 3, ItemSlots.Size - 3),
		Size = UDim2.fromOffset(0, 0),
		AutomaticSize = Enum.AutomaticSize.XY,
		BackgroundTransparency = 1,
		ZIndex = 9,
		Parent = holder,
		[New.Children] = { New("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, VerticalAlignment = Enum.VerticalAlignment.Bottom, HorizontalAlignment = Enum.HorizontalAlignment.Right, Padding = UDim.new(0, 2) }) },
	})
	for i, t in { { "Top", "TOP", T.Gold }, { "Up", "UP", T.Good } } do
		New("TextLabel", {
			Name = t[1],
			Size = UDim2.fromOffset(0, 16),
			AutomaticSize = Enum.AutomaticSize.X,
			BackgroundColor3 = t[3],
			Text = t[2],
			TextColor3 = T.OnAccent,
			FontFace = T.FontBadge,
			TextSize = New.FigmaSize(T.FontBadge, 11),
			Visible = false,
			LayoutOrder = i,
			ZIndex = 9,
			Parent = tags,
			[New.Children] = { New.Pill(), New("UIPadding", { PaddingLeft = UDim.new(0, 5), PaddingRight = UDim.new(0, 5) }) },
		})
	end
	-- C18 hot fish badge (Figma Economy 7: orange "xN" pill on the stack's top-right)
	New("Frame", {
		Name = "Hot",
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, 6, 0, -6),
		Size = UDim2.fromOffset(0, 18),
		AutomaticSize = Enum.AutomaticSize.X,
		BackgroundColor3 = T.Gold,
		Visible = false,
		ZIndex = 9,
		Parent = holder,
		[New.Children] = {
			New.Pill(),
			New("UIStroke", { Color = Color3.new(1, 1, 1), Thickness = 2 }),
			New("UIPadding", { PaddingLeft = UDim.new(0, 4), PaddingRight = UDim.new(0, 6) }),
			New("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 2), VerticalAlignment = Enum.VerticalAlignment.Center, SortOrder = Enum.SortOrder.LayoutOrder }),
		},
	})
	New.Image({ Name = "Icon", Key = "ui/status/hot_price", Fallback = T.GoldLip, Size = UDim2.fromOffset(12, 12), LayoutOrder = 1, ZIndex = 10, Parent = holder.Hot })
	New("TextLabel", {
		Name = "Text",
		Size = UDim2.fromOffset(0, 16),
		AutomaticSize = Enum.AutomaticSize.X,
		BackgroundTransparency = 1,
		Text = "x3",
		TextColor3 = T.OnAccent,
		FontFace = T.FontBadge,
		TextSize = New.FigmaSize(T.FontBadge, 11),
		LayoutOrder = 2,
		ZIndex = 10,
		Parent = holder.Hot,
	})
	New.ApplyImages(holder)
	return holder
end

function ItemSlots.Bind(holder: Instance, e: any, selectedKey: string?, isNew: boolean?)
	local slot = holder:FindFirstChild("ItemSlot")
	if not slot then
		return
	end
	ItemSlots.SetPlus(holder, if e.Kind == "Empty" then nil else e.Plus)
	ItemSlots.SetNotable(holder, if e.Kind == "Empty" then nil else e, isNew == true)
	local hot = holder:FindFirstChild("Hot")
	if hot then
		local mult = if e.Kind == "Fish" then HotFish.Mult(e.Id) else 1
		-- the selected tick sits in the same corner: hide the badge while selected
		hot.Visible = mult > 1 and not (selectedKey ~= nil and selectedKey == e.Key)
		hot.Text.Text = `x{mult}`
	end
	if e.Kind == "Empty" then
		SetItemSlot(slot, { Empty = true })
		return
	end
	local rarity = e.Rarity and Registry.Rarities[e.Rarity]
	local color = e.Color or (if rarity then rarity.Color else T.Track)
	local mut = e.Mutation and Registry.Mutations[e.Mutation]
	SetItemSlot(slot, {
		Icon = e.Icon,
		IconColor = color,
		IconText = string.upper(string.sub(e.Name, 1, 1)),
		CornerColor = color,
		Count = e.Count,
		New = isNew == true,
		Mutation = if mut then "fish/mut_" .. string.lower(e.Mutation) else nil,
		MutationColor = if mut then mut.Color else nil,
		Selected = selectedKey ~= nil and selectedKey == e.Key,
		Ring = if e.Equipped then T.SkyLip else nil,
	})
end

return ItemSlots
