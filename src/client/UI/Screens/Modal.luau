--!nonstrict
-- Figma 14 · Modal (node 3492:17615): generic confirm dialog (Sell All, Rebirth, ...).
-- Static layout only; behaviour lives in UI/Modal.luau. Baked into StarterGui by tools/ui/bake.mjs.

local New = require(script.Parent.Parent.New)
local T = New.Theme

local Screen = { Name = "Modal" }

function Screen.Build(): ScreenGui
	local gui = New("ScreenGui", {
		Name = "Modal",
		ResetOnSpawn = false,
		IgnoreGuiInset = true,
		DisplayOrder = 50,
		Enabled = false,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	}) :: ScreenGui

	New("TextButton", {
		Name = "Dim",
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = T.Text,
		BackgroundTransparency = 0.72,
		AutoButtonColor = false,
		Text = "",
		Parent = gui,
	})

	local window = New.Panel({
		Name = "Window",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(600, 349),
		Radius = 36,
		Parent = gui,
	})
	New.Shadow(window, "slice_shadow_modal")

	local body = New("Frame", { Name = "Body", Size = UDim2.new(1, 0, 0, 248), BackgroundTransparency = 1, Parent = window })
	New.Image({
		Name = "Icon",
		Key = "ui/status/sell_bag",
		Fallback = T.Gold,
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 44),
		Size = UDim2.fromOffset(96, 96),
		Parent = body,
	})
	New.Title({
		Name = "Title",
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 150),
		Size = UDim2.fromOffset(500, 30),
		Text = "Sell all 18 fish?",
		TextSize = 26,
		Parent = body,
	})
	New.Text({
		Name = "Message",
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 188),
		Size = UDim2.fromOffset(500, 44),
		Text = `You'll get {New.Highlight("2,340 coins")}. Fish with mutations are included.`,
		RichText = true,
		TextColor3 = T.SubText,
		TextSize = 16,
		TextWrapped = true,
		TextYAlignment = Enum.TextYAlignment.Top,
		Parent = body,
	})

	-- Sand footer with rounded bottom corners (square top edge: a cover strip hides the top rounding)
	local footer = New("Frame", {
		Name = "Footer",
		Position = UDim2.fromOffset(2, 248),
		Size = UDim2.new(1, -4, 0, 99),
		BackgroundColor3 = T.PanelLight,
		BorderSizePixel = 0,
		Parent = window,
		[New.Children] = { New.Corner(34) },
	})
	New("Frame", { Name = "Square", Size = UDim2.new(1, 0, 0, 40), BackgroundColor3 = T.PanelLight, BorderSizePixel = 0, Parent = footer })
	New.Button({ Name = "Cancel", Position = UDim2.fromOffset(38, 18), Size = UDim2.fromOffset(248, 57), Text = "Cancel", TextSize = 22, BackgroundColor3 = T.PanelLight, ZIndex = 2, Parent = footer })
	New.Button({ Name = "Confirm", Position = UDim2.fromOffset(306, 18), Size = UDim2.fromOffset(248, 57), Text = "Confirm", TextSize = 22, BackgroundColor3 = T.Good, ZIndex = 2, Parent = footer })

	return gui
end

return Screen
