--!nonstrict
-- Enhance popup (C16), Figma "Economy · 4 Enhance" -> "Screen C16 · Enhance popup" (node 3539:29395).
-- 500 wide cream window r36: Picture 120 (item art) / "Enhance <Name>" / level pills +3 -> +4 /
-- one row per stat "Luck  +17% -> +18%" / sand footer: Cancel + gold coin price button.
-- Opened from the item card's ENHANCE button (UI/ItemDetail); confirm runs the server action there.
--   EnhancePopup.Open({ Name, Icon, State = Enhance.State(...) }, function() ... end)
-- shortcut: no Materials row (Figma "phase 2" Pearls cost, GameConfig.Enhance.PearlCosts is empty); add it with phase 2.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Registry = require(Shared.Registry)
local Format = require(Shared.Util.Format)

local New = require(script.Parent.New)
local Window = require(script.Parent.Window)
local T = New.Theme

local EnhancePopup = {}

local gui: ScreenGui? = nil
local refs: any = nil
local pending: (() -> ())? = nil

local function short(n: number): string
	if n < 1000 then
		return tostring(math.floor(n))
	end
	for _, s in { { 1e9, "B" }, { 1e6, "M" }, { 1e3, "k" } } do
		if n >= s[1] then
			local v = n / s[1]
			local txt = if v < 10 then string.format("%.1f", v) else tostring(math.floor(v))
			return (string.gsub(txt, "%.0$", "")) .. s[2]
		end
	end
	return tostring(n)
end

-- "+17.4%" / "+0.35": one decimal for percents, a +1 level often moves a stat by less than 1%
local function valueText(key: string, v: number): string
	local def = Registry.StatDefs[key]
	if def and def.Percent then
		local pct = (string.gsub(string.format("%.1f", math.abs(v) * 100), "%.0$", ""))
		return (if def.Reduces or v < 0 then "-" else "+") .. pct .. "%"
	end
	local s = Format.Stat(key, def, v) -- "+0.35 Reel Power": drop the name
	return if def then string.sub(s, 1, #s - #def.Display - 1) else s
end

local function levelPill(name: string, color: Color3): TextLabel
	return New("TextLabel", {
		Name = name,
		Size = UDim2.fromOffset(0, 24),
		AutomaticSize = Enum.AutomaticSize.X,
		BackgroundColor3 = color,
		Text = "",
		TextColor3 = T.OnAccent,
		FontFace = T.FontBadge,
		TextSize = New.FigmaSize(T.FontBadge, 12),
		[New.Children] = { New.Corner(999), New("UIPadding", { PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 12) }) },
	}) :: TextLabel
end

local shell: any = nil
local function close()
	pending = nil
	if shell then
		shell.Close()
	end
end

local function ensure()
	if gui then
		return
	end
	-- shell = Window core (ScreenGui in PlayerGui, Modal layer above the item card, open/close/register)
	shell = Window.Shell({ Name = "EnhancePopup", Layer = "Modal", Close = false, Padding = 0, Radius = 36, Size = Vector2.new(500, 491), AutoHeight = true, Clip = true })
	gui = shell.Gui
	local win = shell.Frame
	New("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Parent = win })
	local body = New("Frame", {
		Name = "Body",
		Size = UDim2.fromScale(1, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		LayoutOrder = 1,
		Parent = win,
		[New.Children] = {
			New("UIPadding", { PaddingTop = UDim.new(0, 34), PaddingBottom = UDim.new(0, 26), PaddingLeft = UDim.new(0, 40), PaddingRight = UDim.new(0, 40) }),
			New("UIListLayout", { Padding = UDim.new(0, 10), HorizontalAlignment = Enum.HorizontalAlignment.Center, SortOrder = Enum.SortOrder.LayoutOrder }),
		},
	})
	local picture = New("Frame", { Name = "Picture", Size = UDim2.fromOffset(120, 120), BackgroundColor3 = Color3.new(1, 1, 1), LayoutOrder = 1, Parent = body, [New.Children] = { New.Corner(24), New.Stroke(T.Track, 2) } })
	local img = New.Image({ Name = "Img", Key = "", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(100, 100), Parent = picture })
	local title = New.Title({ Name = "Title", Size = UDim2.new(1, 0, 0, 30), Text = "", TextSize = 26, LayoutOrder = 2, Parent = body })
	local levels = New("Frame", {
		Name = "Levels",
		Size = UDim2.fromOffset(0, 30),
		AutomaticSize = Enum.AutomaticSize.X,
		BackgroundTransparency = 1,
		LayoutOrder = 3,
		Parent = body,
		[New.Children] = { New("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 8), VerticalAlignment = Enum.VerticalAlignment.Center, SortOrder = Enum.SortOrder.LayoutOrder }) },
	})
	local from = levelPill("From", T.SkyLip)
	from.LayoutOrder = 1
	from.Parent = levels
	New("TextLabel", { Name = "Arrow", Size = UDim2.fromOffset(26, 30), BackgroundTransparency = 1, Text = ">", TextColor3 = T.SubText, FontFace = T.Font, TextSize = New.FigmaSize(T.Font, 26), LayoutOrder = 2, Parent = levels })
	local to = levelPill("To", T.GoodLip)
	to.LayoutOrder = 3
	to.Parent = levels
	local rows = New("Frame", {
		Name = "Rows",
		Size = UDim2.new(0, 380, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		LayoutOrder = 4,
		Parent = body,
		[New.Children] = { New("UIListLayout", { Padding = UDim.new(0, 10), SortOrder = Enum.SortOrder.LayoutOrder }) },
	})
	local footer = New("Frame", {
		Name = "Footer",
		Size = UDim2.new(1, 0, 0, 93),
		BackgroundColor3 = T.PanelLight,
		BorderSizePixel = 0,
		LayoutOrder = 2,
		Parent = win,
		[New.Children] = {
			New("UIPadding", { PaddingTop = UDim.new(0, 16), PaddingBottom = UDim.new(0, 20), PaddingLeft = UDim.new(0, 32), PaddingRight = UDim.new(0, 32) }),
			New("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 16), VerticalAlignment = Enum.VerticalAlignment.Center, SortOrder = Enum.SortOrder.LayoutOrder }),
		},
	})
	local cancel = New.Button({ Name = "Cancel", Size = UDim2.new(1, -134, 0, 57), Text = "Cancel", TextSize = 22, LayoutOrder = 1, Parent = footer })
	local buy = New.Button({ Name = "Buy", Size = UDim2.fromOffset(118, 48), Text = "", BackgroundColor3 = T.Gold, LayoutOrder = 2, Parent = footer })
	local cost = New("Frame", {
		Name = "Cost",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(0, 24),
		AutomaticSize = Enum.AutomaticSize.X,
		BackgroundTransparency = 1,
		ZIndex = 5,
		Parent = buy,
		[New.Children] = { New("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 6), VerticalAlignment = Enum.VerticalAlignment.Center, SortOrder = Enum.SortOrder.LayoutOrder }) },
	})
	New.Image({ Name = "Coin", Key = "ui/status/coin", Fallback = T.Gold, Size = UDim2.fromOffset(22, 22), LayoutOrder = 1, ZIndex = 5, Parent = cost })
	local price = New("TextLabel", { Name = "Price", Size = UDim2.fromOffset(0, 24), AutomaticSize = Enum.AutomaticSize.X, BackgroundTransparency = 1, Text = "", TextColor3 = T.OnAccent, FontFace = T.Font, TextSize = New.FigmaSize(T.Font, 20), LayoutOrder = 2, ZIndex = 5, Parent = cost })

	cancel.Activated:Connect(close)
	buy.Activated:Connect(function()
		local cb = pending
		close()
		if cb then
			cb()
		end
	end)
	refs = { Img = img, Title = title, From = from, To = to, Rows = rows, Price = price }
end

local function statRow(key: string, a: number, b: number, order: number): Frame
	local def = Registry.StatDefs[key]
	local row = New("Frame", {
		Name = "Cmp " .. key,
		Size = UDim2.new(1, 0, 0, 22),
		BackgroundTransparency = 1,
		LayoutOrder = order,
		[New.Children] = { New("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }) },
	})
	local function cell(name: string, text: string, color: Color3, w: number?, i: number)
		New("TextLabel", {
			Name = name,
			Size = UDim2.fromOffset(w or 0, 22),
			AutomaticSize = if w then Enum.AutomaticSize.None else Enum.AutomaticSize.X,
			BackgroundTransparency = 1,
			Text = text,
			TextColor3 = color,
			FontFace = T.FontBody,
			TextSize = New.FigmaSize(T.FontBody, 16),
			TextXAlignment = Enum.TextXAlignment.Left,
			LayoutOrder = i,
			Parent = row,
		})
	end
	cell("Label", def and def.Display or key, T.SubText, 130, 1)
	cell("From", valueText(key, a), T.Text, nil, 2)
	cell("Arrow", ">", T.SubText, nil, 3)
	cell("To", valueText(key, b), T.GoodLip, nil, 4)
	return row
end

-- info = { Name, Icon, State = Enhance.State(...) } (State.Coins must be set: not maxed)
function EnhancePopup.Open(info: { [string]: any }, onConfirm: () -> ())
	local state = info.State
	if not state or not state.Coins or not state.NextStats then
		return
	end
	ensure()
	New.SetImageKey(refs.Img, info.Icon)
	refs.Title.Text = `Enhance {info.Name}`
	refs.From.Text = `+{state.Level}`
	refs.To.Text = `+{state.Level + 1}`
	for _, c in refs.Rows:GetChildren() do
		if c:IsA("GuiObject") then
			c:Destroy()
		end
	end
	local keys = {}
	for k in state.NextStats do
		if Registry.StatDefs[k] and state.NextStats[k] ~= (state.Stats[k] or 0) then
			table.insert(keys, k)
		end
	end
	table.sort(keys, function(a, b)
		local ha, hb = Registry.StatDefs[a].Highlight == true, Registry.StatDefs[b].Highlight == true
		if ha ~= hb then
			return ha
		end
		return a < b
	end)
	for i, k in keys do
		statRow(k, state.Stats[k] or 0, state.NextStats[k], i).Parent = refs.Rows
	end
	refs.Price.Text = short(state.Coins)
	pending = onConfirm
	shell.Open()
end

function EnhancePopup.IsOpen(): boolean
	return gui ~= nil and gui.Enabled
end

return EnhancePopup
