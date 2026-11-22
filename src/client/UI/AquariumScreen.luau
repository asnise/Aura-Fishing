--!nonstrict
-- Aquarium window, built to match Figma "Economy · 2 Aquarium" → "Window Aquarium" (node 3546:35509,
-- export docs/figma/economy_aquarium_window.png). 760x610 cream window, r24:
--   Header  Title "Aquarium" (Fredoka 26) + red close button
--   Head    Pearls chip (live "1,250.38") · rate pill "+0.34/s" · "Offline cap 4h" pill · spacer · "Slots 6 / 20" · MASTERY pill
--   Grid    4 columns of 162x176 cards (12px gap): tank fish (water panel + bubbles, fish art 96, rarity
--           corner, mutation badge, name, rate pill "+0.045/s"; tap = Return to Bag modal), "Add fish" (+), locked "Expand" (button shows only the cost)
--   Footer  hint + coins chip
-- AquariumScreen.Create(handlers) -> screen; screen.Render(profile, stats); screen.Tick(pearls, ratePerMin)
--   handlers: OnRemove(uid), OnAdd(), OnExpand(), OnMastery()

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Registry = require(Shared.Registry)
local Aquarium = require(Shared.Aquarium)
local Format = require(Shared.Util.Format)

local New = require(script.Parent.New)
local Window = require(script.Parent.Window)
local Components = require(script.Parent.Components)
local VirtualGrid = require(script.Parent.VirtualGrid)

local T = New.Theme
local WHITE = Color3.new(1, 1, 1)
local GOOD_TEXT = Color3.fromRGB(79, 175, 138) -- Figma #4FAF8A
local WATER_TOP = Color3.fromRGB(207, 239, 255) -- SkySoft
local WATER_BOTTOM = Color3.fromRGB(165, 214, 242)

local CARD_W, CARD_H, GAP = 162, 176, 12

local AquariumScreen = {}

local function pill(props: { [string]: any }): Frame
	local f = New("Frame", {
		Name = props.Name,
		Size = UDim2.fromOffset(0, props.Height or 24),
		AutomaticSize = Enum.AutomaticSize.X,
		BackgroundColor3 = props.Color or T.Panel,
		BackgroundTransparency = props.Transparent and 1 or 0,
		LayoutOrder = props.Order or 0,
		[New.Children] = {
			New.Pill(),
			New("UIPadding", { PaddingLeft = UDim.new(0, props.PadL or 10), PaddingRight = UDim.new(0, props.PadR or 14) }),
			New("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 6), VerticalAlignment = Enum.VerticalAlignment.Center, SortOrder = Enum.SortOrder.LayoutOrder }),
		},
	}) :: Frame
	if props.Stroke then
		New.Stroke(T.Track, 2).Parent = f
	end
	return f
end

local function pillText(parent: Instance, name: string, text: string, color: Color3, size: number, font: Font?, order: number?): TextLabel
	return New("TextLabel", {
		Name = name,
		Size = UDim2.fromOffset(0, size + 4),
		AutomaticSize = Enum.AutomaticSize.X,
		BackgroundTransparency = 1,
		Text = text,
		TextColor3 = color,
		FontFace = font or T.FontBadge,
		TextSize = New.FigmaSize(font or T.FontBadge, size),
		LayoutOrder = order or 2,
		Parent = parent,
	}) :: TextLabel
end

local function rarityCorner(parent: Instance, color: Color3)
	local leg = 30 / (2 * CARD_W) -- same hard-edged gradient trick as Make.ItemSlot
	New("Frame", {
		Name = "Rarity Corner",
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = color,
		BorderSizePixel = 0,
		ZIndex = 4,
		Parent = parent,
		[New.Children] = {
			New.Corner(T.RadiusCard),
			New("UIGradient", {
				Rotation = 45,
				Transparency = NumberSequence.new({
					NumberSequenceKeypoint.new(0, 0),
					NumberSequenceKeypoint.new(leg, 0),
					NumberSequenceKeypoint.new(leg + 0.002, 1),
					NumberSequenceKeypoint.new(1, 1),
				}),
			}),
		},
	})
end

function AquariumScreen.Create(handlers: { [string]: any }): any
	local screen: any = {}
	-- shell (ScreenGui in PlayerGui, panel, title, X, open/close/register) = Window core
	local shell = Window.Shell({ Name = "Aquarium", Title = "Aquarium", WindowName = "Window Aquarium", ScrollOnShort = true })
	local gui, win = shell.Gui, shell.Frame
	local rendered = false
	shell.OnOpen = function()
		if not rendered then
			shell.SetLoading(true) -- spins until the controller renders the save data
		end
	end

	-- Head row (y 71)
	local head = New("Frame", {
		Name = "Head",
		Position = UDim2.fromOffset(0, 71),
		Size = UDim2.new(1, 0, 0, 40),
		BackgroundTransparency = 1,
		Parent = win,
		[New.Children] = { New("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 12), VerticalAlignment = Enum.VerticalAlignment.Center, SortOrder = Enum.SortOrder.LayoutOrder }) },
	})
	local pearls = pill({ Name = "Pearls", Height = 40, Order = 1, Stroke = true, PadL = 12, PadR = 20 })
	New.Image({ Name = "Img ui/status/pearl", Key = "ui/status/pearl", Fallback = T.Sky, Size = UDim2.fromOffset(24, 24), LayoutOrder = 1, Parent = pearls })
	local pearlsValue = pillText(pearls, "Value", "0", T.Text, 20, T.Font)
	pearls.Parent = head
	local rate = pill({ Name = "Rate", Order = 2, Transparent = true, PadL = 0, PadR = 10 })
	local rateValue = pillText(rate, "Label", "+0/s", GOOD_TEXT, 12)
	rate.Parent = head
	local cap = pill({ Name = "Offline Cap", Order = 3, Color = T.PanelLight, PadL = 10, PadR = 14 })
	New.Image({ Name = "icon_timer", Key = "icon_timer", Fallback = T.SubText, ImageColor3 = T.SubText, Size = UDim2.fromOffset(14, 14), LayoutOrder = 1, Parent = cap })
	local capValue = pillText(cap, "Label", "Offline cap 4h", T.SubText, 12)
	cap.Parent = head
	New("Frame", {
		Name = "Spacer",
		Size = UDim2.fromOffset(1, 1),
		BackgroundTransparency = 1,
		LayoutOrder = 4,
		Parent = head,
		[New.Children] = { New("UIFlexItem", { FlexMode = Enum.UIFlexMode.Fill }) },
	})
	local slots = New.Text({ Name = "Slots", Size = UDim2.fromOffset(90, 19), Text = "Slots 0 / 0", TextColor3 = T.SubText, TextSize = 14, TextXAlignment = Enum.TextXAlignment.Right, LayoutOrder = 5, Parent = head })

	-- Grid (y 125, 2 rows visible, scrolls)
	local grid = New("ScrollingFrame", {
		Name = "Grid",
		Position = UDim2.fromOffset(-6, 119),
		Size = UDim2.new(1, 12, 0, 376),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 6,
		ScrollBarImageColor3 = T.Track,
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		CanvasSize = UDim2.new(),
		Parent = win,
		[New.Children] = {
			-- inner margin so card strokes/badges are never clipped by the scroll frame
			New("UIPadding", { PaddingTop = UDim.new(0, 6), PaddingLeft = UDim.new(0, 6), PaddingRight = UDim.new(0, 6), PaddingBottom = UDim.new(0, 6) }),
			New("UIGridLayout", { CellSize = UDim2.fromOffset(CARD_W, CARD_H), CellPadding = UDim2.fromOffset(GAP, GAP), SortOrder = Enum.SortOrder.LayoutOrder }),
		},
	})

	-- Footer (y 525)
	New.Text({ Name = "Hint", Position = UDim2.fromOffset(0, 535), Size = UDim2.fromOffset(420, 19), Text = "Fish here make Pearls, even while you're offline.", TextColor3 = T.SubText, TextSize = 14, TextXAlignment = Enum.TextXAlignment.Left, Parent = win })
	local coins = Components.Clone("CurrencyChip")
	coins.Name = "Coins"
	coins.AnchorPoint = Vector2.new(1, 0)
	coins.Position = UDim2.new(1, 0, 0, 525)
	New.SetImageKey(coins.Icon, "ui/status/coin", T.Gold)
	New.FormatCurrencyChip(coins, 20)
	coins.Parent = win

	-- Cards are virtualized (UI/VirtualGrid): one pooled view per kind (Fish / Empty / Locked), only the
	-- visible rows exist, Render() rebinds instead of destroying and rebuilding every card.
	local refsOf: { [Instance]: any } = {} -- view -> named parts that Bind changes

	local function createFish(): GuiObject
		local card = New("TextButton", {
			Name = "Tank Fish",
			BackgroundColor3 = WHITE,
			Text = "",
			AutoButtonColor = false,
			[New.Children] = { New.Corner(T.RadiusCard), New.Stroke(T.Track, 2) },
		})
		local water = New("Frame", {
			Name = "Water",
			Size = UDim2.new(1, 0, 0, 118),
			BackgroundColor3 = WHITE,
			BorderSizePixel = 0,
			Parent = card,
			[New.Children] = {
				New.Corner(T.RadiusCard),
				New("UIGradient", { Rotation = 90, Color = ColorSequence.new(WATER_TOP, WATER_BOTTOM) }),
			},
		})
		-- square off the water panel's bottom corners
		New("Frame", { Name = "WaterBottom", Position = UDim2.new(0, 0, 1, -T.RadiusCard), Size = UDim2.new(1, 0, 0, T.RadiusCard), BackgroundColor3 = WATER_BOTTOM, BorderSizePixel = 0, Parent = water })
		for _, b in { { 18, 22, 10 }, { 30, 42, 6 } } do
			New("Frame", { Name = "Bubble", Position = UDim2.fromOffset(b[1], b[2]), Size = UDim2.fromOffset(b[3], b[3]), BackgroundColor3 = WHITE, BackgroundTransparency = 0.35, ZIndex = 2, Parent = card, [New.Children] = { New.Pill() } })
		end
		local fishImg = New.Image({ Name = "Img fish", Key = "fish/PebbleMinnow", Fallback = WATER_BOTTOM, FallbackText = "?", Position = UDim2.fromOffset(33, 12), Size = UDim2.fromOffset(96, 96), ZIndex = 3, Parent = card })
		rarityCorner(card, T.Track)
		local mutImg = New.Image({ Name = "Img fish/mut", Key = "", Fallback = T.Good, Position = UDim2.fromOffset(130, 6), Size = UDim2.fromOffset(26, 26), ZIndex = 5, Visible = false, Parent = card })
		local name = New.Title({ Name = "FishName", Position = UDim2.fromOffset(12, 124), Size = UDim2.new(1, -24, 0, 24), Text = "", TextSize = 18, TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd, Parent = card })
		local ratePill = pill({ Name = "Rate", Height = 22, PadL = 6, PadR = 12 })
		ratePill.Position = UDim2.fromOffset(10, 148)
		New.Image({ Name = "Img ui/status/pearl", Key = "ui/status/pearl", Fallback = T.Sky, Size = UDim2.fromOffset(16, 16), LayoutOrder = 1, Parent = ratePill })
		local rate = pillText(ratePill, "Value", "", GOOD_TEXT, 12)
		ratePill.Parent = card
		refsOf[card] = { Fish = fishImg, Corner = card:FindFirstChild("Rarity Corner"), Mutation = mutImg, Name = name, Rate = rate }
		return card
	end

	local function bindFish(card: any, f: any)
		local r = refsOf[card]
		local def = Registry.Fish[f.Id]
		local rarity = def and Registry.Rarities[def.Rarity]
		card.Name = "Tank " .. f.Id
		New.SetImageKey(r.Fish, "fish/" .. f.Id, WATER_BOTTOM, "?")
		r.Corner.BackgroundColor3 = if rarity then rarity.Color else T.Track
		local mut = f.Mutation and Registry.Mutations[f.Mutation]
		r.Mutation.Visible = mut ~= nil
		if mut then
			New.SetImageKey(r.Mutation, "fish/mut_" .. string.lower(f.Mutation), mut.Color)
		end
		r.Name.Text = def and def.Name or f.Id
		r.Rate.Text = Aquarium.FormatRate(f.Rate)
	end

	local function createEmpty(): GuiObject
		local card = New("TextButton", { Name = "Btn Tank Empty", BackgroundColor3 = T.PanelLight, Text = "", AutoButtonColor = false, [New.Children] = { New.Corner(T.RadiusCard), New.Stroke(T.Track, 2) } })
		New("TextLabel", { Name = "Plus", Position = UDim2.fromOffset(0, 44), Size = UDim2.new(1, 0, 0, 53), BackgroundTransparency = 1, Text = "+", TextColor3 = Color3.fromRGB(201, 187, 163), FontFace = T.Font, TextSize = 44, Parent = card })
		New.Text({ Name = "Label", Position = UDim2.fromOffset(0, 108), Size = UDim2.new(1, 0, 0, 19), Text = "Add fish", TextColor3 = T.SubText, TextSize = 14, Parent = card })
		return card
	end

	local function createLocked(): GuiObject
		local card = New("Frame", { Name = "Btn Tank Locked", BackgroundColor3 = T.PanelLight, [New.Children] = { New.Corner(T.RadiusCard), New.Stroke(T.Track, 2) } })
		New.Image({ Name = "icon_lock", Key = "icon_lock", Fallback = T.SubText, ImageColor3 = Color3.fromRGB(176, 160, 136), AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 40), Size = UDim2.fromOffset(30, 34), Parent = card })
		New.Text({ Name = "Label", Position = UDim2.fromOffset(0, 86), Size = UDim2.new(1, 0, 0, 19), Text = "Expand", TextColor3 = T.SubText, TextSize = 14, Parent = card })
		local b = New.Button({ Name = "Btn Expand", AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 112), Size = UDim2.fromOffset(118, 59), Text = "", BackgroundColor3 = T.Gold, Parent = card })
		local cost = New("Frame", {
			Name = "Cost",
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromOffset(0, 22),
			AutomaticSize = Enum.AutomaticSize.X,
			BackgroundTransparency = 1,
			ZIndex = 5,
			Parent = b,
			[New.Children] = { New("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 4), VerticalAlignment = Enum.VerticalAlignment.Center, SortOrder = Enum.SortOrder.LayoutOrder }) },
		})
		New.Image({ Name = "Coin", Key = "ui/status/coin", Fallback = T.Gold, Size = UDim2.fromOffset(18, 18), LayoutOrder = 1, ZIndex = 5, Parent = cost })
		local value = New("TextLabel", { Name = "Value", Size = UDim2.fromOffset(0, 20), AutomaticSize = Enum.AutomaticSize.X, BackgroundTransparency = 1, Text = "", TextColor3 = WHITE, FontFace = T.FontBadge, TextSize = New.FigmaSize(T.FontBadge, 17), LayoutOrder = 2, ZIndex = 5, Parent = cost })
		refsOf[card] = { Button = b, Value = value }
		return card
	end

	local function bindLocked(card: any, it: any)
		local r = refsOf[card]
		local price = it.Price
		r.Value.Text = if price >= 1000000 then string.format("%gM", math.floor(price / 100000) / 10) elseif price >= 10000 then string.format("%gk", math.floor(price / 100) / 10) else Format.Number(price)
		local textColor = if it.CanBuy then WHITE else T.DisabledText
		r.Value.TextColor3 = textColor
		if it.CanBuy then
			New.SetButtonColor(r.Button, T.Gold)
		else
			New.SetButtonColor(r.Button, T.Disabled, T.DisabledText)
		end
	end

	local cards
	cards = VirtualGrid.new(grid, {
		KindOf = function(it)
			return it.Kind
		end,
		Create = function(kind)
			local card
			if kind == "Fish" then
				card = createFish()
			elseif kind == "Empty" then
				card = createEmpty()
			else
				card = createLocked()
			end
			local button = if kind == "Locked" then refsOf[card].Button else card
			button.Activated:Connect(function()
				local it = cards:ItemOf(card)
				if not it then
					return
				end
				if it.Kind == "Fish" then
					if handlers.OnSelect then
						handlers.OnSelect(it.Fish)
					elseif handlers.OnRemove then
						handlers.OnRemove(it.Fish)
					end
				elseif it.Kind == "Empty" then
					handlers.OnAdd()
				elseif it.IsNext then
					handlers.OnExpand()
				end
			end)
			return card
		end,
		Bind = function(card, it, _, kind)
			if kind == "Fish" then
				bindFish(card, it.Fish)
			elseif kind == "Locked" then
				bindLocked(card, it)
			end
		end,
	})

	function screen.Render(profile: any, stats: any)
		if not rendered then
			rendered = true
			shell.SetLoading(false)
		end
		local st = Aquarium.State(profile, stats)
		local items = {}
		for _, f in st.Fish do
			table.insert(items, { Kind = "Fish", Fish = f })
		end
		for _ = #st.Fish + 1, st.Slots do
			table.insert(items, { Kind = "Empty" })
		end
		-- next slot to buy + one preview after it (Figma shows two locked cards)
		local cfg = Registry.GameConfig.Aquarium
		for k = 0, 1 do
			local price = cfg.SlotPrices[st.Slots - cfg.StartSlots + 1 + k]
			if price then
				table.insert(items, { Kind = "Locked", Price = price, CanBuy = k == 0 and profile.Coins >= price, IsNext = k == 0 })
			end
		end
		cards:SetItems(items)
		slots.Text = `Slots {#st.Fish} / {st.Slots}`
		capValue.Text = `Offline cap {st.OfflineCapHours}h` .. (if st.Boost > 1 then ` | x{st.Boost} boost` else "")
		coins.Value.Text = Format.Number(profile.Coins)
	end

	-- every frame: live Pearls total + total rate
	function screen.Tick(pearlsNow: number, ratePerMin: number)
		pearlsValue.Text = Aquarium.FormatPearls(pearlsNow)
		rateValue.Text = Aquarium.FormatRate(ratePerMin)
	end

	screen.Open = shell.Open
	screen.Close = shell.Close
	screen.IsOpen = shell.IsOpen
	screen.Gui = gui
	return screen
end

return AquariumScreen
