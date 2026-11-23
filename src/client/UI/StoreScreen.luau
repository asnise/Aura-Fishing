--!nonstrict
-- Store window matching Figma "Economy · 6 Store (C6/C19)" (node 3546:36700).
-- 760x610 cream window, r24:
--   Header: Title "Store" (Fredoka 26) + red close button
--   Tabs: Passes / Gems / Boosts / Packs (4 tabs, 173x57 each)
--   Passes: 88 px rows with a pager when they exceed the content area.
--   Gems: List (25, 110 POPULAR, 300 BEST VALUE) + drop rates link
--   Boosts: List of 2x Coins and 2x Pearls (2h)
--   Packs: Starter Pack and Coin Chest (coming later)
-- No dim overlay behind the window (user request 2026-11-20). Price buttons spin until Roblox returns the price.

local MarketplaceService = game:GetService("MarketplaceService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Registry = require(Shared.Registry)
local Remotes = require(Shared.Remotes)
local Boosts = require(Shared.Boosts)
local _Format = require(Shared.Util.Format)

local New = require(script.Parent.New)
local Window = require(script.Parent.Window)
local StarterPackModal = require(script.Parent.StarterPackModal)

local T = New.Theme
local WHITE = Color3.new(1, 1, 1)
local Products = Registry.Products

local StoreScreen = {}

-- Robux prices from Roblox, cached. done(price) runs now when known, else once fetched (fallback on failure).
local priceCache: { [string]: number } = {}
local pricePending: { [string]: { (number) -> () } } = {}
local function fetchPrice(kind: string, id: number, fallback: number, done: (number) -> ())
	if id <= 0 then
		done(fallback)
		return
	end
	local key = kind .. id
	if priceCache[key] then
		done(priceCache[key])
		return
	end
	if pricePending[key] then
		table.insert(pricePending[key], done)
		return
	end
	pricePending[key] = { done }
	task.spawn(function()
		local ok, info = pcall(function()
			return MarketplaceService:GetProductInfo(id, if kind == "Pass" then Enum.InfoType.GamePass else Enum.InfoType.Product)
		end)
		local price = if ok and info and type(info.PriceInRobux) == "number" then info.PriceInRobux else fallback
		priceCache[key] = price
		local list = pricePending[key]
		pricePending[key] = nil
		for _, f in list do
			task.spawn(f, price)
		end
	end)
end

-- Green Robux button; spins until the real price is known.
local function buyButton(kind: string, id: number, fallback: number, onClick: () -> ()): TextButton
	local btn = New.RobuxButton({
		Name = "Btn Buy",
		Size = UDim2.fromOffset(88, 46),
		BackgroundColor3 = T.Good,
		Activated = onClick,
	}, fallback)
	local content = (btn :: any).Face.Content
	local spin: Frame? = nil
	if id > 0 and not priceCache[kind .. id] then
		content.Visible = false
		spin = New.Spinner({ Size = UDim2.fromOffset(24, 24), Thickness = 3, Color = WHITE, Parent = (btn :: any).Face })
	end
	fetchPrice(kind, id, fallback, function(price)
		content.Price.Text = tostring(price)
		content.Visible = true
		if spin then
			spin:Destroy()
		end
	end)
	return btn
end

-- Disabled button indicating owned state (keeps full button footprint for clean grid alignment).
local function ownedButton(label: string?): TextButton
	local btn = New.Button({
		Name = "Btn Owned",
		Size = UDim2.fromOffset(88, 46),
		BackgroundColor3 = T.Disabled,
		TextColor3 = T.DisabledText,
		Text = label or "OWNED",
		MaxTextSize = 16,
		Active = false,
	})
	btn.AutoButtonColor = false
	return btn
end

-- Disabled button indicating coming soon state.
local function comingSoonButton(): TextButton
	local btn = New.Button({
		Name = "Btn Coming Soon",
		Size = UDim2.fromOffset(118, 46),
		BackgroundColor3 = T.Disabled,
		TextColor3 = T.DisabledText,
		Text = "COMING SOON",
		MaxTextSize = 13,
		Active = false,
	})
	btn.AutoButtonColor = false
	return btn
end

local function badgePill(text: string): Frame
	return New("Frame", {
		Name = "Badge",
		Size = UDim2.fromOffset(0, 20),
		AutomaticSize = Enum.AutomaticSize.X,
		BackgroundColor3 = T.Accent,
		[New.Children] = {
			New.Corner(999),
			New("UIPadding", { PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10) }),
			New("TextLabel", {
				Size = UDim2.fromOffset(0, 20),
				AutomaticSize = Enum.AutomaticSize.X,
				BackgroundTransparency = 1,
				Text = text,
				TextColor3 = WHITE,
				FontFace = T.FontBadge,
				TextSize = New.FigmaSize(T.FontBadge, 12),
			}),
		},
	})
end

function StoreScreen.Create(opts: { OnGachaRates: (() -> ())? }?): any
	opts = opts or {}
	local screen: any = {}
	local currentTab = "Passes"
	local lastProfile: any = nil


	-- shell (ScreenGui in PlayerGui, panel, title, X, open/close/register) = Window core
	local shortScreen = Window.IsShortScreen()
	local windowHeight = if shortScreen then 440 else 610
	local shell = Window.Shell({ Name = "Store", Title = "Store", WindowName = "Window Store", Size = Vector2.new(760, windowHeight) })
	local gui, win = shell.Gui, shell.Frame
	screen.Gui = gui

	-- Tabs row (y 71, h 57)
	local tabList = { "Passes", "Gems", "Boosts", "Packs" }
	local tabButtons: { [string]: TextButton } = {}

	local tabsFrame = New("Frame", {
		Name = "Tabs",
		Position = UDim2.fromOffset(0, 71),
		Size = UDim2.new(1, 0, 0, 57),
		BackgroundTransparency = 1,
		Parent = win,
		[New.Children] = {
			New("UIListLayout", {
				FillDirection = Enum.FillDirection.Horizontal,
				Padding = UDim.new(0, 8),
				VerticalAlignment = Enum.VerticalAlignment.Center,
				SortOrder = Enum.SortOrder.LayoutOrder,
			}),
		},
	})

	for i, name in tabList do
		local btn = New.Button({
			Name = "Btn Tab " .. name,
			Size = UDim2.fromOffset(173, 57),
			Text = name,
			TextSize = 22,
			BackgroundColor3 = if name == currentTab then T.Accent else T.PanelLight,
			Radius = 16,
			LayoutOrder = i,
			Parent = tabsFrame,
		})
		tabButtons[name] = btn
		btn.Activated:Connect(function()
			screen.SetTab(name)
		end)
	end

	-- Content frame
	local content = New("Frame", {
		Name = "Content",
		Position = UDim2.fromOffset(0, 142),
		Size = UDim2.new(1, 0, 1, -142),
		BackgroundTransparency = 1,
		Parent = win,
	})

	local function clearContent()
		for _, c in content:GetChildren() do
			c:Destroy()
		end
	end

	local function updateTabStyles()
		for name, btn in tabButtons do
			local active = name == currentTab
			New.SetButtonColor(btn, if active then T.Accent else T.PanelLight, if active then WHITE else T.Text)
		end
	end

	-- Render Passes Tab: a list of 88 high rows (Figma C6b)
	local function renderPasses()
		local grid = New("Frame", {
			Name = "Grid",
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			Parent = content,
			[New.Children] = {
				New("UIListLayout", {
					FillDirection = Enum.FillDirection.Vertical,
					Padding = UDim.new(0, 10),
					SortOrder = Enum.SortOrder.LayoutOrder,
				}),
			},
		})

		local tradeLicense = Products.Passes.TradeLicense
		local passCards = {
			{
				Key = "InfiniteBag",
				Name = "Infinite Bag",
				Icon = "ui/icons/infinite_bag",
				Benefits = { "Your bag never fills up.", "Fish forever, sell when you like." },
				DefaultPrice = 349,
				Order = 1,
			},
			{
				Key = "AutoFishPro",
				Name = "Auto-Fish Pro",
				Icon = "ui/icons/auto_pro",
				Benefits = { "Auto wait -25%", "Auto rewards x1.25" },
				DefaultPrice = 249,
				Order = 2,
			},
			{
				Key = "VIP",
				Name = "VIP",
				Icon = "ui/icons/vip",
				Benefits = { "+15% Luck, gold name", "Offline Pearls up to 12h" },
				DefaultPrice = 149,
				Order = 3,
			},
			{
				Key = "ExtraCast",
				Name = "Extra Cast",
				Icon = "ui/icons/extra_cast",
				Benefits = { "Fish with two lines at once." },
				DefaultPrice = 199,
				ComingSoon = true,
				Order = 4,
			},
			{
				Key = "TradeLicense",
				Name = tradeLicense.Name,
				Icon = "ui/icons/trade_license",
				Benefits = { tradeLicense.Description },
				DefaultPrice = tradeLicense.Price,
				ComingSoon = tradeLicense.PassId <= 0,
				Order = tradeLicense.Order,
			},
		}

		for _, item in passCards do
			local pDef = Products.Passes[item.Key]
			local passId = pDef and pDef.PassId or 0
			local isOwned = lastProfile and lastProfile.Passes and lastProfile.Passes[item.Key] ~= nil

			local card = New("Frame", {
				Name = "Pass " .. item.Name,
				Size = UDim2.new(1, 0, 0, 88),
				BackgroundColor3 = T.PanelLight,
				LayoutOrder = item.Order,
				Parent = grid,
				[New.Children] = { New.Corner(20) },
			})

			-- Art tile (64x64)
			New("Frame", {
				Name = "Art",
				Position = UDim2.fromOffset(14, 12),
				Size = UDim2.fromOffset(64, 64),
				BackgroundColor3 = WHITE,
				Parent = card,
				[New.Children] = {
					New.Corner(16),
					New.Stroke(T.Track, 1.5),
					New.Image({
						Name = "Img",
						Key = item.Icon,
						Size = UDim2.fromOffset(56, 56),
						AnchorPoint = Vector2.new(0.5, 0.5),
						Position = UDim2.fromScale(0.5, 0.5),
					}),
				},
			})

			New("TextLabel", {
				Name = "Name",
				Position = UDim2.fromOffset(92, 13),
				Size = UDim2.new(1, -(92 + 150), 0, 30),
				BackgroundTransparency = 1,
				Text = item.Name,
				TextColor3 = T.Text,
				FontFace = T.Font,
				TextSize = New.FigmaSize(T.Font, 24),
				TextXAlignment = Enum.TextXAlignment.Left,
				Parent = card,
			})
			New("TextLabel", {
				Name = "Benefits",
				Position = UDim2.fromOffset(92, 47),
				Size = UDim2.new(1, -(92 + 150), 0, 20),
				BackgroundTransparency = 1,
				Text = table.concat(item.Benefits, "  /  "),
				TextColor3 = T.SubText,
				FontFace = T.FontBody,
				TextSize = New.FigmaSize(T.FontBody, 14),
				TextXAlignment = Enum.TextXAlignment.Left,
				TextTruncate = Enum.TextTruncate.AtEnd,
				Parent = card,
			})

			-- Action: price button / OWNED / COMING SOON, right-aligned
			local actionRow = New("Frame", {
				Name = "ActionRow",
				AnchorPoint = Vector2.new(1, 0.5),
				Position = UDim2.new(1, -14, 0.5, 0),
				Size = UDim2.fromOffset(130, 46),
				BackgroundTransparency = 1,
				Parent = card,
			})
			local btn
			if item.ComingSoon then
				btn = comingSoonButton()
			elseif isOwned then
				btn = ownedButton()
			else
				btn = buyButton("Pass", passId, pDef and pDef.Price or item.DefaultPrice, function()
					Remotes.Event("PromptPass"):FireServer(item.Key)
				end)
			end
			btn.AnchorPoint = Vector2.new(1, 0.5)
			btn.Position = UDim2.new(1, 0, 0.5, 0)
			btn.Parent = actionRow
		end
	end

	local function productList(): Frame
		return New("Frame", {
			Name = "Product List",
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			Parent = content,
			[New.Children] = {
				New("UIListLayout", {
					FillDirection = Enum.FillDirection.Vertical,
					SortOrder = Enum.SortOrder.LayoutOrder,
				}),
			},
		})
	end

	local function productRow(list: Frame, item, action: GuiObject, subColor: Color3?)
		local row = New("Frame", {
			Name = "Product " .. item.Name,
			Size = UDim2.new(1, 0, 0, 74),
			BackgroundTransparency = 1,
			LayoutOrder = item.Order,
			Parent = list,
		})

		New.Image({
			Name = "Img",
			Key = item.Icon,
			Size = UDim2.fromOffset(56, 56),
			Position = UDim2.fromOffset(12, 9),
			Parent = row,
		})

		local textWidth = if item.Badge then -296 else -192
		New("TextLabel", {
			Name = "Name",
			Position = UDim2.fromOffset(80, 15),
			Size = UDim2.new(1, textWidth, 0, 24),
			BackgroundTransparency = 1,
			Text = item.Name,
			TextColor3 = T.Text,
			FontFace = T.Font,
			TextSize = New.FigmaSize(T.Font, 20),
			TextXAlignment = Enum.TextXAlignment.Left,
			Parent = row,
		})
		New("TextLabel", {
			Name = "Sub",
			Position = UDim2.fromOffset(80, 43),
			Size = UDim2.new(1, textWidth, 0, 16),
			BackgroundTransparency = 1,
			Text = item.Sub,
			TextColor3 = subColor or T.SubText,
			FontFace = T.FontBadge,
			TextSize = New.FigmaSize(T.FontBadge, 12),
			TextXAlignment = Enum.TextXAlignment.Left,
			Parent = row,
		})

		if item.Badge then
			local badge = badgePill(item.Badge)
			badge.AnchorPoint = Vector2.new(1, 0.5)
			badge.Position = UDim2.new(1, -112, 0.5, 0)
			badge.Parent = row
		end

		action.AnchorPoint = Vector2.new(1, 0.5)
		action.Position = UDim2.new(1, -12, 0.5, 0)
		action.Parent = row

		New("Frame", {
			Name = "Divider",
			Position = UDim2.new(0, 0, 1, -1),
			Size = UDim2.new(1, 0, 0, 1),
			BorderSizePixel = 0,
			BackgroundColor3 = T.Track,
			Parent = row,
		})
	end

	local function productBuyButton(key: string, fallbackPrice: number): TextButton
		local product = Products.Products[key]
		return buyButton("Product", product and product.ProductId or 0, product and product.Price or fallbackPrice, function()
			Remotes.Event("PromptProduct"):FireServer(key)
		end)
	end

	local function renderGems()
		local list = productList()

		local gems = {
			{
				Key = "GemsSmall",
				Name = "25 Gems",
				Sub = "5 aura rolls",
				Icon = "ui/shop/gems_s",
				DefaultPrice = 25,
				Order = 1,
			},
			{
				Key = "GemsMedium",
				Name = "110 Gems",
				Sub = "22 rolls, +11% bonus",
				Icon = "ui/shop/gems_m",
				DefaultPrice = 99,
				Badge = "POPULAR",
				Order = 2,
			},
			{
				Key = "GemsLarge",
				Name = "300 Gems",
				Sub = "60 rolls, +20% bonus",
				Icon = "ui/shop/gems_l",
				DefaultPrice = 249,
				Badge = "BEST VALUE",
				Order = 3,
			},
		}

		for _, item in gems do
			productRow(list, item, productBuyButton(item.Key, item.DefaultPrice))
		end

		local linkRow = New("TextButton", {
			Name = "RatesLink",
			Size = UDim2.new(1, 0, 0, 40),
			LayoutOrder = 4,
			BackgroundTransparency = 1,
			Text = "",
			AutoButtonColor = false,
			Parent = list,
			[New.Children] = {
				New("UIPadding", { PaddingLeft = UDim.new(0, 12) }),
				New("UIListLayout", {
					FillDirection = Enum.FillDirection.Horizontal,
					HorizontalAlignment = Enum.HorizontalAlignment.Left,
					VerticalAlignment = Enum.VerticalAlignment.Center,
					Padding = UDim.new(0, 8),
					SortOrder = Enum.SortOrder.LayoutOrder,
				}),
				New.Image({
					Name = "Icon",
					Key = "icon_info",
					Tint = Color3.fromRGB(107, 179, 222),
					Size = UDim2.fromOffset(18, 18),
					LayoutOrder = 1,
				}),
				New("TextLabel", {
					Name = "Label",
					Size = UDim2.fromOffset(0, 20),
					AutomaticSize = Enum.AutomaticSize.X,
					BackgroundTransparency = 1,
					Text = "Gems are used for random aura rolls - tap to see drop rates",
					TextColor3 = Color3.fromRGB(107, 179, 222),
					FontFace = T.FontBody,
					TextSize = New.FigmaSize(T.FontBody, 14),
					LayoutOrder = 2,
				}),
			},
		})

		linkRow.Activated:Connect(function()
			if opts and opts.OnGachaRates then
				opts.OnGachaRates()
			else
				Remotes.Func("PullAura"):InvokeServer("Altar", 0)
			end
		end)
	end

	local function renderBoosts()
		local list = productList()

		local boosts = {
			{
				Key = "BoostCoins",
				Name = "2x Coins",
				BoostId = "Coins",
				Sub = "2 hours, stacks time",
				Icon = "ui/shop/boost_coins",
				DefaultPrice = 39,
				Order = 1,
			},
			{
				Key = "BoostPearls",
				Name = "2x Pearls",
				BoostId = "Pearls",
				Sub = "2 hours, works offline",
				Icon = "ui/shop/boost_pearls",
				DefaultPrice = 39,
				Order = 2,
			},
		}

		for _, item in boosts do
			local left = if lastProfile then Boosts.Remaining(lastProfile, item.BoostId) else 0
			item.Sub = if left > 0
				then `Active: {math.floor(left / 3600)}h {math.floor(left % 3600 / 60)}m left`
				else item.Sub

			productRow(list, item, productBuyButton(item.Key, item.DefaultPrice), if left > 0 then T.GoodLip else nil)
		end
	end

	local function renderPacks()
		local list = productList()
		local bought = lastProfile and lastProfile.Purchases and lastProfile.Purchases.Once and lastProfile.Purchases.Once.StarterPack

		local action
		if bought then
			action = ownedButton("BOUGHT")
		else
			action = New.Button({
				Name = "Btn Buy",
				Size = UDim2.fromOffset(88, 46),
				Text = "Buy",
				TextSize = 18,
				BackgroundColor3 = T.Good,
				Activated = function()
					local product = Products.Products.StarterPack
					fetchPrice("Product", product and product.ProductId or 0, product and product.Price or 49, StarterPackModal.Open)
				end,
			})
		end

		productRow(list, {
			Name = "Starter Pack",
			Icon = "ui/shop/starter_bundle",
			Sub = "One time only",
			Badge = "x1",
			Order = 1,
		}, action)

		productRow(list, {
			Name = "Coin Chest",
			Icon = "ui/shop/coins_l",
			Sub = "Coming later",
			Order = 2,
		}, New.Button({
			Name = "Btn Buy",
			Size = UDim2.fromOffset(88, 46),
			Text = "—",
			BackgroundColor3 = T.Disabled,
			Interactable = false,
			Selectable = false,
		}))
	end

	-- Keep the existing pager whenever a tab has more cards than the window can show.
	local storePage = 1
	local function paginate()
		if not shortScreen and currentTab ~= "Passes" then
			return
		end
		local container = content:FindFirstChild("Grid") or content:FindFirstChild("Product List")
		if not container then
			return
		end
		local kids = {}
		for _, c in container:GetChildren() do
			if c:IsA("GuiObject") then
				table.insert(kids, c)
			end
		end
		table.sort(kids, function(a, b)
			return a.LayoutOrder < b.LayoutOrder
		end)
		local columns = if container:FindFirstChildOfClass("UIGridLayout") then 2 else 1
		local rowH, gap = 0, if container.Name == "Grid" then 10 else 0
		for _, k in kids do
			rowH = math.max(rowH, k.Size.Y.Offset)
		end
		local contentH = windowHeight - 44 - content.Position.Y.Offset
		if not shortScreen and math.ceil(#kids / columns) * (rowH + gap) - gap <= contentH then
			return
		end
		local rowsFit = math.max(1, math.floor((contentH - 52 + gap) / (rowH + gap)))
		local perPage = rowsFit * columns
		local pages = math.max(1, math.ceil(#kids / perPage))
		storePage = math.clamp(storePage, 1, pages)
		for i, k in kids do
			k.Visible = i > (storePage - 1) * perPage and i <= storePage * perPage
		end
		if pages <= 1 then
			return
		end
		container.Size = UDim2.new(1, 0, 1, -52)
		local bar = New("Frame", {
			Name = "Pager",
			AnchorPoint = Vector2.new(0.5, 1),
			Position = UDim2.new(0.5, 0, 1, 0),
			Size = UDim2.fromOffset(220, 44),
			BackgroundTransparency = 1,
			Parent = content,
			[New.Children] = { New("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 12), HorizontalAlignment = Enum.HorizontalAlignment.Center, VerticalAlignment = Enum.VerticalAlignment.Center, SortOrder = Enum.SortOrder.LayoutOrder }) },
		})
		local function step(delta: number)
			storePage = math.clamp(storePage + delta, 1, pages)
			screen.Render(lastProfile, nil)
		end
		local prev = New.Button({ Name = "Prev", Size = UDim2.fromOffset(64, 40), Text = "<", TextSize = 20, BackgroundColor3 = if storePage > 1 then T.PanelLight else T.Disabled, LayoutOrder = 1, Parent = bar })
		New.Text({ Name = "Page", Size = UDim2.fromOffset(56, 40), Text = `{storePage} / {pages}`, TextSize = 16, TextColor3 = T.SubText, LayoutOrder = 2, Parent = bar })
		local nextB = New.Button({ Name = "Next", Size = UDim2.fromOffset(64, 40), Text = ">", TextSize = 20, BackgroundColor3 = if storePage < pages then T.PanelLight else T.Disabled, LayoutOrder = 3, Parent = bar })
		prev.Activated:Connect(function()
			step(-1)
		end)
		nextB.Activated:Connect(function()
			step(1)
		end)
	end

	local renderers = { Passes = renderPasses, Gems = renderGems, Boosts = renderBoosts, Packs = renderPacks }
	function screen.Render(profile: any, _stats: any)
		lastProfile = profile
		clearContent()
		updateTabStyles()
		local ok, err = pcall(renderers[currentTab])
		if ok then
			pcall(paginate)
		end
		if not ok then
			warn(`[Store] {currentTab} tab failed: {err}`)
			clearContent()
			New.Text({ Name = "Error", Size = UDim2.new(1, 0, 0, 40), Text = "Could not load this tab. Close and open the Store again.", TextColor3 = T.SubText, Parent = content })
		end
	end

	function screen.SetTab(tab: string)
		currentTab = tab
		storePage = 1
		if lastProfile then
			screen.Render(lastProfile, nil)
		end
	end

	shell.OnOpen = function()
		if lastProfile then
			screen.Render(lastProfile, nil)
		else
			shell.SetLoading(true, content) -- no save data yet: spin until EconomyController renders it
		end
	end
	function screen.Open(tab: string?)
		if tab then
			currentTab = tab
		end
		shell.Open()
	end
	screen.Close = shell.Close
	screen.IsOpen = shell.IsOpen

	return screen
end

return StoreScreen
