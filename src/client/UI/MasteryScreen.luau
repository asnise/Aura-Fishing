--!nonstrict
-- Mastery window, built to match Figma "Economy · 3 Mastery (C15)" → "Window Mastery" (node 3539:31275,
-- export docs/figma/economy_mastery.png). 760x610 cream window, r24:
--   Header  Title "Mastery" (Fredoka 26) + red close button
--   Head    Pearls chip (live) · rate "+0.34/s" · "Total Lv. 84" pill · spacer · "Kept after Rebirth"
--   Tracks  2 columns of 352x92 sand cards (12px gap): icon tile 60 · name + Lv pill + "now → next" ·
--           UPGRADE button with Pearl price (mint = can afford, grey = not enough Pearls, MAX = capped)
-- Icons / tile colours come from Config/Mastery (Icon, IconTile), so a new track needs no code here.
-- MasteryScreen.Create({ OnUpgrade = fn(track) }) -> screen
--   screen.Render(profile, pearlsNow)   rebind the cards (UI/VirtualGrid, pooled views)
--   screen.Tick(pearlsNow, ratePerMin)  every frame: live Pearls, rate, button affordability

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Registry = require(Shared.Registry)
local Aquarium = require(Shared.Aquarium)
local Mastery = require(Shared.Mastery)
local Format = require(Shared.Util.Format)

local New = require(script.Parent.New)
local Window = require(script.Parent.Window)
local VirtualGrid = require(script.Parent.VirtualGrid)

local T = New.Theme
local WHITE = Color3.new(1, 1, 1)

local CARD_W, CARD_H, GAP = 352, 92, 12

local MasteryScreen = {}

-- "407", "2.1k", "1.5M" (Figma price labels)
local function compact(n: number): string
	local function trim(v: number, suffix: string): string
		local s = string.format("%.1f", math.floor(v * 10) / 10)
		return (s:gsub("%.0$", "")) .. suffix
	end
	if n >= 1e6 then
		return trim(n / 1e6, "M")
	elseif n >= 1e3 then
		return trim(n / 1e3, "k")
	end
	return Format.Number(n)
end

-- Bonus as the short Figma text: "+12%", "-5%", "+1h 30m". precise = one decimal for percents
-- (used when whole numbers would make "now" and "next" look the same, e.g. +1.6% -> +1.8%).
local function effectText(stat: string, v: number, precise: boolean?): string
	if math.abs(v) < 1e-9 then
		return if stat == "OfflineCapHours" then "0h" else "0%"
	end
	if stat == "OfflineCapHours" then
		local totalMin = math.floor(v * 60 + 0.5)
		local h, m = totalMin // 60, totalMin % 60
		if m == 0 then
			return `+{h}h`
		end
		return if h > 0 then `+{h}h {m}m` else `+{m}m`
	end
	local def = Registry.StatDefs[stat]
	-- multipliers (Base 1: Reel Power, Pearl Rate, Sell Mult) add +0.01 per 1%, so show them as % too
	if def and (def.Percent or def.Base == 1) then
		local pct = math.abs(v) * 100
		local r = math.floor(pct + 0.5)
		local s = if not precise or math.abs(pct - r) < 0.05 then tostring(r) else string.format("%.1f", pct)
		return `{if def.Reduces then "-" else "+"}{s}%`
	end
	return (string.format("+%.2f", v):gsub("0+$", ""):gsub("%.$", ""))
end

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
			New("UIPadding", { PaddingLeft = UDim.new(0, props.PadL or 10), PaddingRight = UDim.new(0, props.PadR or 12) }),
			New("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, props.Gap or 5), VerticalAlignment = Enum.VerticalAlignment.Center, SortOrder = Enum.SortOrder.LayoutOrder }),
		},
	}) :: Frame
	if props.Stroke then
		New.Stroke(T.Track, 2).Parent = f
	end
	return f
end

local function label(parent: Instance, name: string, text: string, color: Color3, size: number, font: Font?, order: number?): TextLabel
	return New("TextLabel", {
		Name = name,
		Size = UDim2.fromOffset(0, size + 5),
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

function MasteryScreen.Create(handlers: { [string]: any }): any
	local screen: any = {}
	-- shell (ScreenGui in PlayerGui, panel, title, X, open/close/register) = Window core
	local shell = Window.Shell({ Name = "Mastery", Title = "Mastery", WindowName = "Window Mastery" })
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
		[New.Children] = { New("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 10), VerticalAlignment = Enum.VerticalAlignment.Center, SortOrder = Enum.SortOrder.LayoutOrder }) },
	})
	local pearls = pill({ Name = "Pearls", Height = 40, Order = 1, Stroke = true, PadL = 12, PadR = 20, Gap = 8 })
	New.Image({ Name = "Img ui/status/pearl", Key = "ui/status/pearl", Fallback = T.Sky, Size = UDim2.fromOffset(24, 24), LayoutOrder = 1, Parent = pearls })
	local pearlsValue = label(pearls, "Value", "0", T.Text, 20, T.Font)
	pearls.Parent = head
	local rate = pill({ Name = "Rate", Order = 2, Transparent = true, PadL = 0, PadR = 4 })
	local rateValue = label(rate, "Label", "+0/s", T.GoodLip, 12)
	rate.Parent = head
	local total = pill({ Name = "Pill Total Lv", Height = 28, Order = 3, PadL = 10, PadR = 12 })
	New.Image({ Name = "Img ui/mastery/total_level", Key = "ui/mastery/total_level", Fallback = T.Good, Size = UDim2.fromOffset(18, 18), LayoutOrder = 1, Parent = total })
	local totalValue = label(total, "Label", "Total Lv. 0", T.GemLip, 12)
	total.Parent = head
	New("Frame", {
		Name = "Spacer",
		Size = UDim2.fromOffset(1, 1),
		BackgroundTransparency = 1,
		LayoutOrder = 4,
		Parent = head,
		[New.Children] = { New("UIFlexItem", { FlexMode = Enum.UIFlexMode.Fill }) },
	})
	New.Text({ Name = "Note", Size = UDim2.fromOffset(130, 19), Text = "Kept after Rebirth", TextColor3 = T.SubText, TextSize = 14, TextXAlignment = Enum.TextXAlignment.Right, LayoutOrder = 5, Parent = head })

	-- Tracks (y 119 incl. 6px inner margin so strokes/lips are never clipped)
	local grid = New("ScrollingFrame", {
		Name = "Tracks",
		Position = UDim2.fromOffset(-6, 119),
		Size = UDim2.new(1, 12, 1, -119),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 6,
		ScrollBarImageColor3 = T.Track,
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		CanvasSize = UDim2.new(),
		Parent = win,
		[New.Children] = {
			New("UIPadding", { PaddingTop = UDim.new(0, 6), PaddingLeft = UDim.new(0, 6), PaddingRight = UDim.new(0, 6), PaddingBottom = UDim.new(0, 6) }),
			New("UIGridLayout", { CellSize = UDim2.fromOffset(CARD_W, CARD_H), CellPadding = UDim2.fromOffset(GAP, GAP), SortOrder = Enum.SortOrder.LayoutOrder }),
		},
	})

	-- Cards are virtualized (UI/VirtualGrid): pooled views, only the visible rows exist, Render() rebinds.
	-- per view: { Tile, Icon, Name, Lv, From, Arrow, To, Refit, Button, Label, Cost, Value, Price, Can, Track }
	local refsOf: { [Instance]: any } = {}

	local function paint(b: any, can: boolean)
		b.Can = can
		if can then
			New.SetButtonColor(b.Button, T.Good, WHITE)
		else
			New.SetButtonColor(b.Button, T.Disabled, T.DisabledText)
		end
		local textColor = if can then WHITE else T.DisabledText
		b.Label.TextColor3 = textColor
		b.Value.TextColor3 = textColor
	end

	-- shrink the "now → next" line until it fits next to the button (long values like "+12.5%").
	-- Connected once per pooled view; the returned refit() restarts from 14 after every bind.
	local function fitLine(line: Frame, room: Frame, parts: { TextLabel }): () -> ()
		-- one step per call: AbsoluteSize only updates after layout, and the change re-fires fit()
		local size = 14
		local function fit()
			-- room is 0 wide until the flex layout has run: wait for a real width
			if size > 10 and room.AbsoluteSize.X > 40 and line.AbsoluteSize.X > room.AbsoluteSize.X then
				size -= 1
				for _, p in parts do
					p.TextSize = New.FigmaSize(T.FontBody, size)
				end
			end
		end
		line:GetPropertyChangedSignal("AbsoluteSize"):Connect(fit)
		room:GetPropertyChangedSignal("AbsoluteSize"):Connect(fit)
		return function()
			size = 14
			for _, p in parts do
				p.TextSize = New.FigmaSize(T.FontBody, size)
			end
			task.defer(fit)
		end
	end

	local function createCard(): GuiObject
		local card = New("Frame", {
			Name = "Track",
			BackgroundColor3 = T.PanelLight,
			[New.Children] = {
				New.Corner(T.RadiusCard),
				New("UIPadding", { PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 12), PaddingTop = UDim.new(0, 12), PaddingBottom = UDim.new(0, 12) }),
				New("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 12), VerticalAlignment = Enum.VerticalAlignment.Center, SortOrder = Enum.SortOrder.LayoutOrder }),
			},
		})

		-- icon tile: white vector icon on a coloured tile, or full-colour art on white
		local tile = New("Frame", {
			Name = "Icon",
			Size = UDim2.fromOffset(60, 60),
			BackgroundColor3 = WHITE,
			LayoutOrder = 1,
			Parent = card,
			[New.Children] = { New.Corner(T.RadiusButton), New.Stroke(T.Track, 2) },
		})
		local icon = New.Image({
			Name = "Img",
			Key = "",
			Fallback = WHITE,
			FallbackText = "?",
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromOffset(46, 46),
			Parent = tile,
		})

		-- name + Lv pill + effect
		local text = New("Frame", {
			Name = "Text",
			Size = UDim2.fromOffset(0, 50),
			BackgroundTransparency = 1,
			LayoutOrder = 2,
			Parent = card,
			[New.Children] = {
				New("UIFlexItem", { FlexMode = Enum.UIFlexMode.Fill }),
				New("UIListLayout", { FillDirection = Enum.FillDirection.Vertical, Padding = UDim.new(0, 2), SortOrder = Enum.SortOrder.LayoutOrder }),
			},
		})
		local name = New.Title({ Name = "Name", Size = UDim2.new(1, 0, 0, 24), Text = "", TextSize = 20, TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd, LayoutOrder = 1, Parent = text })
		local line = New("Frame", {
			Name = "Line",
			Size = UDim2.fromOffset(0, 24),
			AutomaticSize = Enum.AutomaticSize.X,
			BackgroundTransparency = 1,
			LayoutOrder = 2,
			Parent = text,
			[New.Children] = { New("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 6), VerticalAlignment = Enum.VerticalAlignment.Center, SortOrder = Enum.SortOrder.LayoutOrder }) },
		})
		local lv = pill({ Name = "Pill Lv", Order = 1, PadL = 8, PadR = 8 })
		local lvLabel = label(lv, "Label", "Lv.0", T.GemLip, 12)
		lv.Parent = line
		local effect = New("Frame", {
			Name = "Effect",
			Size = UDim2.fromOffset(0, 19),
			AutomaticSize = Enum.AutomaticSize.X,
			BackgroundTransparency = 1,
			LayoutOrder = 2,
			Parent = line,
			[New.Children] = { New("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 4), VerticalAlignment = Enum.VerticalAlignment.Center, SortOrder = Enum.SortOrder.LayoutOrder }) },
		})
		local from = label(effect, "From", "", T.Text, 14, T.FontBody, 1)
		local arrow = label(effect, "Arrow", "→", T.SubText, 14, T.FontBody, 2)
		local to = label(effect, "To", "", T.GoodLip, 14, T.FontBody, 3)
		local refit = fitLine(line, text, { from, arrow, to })

		-- UPGRADE / MAX button (104x59 incl. lip)
		local btn = New.Button({ Name = "Btn Upgrade", Size = UDim2.fromOffset(104, 59), Text = "", BackgroundColor3 = T.Good, LayoutOrder = 3, Parent = card })
		local up = New("TextLabel", {
			Name = "Label",
			Position = UDim2.fromOffset(0, 7),
			Size = UDim2.new(1, 0, 0, 18),
			BackgroundTransparency = 1,
			Text = "UPGRADE",
			TextColor3 = WHITE,
			FontFace = T.Font,
			TextSize = New.FigmaSize(T.Font, 15),
			ZIndex = 5,
			Parent = btn,
		})
		local cost = New("Frame", {
			Name = "Cost",
			AnchorPoint = Vector2.new(0.5, 0),
			Position = UDim2.new(0.5, 0, 0, 27),
			Size = UDim2.fromOffset(0, 17),
			AutomaticSize = Enum.AutomaticSize.X,
			BackgroundTransparency = 1,
			ZIndex = 5,
			Parent = btn,
			[New.Children] = { New("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 4), VerticalAlignment = Enum.VerticalAlignment.Center, SortOrder = Enum.SortOrder.LayoutOrder }) },
		})
		New.Image({ Name = "Img ui/status/pearl", Key = "ui/status/pearl", Fallback = T.Sky, Size = UDim2.fromOffset(16, 16), LayoutOrder = 1, ZIndex = 5, Parent = cost })
		local value = New("TextLabel", {
			Name = "Value",
			Size = UDim2.fromOffset(0, 17),
			AutomaticSize = Enum.AutomaticSize.X,
			BackgroundTransparency = 1,
			Text = "",
			TextColor3 = WHITE,
			FontFace = T.Font,
			TextSize = New.FigmaSize(T.Font, 14),
			LayoutOrder = 2,
			ZIndex = 5,
			Parent = cost,
		})
		local r = { Tile = tile, Icon = icon, Name = name, Lv = lvLabel, From = from, To = to, Refit = refit, Button = btn, Label = up, Cost = cost, Value = value, Price = nil, Can = nil, Track = nil }
		refsOf[card] = r
		btn.Activated:Connect(function()
			if r.Can and r.Track and handlers.OnUpgrade then
				handlers.OnUpgrade(r.Track)
			end
		end)
		return card
	end

	local lastPearls = 0

	local function bindCard(card: any, t: any)
		local r = refsOf[card]
		r.Track = t
		card.Name = "Track " .. t.Name
		local tileColor = if t.IconTile then (T :: any)[t.IconTile] or T.Good else WHITE
		r.Tile.BackgroundColor3 = tileColor
		local iconSize = if t.IconTile then 34 else 46
		r.Icon.Size = UDim2.fromOffset(iconSize, iconSize)
		New.SetImageKey(r.Icon, t.Icon or "", tileColor, string.sub(t.Name, 1, 1))
		r.Name.Text = t.Name
		r.Lv.Text = `Lv.{t.Level}`
		local nowText = effectText(t.Stat, t.Current)
		local nextText = if t.Next then effectText(t.Stat, t.Next) else nowText
		if t.Next and nextText == nowText then
			nowText, nextText = effectText(t.Stat, t.Current, true), effectText(t.Stat, t.Next, true)
		end
		r.From.Text = nowText
		r.To.Text = nextText
		r.Refit()

		local isMax = t.Price == nil
		r.Label.Position = UDim2.fromOffset(0, if isMax then 0 else 7)
		r.Label.Size = if isMax then UDim2.new(1, 0, 1, -5) else UDim2.new(1, 0, 0, 18)
		r.Label.Text = if isMax then "MAX" else "UPGRADE"
		r.Cost.Visible = not isMax
		r.Value.Text = if t.Price then compact(t.Price) else ""
		r.Price = t.Price
		paint(r, not isMax and lastPearls >= t.Price)
	end

	local cards = VirtualGrid.new(grid, {
		Create = createCard,
		Bind = function(card, t)
			bindCard(card, t)
		end,
	})

	function screen.Render(profile: any, pearlsNow: number)
		if not rendered then
			rendered = true
			shell.SetLoading(false)
		end
		lastPearls = pearlsNow
		cards:SetItems(Mastery.Tracks(profile))
		totalValue.Text = `Total Lv. {Mastery.TotalLevel(profile)}`
		pearlsValue.Text = Aquarium.FormatPearls(pearlsNow)
	end

	-- every frame: live Pearls total + rate; a button turns mint the moment the Pearls are there
	function screen.Tick(pearlsNow: number, ratePerMin: number)
		lastPearls = pearlsNow
		pearlsValue.Text = Aquarium.FormatPearls(pearlsNow)
		rateValue.Text = Aquarium.FormatRate(ratePerMin)
		cards:ForEachVisible(function(card)
			local b = refsOf[card]
			if b.Price then
				local can = pearlsNow >= b.Price
				if can ~= b.Can then
					paint(b, can)
				end
			end
		end)
	end

	screen.Open = shell.Open
	screen.Close = shell.Close
	screen.IsOpen = shell.IsOpen
	screen.Gui = gui
	return screen
end

return MasteryScreen
