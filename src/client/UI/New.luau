--!nonstrict
-- Tiny declarative Instance builder + the "Cozy Lake" UI theme (docs/UI_STYLE.md).
--   New("Frame", { Size = ..., [New.Children] = { New("UICorner", {}) } })
-- Props that are functions are connected as events: { Activated = function() end }
-- Change colours/fonts ONLY in THEME below; controllers read New.Theme.

local New = {}
New.ClickHook = nil :: (() -> ())? -- set by Controllers/SoundController: plays ui_click on every button
New.PlaySound = nil :: ((string) -> ())? -- set by Controllers/SoundController (UI modules cannot require controllers)

-- Play a Config/Sounds id from UI code; silent until SoundController is running.
function New.Sfx(id: string)
	if New.PlaySound then
		New.PlaySound(id)
	end
end
New.Children = newproxy(false)

local rgb = Color3.fromRGB

local THEME = {
	-- surfaces
	Scene = rgb(191, 232, 224), -- mint backdrop
	Panel = rgb(255, 248, 236), -- cream card
	PanelPale = rgb(255, 253, 247), -- daily reward card
	PanelLight = rgb(243, 233, 216), -- sand rows / secondary buttons
	Track = rgb(230, 220, 203), -- bar tracks, panel edge
	-- buttons you can't use yet (can't afford / level lock): muted grey-sand, darker than list rows (white reads as clickable)
	Disabled = rgb(216, 209, 196),
	DisabledLip = rgb(188, 179, 164),
	DisabledText = rgb(138, 132, 120),
	-- text
	Text = rgb(61, 75, 92),
	SubText = rgb(122, 138, 153),
	OnAccent = rgb(255, 255, 255),
	-- accents (face, lip)
	Accent = rgb(255, 158, 128),
	AccentLip = rgb(224, 122, 92),
	Sky = rgb(154, 212, 245),
	SkySoft = rgb(207, 239, 255), -- Ring Reel track
	SkyLip = rgb(107, 179, 222),
	Good = rgb(127, 211, 176),
	GoodLip = rgb(79, 175, 138),
	Gold = rgb(242, 181, 68),
	GoldLip = rgb(201, 139, 30),
	Gem = rgb(183, 156, 242),
	GemLip = rgb(140, 111, 214),
	Bad = rgb(242, 122, 122),
	BadLip = rgb(204, 84, 84),
	-- pastel tile tints (Main Menu hub icon circles, Figma hub_tile)
	TintPeach = rgb(255, 220, 207),
	TintLilac = rgb(229, 219, 250),
	TintSky = rgb(211, 236, 250),
	TintButter = rgb(251, 234, 184),
	TintMint = rgb(210, 240, 226),
	TintPink = rgb(251, 216, 226),
	TintSand = rgb(243, 227, 200),
	-- Main Menu phone header gradient (top -> bottom)
	HubSkyTop = rgb(169, 220, 247),
	HubSkyBottom = rgb(127, 195, 238),
	-- fonts
	Font = Font.new("rbxasset://fonts/families/FredokaOne.json", Enum.FontWeight.Regular),
	FontBody = Font.new("rbxasset://fonts/families/Nunito.json", Enum.FontWeight.Bold),
	FontBadge = Font.new("rbxasset://fonts/families/Nunito.json", Enum.FontWeight.ExtraBold), -- Figma badges/tags: Nunito ExtraBold 12
	-- shapes
	RadiusWindow = 24,
	RadiusCard = 18,
	RadiusButton = 16,
}
New.Theme = THEME

-- Lip colour for a face colour (falls back to 20% darker).
local LIPS = {
	[THEME.Accent] = THEME.AccentLip,
	[THEME.Sky] = THEME.SkyLip,
	[THEME.Good] = THEME.GoodLip,
	[THEME.Gold] = THEME.GoldLip,
	[THEME.Gem] = THEME.GemLip,
	[THEME.Bad] = THEME.BadLip,
	[THEME.Disabled] = THEME.DisabledLip,
}
local function lipFor(c: Color3): Color3
	return LIPS[c] or c:Lerp(Color3.new(0, 0, 0), 0.18)
end

local function luminance(c: Color3): number
	return 0.2126 * c.R + 0.7152 * c.G + 0.0722 * c.B
end

-- Figma px -> Roblox TextSize. Roblox draws glyphs smaller than Figma at the same number (measured
-- with TextService against Figma text widths, 2026-11-16). Every explicit TextSize in New.* and the
-- baked screens is a Figma size; New.FigmaSize converts it.
local FIGMA_TEXT_SCALE = {
	FredokaOne = 1.17,
	NunitoBold = 1.27,
	NunitoExtraBold = 1.36,
}
function New.FigmaSize(font: Font?, figmaPx: number): number
	local family = font and string.match(font.Family, "([%w]+)%.json$") or "FredokaOne"
	local key = family
	if family == "Nunito" then
		key = if font and font.Weight == Enum.FontWeight.ExtraBold then "NunitoExtraBold" else "NunitoBold"
	end
	return math.round(figmaPx * (FIGMA_TEXT_SCALE[key] or 1.17))
end

local TextService = game:GetService("TextService")

local function create(className: string, props: { [any]: any }?): Instance
	local inst = Instance.new(className)
	if inst:IsA("ScreenGui") then
		inst.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	end
	local children = nil
	local parent = nil
	if props then
		for k, v in props do
			if k == New.Children then
				children = v
			elseif k == "Parent" then
				parent = v
			elseif type(v) == "function" then
				(inst :: any)[k]:Connect(v)
			else
				(inst :: any)[k] = v
			end
		end
	end
	if children then
		for _, c in children do
			c.Parent = inst
		end
	end
	if parent then
		inst.Parent = parent
	end
	return inst
end

setmetatable(New, {
	__call = function(_, className: string, props: { [any]: any }?)
		return create(className, props)
	end,
})

function New.Corner(radius: number?): UICorner
	return create("UICorner", { CornerRadius = UDim.new(0, radius or THEME.RadiusCard) }) :: UICorner
end

function New.Pill(): UICorner
	return create("UICorner", { CornerRadius = UDim.new(0.5, 0) }) :: UICorner
end

function New.Stroke(color: Color3?, thickness: number?): UIStroke
	return create("UIStroke", {
		Color = color or THEME.Track,
		Thickness = thickness or 2,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
	}) :: UIStroke
end

-- Loading spinner: a ring with a fading tail that turns while something loads (Figma "Loading Spinner").
-- Put it on the object / menu that is waiting; Destroy() it when the data arrives.
function New.Spinner(props: { [any]: any }?): Frame
	local p = props or {}
	local color, thickness = p.Color or THEME.Accent, p.Thickness or 4
	p.Color, p.Thickness = nil, nil
	local base: { [any]: any } = {
		Name = "Spinner",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(36, 36),
		BackgroundTransparency = 1,
	}
	for k, v in p do
		base[k] = v
	end
	local f = create("Frame", base) :: Frame
	create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = f })
	local stroke = create("UIStroke", { Color = color, Thickness = thickness, Parent = f })
	local grad = create("UIGradient", {
		Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(0.65, 1), NumberSequenceKeypoint.new(1, 1) }),
		Parent = stroke,
	})
	game:GetService("TweenService"):Create(grad, TweenInfo.new(0.9, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, -1), { Rotation = 360 }):Play()
	return f
end

function New.Padding(px: number): UIPadding
	local u = UDim.new(0, px)
	return create("UIPadding", { PaddingTop = u, PaddingBottom = u, PaddingLeft = u, PaddingRight = u }) :: UIPadding
end

-- Lip band as a *multiplier* gradient: white (= no change) above the band, lip/face ratio inside it.
-- Use on a GuiObject whose BackgroundColor3 is the face colour. Because the top part is white, text
-- drawn on the object keeps its own colour (a UIGradient also tints text; a coloured gradient made
-- white button text invisible).
function New.ButtonLip(face: Color3, lip: Color3?, depth: number?): UIGradient
	local l = lip or lipFor(face)
	local function ratio(a: number, b: number): number
		return if a <= 0.001 then 0 else math.clamp(b / a, 0, 1)
	end
	local mult = Color3.new(ratio(face.R, l.R), ratio(face.G, l.G), ratio(face.B, l.B))
	local cut = 1 - (depth or 0.08)
	local white = Color3.new(1, 1, 1)
	return create("UIGradient", {
		Name = "Lip",
		Rotation = 90,
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, white),
			ColorSequenceKeypoint.new(cut - 0.001, white),
			ColorSequenceKeypoint.new(cut, mult),
			ColorSequenceKeypoint.new(1, mult),
		}),
	}) :: UIGradient
end

-- Soft lip at the bottom of a coloured surface whose BackgroundColor3 is white (bars without text).
function New.Lip(face: Color3, lip: Color3?, depth: number?): UIGradient
	local l = lip or lipFor(face)
	local cut = 1 - (depth or 0.12)
	return create("UIGradient", {
		Rotation = 90,
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, face),
			ColorSequenceKeypoint.new(cut - 0.001, face),
			ColorSequenceKeypoint.new(cut, l),
			ColorSequenceKeypoint.new(1, l),
		}),
	}) :: UIGradient
end

-- Cream card with soft edge.
-- Clip = true: build a CanvasGroup, which clips children to the ROUNDED corners
-- (ClipsDescendants only clips to the rectangle, so sand footers / fills poke out of the corners).
function New.Panel(props: { [any]: any }): Frame
	local base = {
		BackgroundColor3 = THEME.Panel,
		BorderSizePixel = 0,
	}
	local extra = { New.Corner(props.Radius or THEME.RadiusCard), New.Stroke(THEME.Track, 2) }
	local clip = props.Clip == true
	props.Radius, props.Clip = nil, nil
	if clip then
		props.ClipsDescendants = nil
	end
	for k, v in props do
		if k == New.Children then
			for _, c in v do
				table.insert(extra, c)
			end
		else
			base[k] = v
		end
	end
	base[New.Children] = extra
	return create(if clip then "CanvasGroup" else "Frame", base) :: Frame
end

function New.Text(props: { [any]: any }): TextLabel
	local base = {
		BackgroundTransparency = 1,
		TextColor3 = THEME.Text,
		FontFace = THEME.FontBody,
		TextScaled = true,
		[New.Children] = { create("UITextSizeConstraint", { MaxTextSize = props.MaxTextSize or props.TextSize or 22 }) },
	}
	props.MaxTextSize = nil
	if props.TextSize and props.TextScaled == nil then
		base.TextScaled = false -- explicit TextSize = Figma size (converted below)
		props.TextSize = New.FigmaSize(props.FontFace or base.FontFace, props.TextSize)
		base[New.Children][1].MaxTextSize = props.TextSize
	end
	for k, v in props do
		base[k] = v
	end
	return create("TextLabel", base) :: TextLabel
end

-- Width from the real font. AutomaticSize X can measure a label before its custom font has
-- loaded (fallback glyphs are narrower), so neighbours in a list overlap it ("Lv.100" over the
-- XP text). This measures with TextService (waits for the font) and keeps the width in sync
-- with Text / TextSize / FontFace. extra = px added (e.g. 2 x UIStroke thickness).
function New.FitTextWidth(label: TextLabel, extra: number?)
	label.AutomaticSize = Enum.AutomaticSize.None
	local token = 0
	local function fit()
		token += 1
		local mine = token
		task.spawn(function()
			local params = Instance.new("GetTextBoundsParams")
			params.Text = label.Text
			params.Font = label.FontFace
			params.Size = label.TextSize
			params.Width = 100000
			local ok, bounds = pcall(function()
				return TextService:GetTextBoundsAsync(params)
			end)
			if ok and mine == token then
				label.Size = UDim2.new(0, math.ceil(bounds.X) + (extra or 0), label.Size.Y.Scale, label.Size.Y.Offset)
			end
		end)
	end
	label:GetPropertyChangedSignal("Text"):Connect(fit)
	label:GetPropertyChangedSignal("TextSize"):Connect(fit)
	label:GetPropertyChangedSignal("FontFace"):Connect(fit)
	fit()
end

-- RichText highlight for numbers/prices inside body text (Figma: Nunito ExtraBold, cozy/gold-lip).
-- The label needs RichText = true.
function New.Highlight(text: string, color: Color3?): string
	return `<font color="#{(color or THEME.GoldLip):ToHex()}" weight="heavy">{text}</font>`
end

-- Display-font text (titles, numbers).
function New.Title(props: { [any]: any }): TextLabel
	props.FontFace = props.FontFace or THEME.Font
	return New.Text(props)
end

-- Button = Figma "Btn" component: rounded face + 5px darker bottom lip (Figma: bottom-only inside
-- stroke). Built as layers, not a gradient mask:
--   TextButton (transparent, owns Text/TextColor3/BackgroundColor3/Activated — the public API)
--     Lip   Frame  full size, lip colour, same corner
--     Face  Frame  height - LIP, face colour, same corner (its rounded bottom sits on the lip)
--       Label TextLabel  mirrors the button's Text/TextColor3/FontFace/TextSize
-- Code keeps using button.Text / button.BackgroundColor3 / New.SetButtonColor; New.HookButton syncs
-- the layers and adds hover + press (face drops onto the lip). Baked screens are hooked in Baked.Get.
local BUTTON_LIP = 5
New.ButtonLipPx = BUTTON_LIP

local function paintButton(button: GuiButton)
	local face = button.BackgroundColor3
	local faceFrame = button:FindFirstChild("Face") :: Frame?
	local lipFrame = button:FindFirstChild("Lip") :: Frame?
	if faceFrame then
		faceFrame.BackgroundColor3 = face
	end
	if lipFrame and lipFrame:IsA("Frame") then
		lipFrame.BackgroundColor3 = lipFor(face)
	end
end

local function syncLabel(button: TextButton)
	local face = button:FindFirstChild("Face")
	local label = face and face:FindFirstChild("Label") :: TextLabel?
	if not label then
		return
	end
	label.Text = button.Text
	label.TextColor3 = button.TextColor3
	label.FontFace = button.FontFace
	label.TextSize = button.TextSize
	label.TextScaled = button.TextScaled
	label.RichText = button.RichText
	label.TextWrapped = button.TextWrapped
	label.TextXAlignment = button.TextXAlignment
	-- Lip/Face must draw under anything else parented to the button (price icons, DEPTH labels...).
	-- Sibling mode: negative ZIndex keeps them at the back. Global mode: stack just above the button.
	local sg = button:FindFirstAncestorOfClass("ScreenGui")
	local global = sg ~= nil and sg.ZIndexBehavior == Enum.ZIndexBehavior.Global
	local z = button.ZIndex
	local lip = button:FindFirstChild("Lip") :: GuiObject?
	if lip and lip:IsA("GuiObject") then
		lip.ZIndex = if global then z else -2
	end
	(face :: GuiObject).ZIndex = if global then z + 1 else -1
	label.ZIndex = if global then z + 2 else 1
end

-- A UIStroke parented to the button itself would draw a square box around the transparent
-- TextButton; move it onto the rounded Face (border of the visible button).
local function adoptChild(button: Instance, child: Instance)
	if child:IsA("UIStroke") then
		local face = button:FindFirstChild("Face")
		if face then
			child.Parent = face
		end
	end
end

local hooked = setmetatable({}, { __mode = "k" })
function New.HookButton(button: TextButton)
	if hooked[button] or not button:FindFirstChild("Face") then
		return
	end
	hooked[button] = true
	button.Activated:Connect(function()
		if New.ClickHook then
			New.ClickHook() -- set by SoundController: ui_click for every button
		end
	end)
	local face = button:FindFirstChild("Face") :: Frame
	paintButton(button)
	syncLabel(button)
	for _, c in button:GetChildren() do
		adoptChild(button, c)
	end
	button.ChildAdded:Connect(function(c)
		task.defer(adoptChild, button, c)
	end)
	button.AncestryChanged:Connect(function()
		syncLabel(button)
	end)
	for _, prop in { "Text", "TextColor3", "FontFace", "TextSize", "TextScaled", "RichText", "ZIndex" } do
		button:GetPropertyChangedSignal(prop):Connect(function()
			syncLabel(button)
		end)
	end
	local hover, pressed = false, false
	local function refresh()
		local c = button.BackgroundColor3
		if c == THEME.Disabled then -- disabled: no hover, no press
			hover, pressed = false, false
		end
		face.BackgroundColor3 = if hover and not pressed then c:Lerp(Color3.new(1, 1, 1), 0.12) else c
		-- pressed = flat: the face sinks onto the lip's spot and the lip (bottom shadow) disappears
		face.Position = UDim2.fromOffset(0, if pressed then BUTTON_LIP else 0)
		local lip = button:FindFirstChild("Lip") :: Frame?
		if lip then
			lip.BackgroundColor3 = lipFor(c)
			lip.Visible = not pressed
		end
	end
	button:GetPropertyChangedSignal("BackgroundColor3"):Connect(refresh)
	-- a screen hidden mid-click never fires MouseLeave: reset hover/press when it is shown again
	local function reset()
		if hover or pressed then
			hover, pressed = false, false
			refresh()
		end
	end
	button:GetPropertyChangedSignal("Visible"):Connect(reset)
	local sg = button:FindFirstAncestorOfClass("ScreenGui")
	if sg then
		sg:GetPropertyChangedSignal("Enabled"):Connect(reset)
	end
	button.MouseEnter:Connect(function()
		hover = true
		refresh()
	end)
	button.MouseLeave:Connect(function()
		hover, pressed = false, false
		refresh()
	end)
	button.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			pressed = true
			refresh()
		end
	end)
	button.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			pressed = false
			refresh()
		end
	end)
end

-- Hook every layered button under root (baked ScreenGuis copied into PlayerGui).
function New.HookButtons(root: Instance)
	for _, d in root:GetDescendants() do
		if d:IsA("TextButton") and d:GetAttribute("CozyButton") then
			New.HookButton(d)
		end
	end
end

-- BackgroundColor3 picks the colour; light faces get dark text, coloured faces get white text.
function New.Button(props: { [any]: any }): TextButton
	local faceColor = props.BackgroundColor3 or THEME.PanelLight
	local textSize = props.TextSize
	local scaled = true
	if textSize and props.TextScaled == nil then
		scaled = false -- explicit TextSize = Figma size (converted)
		textSize = New.FigmaSize(props.FontFace or THEME.Font, textSize)
	end
	local maxText = props.MaxTextSize or textSize or 20
	local cornerRadius = props.Radius or props.CornerRadius or THEME.RadiusButton
	props.Radius = nil
	props.CornerRadius = nil
	local radius = New.Corner(cornerRadius)
	local label = create("TextLabel", {
		Name = "Label",
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		Text = "",
		[New.Children] = {
			create("UITextSizeConstraint", { MaxTextSize = maxText }),
			create("UIPadding", {
				PaddingTop = UDim.new(0, 2),
				PaddingBottom = UDim.new(0, 2),
				PaddingLeft = UDim.new(0, 6),
				PaddingRight = UDim.new(0, 6),
			}),
		},
	})
	local base = {
		BackgroundColor3 = faceColor,
		BackgroundTransparency = 1,
		TextTransparency = 1, -- drawn by Face.Label
		TextColor3 = luminance(faceColor) > 0.8 and THEME.Text or THEME.OnAccent,
		FontFace = THEME.Font,
		TextScaled = scaled,
		TextSize = textSize or 20,
		AutoButtonColor = false,
		BorderSizePixel = 0,
		[New.Children] = {
			create("Frame", {
				Name = "Lip",
				Size = UDim2.fromScale(1, 1),
				BackgroundColor3 = lipFor(faceColor),
				BorderSizePixel = 0,
				[New.Children] = { radius },
			}),
			create("Frame", {
				Name = "Face",
				Size = UDim2.new(1, 0, 1, -BUTTON_LIP),
				BackgroundColor3 = faceColor,
				BorderSizePixel = 0,
				[New.Children] = { New.Corner(cornerRadius), label },
			}),
		},
	}
	props.MaxTextSize = nil
	props.BackgroundColor3 = nil
	props.TextSize = nil
	for k, v in props do
		base[k] = v
	end
	local button = create("TextButton", base) :: TextButton
	button:SetAttribute("CozyButton", true)
	syncLabel(button)
	New.HookButton(button)
	return button
end

-- Row of small pill badges instead of "a | b | c" text.
-- items: { { Text = "Rare", Color = Color3?, TextColor = Color3? } }
function New.BadgeRow(items: { any }, props: { [any]: any }?): Frame
	local base = {
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		[New.Children] = {
			create("UIListLayout", {
				FillDirection = Enum.FillDirection.Horizontal,
				Wraps = true,
				Padding = UDim.new(0, 6),
				HorizontalAlignment = Enum.HorizontalAlignment.Center,
				SortOrder = Enum.SortOrder.LayoutOrder,
			}),
		},
	}
	if props then
		for k, v in props do
			base[k] = v
		end
	end
	local row = create("Frame", base) :: Frame
	for i, it in items do
		create("TextLabel", {
			Size = UDim2.fromOffset(0, 22),
			AutomaticSize = Enum.AutomaticSize.X,
			BackgroundColor3 = it.Color or THEME.PanelLight,
			Text = it.Text,
			TextColor3 = it.TextColor or (if it.Color then THEME.OnAccent else THEME.Text),
			FontFace = THEME.FontBadge,
			TextSize = New.FigmaSize(THEME.FontBadge, 12),
			LayoutOrder = i,
			ZIndex = props and props.ZIndex or 1,
			Parent = row,
			[New.Children] = { New.Pill(), create("UIPadding", { PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10) }) },
		})
	end
	return row
end

-- Image slot for an asset key from Shared.Config.UIAssets ("fish/BubbleCarp" art or "icon_lock" global).
-- Stores the key in the "ImageKey" attribute so UI baked into StarterGui picks up ids uploaded later
-- (New.ApplyImages runs at runtime). Until the asset is uploaded a rounded "Fallback" Frame shows instead.
-- props: Key (required), Fallback (Color3, default PanelLight), FallbackText (string?), Tint (Color3 for white globals)
function New.Image(props: { [any]: any }): ImageLabel
	local key = props.Key
	local fallbackColor = props.Fallback or THEME.PanelLight
	local fallbackText = props.FallbackText
	local tint = props.Tint
	props.Key, props.Fallback, props.FallbackText, props.Tint = nil, nil, nil, nil
	local base = {
		BackgroundTransparency = 1,
		ScaleType = Enum.ScaleType.Fit,
		ImageColor3 = tint or Color3.new(1, 1, 1),
	}
	for k, v in props do
		base[k] = v
	end
	local img = create("ImageLabel", base) :: ImageLabel
	img:SetAttribute("ImageKey", key)
	local fb = create("Frame", {
		Name = "Fallback",
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = fallbackColor,
		BorderSizePixel = 0,
		ZIndex = img.ZIndex,
		Parent = img,
		[New.Children] = { New.Corner(THEME.RadiusButton) },
	})
	create("TextLabel", {
		Name = "Label",
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Text = fallbackText or "",
		TextColor3 = THEME.OnAccent,
		FontFace = THEME.Font,
		TextScaled = true,
		ZIndex = img.ZIndex,
		Parent = fb,
		[New.Children] = { New.Padding(6) },
	})
	New.ApplyImage(img)
	return img
end

function New.RobuxButton(props: { [any]: any }, price: number): TextButton
	props.Text = ""
	local button = New.Button(props)
	local content = create("Frame", {
		Name = "Content",
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Parent = button.Face,
		[New.Children] = {
			create("UIListLayout", {
				FillDirection = Enum.FillDirection.Horizontal,
				HorizontalAlignment = Enum.HorizontalAlignment.Center,
				VerticalAlignment = Enum.VerticalAlignment.Center,
				Padding = UDim.new(0, 6),
				SortOrder = Enum.SortOrder.LayoutOrder,
			}),
		},
	})
	New.Image({
		Name = "RobuxIcon",
		Key = "icon_robux",
		Tint = button.TextColor3,
		Size = UDim2.fromOffset(22, 22),
		LayoutOrder = 1,
		Parent = content,
	})
	create("TextLabel", {
		Name = "Price",
		Size = UDim2.fromOffset(0, 22),
		AutomaticSize = Enum.AutomaticSize.X,
		BackgroundTransparency = 1,
		Text = tostring(price),
		TextColor3 = button.TextColor3,
		FontFace = THEME.Font,
		TextSize = New.FigmaSize(THEME.Font, 18),
		LayoutOrder = 2,
		Parent = content,
	})
	return button
end

-- Skeleton loading (runtime only): while an Art image is still downloading (IsLoaded = false) a
-- "Skeleton" child shows a pulsing placeholder + loading spinner in its place: fish -> Mystery Fish silhouette,
-- auras -> Unknown Aura, anything else -> a soft rounded block. Hidden as soon as the real art loads.
-- Add a placeholder for a new art folder in SKELETON_ART.
local SKELETON_ART = {
	fish = "fish/MysteryFish",
	auras = "auras/UnknownAura",
}
type SkeletonRequest = { Image: string, Tween: Tween? }
local skeletonRequests: { [ImageLabel]: SkeletonRequest } = setmetatable({}, { __mode = "k" }) :: any
local skeletonHooks: { [Instance]: ImageLabel } = setmetatable({}, { __mode = "kv" }) :: any
local skeletonPreloaded = false
-- Cached images can briefly report IsLoaded = false when rebound to another slot.
local loadedImages: { [string]: boolean } = {}
local SKELETON_DELAY = 0.25
local SKELETON_TIMEOUT = 30

local function clearSkeleton(skeleton: ImageLabel)
	local request = skeletonRequests[skeleton]
	if request and request.Tween then
		request.Tween:Cancel()
	end
	skeletonRequests[skeleton] = nil
	skeleton.Visible = false
	local spin = skeleton:FindFirstChild("Spinner")
	if spin then
		spin:Destroy()
	end
end

local function skeletonRefresh(img: ImageLabel | ImageButton, skeleton: ImageLabel)
	local image = img.Image
	if image ~= "" and img.IsLoaded then
		loadedImages[image] = true
	end
	if image == "" or loadedImages[image] then
		clearSkeleton(skeleton)
		return
	end
	local previous = skeletonRequests[skeleton]
	if previous and previous.Image == image then
		return
	end

	clearSkeleton(skeleton)
	local request: SkeletonRequest = { Image = image }
	skeletonRequests[skeleton] = request
	task.delay(SKELETON_DELAY, function()
		local function waiting(): boolean
			return skeletonRequests[skeleton] == request
				and skeleton.Parent == (img :: Instance)
				and img.Image == image
				and not img.IsLoaded
				and not loadedImages[image]
		end

		if waiting() then
			local hasArt = skeleton.Image ~= ""
			skeleton.ImageTransparency = 0.2
			skeleton.BackgroundTransparency = if hasArt then 1 else 0.2
			skeleton.Visible = true
			if not skeleton:FindFirstChild("Spinner") then -- only while visible: no tweens on hidden slots
				local spin = New.Spinner({ Size = UDim2.fromScale(0.4, 0.4), Thickness = 3, Color = THEME.SubText, ZIndex = skeleton.ZIndex + 1, Parent = skeleton })
				create("UIAspectRatioConstraint", { Parent = spin })
			end
			local tween = game:GetService("TweenService"):Create(
				skeleton,
				TweenInfo.new(0.7, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
				{ [if hasArt then "ImageTransparency" else "BackgroundTransparency"] = 0.75 }
			)
			request.Tween = tween
			tween:Play()
			-- IsLoaded does not always notify while assets stream, so poll until this request ends.
			local deadline = os.clock() + SKELETON_TIMEOUT
			while waiting() and os.clock() < deadline do
				task.wait(0.1)
			end
		end

		if skeletonRequests[skeleton] == request then
			if img.Image == image and img.IsLoaded then
				loadedImages[image] = true
			end
			clearSkeleton(skeleton)
		end
	end)
end

local function skeletonFor(img: ImageLabel | ImageButton, key: string, UIAssets: any)
	local folder = string.match(key, "^([^/]+)/")
	local placeholderKey = folder and SKELETON_ART[folder]
	local sk = img:FindFirstChild("Skeleton") :: ImageLabel?
	if not game:GetService("RunService"):IsRunning() or img:GetAttribute("ShadowOf") or not folder or placeholderKey == key then
		if sk then
			clearSkeleton(sk)
		end
		return
	end

	local placeholderId = placeholderKey and UIAssets.Art[placeholderKey]
	if not UIAssets.IsUploaded(placeholderId) then
		placeholderId = nil
	end
	if not skeletonPreloaded then
		skeletonPreloaded = true
		local ids = {}
		for _, k in SKELETON_ART do
			if UIAssets.IsUploaded(UIAssets.Art[k]) then
				table.insert(ids, UIAssets.Art[k])
			end
		end
		task.spawn(function()
			pcall(function()
				game:GetService("ContentProvider"):PreloadAsync(ids)
			end)
		end)
	end

	if not sk then
		sk = create("ImageLabel", {
			Name = "Skeleton",
			Size = UDim2.fromScale(1, 1),
			BorderSizePixel = 0,
			ZIndex = img.ZIndex,
			Visible = false,
			Parent = img,
		}) :: ImageLabel
		create("UICorner", { CornerRadius = UDim.new(0, THEME.RadiusButton), Parent = sk })
	end
	local skeleton = sk :: ImageLabel
	if skeletonHooks[img] ~= skeleton then
		skeletonHooks[img] = skeleton
		-- Clones can have a Skeleton child, but its connections don't carry over.
		img:GetPropertyChangedSignal("IsLoaded"):Connect(function()
			if img.IsLoaded and img.Image ~= "" then
				loadedImages[img.Image] = true
				clearSkeleton(skeleton)
			end
		end)
		img:GetPropertyChangedSignal("Image"):Connect(function()
			local request = skeletonRequests[skeleton]
			if request and request.Image ~= img.Image then
				clearSkeleton(skeleton)
			end
		end)
	end

	skeleton.Image = placeholderId or ""
	skeleton.ScaleType = img.ScaleType
	skeleton.BackgroundColor3 = THEME.PanelLight
	skeletonRefresh(img, skeleton)
end

-- Resolve one image slot's ImageKey -> uploaded id (or show its Fallback).
function New.ApplyImage(img: ImageLabel | ImageButton)
	local key = img:GetAttribute("ImageKey")
	if type(key) ~= "string" then
		return
	end
	-- FindFirstChild (not WaitForChild): also runs in Studio edit mode while baking, where Shared may be stale
	local ok, UIAssets = pcall(function()
		-- Studio tools (tools/ui/*.mjs) ship a fresh UIAssets next to New: edit-mode require() caches modules
		local m = script.Parent:FindFirstChild("UIAssets")
		if not m then
			local shared = game:GetService("ReplicatedStorage"):FindFirstChild("Shared")
			local config = shared and shared:FindFirstChild("Config")
			m = config and config:FindFirstChild("UIAssets")
		end
		return if m then require(m) :: any else error("UIAssets missing")
	end)
	local id = if ok then (UIAssets.Global[key] or UIAssets.Art[key]) else nil
	local uploaded = ok and UIAssets.IsUploaded(id)
	local target: any = img
	local image = if uploaded then id else ""
	if target.Image ~= image then
		target.Image = image
	end
	local fb = img:FindFirstChild("Fallback")
	if fb and fb:IsA("GuiObject") then
		fb.Visible = not uploaded
	end
	if uploaded then
		skeletonFor(img, key, UIAssets)
	else
		local sk = img:FindFirstChild("Skeleton")
		if sk and sk:IsA("ImageLabel") then
			clearSkeleton(sk)
		end
	end
	-- 9-slice shadow (New.Shadow): once uploaded it draws the panel itself, so hide the plain background
	if img:GetAttribute("ShadowOf") then
		target.Visible = uploaded
		local panel = img.Parent
		if panel and panel:IsA("GuiObject") then
			panel.BackgroundTransparency = if uploaded then 1 else (img:GetAttribute("PanelTransparency") or 0)
		end
	end
end

-- 9-slice tiles exported from Figma section "Roblox 9-slice (export)" (docs/figma/nine_slice.py):
-- white rounded shape + exact Figma drop shadow. insets = shadow margin left, top, right, bottom (px).
local SLICES = {
	slice_shadow_window = { Size = 156, Insets = { 18, 12, 18, 24 }, Radius = 24 },
	slice_shadow_modal = { Size = 156, Insets = { 18, 12, 18, 24 }, Radius = 36 },
	slice_shadow_glass = { Size = 180, Insets = { 30, 20, 30, 40 }, Radius = 48 },
}

-- Figma drop shadow under a panel (UICorner can't draw shadows). Adds a 9-slice ImageLabel "Shadow"
-- behind the panel's children, tinted with the panel colour. Until the PNG is uploaded the panel
-- keeps its normal background and no shadow shows.
function New.Shadow(panel: GuiObject, key: string): ImageLabel
	local s = SLICES[key]
	local l, t, r, b = s.Insets[1], s.Insets[2], s.Insets[3], s.Insets[4]
	local img = create("ImageLabel", {
		Name = "Shadow",
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(-l, -t),
		Size = UDim2.new(1, l + r, 1, t + b),
		ScaleType = Enum.ScaleType.Slice,
		SliceCenter = Rect.new(l + s.Radius, t + s.Radius, s.Size - r - s.Radius, s.Size - b - s.Radius),
		ImageColor3 = panel.BackgroundColor3,
		ImageTransparency = panel.BackgroundTransparency,
		ZIndex = 0,
		Visible = false,
		Parent = panel,
	}) :: ImageLabel
	img:SetAttribute("ImageKey", key)
	img:SetAttribute("ShadowOf", panel.Name)
	img:SetAttribute("PanelTransparency", panel.BackgroundTransparency)
	New.ApplyImage(img)
	return img
end

-- Diagonal stripe (hatch) overlay for empty / disabled areas and the empty track behind a progress fill.
-- assets/ui-global/pattern_stripes(_fine).png, seamless 64px tiles made by tools/art/make_patterns.py.
-- Covers the parent, rounds with the parent's UICorner, sits above the parent background but below
-- its other children (ZIndex 0; needs ZIndexBehavior = Sibling on the ScreenGui, which all our screens use).
-- Draws nothing until the PNG is uploaded.
--   New.Stripes(emptySlot)                                    -- default: Track colour, 10% transparent
--   New.Stripes(progressTrack, { Fine = true, Color = New.Theme.SubText, Transparency = 0.9 }) -- 10% opacity
--     -> stripes on the track (the empty part); the solid Fill frame (child of the track) covers them
function New.Stripes(parent: GuiObject, opts: { [string]: any }?): ImageLabel
	local o = opts or {}
	local key = if o.Fine then "pattern_stripes_fine" else "pattern_stripes"
	local img = create("ImageLabel", {
		Name = "Stripes",
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		ScaleType = Enum.ScaleType.Tile,
		TileSize = UDim2.fromOffset(64, 64),
		ImageColor3 = o.Color or THEME.Track,
		ImageTransparency = o.Transparency or 0.1,
		ZIndex = o.ZIndex or 0,
		Parent = parent,
	}) :: ImageLabel
	local corner = parent:FindFirstChildOfClass("UICorner")
	if corner then
		create("UICorner", { CornerRadius = corner.CornerRadius, Parent = img })
	end
	img:SetAttribute("ImageKey", key)
	New.ApplyImage(img)
	return img
end

-- Change which asset an image slot shows (e.g. a row reused for another fish).
function New.SetImageKey(img: ImageLabel | ImageButton, key: string, fallbackColor: Color3?, fallbackText: string?)
	img:SetAttribute("ImageKey", key)
	local fb = img:FindFirstChild("Fallback")
	if fb and fb:IsA("GuiObject") then
		if fallbackColor then
			fb.BackgroundColor3 = fallbackColor
		end
		local label = fb:FindFirstChild("Label")
		if label and label:IsA("TextLabel") and fallbackText then
			label.Text = fallbackText
		end
	end
	New.ApplyImage(img)
end

function New.ApplyImages(root: Instance)
	for _, d in root:GetDescendants() do
		if (d:IsA("ImageLabel") or d:IsA("ImageButton")) and d:GetAttribute("ImageKey") then
			New.ApplyImage(d)
		end
	end
end

-- Fixed badge slots for baked UI: a horizontal row with `count` hidden pills (Badge1..BadgeN).
-- Fill at runtime with New.SetBadges(row, { { Text = "Rare", Color = c }, ... }); extra slots stay hidden.
function New.BadgeSlots(count: number, props: { [any]: any }): Frame
	local base = {
		Name = "Badges",
		Size = UDim2.new(1, 0, 0, 21),
		BackgroundTransparency = 1,
		[New.Children] = {
			create("UIListLayout", {
				FillDirection = Enum.FillDirection.Horizontal,
				Padding = UDim.new(0, 6),
				VerticalAlignment = Enum.VerticalAlignment.Center,
				SortOrder = Enum.SortOrder.LayoutOrder,
			}),
		},
	}
	for k, v in props do
		base[k] = v
	end
	local row = create("Frame", base) :: Frame
	for i = 1, count do
		create("TextLabel", {
			Name = "Badge" .. i,
			Size = UDim2.fromOffset(0, 21),
			AutomaticSize = Enum.AutomaticSize.X,
			BackgroundColor3 = THEME.PanelLight,
			Text = "Badge",
			TextColor3 = THEME.Text,
			FontFace = THEME.FontBadge,
			TextSize = New.FigmaSize(THEME.FontBadge, 12),
			LayoutOrder = i,
			Visible = false,
			Parent = row,
			[New.Children] = { New.Pill(), create("UIPadding", { PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10) }) },
		})
	end
	return row
end

function New.SetBadges(row: Instance, items: { any })
	local i = 1
	while true do
		local b = row:FindFirstChild("Badge" .. i)
		if not b then
			break
		end
		local it = items[i]
		b.Visible = it ~= nil
		if it then
			b.Text = it.Text
			b.BackgroundColor3 = it.Color or THEME.PanelLight
			b.TextColor3 = it.TextColor or (if it.Color then THEME.OnAccent else THEME.Text)
		end
		i += 1
	end
end

-- Pager "< 1 / N >" for list windows (Shop 4 rows, Auras 3 rows, Fishdex 6 cards per page).
-- Children: Prev, Next (TextButtons) and Label.
function New.Pager(props: { [any]: any }): Frame
	local base = {
		Name = "Pager",
		Size = UDim2.fromOffset(197, 57), -- Figma Pager: 70px buttons, page label 18 SubText
		BackgroundTransparency = 1,
	}
	for k, v in props do
		base[k] = v
	end
	local f = create("Frame", base) :: Frame
	New.Button({ Name = "Prev", Size = UDim2.fromOffset(70, 57), Text = "<", MaxTextSize = 22, Parent = f })
	New.Title({
		Name = "Label",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(52, 22),
		Text = "1 / 1",
		TextColor3 = THEME.SubText,
		MaxTextSize = 18,
		Parent = f,
	})
	New.Button({ Name = "Next", AnchorPoint = Vector2.new(1, 0), Position = UDim2.fromScale(1, 0), Size = UDim2.fromOffset(70, 57), Text = ">", MaxTextSize = 22, Parent = f })
	return f
end

-- Fixed-size window (Shop/Auras/Fishdex, Modal, Main Menu hub): same rule as every other popup.
-- Kept as a name for the baked-screen controllers; see New.FitToScreen below.
function New.FitWindow(window: GuiObject, _designSize: Vector2?)
	local old = window:FindFirstChildOfClass("UIScale")
	if old then
		old:Destroy() -- a UIScale baked/edited in Studio would fight FitToScreen's
	end
	New.FitToScreen(window)
end

-- Pop transition (2026-11-20): everything that appears scales 0.7 -> 1 with one small overshoot (Back Out 0.25 s).
-- Windows/popups using FitToScreen pop by themselves whenever their ScreenGui is enabled or they turn visible;
-- anything else calls New.Pop(obj) when it shows (Gacha page, Daily Login, Item Card, toasts, ...).
local POP_INFO = TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out) -- one quick overshoot, no wobble (Elastic felt sticky)
local POP_FROM = 0.7
local popFns: { [Instance]: () -> () } = setmetatable({}, { __mode = "k" }) :: any

function New.Pop(obj: GuiObject)
	local own = popFns[obj]
	if own then
		own()
		return
	end
	if not game:GetService("RunService"):IsRunning() then
		return
	end
	-- reuse its own UIScale (e.g. the Gacha canvas "Scale") and animate up to its current value
	local sc = obj:FindFirstChildOfClass("UIScale") or create("UIScale", { Name = "PopScale", Parent = obj }) :: UIScale
	local s = sc :: UIScale
	local goal = s:GetAttribute("PopGoal") or s.Scale -- a pop already running: keep its goal
	s:SetAttribute("PopGoal", goal)
	s.Scale = goal * POP_FROM
	local tw = game:GetService("TweenService"):Create(s, POP_INFO, { Scale = goal })
	tw.Completed:Connect(function()
		s:SetAttribute("PopGoal", nil)
	end)
	tw:Play()
end

-- Shrink a popup/panel uniformly so it always fits on screen (landscape phones are ~360px tall).
-- Never enlarges past its designed size. Works with AutomaticSize frames. Also plays New.Pop when shown.
function New.FitToScreen(obj: GuiObject, margin: number?): UIScale
	local pad = margin or 12
	local scale = create("UIScale", { Parent = obj }) :: UIScale
	local busy = false
	local popping = false
	local target = 1
	local popToken: any = nil
	-- the scale that makes the window fit the screen, or nil while it has no layout yet (first open)
	local function measure(): number?
		local screen = obj:FindFirstAncestorOfClass("ScreenGui")
		if not screen then
			return nil
		end
		local s = scale.Scale
		local w, h = obj.AbsoluteSize.X / s, obj.AbsoluteSize.Y / s
		local avail = screen.AbsoluteSize
		if w <= 0 or h <= 0 or avail.X <= 0 then
			return nil
		end
		return math.clamp(math.min((avail.X - pad * 2) / w, (avail.Y - pad * 2) / h), 0.4, 1)
	end
	local function fit()
		if busy or popping then
			return
		end
		local t = measure()
		if not t then
			return
		end
		busy = true
		target = t
		scale.Scale = target
		busy = false
	end
	local popTween: Tween? = nil
	local function pop()
		if not game:GetService("RunService"):IsRunning() then
			return -- no animation in Studio edit mode / while baking
		end
		if popTween then
			popTween:Cancel()
			popTween = nil
		end
		-- A window that opens for the first time (phones especially) has no layout yet: hide it at a tiny scale,
		-- wait until it can be measured, then pop up to the right size. Never show it at full size first.
		local token = {}
		popToken = token
		popping = true
		scale.Scale = 0.05
		task.spawn(function()
			local t = measure()
			local frames = 0
			while not t and frames < 15 do
				game:GetService("RunService").RenderStepped:Wait()
				if popToken ~= token then
					return
				end
				frames += 1
				t = measure()
			end
			if popToken ~= token then
				return
			end
			target = t or target
			scale.Scale = target * POP_FROM
			local tw = game:GetService("TweenService"):Create(scale, POP_INFO, { Scale = target })
			popTween = tw
			tw.Completed:Connect(function(state)
				if popTween == tw and state == Enum.PlaybackState.Completed then
					popping = false
					popTween = nil
					fit() -- content that grew while popping (auto-height windows)
				end
			end)
			tw:Play()
		end)
	end
	popFns[obj] = pop
	obj:GetPropertyChangedSignal("Visible"):Connect(function()
		local screen = obj:FindFirstAncestorOfClass("ScreenGui")
		if obj.Visible and (not screen or screen.Enabled) then
			pop()
		end
	end)
	local resizeConnection: RBXScriptConnection?
	local enabledConnection: RBXScriptConnection?
	local function watchScreen()
		if resizeConnection then
			resizeConnection:Disconnect()
		end
		if enabledConnection then
			enabledConnection:Disconnect()
		end
		local screen = obj:FindFirstAncestorOfClass("ScreenGui")
		resizeConnection = if screen then screen:GetPropertyChangedSignal("AbsoluteSize"):Connect(fit) else nil
		enabledConnection = if screen
			then screen:GetPropertyChangedSignal("Enabled"):Connect(function()
				if (screen :: ScreenGui).Enabled and obj.Visible then
					pop()
				end
			end)
			else nil
		task.defer(fit)
	end
	obj:GetPropertyChangedSignal("AbsoluteSize"):Connect(fit)
	obj.AncestryChanged:Connect(watchScreen)
	watchScreen()
	return scale
end

function New.SetButtonColor(button: GuiButton, face: Color3, textColor: Color3?)
	button.BackgroundColor3 = face
	if button:FindFirstChild("Face") then
		paintButton(button) -- also correct when not hooked (edit-time preview)
	else
		local g = button:FindFirstChildOfClass("UIGradient")
		if g then
			g:Destroy()
		end
		New.ButtonLip(face).Parent = button
	end
	if button:IsA("TextButton") then
		button.TextColor3 = textColor or (luminance(face) > 0.8 and THEME.Text or THEME.OnAccent)
		syncLabel(button)
	end
end

function New.FormatCurrencyChip(c: any, padRight: number?)
	if not c or not c:IsA("GuiObject") then
		return
	end
	c.AutomaticSize = Enum.AutomaticSize.X
	c.Size = UDim2.fromOffset(0, if c.Size.Y.Offset > 0 then c.Size.Y.Offset else 40)

	local pad = c:FindFirstChildOfClass("UIPadding")
	if not pad then
		pad = Instance.new("UIPadding")
		pad.Parent = c
	end
	pad.PaddingLeft = UDim.new(0, 12)
	pad.PaddingRight = UDim.new(0, padRight or 20)
	pad.PaddingTop = UDim.new(0, 6)
	pad.PaddingBottom = UDim.new(0, 6)

	local list = c:FindFirstChildOfClass("UIListLayout")
	if not list then
		list = Instance.new("UIListLayout")
		list.Parent = c
	end
	list.FillDirection = Enum.FillDirection.Horizontal
	list.VerticalAlignment = Enum.VerticalAlignment.Center
	list.SortOrder = Enum.SortOrder.LayoutOrder
	list.Padding = UDim.new(0, 8)

	local icon = c:FindFirstChild("Icon")
	if icon and icon:IsA("GuiObject") then
		icon.LayoutOrder = 1
		icon.Position = UDim2.fromOffset(0, 0)
	end

	local val = c:FindFirstChild("Value")
	if val and val:IsA("TextLabel") then
		val.LayoutOrder = 2
		val.AutomaticSize = Enum.AutomaticSize.X
		val.Size = UDim2.fromOffset(0, 22)
		val.Position = UDim2.fromOffset(0, 0)
		val.TextXAlignment = Enum.TextXAlignment.Left
	end
end

return New
