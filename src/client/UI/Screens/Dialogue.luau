--!nonstrict
-- Figma 11 · Dialogue (docs/figma/cozy_menus_spec.py s_dialogue, 1280x720 frame), B7.
-- NPC talk box at the bottom with a mint name tag, speech-bubble choices on the right and a round
-- close button on the box's top-right corner (clear of the mobile jump button). No portrait: the NPC
-- stands in the 3D world. Static layout + sample text; Controllers/DialogueController fills it.
--   Root        1050x560 transparent frame, bottom-centre (FitToScreen scales it on small screens)
--     Box       cream panel 900x190 (r40, 96% opaque) at the bottom-left of Root; Shadow (9-slice, draws
--               the panel), Content (padding) > Line (wrapped text, typewriter), Hint (hidden)
--     Speaker   mint pill on the box's top edge (x 60): Name
--     Choices   Choice1..Choice4: pill buttons 340x64 (Icon 34 + Label), stacked upwards from above the
--               box's right side (Figma x 900 / y 290 + 370 on the 1280 frame)
--     Close     round 64px panel button on the box's top-right corner

local New = require(script.Parent.Parent.New)
local T = New.Theme

local Screen = { Name = "Dialogue" }

local ROOT = Vector2.new(1050, 560)
local BOX = Vector2.new(900, 190)
local BOX_Y = ROOT.Y - BOX.Y -- 370
local CHOICE_W, CHOICE_H, CHOICE_STEP = 340, 64, 80
local CHOICE_X = 710 -- Figma 900 - box x 190
Screen.MaxChoices = 4

local function choice(root: Frame, i: number)
	-- Choice1 sits lowest (Figma y 370 = 130 above the box top), the rest stack upwards
	local y = BOX_Y - 130 - (i - 1) * CHOICE_STEP
	local b = New("TextButton", {
		Name = "Choice" .. i,
		Position = UDim2.fromOffset(CHOICE_X, y),
		Size = UDim2.fromOffset(CHOICE_W, CHOICE_H),
		BackgroundColor3 = T.Panel,
		Text = "",
		AutoButtonColor = true,
		Visible = i <= 2,
		LayoutOrder = i,
		Parent = root,
		[New.Children] = {
			New.Pill(),
			New.Stroke(T.Track, 2),
			New("UIPadding", { PaddingLeft = UDim.new(0, 22), PaddingRight = UDim.new(0, 30) }),
			New("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 18), VerticalAlignment = Enum.VerticalAlignment.Center, SortOrder = Enum.SortOrder.LayoutOrder }),
		},
	})
	New.Image({ Name = "Icon", Key = if i == 1 then "icon_fish" else "icon_chat", Tint = T.Text, Fallback = T.Track, Size = UDim2.fromOffset(34, 34), LayoutOrder = 1, Parent = b })
	New.Title({
		Name = "Label",
		Size = UDim2.new(1, -52, 0, 30),
		Text = if i == 1 then "Sell All Fish" else "Just chatting",
		TextXAlignment = Enum.TextXAlignment.Left,
		TextSize = 22,
		LayoutOrder = 2,
		Parent = b,
	})
end

function Screen.Build(): ScreenGui
	local gui = New("ScreenGui", {
		Name = "Dialogue",
		ResetOnSpawn = false,
		IgnoreGuiInset = false,
		Enabled = false, -- DialogueController opens it (NPC ProximityPrompt -> "OpenDialogue")
		DisplayOrder = 14,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	}) :: ScreenGui
	local root = New("Frame", {
		Name = "Root",
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 75, 1, -30), -- box centred (root is 150 wider on the right for the choices)
		Size = UDim2.fromOffset(ROOT.X, ROOT.Y),
		BackgroundTransparency = 1,
		Parent = gui,
	})
	local box = New("TextButton", {
		Name = "Box",
		Position = UDim2.fromOffset(0, BOX_Y),
		Size = UDim2.fromOffset(BOX.X, BOX.Y),
		BackgroundColor3 = T.Panel,
		BackgroundTransparency = 0.04,
		Text = "",
		AutoButtonColor = false,
		Parent = root,
		[New.Children] = {
			New.Corner(40),
			New.Stroke(T.Track, 2),
		},
	})
	-- the 9-slice Shadow draws the panel: it must fill the whole box, so the text padding lives on Content
	New.Shadow(box, "slice_shadow_window")
	local content = New("Frame", {
		Name = "Content",
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Parent = box,
		[New.Children] = {
			New("UIPadding", { PaddingTop = UDim.new(0, 52), PaddingLeft = UDim.new(0, 60), PaddingRight = UDim.new(0, 60), PaddingBottom = UDim.new(0, 30) }),
		},
	})
	New.Title({
		Name = "Line",
		Size = UDim2.fromScale(1, 1),
		Text = "Back again? The lake has been generous today... want me to take that catch off your hands?",
		TextColor3 = T.SubText,
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Top,
		TextSize = 24,
		Parent = content,
	})
	New.Text({
		Name = "Hint",
		AnchorPoint = Vector2.new(1, 1),
		Position = UDim2.new(1, 20, 1, 18),
		Size = UDim2.fromOffset(200, 18),
		Text = "tap to continue",
		TextColor3 = T.SubText,
		TextXAlignment = Enum.TextXAlignment.Right,
		TextSize = 13,
		Visible = false,
		Parent = content,
	})
	local tag = New("Frame", {
		Name = "Speaker",
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.fromOffset(60, BOX_Y),
		Size = UDim2.fromOffset(0, 46),
		AutomaticSize = Enum.AutomaticSize.X,
		BackgroundColor3 = T.Good,
		ZIndex = 3,
		Parent = root,
		[New.Children] = {
			New.Pill(),
			New.Stroke(Color3.new(1, 1, 1), 3),
			New("UIPadding", { PaddingLeft = UDim.new(0, 22), PaddingRight = UDim.new(0, 22) }),
		},
	})
	New("TextLabel", {
		Name = "Name",
		Size = UDim2.fromOffset(0, 46),
		AutomaticSize = Enum.AutomaticSize.X,
		BackgroundTransparency = 1,
		Text = "Old Marlin",
		TextColor3 = T.OnAccent,
		FontFace = T.Font,
		TextSize = New.FigmaSize(T.Font, 24),
		ZIndex = 3,
		Parent = tag,
	})
	for i = 1, Screen.MaxChoices do
		choice(root, i)
	end
	local close = New("TextButton", {
		Name = "Close",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromOffset(BOX.X - 8, BOX_Y + 2), -- Figma 1050,466 (64px) on the box corner
		Size = UDim2.fromOffset(64, 64),
		BackgroundColor3 = T.Panel,
		Text = "",
		AutoButtonColor = true,
		ZIndex = 3,
		Parent = root,
		[New.Children] = { New.Pill(), New.Stroke(T.Track, 2) },
	})
	New.Image({
		Name = "Icon",
		Key = "icon_close",
		Tint = T.SubText,
		Fallback = T.SubText,
		FallbackText = "X",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(30, 30),
		ZIndex = 4,
		Parent = close,
	})
	return gui
end

return Screen
