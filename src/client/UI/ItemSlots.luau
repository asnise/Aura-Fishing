--!nonstrict
-- Shared item lists + 72px grid cells for the Inventory (B21) and Character (17 v2) windows.
--   ItemSlots.GearRarity(cat, id)     rarity id for a Rod/Line/Bag (equipment has none: rank by shop order)
--   ItemSlots.Gear(profile, cat)      Rods / Lines in the bag as entries (Kind "Rod" / "Line", one per item)
--   ItemSlots.Auras(profile)          owned auras (Kind "Aura") - auras are normal items, no locked slots
--   ItemSlots.Baits(profile)          baits with count > 0 (Kind "Bait")
--   entry = { Key, Kind, Id, UUID?, Name, Rarity?, Icon, Order, Count?, Equipped?, Color?, Stack?, Mutation?, Value?, Plus? }
--   ItemSlots.NewCell(onPress)        holder Frame with the Components ItemSlot (84px) scaled to 72;
--                                     onPress(holder) on click. Use as VirtualGrid Create.
--   ItemSlots.Bind(holder, entry, selectedKey, isNew?)   fill a cell (Empty entries -> bubbles)

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Registry = require(ReplicatedStorage:WaitForChild("Shared").Registry)
local Inventory = require(ReplicatedStorage.Shared.Inventory)
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

function ItemSlots.Gear(profile: any, cat: string): { any }
	local out = {}
	local kind = Inventory.GearKind(cat)
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
