--!nonstrict
-- Figma 03 · Reel Minigame, A2 "Twin tubes" (node 3526:22708, CHOSEN 2026-11-17). Static layout
-- only (sample: EPIC, 0:12, bar on the fish, reel 60%); FishingController.runMinigame binds it.
--   Panel 140x394 (absolute layout, Figma positions)
--     Header   Rarity (pill), Timer
--     Body     Water (glass tube + bubbles), Lane (Bar, Fish — same rect as Water, not clipped
--              so the bar/fish can overhang the tube), Meter (Track/Fill gold, Bobber image)
--     Hint     "HOLD TO REEL"
-- Bar: Size.Y.Scale = catch bar size, Position.Y.Scale = 1 - bar bottom. Fish/Bobber move by script.

local New = require(script.Parent.Parent.New)
local T = New.Theme

local Screen = { Name = "Minigame" }

local TUBE_W, TUBE_H = 25, 300
local EPIC = Color3.fromRGB(176, 124, 240) -- Config/Rarities.Epic (sample)
local SAMPLE_BAR, SAMPLE_BAR_POS, SAMPLE_FISH, SAMPLE_PROGRESS = 0.28, 0.22, 0.36, 0.6

function Screen.Build(): ScreenGui
	local gui = New("ScreenGui", {
		Name = "Minigame",
		ResetOnSpawn = false,
		DisplayOrder = 15,
		Enabled = false, -- FishingController enables it while reeling
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	}) :: ScreenGui

	local panel = New("Frame", {
		Name = "Panel",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.45),
		Size = UDim2.fromOffset(140, 394),
		BackgroundColor3 = T.Panel,
		Parent = gui,
		[New.Children] = { New.Corner(20), New.Stroke(T.Track, 2) },
	})

	-- header: rarity pill + time left
	local header = New("Frame", {
		Name = "Header",
		Position = UDim2.fromOffset(18, 18),
		Size = UDim2.fromOffset(104, 24),
		BackgroundTransparency = 1,
		Parent = panel,
		[New.Children] = { New("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 8), HorizontalAlignment = Enum.HorizontalAlignment.Center, VerticalAlignment = Enum.VerticalAlignment.Center, SortOrder = Enum.SortOrder.LayoutOrder }) },
	})
	New("TextLabel", {
		Name = "Rarity",
		Size = UDim2.fromOffset(0, 20),
		AutomaticSize = Enum.AutomaticSize.X,
		BackgroundColor3 = EPIC,
		Text = "EPIC",
		TextColor3 = T.OnAccent,
		FontFace = T.FontBadge,
		TextSize = New.FigmaSize(T.FontBadge, 12),
		LayoutOrder = 1,
		Parent = header,
		[New.Children] = { New.Pill(), New("UIPadding", { PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10) }) },
	})
	New("TextLabel", {
		Name = "Timer",
		Size = UDim2.fromOffset(0, 24),
		AutomaticSize = Enum.AutomaticSize.X,
		BackgroundTransparency = 1,
		Text = "0:12",
		TextColor3 = T.SubText,
		FontFace = T.Font,
		TextSize = New.FigmaSize(T.Font, 20),
		LayoutOrder = 2,
		Parent = header,
	})

	local body = New("Frame", { Name = "Body", Position = UDim2.fromOffset(30, 52), Size = UDim2.fromOffset(81, TUBE_H), BackgroundTransparency = 1, Parent = panel })

	-- water tube (glass): gradient + track border, bubbles inside
	local water = New("Frame", {
		Name = "Water",
		Size = UDim2.fromOffset(TUBE_W, TUBE_H),
		BackgroundColor3 = Color3.new(1, 1, 1),
		ClipsDescendants = true,
		Parent = body,
		[New.Children] = {
			New.Corner(10),
			New.Stroke(T.Track, 3),
			New("UIGradient", { Rotation = 90, Color = ColorSequence.new(Color3.fromRGB(190, 230, 250), Color3.fromRGB(76, 143, 199)) }),
		},
	})
	for i, b in { { 5, 45, 10 }, { 18, 90, 7 }, { 9, 165, 12 }, { 19, 225, 8 }, { 6, 264, 6 } } do
		New("Frame", {
			Name = "Bubble" .. i,
			Position = UDim2.fromOffset(b[1], b[2]),
			Size = UDim2.fromOffset(b[3], b[3]),
			BackgroundColor3 = Color3.new(1, 1, 1),
			BackgroundTransparency = 0.5,
			Parent = water,
			[New.Children] = { New.Pill() },
		})
	end

	-- lane: same rect as the water tube, unclipped (bar is 6px wider than the tube, fish 39px)
	local lane = New("Frame", { Name = "Lane", Size = UDim2.fromOffset(TUBE_W, TUBE_H), BackgroundTransparency = 1, ZIndex = 2, Parent = body })
	New("Frame", {
		Name = "Bar",
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.new(0, -3, 1 - SAMPLE_BAR_POS, 0),
		Size = UDim2.new(1, 6, SAMPLE_BAR, 0),
		BackgroundColor3 = T.Good,
		BackgroundTransparency = 0.15,
		ZIndex = 2,
		Parent = lane,
		[New.Children] = { New.Corner(9), New.Stroke(Color3.new(1, 1, 1), 3) },
	})
	local fish = New.Image({
		Name = "Fish",
		Key = "fish/MysteryFish",
		FallbackText = "><>",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 1 - SAMPLE_FISH),
		Size = UDim2.fromOffset(39, 39),
		ZIndex = 3,
		Parent = lane,
	})
	local fb = fish:FindFirstChild("Fallback")
	if fb then
		fb.BackgroundTransparency = 1
	end

	-- reel tube: track colour, gold fill from the bottom, bobber image riding the fill
	local meter = New("Frame", { Name = "Meter", Position = UDim2.fromOffset(56, 0), Size = UDim2.fromOffset(TUBE_W, TUBE_H), BackgroundTransparency = 1, Parent = body })
	local track = New("Frame", {
		Name = "Track",
		Size = UDim2.fromOffset(TUBE_W, TUBE_H),
		BackgroundColor3 = T.Track,
		ClipsDescendants = true,
		Parent = meter,
		[New.Children] = { New.Corner(10), New.Stroke(T.Track, 3) },
	})
	New("Frame", {
		Name = "Fill",
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.fromScale(0, 1),
		Size = UDim2.fromScale(1, SAMPLE_PROGRESS),
		BackgroundColor3 = Color3.new(1, 1, 1),
		Parent = track,
		[New.Children] = { New.Corner(10), New("UIGradient", { Rotation = 90, Color = ColorSequence.new(Color3.fromRGB(255, 212, 92), T.Gold) }) },
	})
	New.Image({
		Name = "Bobber",
		Key = "ui/status/bobber",
		Fallback = T.Accent,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0, TUBE_H * (1 - SAMPLE_PROGRESS)),
		Size = UDim2.fromOffset(24, 24),
		ZIndex = 3,
		Parent = meter,
	})

	New("TextLabel", {
		Name = "Hint",
		Position = UDim2.fromOffset(0, 362),
		Size = UDim2.fromOffset(140, 14),
		BackgroundTransparency = 1,
		Text = "HOLD TO REEL",
		TextColor3 = T.SubText,
		FontFace = T.FontBadge,
		TextSize = New.FigmaSize(T.FontBadge, 12),
		Parent = panel,
	})

	return gui
end

return Screen
