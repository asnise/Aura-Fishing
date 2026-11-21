--!nonstrict
-- Depth popup (Figma 15 · Cast Popup, 3492:17684) opened from the HUD Depth icon button.
-- Static layout only; behaviour lives in UI/CastPopup.luau. No Auto depth toggle and no CAST button:
-- casting is hold-and-release in the world (C25), so this popup only sets the target depth.

local New = require(script.Parent.Parent.New)
local T = New.Theme

local Screen = { Name = "CastPopup" }

local WIDTH, PAD = 470, 16
local INNER = WIDTH - PAD * 2 -- 438

local function frame(name: string, x: number, y: number, w: number, h: number, parent: Instance): Frame
	return New("Frame", {
		Name = name,
		Position = UDim2.fromOffset(x, y),
		Size = UDim2.fromOffset(w, h),
		BackgroundTransparency = 1,
		Parent = parent,
	}) :: Frame
end

function Screen.Build(): ScreenGui
	local gui = New("ScreenGui", {
		Name = "CastPopup",
		ResetOnSpawn = false,
		IgnoreGuiInset = false,
		DisplayOrder = 18,
		Enabled = false,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	}) :: ScreenGui

	-- Transparent input shield: a tap outside the window closes it (no dark backdrop, see AGENTS rule 9).
	New("TextButton", {
		Name = "Shield",
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Text = "",
		AutoButtonColor = false,
		Active = true,
		ZIndex = 1,
		Parent = gui,
	})

	local window = New.Panel({
		Name = "Window",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(WIDTH, 342),
		Radius = 24,
		ZIndex = 2,
		Parent = gui,
	})
	New.Shadow(window, "slice_shadow_modal")
	New.FitToScreen(window)

	-- Header: bobber icon + title + close
	local header = frame("Header", PAD, PAD, INNER, 48, window)
	New.Image({ Name = "Icon", Key = "ui/status/bobber", Fallback = T.TintSky, Position = UDim2.fromOffset(0, 7), Size = UDim2.fromOffset(34, 34), ZIndex = 3, Parent = header })
	New.Title({ Name = "Title", Text = "Depth", TextSize = 26, TextXAlignment = Enum.TextXAlignment.Left, Position = UDim2.fromOffset(44, 8), Size = UDim2.fromOffset(200, 32), ZIndex = 3, Parent = header })
	New.Button({ Name = "Close", Text = "X", TextSize = 22, BackgroundColor3 = Color3.fromRGB(242, 122, 122), AnchorPoint = Vector2.new(1, 0), Position = UDim2.fromScale(1, 0), Size = UDim2.fromOffset(64, 48), ZIndex = 3, Parent = header })

	-- Readout: big depth + zone chip
	New.Title({ Name = "Value", Text = "80m", TextSize = 44, Position = UDim2.fromOffset(PAD, 76), Size = UDim2.fromOffset(INNER, 53), ZIndex = 3, Parent = window })
	local zone = New("Frame", {
		Name = "Zone",
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 132),
		Size = UDim2.fromOffset(110, 22),
		BackgroundColor3 = T.TintSky,
		ZIndex = 3,
		Parent = window,
		[New.Children] = { New.Pill() },
	})
	New.Text({ Name = "Label", Text = "MID WATER", TextSize = 12, FontFace = T.FontBadge, TextColor3 = T.Text, Size = UDim2.fromScale(1, 1), ZIndex = 4, Parent = zone })

	-- Slider: zone bands are added by the controller (they depend on the line's max depth)
	local holder = frame("SliderHolder", PAD, 168, INNER, 34, window)
	holder.ZIndex = 3
	New("Frame", {
		Name = "Track",
		Position = UDim2.fromOffset(0, 8),
		Size = UDim2.fromOffset(INNER, 18),
		BackgroundColor3 = T.Track,
		ClipsDescendants = true,
		ZIndex = 3,
		Parent = holder,
		[New.Children] = { New.Pill() },
	})
	New("Frame", {
		Name = "Knob",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromOffset(INNER / 2, 17),
		Size = UDim2.fromOffset(30, 30),
		BackgroundColor3 = Color3.new(1, 1, 1),
		ZIndex = 5,
		Parent = holder,
		[New.Children] = { New.Pill(), New.Stroke(T.Track, 2) },
	})

	-- Scale labels
	local scale = frame("Scale", PAD, 208, INNER, 14, window)
	New.Text({ Name = "Min", Text = "0m", TextSize = 12, TextColor3 = T.SubText, TextXAlignment = Enum.TextXAlignment.Left, Size = UDim2.fromOffset(80, 14), ZIndex = 3, Parent = scale })
	New.Text({ Name = "Max", Text = "150m (line)", TextSize = 12, TextColor3 = T.SubText, TextXAlignment = Enum.TextXAlignment.Right, AnchorPoint = Vector2.new(1, 0), Position = UDim2.fromScale(1, 0), Size = UDim2.fromOffset(160, 14), ZIndex = 3, Parent = scale })

	-- Presets
	local presets = frame("Presets", PAD, 232, INNER, 57, window)
	for i, p in { { "Shallow", "Shallow 20m" }, { "Mid", "Mid 80m" }, { "Max", "Max" } } do
		New.Button({ Name = p[1], Text = p[2], TextSize = 18, BackgroundColor3 = T.PanelLight, Position = UDim2.fromOffset((i - 1) * 150, 0), Size = UDim2.fromOffset(138, 57), ZIndex = 3, Parent = presets })
	end

	New.Text({ Name = "Species", Text = "9 species live here", TextSize = 14, TextColor3 = T.SubText, Position = UDim2.fromOffset(PAD, 302), Size = UDim2.fromOffset(INNER, 22), ZIndex = 3, Parent = window })

	New.ApplyImages(gui)
	return gui
end

return Screen
