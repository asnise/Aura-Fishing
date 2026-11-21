--!nonstrict
-- Figma 05/06 Shop, 07 Auras, 09 Fishdex (page Out Space): one ScreenGui "Menus" with three fixed
-- 760x610 windows. Lists have a fixed number of slots per page (Shop 4 rows, Auras 3 rows + equipped
-- card, Fishdex 3x2 cards); MenuController fills them and drives the pager. Static layout only.

local New = require(script.Parent.Parent.New)
local T = New.Theme

local Screen = { Name = "Menus" }

local WINDOW = Vector2.new(760, 610)
local PAD = 22
local INNER = WINDOW.X - PAD * 2 -- 716

Screen.ShopRows = 4
Screen.AuraCards = 6
Screen.DexCards = 6

local function window(gui: ScreenGui, name: string, title: string): Frame
	local w = New.Panel({
		Name = name,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(WINDOW.X, WINDOW.Y),
		Radius = T.RadiusWindow,
		Visible = false,
		Parent = gui,
	})
	New.Shadow(w, "slice_shadow_window")
	local header = New("Frame", { Name = "Header", Position = UDim2.fromOffset(PAD, PAD), Size = UDim2.fromOffset(INNER, 57), BackgroundTransparency = 1, Parent = w })
	New.Title({ Name = "Title", Position = UDim2.fromOffset(0, 14), Size = UDim2.fromOffset(400, 30), Text = title, TextXAlignment = Enum.TextXAlignment.Left, TextSize = 26, Parent = header })
	New.Button({ Name = "Close", AnchorPoint = Vector2.new(1, 0), Position = UDim2.fromScale(1, 0), Size = UDim2.fromOffset(73, 57), Text = "X", BackgroundColor3 = T.Bad, TextSize = 22, Parent = header })
	return w
end

local function chip(parent: Instance, name: string, color: Color3, iconKey: string, width: number, order: number)
	local c = New("Frame", {
		Name = name,
		Size = UDim2.fromOffset(width, 40),
		AutomaticSize = Enum.AutomaticSize.X,
		BackgroundColor3 = T.Panel,
		LayoutOrder = order,
		Parent = parent,
		[New.Children] = {
			New.Pill(),
			New.Stroke(),
			New("UIPadding", {
				PaddingLeft = UDim.new(0, 12),
				PaddingRight = UDim.new(0, 20),
			}),
			New("UIListLayout", {
				FillDirection = Enum.FillDirection.Horizontal,
				Padding = UDim.new(0, 8),
				VerticalAlignment = Enum.VerticalAlignment.Center,
				SortOrder = Enum.SortOrder.LayoutOrder,
			}),
			New.Image({
				Name = "Icon",
				Key = iconKey,
				Fallback = color,
				Size = UDim2.fromOffset(24, 24),
				LayoutOrder = 1,
			}),
		},
	})
	local icon = c:FindFirstChild("Icon")
	if icon then
		New.Pill().Parent = icon:FindFirstChild("Fallback")
	end
	New.Title({
		Name = "Value",
		Size = UDim2.fromOffset(0, 22),
		AutomaticSize = Enum.AutomaticSize.X,
		Text = "0",
		TextXAlignment = Enum.TextXAlignment.Left,
		TextSize = 20,
		LayoutOrder = 2,
		Parent = c,
	})
end

local function footer(w: Frame, y: number, pagerX: number?, wallet: { string }): Frame
	local f = New("Frame", { Name = "Footer", Position = UDim2.fromOffset(PAD, y), Size = UDim2.fromOffset(INNER, 57), BackgroundTransparency = 1, Parent = w })
	if pagerX then
		New.Pager({ Position = UDim2.fromOffset(pagerX, 0), Parent = f })
	end
	if #wallet > 0 then
		local wl = New("Frame", {
			Name = "Wallet",
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, 0, 0.5, 0),
			Size = UDim2.fromOffset(240, 40),
			AutomaticSize = Enum.AutomaticSize.X,
			BackgroundTransparency = 1,
			Parent = f,
			[New.Children] = {
				New("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, HorizontalAlignment = Enum.HorizontalAlignment.Right, Padding = UDim.new(0, 10), SortOrder = Enum.SortOrder.LayoutOrder }),
			},
		})
		for i, cur in wallet do
			if cur == "Coins" then
				chip(wl, "Coins", T.Gold, "ui/status/coin", 120, i)
			else
				chip(wl, "Gems", T.Gem, "ui/status/gem", 97, i)
			end
		end
	end
	return f
end

-- 716x80 sand row: picture, title + sub line (or badges), status pill, Use + Action buttons.
local function listRow(parent: Instance, name: string, y: number, withBadges: boolean): Frame
	local r = New("Frame", {
		Name = name,
		Position = UDim2.fromOffset(0, y),
		Size = UDim2.fromOffset(INNER, 80),
		BackgroundColor3 = T.PanelLight,
		Visible = false,
		Parent = parent,
		[New.Children] = { New.Corner(T.RadiusButton) },
	})
	New.Image({ Name = "Picture", Key = "auras/UnknownAura", Fallback = T.Track, Position = UDim2.fromOffset(12, 12), Size = UDim2.fromOffset(56, 56), Parent = r })
	local top = New("Frame", {
		Name = "Top",
		Position = UDim2.fromOffset(80, if withBadges then 16 else 18),
		Size = UDim2.fromOffset(460, 24),
		BackgroundTransparency = 1,
		Parent = r,
		[New.Children] = { New("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 8), VerticalAlignment = Enum.VerticalAlignment.Center, SortOrder = Enum.SortOrder.LayoutOrder }) },
	})
	New("TextLabel", {
		Name = "Title",
		Size = UDim2.fromOffset(0, 24),
		AutomaticSize = Enum.AutomaticSize.X,
		BackgroundTransparency = 1,
		Text = "Item name",
		TextColor3 = T.Text,
		FontFace = T.Font,
		TextSize = New.FigmaSize(T.Font, 20),
		LayoutOrder = 1,
		Parent = top,
	})
	if withBadges then
		-- rarity tag + chance pill next to the name, stat badges on the second line
		local tags = New.BadgeSlots(2, { Name = "Tags", Size = UDim2.fromOffset(0, 21), AutomaticSize = Enum.AutomaticSize.X, LayoutOrder = 2, Parent = top })
		tags.LayoutOrder = 2
		New.BadgeSlots(4, { Name = "Badges", Position = UDim2.fromOffset(80, 44), Size = UDim2.fromOffset(460, 21), Parent = r })
	else
		New.Text({
			Name = "Sub",
			Position = UDim2.fromOffset(80, 44),
			Size = UDim2.fromOffset(INNER - 80 - 154 - 24, 19), -- up to the Action button (Figma subs run that far)
			Text = "Description",
			TextColor3 = T.SubText,
			TextSize = 14,
			TextTruncate = Enum.TextTruncate.AtEnd,
			TextXAlignment = Enum.TextXAlignment.Left,
			Parent = r,
		})
	end
	New("TextLabel", {
		Name = "Status",
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -12 - 154 - 12, 0.5, 0),
		Size = UDim2.fromOffset(0, 21),
		AutomaticSize = Enum.AutomaticSize.X,
		BackgroundColor3 = T.PanelLight,
		Text = "x1",
		TextColor3 = T.Text,
		FontFace = T.FontBadge,
		TextSize = New.FigmaSize(T.FontBadge, 12),
		Visible = false,
		Parent = r,
		[New.Children] = { New.Pill(), New("UIPadding", { PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10) }) },
	})
	local action = New.Button({ Name = "Action", AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -12, 0.5, 0), Size = UDim2.fromOffset(154, 57), Text = "", BackgroundColor3 = T.Gold, TextSize = 22, Parent = r })
	-- Figma 05/06 price button: cream circle with the currency icon + price instead of the word "Buy"
	local price = New("Frame", {
		Name = "Price",
		Size = UDim2.new(1, 0, 1, -New.ButtonLipPx), -- centred on the face, not the lip
		BackgroundTransparency = 1,
		Parent = action,
		[New.Children] = {
			New("UIListLayout", {
				FillDirection = Enum.FillDirection.Horizontal,
				HorizontalAlignment = Enum.HorizontalAlignment.Center,
				VerticalAlignment = Enum.VerticalAlignment.Center,
				Padding = UDim.new(0, 8),
				SortOrder = Enum.SortOrder.LayoutOrder,
			}),
		},
	})
	local icon = New("Frame", { Name = "Icon", Size = UDim2.fromOffset(30, 30), BackgroundColor3 = T.Panel, LayoutOrder = 1, Parent = price, [New.Children] = { New.Pill() } })
	New.Image({ Name = "Image", Key = "ui/status/coin", Fallback = T.Gold, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(22, 22), Parent = icon })
	New("TextLabel", {
		Name = "Label",
		Size = UDim2.fromOffset(0, 30),
		AutomaticSize = Enum.AutomaticSize.X,
		BackgroundTransparency = 1,
		Text = "2,500",
		TextColor3 = T.OnAccent,
		FontFace = T.Font,
		TextSize = New.FigmaSize(T.Font, 22),
		LayoutOrder = 2,
		Parent = price,
	})
	New.Button({ Name = "Use", AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -12 - 154 - 12, 0.5, 0), Size = UDim2.fromOffset(95, 57), Text = "Use", BackgroundColor3 = T.Sky, TextSize = 22, Visible = false, Parent = r })
	return r
end

local function buildShop(gui: ScreenGui)
	local w = window(gui, "Shop", "Shop")
	local tabs = New("Frame", {
		Name = "Tabs",
		Position = UDim2.fromOffset(PAD, 93),
		Size = UDim2.fromOffset(INNER, 57),
		BackgroundTransparency = 1,
		Parent = w,
		[New.Children] = { New("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }) },
	})
	-- 6 fixed tab slots; MenuController labels/sizes the ones that match Config.Equipment categories
	for i = 1, 6 do
		New.Button({ Name = "Tab" .. i, Size = UDim2.fromOffset(173, 57), Text = "Tab", TextSize = 22, LayoutOrder = i, Visible = i <= 4, Parent = tabs })
	end
	local list = New("Frame", { Name = "List", Position = UDim2.fromOffset(PAD, 164), Size = UDim2.fromOffset(INNER, 350), BackgroundTransparency = 1, Parent = w })
	for i = 1, Screen.ShopRows do
		listRow(list, "Row" .. i, (i - 1) * 90, false)
	end
	New.Text({
		Name = "Empty",
		Position = UDim2.fromOffset(0, 140),
		Size = UDim2.fromOffset(INNER, 30),
		Text = "Nothing here yet",
		TextColor3 = T.SubText,
		Visible = false,
		Parent = list,
	})
	footer(w, 528, 0, { "Coins", "Gems" })
end

local function auraCard(parent: Instance, name: string): Frame
	local card = New("Frame", {
		Name = name,
		Size = UDim2.fromOffset(228, 140),
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		Visible = false,
		Parent = parent,
		[New.Children] = {
			New.Corner(18),
			New.Stroke(T.Track, 1.5),
		},
	})

	-- Picture: 58x58
	New.Image({
		Name = "Picture",
		Key = "auras/UnknownAura",
		Fallback = T.Track,
		Position = UDim2.fromOffset(10, 14),
		Size = UDim2.fromOffset(58, 58),
		Parent = card,
		[New.Children] = { New.Corner(14) },
	})

	-- Name: Fredoka One 15px
	New("TextLabel", {
		Name = "AuraName",
		Position = UDim2.fromOffset(76, 12),
		Size = UDim2.fromOffset(116, 20),
		BackgroundTransparency = 1,
		Text = "Sparkling Dew",
		TextColor3 = T.Text,
		FontFace = T.Font,
		TextSize = New.FigmaSize(T.Font, 15),
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Parent = card,
	})

	-- Rarity: Nunito Bold 12px
	New("TextLabel", {
		Name = "Rarity",
		Position = UDim2.fromOffset(76, 32),
		Size = UDim2.fromOffset(116, 16),
		BackgroundTransparency = 1,
		Text = "Common",
		TextColor3 = T.SubText,
		FontFace = T.FontBody,
		TextSize = New.FigmaSize(T.FontBody, 12),
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = card,
	})

	-- State: Nunito Bold 12px, #5b418d
	New("TextLabel", {
		Name = "State",
		Position = UDim2.fromOffset(76, 48),
		Size = UDim2.fromOffset(116, 16),
		BackgroundTransparency = 1,
		Text = "Discovered",
		TextColor3 = Color3.fromRGB(91, 65, 141),
		FontFace = T.FontBody,
		TextSize = New.FigmaSize(T.FontBody, 12),
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = card,
	})

	-- Chance: Nunito Bold 12px, SubText
	New("TextLabel", {
		Name = "Chance",
		Position = UDim2.fromOffset(76, 64),
		Size = UDim2.fromOffset(116, 16),
		BackgroundTransparency = 1,
		Text = "1 in 10",
		TextColor3 = T.SubText,
		FontFace = T.FontBody,
		TextSize = New.FigmaSize(T.FontBody, 12),
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = card,
	})

	-- Locked mark: lock icon at top right
	New.Image({
		Name = "LockedMark",
		Key = "ui/icons/lock",
		Fallback = T.Text,
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -10, 0, 10),
		Size = UDim2.fromOffset(20, 20),
		Visible = false,
		Parent = card,
	})

	-- Footer: 208x34 fill #eee5fa, corner 11
	local foot = New("Frame", {
		Name = "Footer",
		Position = UDim2.fromOffset(10, 96),
		Size = UDim2.fromOffset(208, 34),
		BackgroundColor3 = Color3.fromRGB(238, 229, 250),
		Parent = card,
		[New.Children] = { New.Corner(11) },
	})
	New.Image({
		Name = "GemIcon",
		Key = "ui/status/gem",
		Fallback = T.Gem,
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 8, 0.5, 0),
		Size = UDim2.fromOffset(20, 20),
		Parent = foot,
	})
	New("TextLabel", {
		Name = "Amount",
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 32, 0.5, 0),
		Size = UDim2.fromOffset(60, 18),
		BackgroundTransparency = 1,
		Text = "+5 Gems",
		TextColor3 = Color3.fromRGB(91, 65, 141),
		FontFace = T.FontBody,
		TextSize = New.FigmaSize(T.FontBody, 13),
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = foot,
	})
	New("TextLabel", {
		Name = "RewardState",
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -10, 0.5, 0),
		Size = UDim2.fromOffset(80, 18),
		BackgroundTransparency = 1,
		Text = "Awarded",
		TextColor3 = Color3.fromRGB(91, 65, 141),
		FontFace = T.FontBody,
		TextSize = New.FigmaSize(T.FontBody, 12),
		TextXAlignment = Enum.TextXAlignment.Right,
		Parent = foot,
	})

	return card
end

local function buildAuras(gui: ScreenGui)
	local w = window(gui, "Auras", "Aura Index")
	w.Size = UDim2.fromOffset(WINDOW.X, 545)

	-- Subtitle: "Discover and collect Auras"
	New.Text({
		Name = "Subtitle",
		Position = UDim2.fromOffset(0, 36),
		Size = UDim2.fromOffset(300, 20),
		Text = "Discover and collect Auras",
		TextColor3 = T.SubText,
		TextSize = 14,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = w.Header,
	})
	-- Collection count pill: "3 / 15"
	local countPill = New("Frame", {
		Name = "CollectionCount",
		Position = UDim2.fromOffset(160, 12),
		Size = UDim2.fromOffset(68, 30),
		BackgroundColor3 = T.PanelLight,
		Parent = w.Header,
		[New.Children] = {
			New.Pill(),
			New("UIListLayout", {
				FillDirection = Enum.FillDirection.Horizontal,
				HorizontalAlignment = Enum.HorizontalAlignment.Center,
				VerticalAlignment = Enum.VerticalAlignment.Center,
				Padding = UDim.new(0, 2),
				SortOrder = Enum.SortOrder.LayoutOrder,
			}),
		},
	})
	New.Title({
		Name = "Used",
		Size = UDim2.fromOffset(0, 22),
		AutomaticSize = Enum.AutomaticSize.X,
		Text = "3",
		TextColor3 = T.Text,
		TextSize = 18,
		LayoutOrder = 1,
		Parent = countPill,
	})
	New.Title({
		Name = "Max",
		Size = UDim2.fromOffset(0, 22),
		AutomaticSize = Enum.AutomaticSize.X,
		Text = "/ 15",
		TextColor3 = T.SubText,
		TextSize = 18,
		LayoutOrder = 2,
		Parent = countPill,
	})

	-- Discovery log banner: 450x52
	local log = New("Frame", {
		Name = "DiscoveryLog",
		Position = UDim2.fromOffset(PAD, 84),
		Size = UDim2.fromOffset(450, 52),
		BackgroundColor3 = Color3.fromRGB(238, 229, 250),
		Parent = w,
		[New.Children] = { New.Corner(13) },
	})
	New.Image({
		Name = "GemIcon",
		Key = "ui/status/gem",
		Fallback = T.Gem,
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 12, 0.5, 0),
		Size = UDim2.fromOffset(30, 30),
		Parent = log,
	})
	New.Title({
		Name = "GemsEarned",
		Position = UDim2.fromOffset(50, 7),
		Size = UDim2.fromOffset(240, 20),
		Text = "15 / 75 Gems earned",
		TextColor3 = Color3.fromRGB(91, 65, 141),
		TextSize = 16,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = log,
	})
	local bar = New("Frame", {
		Name = "ProgressBar",
		Position = UDim2.fromOffset(50, 31),
		Size = UDim2.fromOffset(220, 6),
		BackgroundColor3 = T.Track,
		Parent = log,
		[New.Children] = { New.Corner(3) },
	})
	New("Frame", {
		Name = "Fill",
		Size = UDim2.fromScale(0.2, 1),
		BackgroundColor3 = T.Good,
		BorderSizePixel = 0,
		Parent = bar,
		[New.Children] = { New.Corner(3) },
	})
	New.Text({
		Name = "FindsLeft",
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -14, 0.5, 0),
		Size = UDim2.fromOffset(150, 20),
		Text = "12 first finds left",
		TextColor3 = Color3.fromRGB(91, 65, 141),
		TextSize = 13,
		TextXAlignment = Enum.TextXAlignment.Right,
		Parent = log,
	})

	-- Star Tokens wallet card: 254x52 next to DiscoveryLog
	local tokensCard = New("Frame", {
		Name = "StarTokens",
		Position = UDim2.fromOffset(PAD + 450 + 12, 84),
		Size = UDim2.fromOffset(INNER - 450 - 12, 52),
		BackgroundColor3 = Color3.fromRGB(254, 246, 235),
		Parent = w,
		[New.Children] = {
			New.Corner(13),
			New.Stroke(Color3.fromRGB(235, 220, 195)),
		},
	})
	New.Image({
		Name = "Icon",
		Key = "ui/status/star_token",
		Fallback = T.Gold,
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 10, 0.5, 0),
		Size = UDim2.fromOffset(32, 32),
		Parent = tokensCard,
	})
	local tokensText = New("Frame", {
		Name = "TextGroup",
		Position = UDim2.fromOffset(48, 6),
		Size = UDim2.new(1, -54, 1, -12),
		BackgroundTransparency = 1,
		Parent = tokensCard,
		[New.Children] = {
			New("UIListLayout", {
				FillDirection = Enum.FillDirection.Vertical,
				VerticalAlignment = Enum.VerticalAlignment.Center,
				Padding = UDim.new(0, 1),
				SortOrder = Enum.SortOrder.LayoutOrder,
			}),
		},
	})
	New.Text({
		Name = "Label",
		Size = UDim2.new(1, 0, 0, 16),
		Text = "Star Tokens",
		TextColor3 = T.SubText,
		TextSize = 12,
		TextXAlignment = Enum.TextXAlignment.Left,
		LayoutOrder = 1,
		Parent = tokensText,
	})
	New.Title({
		Name = "Value",
		Size = UDim2.new(1, 0, 0, 22),
		Text = "7",
		TextColor3 = T.Text,
		TextSize = 18,
		TextXAlignment = Enum.TextXAlignment.Left,
		LayoutOrder = 2,
		Parent = tokensText,
	})

	-- Grid: 6 cards (3x2)
	local grid = New("Frame", {
		Name = "Grid",
		Position = UDim2.fromOffset(PAD, 146),
		Size = UDim2.fromOffset(INNER, 300),
		BackgroundTransparency = 1,
		Parent = w,
		[New.Children] = {
			New("UIGridLayout", {
				CellSize = UDim2.fromOffset(228, 140),
				CellPadding = UDim2.fromOffset(16, 14),
				FillDirectionMaxCells = 3,
				SortOrder = Enum.SortOrder.LayoutOrder,
			}),
		},
	})
	for i = 1, Screen.AuraCards do
		local c = auraCard(grid, "Card" .. i)
		c.LayoutOrder = i
	end

	-- Footer: Pager on left, Go to Altar button on right
	local f = New("Frame", {
		Name = "Footer",
		Position = UDim2.fromOffset(PAD, 465),
		Size = UDim2.fromOffset(INNER, 57),
		BackgroundTransparency = 1,
		Parent = w,
	})
	New.Pager({ AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 0, 0.5, 0), Parent = f })
	New.Button({
		Name = "Altar",
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, 0, 0.5, 0),
		Size = UDim2.fromOffset(170, 44),
		Text = "Go to Altar",
		BackgroundColor3 = T.Gem,
		TextSize = 18,
		Parent = f,
	})
end

local function dexCard(parent: Instance, i: number)
	local col, rowN = (i - 1) % 3, (i - 1) // 3
	local c = New.Panel({
		Name = "Card" .. i,
		Position = UDim2.fromOffset(col * 240, rowN * 196),
		Size = UDim2.fromOffset(228, 184),
		Radius = T.RadiusCard,
		Visible = false,
		Parent = parent,
	})
	local pic = New("Frame", {
		Name = "Picture",
		Position = UDim2.fromOffset(14, 14),
		Size = UDim2.fromOffset(200, 70),
		BackgroundColor3 = Color3.fromRGB(244, 250, 253), -- Figma Picture fill (pale water)
		Parent = c,
		[New.Children] = { New.Corner(12) },
	})
	New.Image({ Name = "Image", Key = "fish/MysteryFish", Fallback = T.Track, FallbackText = "?", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(96, 64), Parent = pic })
	New.Title({ Name = "FishName", Position = UDim2.fromOffset(14, 90), Size = UDim2.fromOffset(200, 24), Text = "Fish name", TextXAlignment = Enum.TextXAlignment.Left, TextSize = 20, Parent = c })
	New.BadgeSlots(2, { Name = "Where", Position = UDim2.fromOffset(14, 120), Size = UDim2.fromOffset(200, 21), Parent = c })
	New.BadgeSlots(2, { Name = "Record", Position = UDim2.fromOffset(14, 147), Size = UDim2.fromOffset(200, 21), Parent = c })
end

local function buildFishdex(gui: ScreenGui)
	local w = window(gui, "Fishdex", "Fishdex")
	-- Figma 09 top row: discovery chip (fishdex icon + "7 / 20", number only) left, Sort button right.
	local sum = New("Frame", { Name = "Summary", Position = UDim2.fromOffset(PAD, 93), Size = UDim2.fromOffset(INNER, 40), BackgroundTransparency = 1, Parent = w })
	chip(sum, "Count", T.Sky, "ui/icons/fishdex", 117, 1)
	local count = sum:FindFirstChild("Count") :: Frame
	;(count:FindFirstChild("Value") :: TextLabel).Text = "0 / 20"
	New.Button({ Name = "Sort", AnchorPoint = Vector2.new(1, 0), Position = UDim2.fromScale(1, 0), Size = UDim2.fromOffset(190, 40), Text = "Sort: Depth", TextSize = 22, Parent = sum })
	local grid = New("Frame", { Name = "Grid", Position = UDim2.fromOffset(PAD, 147), Size = UDim2.fromOffset(INNER, 380), BackgroundTransparency = 1, Parent = w })
	for i = 1, Screen.DexCards do
		dexCard(grid, i)
	end
	footer(w, 541, 0, {}) -- pager bottom-left, same spot in every window
end

function Screen.Build(): ScreenGui
	local gui = New("ScreenGui", {
		Name = "Menus",
		ResetOnSpawn = false,
		IgnoreGuiInset = false,
		DisplayOrder = 10,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	}) :: ScreenGui
	buildShop(gui)
	buildAuras(gui)
	buildFishdex(gui)
	return gui
end

return Screen
