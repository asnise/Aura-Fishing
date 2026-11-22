--!nonstrict
-- Window core: every code-built window (Store, Aquarium, Mastery, Quests, Credits, Enhance popup,
-- Put in Tank, Skills...) gets its shell from here, so they all open / close / scale / load the same way.
--
--   local w = Window.Shell({ Name = "Store", Title = "Store", Size = Vector2.new(760, 610) })
--     -> w.Gui (ScreenGui in PlayerGui), w.Frame (cream panel), w.TitleLabel, w.CloseButton
--     -> w.Open() / w.Close() / w.IsOpen(); w.OnOpen(), w.OnClose() hooks
--     -> w.SetLoading(true, target?) = spinner over target (default the whole window) until SetLoading(false)
--   opts: Name (MenuManager id), Title (nil = no title), Close (default true), Size, Padding (22), Radius,
--         Layer ("Main"), StackOn, DisplayOrder (by layer), Dim (false), WindowName, AutoHeight, Clip (rounded clipping).
--   Standard header (Figma windows): title Fredoka 26 at y 13, red X 73x57 top-right.
--
-- Below the shell, the old small kit for list windows without a Figma design:
--   local w = Window.Create({ Name = "Aquarium", Title = "Aquarium", Size = Vector2.new(680, 500), Tabs = { "Tank", "Mastery" } })
--   w.OnTab = function(tab) ... end ; w.Open() ; w.Close() ; w.Body (Frame) ; w.Header (TextLabel under the title)
--   Window.Row({ Title, Sub, Button = { Text, Color, Enabled, OnClick, RobuxPrice? } , Icon = key?, IconColor? }) -> Frame
--   Window.Clear(frame)
--   Open/close rules come from MenuManager: pass Layer (default "Main") and StackOn = { "Character" } to stack.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local New = require(script.Parent.New)
local MenuManager = require(script.Parent.MenuManager)
local T = New.Theme

local Window = {}

-- Phones in landscape: the ScreenGui is shorter than 520 (below the top bar).
function Window.IsShortScreen(): boolean
	local camera = workspace.CurrentCamera
	local vp = if camera then camera.ViewportSize else Vector2.new(1280, 720)
	return vp.Y - game:GetService("GuiService"):GetGuiInset().Y < 520
end

local LAYER_ORDER = { Hub = 20, Main = 10, Dialogue = 14, Popup = 30, Modal = 50 }

function Window.Shell(opts: { [string]: any }): any
	local size: Vector2 = opts.Size or Vector2.new(760, 610)
	local layer = opts.Layer or "Main"
	local pad = opts.Padding or 22
	local w: any = { OnOpen = nil, OnClose = nil }
	-- PlayerGui only: in Studio edit mode (no PlayerGui) the window is built unparented, never into StarterGui
	local player = Players.LocalPlayer
	local gui = New("ScreenGui", {
		Name = opts.Name,
		ResetOnSpawn = false,
		DisplayOrder = opts.DisplayOrder or LAYER_ORDER[layer] or 10,
		Enabled = false,
		IgnoreGuiInset = false,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		Parent = if RunService:IsRunning() and player then player:WaitForChild("PlayerGui") else nil,
	})
	if opts.Dim then
		New("TextButton", { Name = "Dim", Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 0.35, Text = "", AutoButtonColor = false, BorderSizePixel = 0, Parent = gui })
	end
	local frame = New.Panel({
		Name = opts.WindowName or "Window",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(size.X, if opts.AutoHeight then 0 else size.Y),
		AutomaticSize = if opts.AutoHeight then Enum.AutomaticSize.Y else Enum.AutomaticSize.None,
		Radius = opts.Radius or T.RadiusWindow,
		Clip = opts.Clip, -- rounded clipping (CanvasGroup) for windows with a sand footer band
		Parent = gui,
	})
	if pad > 0 then
		New.Padding(pad).Parent = frame
	end
	New.FitToScreen(frame, 24)
	if opts.Title then
		w.TitleLabel = New.Title({ Name = "Title", Position = UDim2.fromOffset(0, 13), Size = UDim2.new(1, -90, 0, 32), Text = opts.Title, TextSize = 26, TextXAlignment = Enum.TextXAlignment.Left, Parent = frame })
	end
	if opts.Close ~= false then
		w.CloseButton = New.Button({ Name = "Btn Close", AnchorPoint = Vector2.new(1, 0), Position = UDim2.fromScale(1, 0), Size = UDim2.fromOffset(73, 57), Text = "X", TextSize = 22, BackgroundColor3 = T.Bad, Parent = frame })
		w.CloseButton.Activated:Connect(function()
			w.Close()
		end)
	end
	w.Gui = gui
	w.Frame = frame

	-- Short screens (phones in landscape): a 760x610 design would be scaled to ~0.45 and unreadable. With
	-- opts.ScrollOnShort = true (list-like windows such as Aquarium) the window gets the height of the screen, the
	-- title and close button stay put, and the content scrolls. Store never scrolls: it pages (StoreScreen).
	local camera = workspace.CurrentCamera
	local vp = if camera then camera.ViewportSize else Vector2.new(1280, 720)
	vp = Vector2.new(vp.X, vp.Y - game:GetService("GuiService"):GetGuiInset().Y) -- the ScreenGui starts below the top bar
	if vp.Y < 520 and opts.ScrollOnShort == true and not opts.AutoHeight and opts.Close ~= false and size.Y > 380 then
		local HEADER = 64
		local designInner = size.Y - pad * 2
		frame.Size = UDim2.fromOffset(size.X, math.min(size.Y, math.floor((vp.Y - 48) / 0.78)))
		local scroller = New("ScrollingFrame", {
			Name = "Scroller",
			Position = UDim2.fromOffset(0, HEADER),
			Size = UDim2.new(1, 0, 1, -HEADER),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			ScrollBarThickness = 4,
			ScrollingDirection = Enum.ScrollingDirection.Y,
			CanvasSize = UDim2.fromOffset(0, designInner - HEADER),
			Parent = frame,
		})
		local inner = New("Frame", {
			Name = "Inner",
			Position = UDim2.fromOffset(0, -HEADER),
			Size = UDim2.new(1, 0, 0, designInner),
			BackgroundTransparency = 1,
			Parent = scroller,
		})
		local function keep(c: Instance): boolean
			return not c:IsA("GuiObject") or c == scroller or c == w.TitleLabel or c == w.CloseButton or c.Name == "Loading"
		end
		local function adopt()
			for _, c in frame:GetChildren() do
				if not keep(c) then
					c.Parent = inner
				end
			end
		end
		w.Inner = inner
		w.Adopt = adopt
		-- the builders add their content right after Shell returns, so adopt on the next frame and for late additions
		frame.ChildAdded:Connect(function(c)
			if not keep(c) then
				task.defer(function()
					if c.Parent == frame then
						c.Parent = inner
					end
				end)
			end
		end)
		task.defer(adopt)
	end

	function w.Open(...)
		MenuManager.WillOpen(opts.Name)
		gui.Enabled = true
		if w.OnOpen then
			w.OnOpen(...)
		end
	end
	function w.Close()
		if not gui.Enabled then
			return
		end
		gui.Enabled = false
		if w.OnClose then
			w.OnClose()
		end
		MenuManager.Closed(opts.Name)
	end
	function w.IsOpen(): boolean
		return gui.Enabled
	end
	-- Spinner over `target` (default the window) while data loads; content under it stays as it is.
	function w.SetLoading(on: boolean, target: GuiObject?)
		local host = target or frame
		local old = host:FindFirstChild("Loading")
		if old then
			old:Destroy()
		end
		if on then
			local cover = New("Frame", { Name = "Loading", Size = UDim2.fromScale(1, 1), BackgroundColor3 = T.Panel, BackgroundTransparency = 0.15, ZIndex = 50, Parent = host })
			New.Spinner({ Size = UDim2.fromOffset(48, 48), Thickness = 5, ZIndex = 51, Parent = cover })
		end
	end
	MenuManager.Register(opts.Name, {
		Layer = layer,
		StackOn = opts.StackOn,
		Open = function(...)
			w.Open(...)
		end,
		Close = function()
			w.Close()
		end,
		IsOpen = w.IsOpen,
		Gui = function()
			return gui
		end,
	})
	return w
end

-- Empties a body (old layouts too, so tabs never stack UIListLayout/UIGridLayout) and adds an inner
-- margin: the ScrollingFrame clips its children, and strokes / tick badges / NEW pills sit a few px
-- outside their cards - without the margin they get cut at the edges.
function Window.Clear(frame: Instance)
	for _, c in frame:GetChildren() do
		c:Destroy()
	end
	New("UIPadding", {
		PaddingTop = UDim.new(0, 12),
		PaddingLeft = UDim.new(0, 8),
		PaddingRight = UDim.new(0, 14),
		PaddingBottom = UDim.new(0, 12),
		Parent = frame,
	})
end

function Window.Create(opts: { [string]: any }): any
	local shell = Window.Shell({ Name = opts.Name, Title = opts.Title, Size = opts.Size or Vector2.new(680, 500), Padding = 20, Layer = opts.Layer, StackOn = opts.StackOn })
	local w: any = { Tab = opts.Tabs and opts.Tabs[1] or nil, OnTab = nil, OnOpen = nil }
	local frame = shell.Frame
	local header = New.Text({
		Name = "Header",
		Position = UDim2.fromOffset(0, 62),
		Size = UDim2.new(1, 0, 0, 22),
		Text = "",
		TextColor3 = T.SubText,
		TextXAlignment = Enum.TextXAlignment.Left,
		MaxTextSize = 16,
		RichText = true,
		Parent = frame,
	})
	local top = 92
	local tabButtons = {}
	if opts.Tabs then
		local bar = New("Frame", {
			Name = "Tabs",
			Position = UDim2.fromOffset(0, top),
			Size = UDim2.new(1, 0, 0, 44),
			BackgroundTransparency = 1,
			Parent = frame,
			[New.Children] = { New("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }) },
		})
		for i, name in opts.Tabs do
			local b = New.Button({
				Name = name,
				LayoutOrder = i,
				Size = UDim2.new(1 / #opts.Tabs, -8, 1, 0),
				Text = name,
				BackgroundColor3 = T.PanelLight,
				MaxTextSize = 20,
				Parent = bar,
			})
			tabButtons[name] = b
			b.Activated:Connect(function()
				w.SetTab(name)
			end)
		end
		top += 54
	end
	local body = New("ScrollingFrame", {
		Name = "Body",
		Position = UDim2.fromOffset(0, top),
		Size = UDim2.new(1, 0, 1, -top),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 6,
		ScrollBarImageColor3 = T.Track,
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		CanvasSize = UDim2.new(),
		Parent = frame,
	})

	w.Gui = shell.Gui
	w.Frame = frame
	w.Header = header
	w.Body = body
	w.SetLoading = shell.SetLoading

	function w.SetTab(name: string)
		w.Tab = name
		for n, b in tabButtons do
			New.SetButtonColor(b, if n == name then T.Accent else T.PanelLight)
		end
		body.CanvasPosition = Vector2.zero
		if w.OnTab then
			w.OnTab(name)
		end
	end
	shell.OnOpen = function(tab: string?)
		if tab or w.Tab then
			w.SetTab(tab or w.Tab)
		elseif w.OnTab then
			w.OnTab(nil)
		end
		if w.OnOpen then
			w.OnOpen()
		end
	end
	shell.OnClose = function()
		if w.OnClose then
			w.OnClose()
		end
	end
	w.Open = shell.Open
	w.Close = shell.Close
	w.IsOpen = shell.IsOpen
	return w
end

-- List layout for a body (call once per refresh after Clear).
function Window.List(body: Instance, padding: number?)
	New("UIListLayout", { Padding = UDim.new(0, padding or 8), SortOrder = Enum.SortOrder.LayoutOrder, Parent = body })
end

-- One row: [icon] Title / Sub ............ [Button]
function Window.Row(props: { [string]: any }): Frame
	local row = New.Panel({
		Name = props.Name or "Row",
		LayoutOrder = props.Order or 0,
		Size = UDim2.new(1, 0, 0, props.Height or 74),
		BackgroundColor3 = T.PanelLight,
	})
	New.Padding(10).Parent = row
	local left = 0
	if props.Icon then
		New.Image({
			Name = "Icon",
			Key = props.Icon,
			Fallback = props.IconColor or T.Track,
			FallbackText = props.IconText,
			Size = UDim2.fromOffset(52, 52),
			Position = UDim2.new(0, 0, 0.5, -26),
			Parent = row,
		})
		left = 62
	end
	local btnW = if props.Button then (props.Button.Width or 150) else 0
	New.Title({
		Name = "Title",
		Position = UDim2.fromOffset(left, 0),
		Size = UDim2.new(1, -left - btnW - 10, 0, 26),
		Text = props.Title or "",
		TextXAlignment = Enum.TextXAlignment.Left,
		MaxTextSize = 20,
		RichText = true,
		Parent = row,
	})
	New.Text({
		Name = "Sub",
		Position = UDim2.fromOffset(left, 28),
		Size = UDim2.new(1, -left - btnW - 10, 1, -28),
		Text = props.Sub or "",
		TextColor3 = T.SubText,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Top,
		TextWrapped = true,
		MaxTextSize = 15,
		RichText = true,
		Parent = row,
	})
	if props.Button then
		local b = props.Button
		local buttonProps = {
			Name = "Action",
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, 0, 0.5, 0),
			Size = UDim2.fromOffset(btnW, 48),
			Text = b.Text,
			BackgroundColor3 = if b.Enabled == false then T.Disabled else (b.Color or T.Good),
			MaxTextSize = 18,
			Parent = row,
		}
		local button = if b.RobuxPrice ~= nil then New.RobuxButton(buttonProps, b.RobuxPrice) else New.Button(buttonProps)
		if b.Enabled == false then
			New.SetButtonColor(button, T.Disabled, T.DisabledText)
		elseif b.OnClick then
			button.Activated:Connect(b.OnClick)
		end
	end
	return row :: Frame
end

return Window
