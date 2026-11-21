--!strict
-- C18 Merchant sign (Figma Economy 7 "Merchant sign"): a BillboardGui above the Merchant with the 1-2 hot
-- fish of the hour, their price multiplier and time left. Client-only: HotFish.Current() gives the same
-- list as the server (picked from the UTC hour), so this just redraws every second.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Registry = require(Shared.Registry)
local HotFish = require(Shared.HotFish)

local New = require(script.Parent.Parent.UI.New)

local T = New.Theme

local HotFishController = {}

local MAX = 2
local SIGN_HEIGHT = 150
local TITLE_GAP = 12
local sign: BillboardGui? = nil
local cards: { any } = {}
local foot: TextLabel? = nil
local key = ""

local function findMerchant(): BasePart?
	local m = Workspace:FindFirstChild("Merchant", true)
	if m and m:IsA("Model") then
		return m.PrimaryPart or m:FindFirstChildWhichIsA("BasePart", true)
	end
	return if m and m:IsA("BasePart") then m else nil
end

local function merchantTitle(part: BasePart): BillboardGui?
	for _, child in part:GetChildren() do
		if child:IsA("BillboardGui") then
			local text = child:FindFirstChildWhichIsA("TextLabel", true)
			if text and text.Text == "Fish Merchant" then
				return child
			end
		end
	end
	return nil
end

local function build(adornee: BasePart)
	local gui = Instance.new("BillboardGui")
	gui.Name = "HotFishSign"
	gui.Size = UDim2.fromOffset(260, SIGN_HEIGHT)
	gui.StudsOffset = Vector3.new(0, adornee.Size.Y / 2 + 5, 0)
	gui.MaxDistance = 90
	gui.LightInfluence = 0
	gui.ResetOnSpawn = false
	gui.Adornee = adornee
	gui.AlwaysOnTop = true
	local title = merchantTitle(adornee)
	if title then
		gui.Adornee = title.Adornee or adornee
		gui.StudsOffset = title.StudsOffset
		gui.StudsOffsetWorldSpace = title.StudsOffsetWorldSpace
		gui.ExtentsOffset = title.ExtentsOffset
		gui.ExtentsOffsetWorldSpace = title.ExtentsOffsetWorldSpace
		local titleHeight = title.Size.Y.Offset
		local titleTop = titleHeight * (0.5 + title.SizeOffset.Y)
		-- Use the nameplate's anchor and leave a pixel gap at every camera distance.
		gui.SizeOffset = Vector2.new(0, 0.5 + (titleTop + TITLE_GAP) / SIGN_HEIGHT)
	end
	local panel = New.Panel({
		Size = UDim2.fromScale(1, 1),
		Radius = 20,
		Parent = gui,
		[New.Children] = { New("UIStroke", { Color = T.Accent, Thickness = 3 }) },
	})
	local head = New("Frame", {
		Name = "Head",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0),
		Size = UDim2.fromOffset(0, 30),
		AutomaticSize = Enum.AutomaticSize.X,
		BackgroundColor3 = T.Accent,
		Parent = panel,
		[New.Children] = {
			New.Pill(),
			New("UIPadding", { PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 14) }),
			New("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 6), VerticalAlignment = Enum.VerticalAlignment.Center, SortOrder = Enum.SortOrder.LayoutOrder }),
		},
	})
	New.Image({ Key = "ui/status/hot_price", Fallback = T.Gold, Size = UDim2.fromOffset(20, 20), LayoutOrder = 1, Parent = head })
	New("TextLabel", {
		Size = UDim2.fromOffset(0, 24),
		AutomaticSize = Enum.AutomaticSize.X,
		BackgroundTransparency = 1,
		Text = "HOT FISH",
		TextColor3 = T.OnAccent,
		FontFace = T.Font,
		TextSize = 20,
		LayoutOrder = 2,
		Parent = head,
	})
	local row = New("Frame", {
		Name = "Row",
		Position = UDim2.fromOffset(0, 22),
		Size = UDim2.new(1, 0, 1, -50),
		BackgroundTransparency = 1,
		Parent = panel,
		[New.Children] = {
			New("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 12), HorizontalAlignment = Enum.HorizontalAlignment.Center, SortOrder = Enum.SortOrder.LayoutOrder }),
		},
	})
	for i = 1, MAX do
		local c = New("Frame", { Name = "Fish" .. i, Size = UDim2.fromOffset(110, 96), BackgroundTransparency = 1, LayoutOrder = i, Parent = row })
		local img = New.Image({ Name = "Icon", Key = "fish/BubbleCarp", Fallback = T.PanelLight, AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.fromScale(0.5, 0), Size = UDim2.fromOffset(64, 64), Parent = c })
		local mult = New("TextLabel", {
			Name = "Mult",
			AnchorPoint = Vector2.new(1, 0),
			Position = UDim2.new(1, -14, 0, 0),
			Size = UDim2.fromOffset(0, 18),
			AutomaticSize = Enum.AutomaticSize.X,
			BackgroundColor3 = T.Gold,
			Text = "x3",
			TextColor3 = T.OnAccent,
			FontFace = T.FontBadge,
			TextSize = 13,
			ZIndex = 2,
			Parent = c,
			[New.Children] = { New.Pill(), New("UIPadding", { PaddingLeft = UDim.new(0, 6), PaddingRight = UDim.new(0, 6) }) },
		})
		local name = New("TextLabel", {
			Name = "FishName",
			Position = UDim2.fromOffset(0, 66),
			Size = UDim2.new(1, 0, 0, 22),
			BackgroundTransparency = 1,
			Text = "Bubble Carp",
			TextColor3 = T.Text,
			FontFace = T.Font,
			TextScaled = true,
			Parent = c,
			[New.Children] = { New("UITextSizeConstraint", { MaxTextSize = 17 }) },
		})
		cards[i] = { Frame = c, Icon = img, Mult = mult, Name = name }
	end
	foot = New("TextLabel", {
		Name = "Foot",
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -6),
		Size = UDim2.new(1, -20, 0, 20),
		BackgroundTransparency = 1,
		Text = "x3 price - 12m left",
		TextColor3 = T.SubText,
		FontFace = T.FontBadge,
		TextSize = 14,
		Parent = panel,
	})

	New.ApplyImages(gui)
	gui.Parent = adornee
	sign = gui
end

local function refresh()
	if not sign or not sign.Parent then
		local part = findMerchant()
		if not part then
			return
		end
		build(part)
		key = ""
	end
	local list = HotFish.Current()
	local now = os.time()
	local k = HotFish.Key(now)
	if k ~= key then
		key = k
		for i = 1, MAX do
			local e = list[i]
			local c = cards[i]
			c.Frame.Visible = e ~= nil
			if e then
				local f = Registry.Fish[e.FishId]
				New.SetImageKey(c.Icon, `fish/{e.FishId}`, T.PanelLight, "?")
				c.Name.Text = if f then f.Name else e.FishId
				c.Mult.Text = `x{e.Mult}`
			end
		end
	end
	local first = list[1]

	if first and foot then
		local left = math.max(0, first.EndsAt - now)
		foot.Text = `Sell price up - {math.ceil(left / 60)}m left`
	end
	if sign then
		sign.Enabled = first ~= nil
	end
end

function HotFishController.Init()
	task.spawn(function()
		while true do
			pcall(refresh)
			task.wait(1)
		end
	end)
end

return HotFishController
