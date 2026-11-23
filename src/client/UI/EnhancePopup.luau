--!nonstrict
-- Enhance popup (C16), Figma "C16 · Enhance Progression Table" -> "C16 · Enhance Popup (Attribute Comparison Table)" (node 3788:26962).
-- 500 wide cream window r36:
--   Header: 92x92 Picture / "Enchant Preview" tag / "Enhance <Name>" / Level row "+N > +N+1" with chevron
--   Table: 4-column Attribute Comparison Table (Attribute, Before, After, Gain pill)
--          with auto-scaled fonts so long stat names never get clipped.
--   Footer: Sand panel with Cancel + gold coin price button.
-- Phones / short screens: compact mode (smaller header, shorter footer, the table scrolls after 3 rows) so the
-- window is never scaled down to a sliver.
-- Opened from the item card's ENHANCE button (UI/ItemDetail); confirm runs the server action there.
--   EnhancePopup.Open({ Name, Icon, State = Enhance.State(...) }, function() ... end)

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

-- Colors matching Cozy Lake tokens
local WHITE = Color3.new(1, 1, 1)
local BG_BEFORE_TH = Color3.fromRGB(240, 248, 253)
local BG_BEFORE_CELL = Color3.fromRGB(246, 251, 254)
local BG_AFTER_TH = Color3.fromRGB(240, 250, 245)
local BG_AFTER_CELL = Color3.fromRGB(244, 251, 247)
local ROW_DIVIDER = Color3.fromRGB(240, 234, 225)

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

-- "+17%" / "+0.35": one decimal for percents when needed
local function valueText(key: string, v: number): string
	local def = Registry.StatDefs[key]
	if def and def.Percent then
		local pct = (string.gsub(string.format("%.1f", math.abs(v) * 100), "%.0$", ""))
		return (if def.Reduces or v < 0 then "-" else "+") .. pct .. "%"
	end
	local s = Format.Stat(key, def, v)
	return if def then string.sub(s, 1, #s - #def.Display - 1) else s
end

-- Gain difference text: "+1%", "+0.01", "+0.2%"
local function gainText(key: string, a: number, b: number): string
	local diff = b - a
	local def = Registry.StatDefs[key]
	if def and def.Percent then
		local pct = (string.gsub(string.format("%.1f", math.abs(diff) * 100), "%.0$", ""))
		return (if diff >= 0 then "+" else "-") .. pct .. "%"
	end
	local s = Format.Stat(key, def, diff)
	local clean = if def then string.sub(s, 1, #s - #def.Display - 1) else s
	if diff > 0 and not string.find(clean, "^%+") then
		clean = "+" .. clean
	end
	return clean
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
		TextSize = New.FigmaSize(T.FontBadge, 13),
		[New.Children] = {
			New.Corner(999),
			New("UIPadding", {
				PaddingLeft = UDim.new(0, 10),
				PaddingRight = UDim.new(0, 10),
			}),
		},
	}) :: TextLabel
end

local function chevronBadge(): TextLabel
	return New("TextLabel", {
		Name = "Chevron",
		Size = UDim2.fromOffset(0, 24),
		AutomaticSize = Enum.AutomaticSize.X,
		BackgroundTransparency = 1,
		Text = ">",
		TextColor3 = T.SubText,
		FontFace = T.Font,
		TextSize = New.FigmaSize(T.Font, 18),
		LayoutOrder = 3,
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
	-- 500 wide cream window r36
	shell = Window.Shell({
		Name = "EnhancePopup",
		Layer = "Modal",
		Close = false,
		Padding = 0,
		Radius = 36,
		Size = Vector2.new(500, 480),
		AutoHeight = true,
		Clip = true,
	})
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
			New("UIPadding", {
				PaddingTop = UDim.new(0, 30),
				PaddingBottom = UDim.new(0, 24),
				PaddingLeft = UDim.new(0, 32),
				PaddingRight = UDim.new(0, 32),
			}),
			New("UIListLayout", {
				Padding = UDim.new(0, 18),
				HorizontalAlignment = Enum.HorizontalAlignment.Center,
				SortOrder = Enum.SortOrder.LayoutOrder,
			}),
		},
	})

	-- Top Header Row (Item Icon + Info Stack)
	local header = New("Frame", {
		Name = "Header",
		Size = UDim2.new(1, 0, 0, 92),
		BackgroundTransparency = 1,
		LayoutOrder = 1,
		Parent = body,
		[New.Children] = {
			New("UIListLayout", {
				FillDirection = Enum.FillDirection.Horizontal,
				Padding = UDim.new(0, 16),
				VerticalAlignment = Enum.VerticalAlignment.Center,
				SortOrder = Enum.SortOrder.LayoutOrder,
			}),
		},
	})

	local pictureBox = New("Frame", {
		Name = "Picture",
		Size = UDim2.fromOffset(92, 92),
		BackgroundColor3 = WHITE,
		LayoutOrder = 1,
		Parent = header,
		[New.Children] = {
			New.Corner(22),
			New.Stroke(T.Track, 2),
		},
	})
	local img = New.Image({
		Name = "Img",
		Key = "",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(80, 80),
		Parent = pictureBox,
	})

	local infoStack = New("Frame", {
		Name = "InfoStack",
		Size = UDim2.new(1, -108, 0, 92),
		BackgroundTransparency = 1,
		LayoutOrder = 2,
		Parent = header,
		[New.Children] = {
			New("UIListLayout", {
				FillDirection = Enum.FillDirection.Vertical,
				Padding = UDim.new(0, 4),
				VerticalAlignment = Enum.VerticalAlignment.Center,
				SortOrder = Enum.SortOrder.LayoutOrder,
			}),
		},
	})

	local title = New.Title({
		Name = "Title",
		Size = UDim2.new(1, 0, 0, 30),
		Text = "",
		FontFace = T.Font,
		TextSize = 26,
		LayoutOrder = 2,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = infoStack,
	})

	local levelRow = New("Frame", {
		Name = "LevelRow",
		Size = UDim2.fromOffset(0, 26),
		AutomaticSize = Enum.AutomaticSize.X,
		BackgroundTransparency = 1,
		LayoutOrder = 3,
		Parent = infoStack,
		[New.Children] = {
			New("UIListLayout", {
				FillDirection = Enum.FillDirection.Horizontal,
				Padding = UDim.new(0, 8),
				VerticalAlignment = Enum.VerticalAlignment.Center,
				SortOrder = Enum.SortOrder.LayoutOrder,
			}),
		},
	})

	New("TextLabel", {
		Name = "LevelLabel",
		Size = UDim2.fromOffset(0, 24),
		AutomaticSize = Enum.AutomaticSize.X,
		BackgroundTransparency = 1,
		Text = "Level",
		TextColor3 = T.SubText,
		FontFace = T.FontBody,
		TextSize = New.FigmaSize(T.FontBody, 14),
		LayoutOrder = 1,
		Parent = levelRow,
	})

	local from = levelPill("From", Color3.fromRGB(107, 179, 222))
	from.LayoutOrder = 2
	from.Parent = levelRow

	local chevron = chevronBadge()
	chevron.LayoutOrder = 3
	chevron.Parent = levelRow

	local to = levelPill("To", T.GoodLip)
	to.LayoutOrder = 4
	to.Parent = levelRow

	-- Attribute Comparison Table (4 Columns: Attribute, Before, After, Gain)
	local tableCard = New("Frame", {
		Name = "AttributeTable",
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundColor3 = WHITE,
		ClipsDescendants = true,
		LayoutOrder = 2,
		Parent = body,
		[New.Children] = {
			New.Corner(18),
			New.Stroke(T.Track, 2),
			New("UIListLayout", {
				FillDirection = Enum.FillDirection.Vertical,
				SortOrder = Enum.SortOrder.LayoutOrder,
			}),
		},
	})

	local thRow = New("Frame", {
		Name = "HeadRow",
		Size = UDim2.new(1, 0, 0, 44),
		BackgroundTransparency = 1,
		LayoutOrder = 1,
		Parent = tableCard,
		[New.Children] = {
			New("UIListLayout", {
				FillDirection = Enum.FillDirection.Horizontal,
				SortOrder = Enum.SortOrder.LayoutOrder,
			}),
		},
	})

	local _thAttr = New("TextLabel", {
		Name = "ThAttr",
		Size = UDim2.fromOffset(130, 44),
		BackgroundTransparency = 1,
		Text = "Attribute",
		TextColor3 = T.SubText,
		FontFace = T.Font,
		TextSize = New.FigmaSize(T.Font, 13),
		TextXAlignment = Enum.TextXAlignment.Left,
		LayoutOrder = 1,
		Parent = thRow,
		[New.Children] = {
			New("UIPadding", {
				PaddingLeft = UDim.new(0, 14),
				PaddingRight = UDim.new(0, 14),
			}),
		},
	})

	New("Frame", { Name = "VDiv1", Size = UDim2.new(0, 1, 1, 0), BackgroundColor3 = T.Track, BorderSizePixel = 0, LayoutOrder = 2, Parent = thRow })

	local thBefore = New("Frame", {
		Name = "ThBefore",
		Size = UDim2.fromOffset(84, 44),
		BackgroundColor3 = BG_BEFORE_TH,
		BorderSizePixel = 0,
		LayoutOrder = 3,
		Parent = thRow,
		[New.Children] = {
			New("UIListLayout", {
				FillDirection = Enum.FillDirection.Vertical,
				VerticalAlignment = Enum.VerticalAlignment.Center,
				HorizontalAlignment = Enum.HorizontalAlignment.Center,
			}),
			New("TextLabel", {
				Name = "Label",
				Size = UDim2.new(1, 0, 0, 16),
				BackgroundTransparency = 1,
				Text = "Before",
				TextColor3 = T.SkyLip,
				FontFace = T.FontBadge,
				TextSize = New.FigmaSize(T.FontBadge, 12),
			}),
			New("TextLabel", {
				Name = "Lv",
				Size = UDim2.new(1, 0, 0, 14),
				BackgroundTransparency = 1,
				Text = "+3",
				TextColor3 = T.SkyLip,
				FontFace = T.Font,
				TextSize = New.FigmaSize(T.Font, 12),
			}),
		},
	})

	New("Frame", { Name = "VDiv2", Size = UDim2.new(0, 1, 1, 0), BackgroundColor3 = T.Track, BorderSizePixel = 0, LayoutOrder = 4, Parent = thRow })

	local thAfter = New("Frame", {
		Name = "ThAfter",
		Size = UDim2.fromOffset(84, 44),
		BackgroundColor3 = BG_AFTER_TH,
		BorderSizePixel = 0,
		LayoutOrder = 5,
		Parent = thRow,
		[New.Children] = {
			New("UIListLayout", {
				FillDirection = Enum.FillDirection.Vertical,
				VerticalAlignment = Enum.VerticalAlignment.Center,
				HorizontalAlignment = Enum.HorizontalAlignment.Center,
			}),
			New("TextLabel", {
				Name = "Label",
				Size = UDim2.new(1, 0, 0, 16),
				BackgroundTransparency = 1,
				Text = "After",
				TextColor3 = T.GoodLip,
				FontFace = T.FontBadge,
				TextSize = New.FigmaSize(T.FontBadge, 12),
			}),
			New("TextLabel", {
				Name = "Lv",
				Size = UDim2.new(1, 0, 0, 14),
				BackgroundTransparency = 1,
				Text = "+4",
				TextColor3 = T.GoodLip,
				FontFace = T.Font,
				TextSize = New.FigmaSize(T.Font, 12),
			}),
		},
	})

	New("Frame", { Name = "VDiv3", Size = UDim2.new(0, 1, 1, 0), BackgroundColor3 = T.Track, BorderSizePixel = 0, LayoutOrder = 6, Parent = thRow })

	New("TextLabel", {
		Name = "ThGain",
		Size = UDim2.new(1, -303, 1, 0),
		BackgroundTransparency = 1,
		Text = "Gain",
		TextColor3 = T.SubText,
		FontFace = T.Font,
		TextSize = New.FigmaSize(T.Font, 13),
		TextXAlignment = Enum.TextXAlignment.Right,
		LayoutOrder = 7,
		Parent = thRow,
		[New.Children] = {
			New("UIPadding", {
				PaddingLeft = UDim.new(0, 14),
				PaddingRight = UDim.new(0, 14),
			}),
		},
	})

	-- Divider between header and rows
	New("Frame", {
		Name = "HHeadDiv",
		Size = UDim2.new(1, 0, 0, 1),
		BackgroundColor3 = T.Track,
		BorderSizePixel = 0,
		LayoutOrder = 2,
		Parent = tableCard,
	})

	-- Container for data rows
	local tableBody = New("ScrollingFrame", {
		Name = "TableBody",
		Size = UDim2.new(1, 0, 0, 0),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollBarThickness = 6,
		ScrollBarImageColor3 = T.SubText,
		ScrollBarImageTransparency = 0.2,
		ScrollingDirection = Enum.ScrollingDirection.Y,
		LayoutOrder = 3,
		Parent = tableCard,
		[New.Children] = {
			New("UIListLayout", {
				FillDirection = Enum.FillDirection.Vertical,
				SortOrder = Enum.SortOrder.LayoutOrder,
			}),
		},
	})

	-- Bottom Footer
	local footer = New("Frame", {
		Name = "Footer",
		Size = UDim2.new(1, 0, 0, 93),
		BackgroundColor3 = T.PanelLight,
		BorderSizePixel = 0,
		LayoutOrder = 2,
		Parent = win,
		[New.Children] = {
			New("UIPadding", {
				PaddingTop = UDim.new(0, 16),
				PaddingBottom = UDim.new(0, 20),
				PaddingLeft = UDim.new(0, 32),
				PaddingRight = UDim.new(0, 32),
			}),
			New("UIListLayout", {
				FillDirection = Enum.FillDirection.Horizontal,
				Padding = UDim.new(0, 16),
				VerticalAlignment = Enum.VerticalAlignment.Center,
				SortOrder = Enum.SortOrder.LayoutOrder,
			}),
		},
	})
	local cancel = New.Button({
		Name = "Cancel",
		Size = UDim2.new(1, -134, 0, 52),
		Text = "Cancel",
		TextSize = 20,
		LayoutOrder = 1,
		Parent = footer,
	})
	local buy = New.Button({
		Name = "Buy",
		Size = UDim2.fromOffset(118, 48),
		Text = "",
		BackgroundColor3 = T.Gold,
		LayoutOrder = 2,
		Parent = footer,
	})
	local cost = New("Frame", {
		Name = "Cost",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(0, 24),
		AutomaticSize = Enum.AutomaticSize.X,
		BackgroundTransparency = 1,
		ZIndex = 5,
		Parent = buy,
		[New.Children] = {
			New("UIListLayout", {
				FillDirection = Enum.FillDirection.Horizontal,
				Padding = UDim.new(0, 6),
				VerticalAlignment = Enum.VerticalAlignment.Center,
				SortOrder = Enum.SortOrder.LayoutOrder,
			}),
		},
	})
	New.Image({
		Name = "Coin",
		Key = "ui/status/coin",
		Fallback = T.Gold,
		Size = UDim2.fromOffset(22, 22),
		LayoutOrder = 1,
		ZIndex = 5,
		Parent = cost,
	})
	local price = New("TextLabel", {
		Name = "Price",
		Size = UDim2.fromOffset(0, 24),
		AutomaticSize = Enum.AutomaticSize.X,
		BackgroundTransparency = 1,
		Text = "",
		TextColor3 = T.OnAccent,
		FontFace = T.Font,
		TextSize = New.FigmaSize(T.Font, 20),
		LayoutOrder = 2,
		ZIndex = 5,
		Parent = cost,
	})

	cancel.Activated:Connect(close)
	buy.Activated:Connect(function()
		local cb = pending
		close()
		if cb then
			cb()
		end
	end)

	refs = {
		Img = img,
		Title = title,
		From = from,
		To = to,
		ThBeforeLv = (thBefore :: any).Lv,
		ThAfterLv = (thAfter :: any).Lv,
		TableBody = tableBody,
		Price = price,
		Table = tableCard,
		HeaderList = header:FindFirstChildOfClass("UIListLayout"),
		Body = body,
		BodyPad = body:FindFirstChildOfClass("UIPadding"),
		BodyList = body:FindFirstChildOfClass("UIListLayout"),
		Header = header,
		Picture = pictureBox,
		PictureImg = img,
		Info = infoStack,
		Footer = footer,
		Cancel = cancel,
		Buy = buy,
	}
end

local function statTableRow(key: string, a: number, b: number, order: number, isLast: boolean): Frame
	local def = Registry.StatDefs[key]
	local rowContainer = New("Frame", {
		Name = "RowWrapper_" .. key,
		Size = UDim2.new(1, 0, 0, if isLast then 48 else 49),
		BackgroundTransparency = 1,
		LayoutOrder = order,
		[New.Children] = {
			New("UIListLayout", {
				FillDirection = Enum.FillDirection.Vertical,
				SortOrder = Enum.SortOrder.LayoutOrder,
			}),
		},
	})

	local row = New("Frame", {
		Name = "RowContent",
		Size = UDim2.new(1, 0, 0, 48),
		BackgroundTransparency = 1,
		LayoutOrder = 1,
		Parent = rowContainer,
		[New.Children] = {
			New("UIListLayout", {
				FillDirection = Enum.FillDirection.Horizontal,
				SortOrder = Enum.SortOrder.LayoutOrder,
			}),
		},
	})

	-- Cell 1: Attribute Name (AUTO SCALED FONT with Fredoka One / T.Font)
	New("TextLabel", {
		Name = "CellAttr",
		Size = UDim2.fromOffset(130, 48),
		BackgroundTransparency = 1,
		Text = def and def.Display or key,
		TextColor3 = T.Text,
		FontFace = T.Font,
		TextSize = New.FigmaSize(T.Font, 15),
		TextWrapped = false,
		TextTruncate = Enum.TextTruncate.AtEnd,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Center,
		LayoutOrder = 1,
		Parent = row,
		[New.Children] = {
			New("UIPadding", {
				PaddingLeft = UDim.new(0, 14),
				PaddingRight = UDim.new(0, 4),
			}),
		},
	})

	New("Frame", { Name = "VDiv1", Size = UDim2.new(0, 1, 1, 0), BackgroundColor3 = T.Track, BorderSizePixel = 0, LayoutOrder = 2, Parent = row })

	-- Cell 2: Before Value (Fredoka One, Auto-scaled font)
	New("TextLabel", {
		Name = "CellBefore",
		Size = UDim2.fromOffset(84, 48),
		BackgroundColor3 = BG_BEFORE_CELL,
		BorderSizePixel = 0,
		Text = valueText(key, a),
		TextColor3 = T.Text,
		FontFace = T.Font,
		TextSize = New.FigmaSize(T.Font, 15),
		TextWrapped = false,
		TextTruncate = Enum.TextTruncate.AtEnd,
		TextXAlignment = Enum.TextXAlignment.Center,
		TextYAlignment = Enum.TextYAlignment.Center,
		LayoutOrder = 3,
		Parent = row,
		[New.Children] = {
			New("UIPadding", {
				PaddingLeft = UDim.new(0, 4),
				PaddingRight = UDim.new(0, 4),
			}),
		},
	})

	New("Frame", { Name = "VDiv2", Size = UDim2.new(0, 1, 1, 0), BackgroundColor3 = T.Track, BorderSizePixel = 0, LayoutOrder = 4, Parent = row })

	-- Cell 3: After Value (Fredoka One, Mint Green, Auto-scaled font)
	New("TextLabel", {
		Name = "CellAfter",
		Size = UDim2.fromOffset(84, 48),
		BackgroundColor3 = BG_AFTER_CELL,
		BorderSizePixel = 0,
		Text = valueText(key, b),
		TextColor3 = T.GoodLip,
		FontFace = T.Font,
		TextSize = New.FigmaSize(T.Font, 15),
		TextWrapped = false,
		TextTruncate = Enum.TextTruncate.AtEnd,
		TextXAlignment = Enum.TextXAlignment.Center,
		TextYAlignment = Enum.TextYAlignment.Center,
		LayoutOrder = 5,
		Parent = row,
		[New.Children] = {
			New("UIPadding", {
				PaddingLeft = UDim.new(0, 4),
				PaddingRight = UDim.new(0, 4),
			}),
		},
	})

	New("Frame", { Name = "VDiv3", Size = UDim2.new(0, 1, 1, 0), BackgroundColor3 = T.Track, BorderSizePixel = 0, LayoutOrder = 6, Parent = row })

	-- Cell 4: Gain Badge (Nunito ExtraBold Pill)
	local cellGain = New("Frame", {
		Name = "CellGain",
		Size = UDim2.new(1, -303, 1, 0),
		BackgroundTransparency = 1,
		LayoutOrder = 7,
		Parent = row,
		[New.Children] = {
			New("UIPadding", {
				PaddingLeft = UDim.new(0, 8),
				PaddingRight = UDim.new(0, 12),
			}),
		},
	})

	local _gainBadge = New("TextLabel", {
		Name = "GainBadge",
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, 0, 0.5, 0),
		Size = UDim2.fromOffset(0, 22),
		AutomaticSize = Enum.AutomaticSize.X,
		BackgroundColor3 = T.GoodLip,
		Text = gainText(key, a, b),
		TextColor3 = WHITE,
		FontFace = T.FontBadge,
		TextSize = New.FigmaSize(T.FontBadge, 12),
		TextXAlignment = Enum.TextXAlignment.Center,
		TextYAlignment = Enum.TextYAlignment.Center,
		Parent = cellGain,
		[New.Children] = {
			New.Corner(999),
			New("UIPadding", {
				PaddingLeft = UDim.new(0, 8),
				PaddingRight = UDim.new(0, 8),
			}),
		},
	})

	if not isLast then
		New("Frame", {
			Name = "HRowDiv",
			Size = UDim2.new(1, 0, 0, 1),
			BackgroundColor3 = ROW_DIVIDER,
			BorderSizePixel = 0,
			LayoutOrder = 2,
			Parent = rowContainer,
		})
	end

	return rowContainer
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
	refs.ThBeforeLv.Text = `+{state.Level}`
	refs.ThAfterLv.Text = `+{state.Level + 1}`

	for _, c in refs.TableBody:GetChildren() do
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
		local ha = Registry.StatDefs[a].Highlight == true
		local hb = Registry.StatDefs[b].Highlight == true
		if ha ~= hb then
			return ha
		end
		return a < b
	end)

	for i, k in keys do
		local isLast = i == #keys
		statTableRow(k, state.Stats[k] or 0, state.NextStats[k], i, isLast).Parent = refs.TableBody
	end

	-- Phones / short screens: a wide two-column window (item on the left, table on the right) so it needs no
	-- shrinking. The table scrolls after a few rows.
	local camera = workspace.CurrentCamera
	local viewport = if camera then camera.ViewportSize else Vector2.new(1280, 720)
	local compact = viewport.Y < 560
	local rowH = if compact then 36 else 49
	local maxRows = if compact then 4 else 6
	refs.TableBody.Size = UDim2.new(1, 0, 0, math.min(#keys, maxRows) * rowH)
	refs.TableBody.ScrollingEnabled = #keys > maxRows
	refs.TableBody.CanvasPosition = Vector2.zero
	for _, row in refs.TableBody:GetChildren() do
		if row:IsA("Frame") then
			row.Size = UDim2.new(1, 0, 0, rowH)
			local content = row:FindFirstChild("RowContent")
			if content then
				content.Size = UDim2.new(1, 0, 0, rowH - 1)
				for _, cell in content:GetChildren() do
					if cell:IsA("GuiObject") and cell.Size.Y.Offset > 0 and cell.Name ~= "CellGain" then
						cell.Size = UDim2.new(cell.Size.X.Scale, cell.Size.X.Offset, 0, rowH - 1)
					end
				end
			end
		end
	end
	local pic = if compact then 72 else 92
	refs.Picture.Size = UDim2.fromOffset(pic, pic)
	refs.PictureImg.Size = UDim2.fromOffset(pic - 12, pic - 12)
	refs.Title.TextSize = if compact then 20 else 26
	refs.Title.TextWrapped = compact
	refs.Title.AutomaticSize = if compact then Enum.AutomaticSize.Y else Enum.AutomaticSize.None
	refs.Title.Size = UDim2.new(1, 0, 0, if compact then 0 else 30)
	if compact then
		shell.Frame.Size = UDim2.fromOffset(620, 0)
		refs.BodyList.FillDirection = Enum.FillDirection.Horizontal
		refs.BodyList.VerticalAlignment = Enum.VerticalAlignment.Top
		refs.BodyList.Padding = UDim.new(0, 16)
		refs.HeaderList.FillDirection = Enum.FillDirection.Vertical
		refs.HeaderList.HorizontalAlignment = Enum.HorizontalAlignment.Left
		refs.HeaderList.Padding = UDim.new(0, 8)
		refs.Header.Size = UDim2.fromOffset(170, 0)
		refs.Header.AutomaticSize = Enum.AutomaticSize.Y
		refs.Info.Size = UDim2.new(1, 0, 0, 0)
		refs.Info.AutomaticSize = Enum.AutomaticSize.Y
		refs.Table.Size = UDim2.new(1, -186, 0, 0)
	else
		shell.Frame.Size = UDim2.fromOffset(500, 0)
		refs.BodyList.FillDirection = Enum.FillDirection.Vertical
		refs.BodyList.VerticalAlignment = Enum.VerticalAlignment.Top
		refs.BodyList.Padding = UDim.new(0, 18)
		refs.HeaderList.FillDirection = Enum.FillDirection.Horizontal
		refs.HeaderList.HorizontalAlignment = Enum.HorizontalAlignment.Left
		refs.HeaderList.Padding = UDim.new(0, 16)
		refs.Header.Size = UDim2.new(1, 0, 0, pic)
		refs.Header.AutomaticSize = Enum.AutomaticSize.None
		refs.Info.Size = UDim2.new(1, -(pic + 16), 0, pic)
		refs.Info.AutomaticSize = Enum.AutomaticSize.None
		refs.Table.Size = UDim2.new(1, 0, 0, 0)
	end
	refs.BodyPad.PaddingTop = UDim.new(0, if compact then 18 else 30)
	refs.BodyPad.PaddingBottom = UDim.new(0, if compact then 14 else 24)
	refs.BodyPad.PaddingLeft = UDim.new(0, if compact then 22 else 32)
	refs.BodyPad.PaddingRight = UDim.new(0, if compact then 22 else 32)
	refs.Footer.Size = UDim2.new(1, 0, 0, if compact then 72 else 93)
	refs.Cancel.Size = UDim2.new(1, -134, 0, if compact then 46 else 52)
	refs.Buy.Size = UDim2.fromOffset(118, if compact then 44 else 48)

	refs.Price.Text = short(state.Coins)
	pending = onConfirm
	shell.Open()
end

function EnhancePopup.IsOpen(): boolean
	return gui ~= nil and gui.Enabled
end

return EnhancePopup
