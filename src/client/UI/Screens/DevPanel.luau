--!nonstrict
-- Dev panel (F2, dev/admin only — Config/Dev). Static layout; Controllers/DevController binds it.
--   Window: Header (Title, Close), Input (TextBox) + Run, Quick (grid of preset buttons; each button's
--   attribute "Command" is the line it runs — add presets in QUICK), Output (scrolling log).

local New = require(script.Parent.Parent.New)
local T = New.Theme

local Screen = { Name = "DevPanel" }

-- { label, command, colour }
Screen.Quick = {
	{ "+1,000 Gems", "give gems 1000", T.Gem },
	{ "+10k Coins", "give coins 10000", T.Gold },
	{ "+3 Chests", "give chest TreasureChest 3", T.Accent },
	{ "+20 Shrimp", "give bait Shrimp 20", T.Sky },
	{ "Altar pity 99", "pity Altar 99", T.Gem },
	{ "Banner 400 pulls", "pulls NeonTide 400", T.Gem },
	{ "Level 100", "level 100", T.Good },
	{ "Coolbox bag", "equip Bags Coolbox", T.Sky },
	{ "Clear bag", "clearbag", T.PanelLight },
	{ "Help", "help", T.PanelLight },
}

function Screen.Build(): ScreenGui
	local gui = New("ScreenGui", {
		Name = "DevPanel",
		ResetOnSpawn = false,
		DisplayOrder = 60,
		Enabled = false,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	}) :: ScreenGui

	local w = New.Panel({
		Name = "Window",
		AnchorPoint = Vector2.new(1, 1),
		Position = UDim2.new(1, -230, 1, -16),
		Size = UDim2.fromOffset(440, 420),
		Radius = 20,
		Parent = gui,
	})
	New.Title({ Name = "Title", Position = UDim2.fromOffset(16, 12), Size = UDim2.fromOffset(300, 30), Text = "Dev panel (F2)", TextXAlignment = Enum.TextXAlignment.Left, TextSize = 22, Parent = w })
	New.Button({ Name = "Close", AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -12, 0, 10), Size = UDim2.fromOffset(44, 38), Text = "X", BackgroundColor3 = T.Bad, TextSize = 18, Parent = w })

	New("TextBox", {
		Name = "Input",
		Position = UDim2.fromOffset(16, 58),
		Size = UDim2.fromOffset(310, 40),
		BackgroundColor3 = Color3.new(1, 1, 1),
		Text = "",
		PlaceholderText = "give gems 1000",
		PlaceholderColor3 = T.SubText,
		TextColor3 = T.Text,
		FontFace = T.FontBody,
		TextSize = 18,
		ClearTextOnFocus = false,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = w,
		[New.Children] = { New.Corner(12), New.Stroke(), New("UIPadding", { PaddingLeft = UDim.new(0, 10) }) },
	})
	New.Button({ Name = "Run", Position = UDim2.fromOffset(336, 58), Size = UDim2.fromOffset(88, 44), Text = "RUN", BackgroundColor3 = T.Accent, TextSize = 18, Parent = w })

	local quick = New("Frame", {
		Name = "Quick",
		Position = UDim2.fromOffset(16, 112),
		Size = UDim2.fromOffset(408, 160),
		BackgroundTransparency = 1,
		Parent = w,
		[New.Children] = { New("UIGridLayout", { CellSize = UDim2.fromOffset(132, 36), CellPadding = UDim2.fromOffset(6, 6), SortOrder = Enum.SortOrder.LayoutOrder }) },
	})
	for i, q in Screen.Quick do
		local b = New.Button({ Name = "Q" .. i, Text = q[1], BackgroundColor3 = q[3], TextSize = 14, LayoutOrder = i, Parent = quick })
		b:SetAttribute("Command", q[2])
	end

	local out = New("ScrollingFrame", {
		Name = "Output",
		Position = UDim2.fromOffset(16, 284),
		Size = UDim2.fromOffset(408, 120),
		BackgroundColor3 = T.PanelLight,
		ScrollBarThickness = 6,
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		Parent = w,
		[New.Children] = { New.Corner(12), New("UIPadding", { PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10), PaddingTop = UDim.new(0, 6) }) },
	})
	New("TextLabel", {
		Name = "Log",
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		Text = "Type a command or press a preset. 'help' lists everything.",
		TextColor3 = T.Text,
		FontFace = T.FontBody,
		TextSize = 14,
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Top,
		Parent = out,
	})
	return gui
end

return Screen
