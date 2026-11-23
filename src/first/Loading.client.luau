--!nonstrict
-- Loading screen (ReplicatedFirst): covers the game until images, sounds, music and the player's save are ready.
-- Simple first version (title + progress bar + current step + tip); the real design comes later (Figma first).
-- Steps are conditions: images are preloaded here, the rest are flags set by the client:
--   player attribute SoundsReady / MusicReady  (Controllers/SoundController, after its PreloadAsync batches)
--   player attribute DataReady                 (Main.client: first profile arrived)
--   player attribute ClientReady               (Main.client: every controller Init finished)
-- Never blocks forever: after MAX_WAIT seconds the game opens anyway.
-- Colours / fonts mirror UI/New.Theme (this script runs before the client modules exist, so it cannot require them).

local ContentProvider = game:GetService("ContentProvider")
local Players = game:GetService("Players")
local ReplicatedFirst = game:GetService("ReplicatedFirst")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local MAX_WAIT = 40

local SKY_TOP = Color3.fromRGB(169, 220, 247)
local SKY_BOTTOM = Color3.fromRGB(127, 195, 238)
local SKY_LIP = Color3.fromRGB(107, 179, 222)
local CREAM = Color3.fromRGB(255, 248, 236)
local ACCENT = Color3.fromRGB(255, 158, 128)
local TEXT = Color3.fromRGB(61, 75, 92)
local FONT = Font.new("rbxasset://fonts/families/FredokaOne.json", Enum.FontWeight.Regular)
local FONT_BODY = Font.new("rbxasset://fonts/families/Nunito.json", Enum.FontWeight.Bold)

local TIPS = {
	"Press Q to dash forward with a flip.",
	"Rare fish bite more often with a better bait.",
	"Sell your catch to Old Marlin for coins.",
	"Auras boost your stats. Roll one at the Altar.",
	"Trade with other players using a Trade License.",
}

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- UI -------------------------------------------------------------------------------------------------

local function make(className: string, props: { [string]: any }, children: { Instance }?): any
	local inst = (Instance :: any).new(className)
	for k, v in props do
		inst[k] = v
	end
	if children then
		for _, c in children do
			c.Parent = inst
		end
	end
	return inst
end

local gui = make("ScreenGui", {
	Name = "LoadingScreen",
	DisplayOrder = 1000,
	IgnoreGuiInset = true,
	ResetOnSpawn = false,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
})
local root = make("CanvasGroup", { Name = "Root", Size = UDim2.fromScale(1, 1), BackgroundColor3 = SKY_TOP, BorderSizePixel = 0, Parent = gui }, {
	make("UIGradient", { Rotation = 90, Color = ColorSequence.new(SKY_TOP, SKY_BOTTOM) }),
})
local center = make("Frame", { Name = "Center", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.48), Size = UDim2.fromOffset(460, 220), BackgroundTransparency = 1, Parent = root })
make("UIScale", { Parent = center })
make("TextLabel", {
	Name = "Title", Size = UDim2.new(1, 0, 0, 80), BackgroundTransparency = 1, Text = "Aura Fishing", FontFace = FONT, TextSize = 64,
	TextColor3 = Color3.new(1, 1, 1), Parent = center,
}, { make("UIStroke", { Color = SKY_LIP, Thickness = 4 }) })
local status = make("TextLabel", {
	Name = "Status", Position = UDim2.fromOffset(0, 104), Size = UDim2.new(1, -70, 0, 26), BackgroundTransparency = 1, Text = "Starting...",
	FontFace = FONT_BODY, TextSize = 20, TextColor3 = TEXT, TextXAlignment = Enum.TextXAlignment.Left, Parent = center,
})
local percent = make("TextLabel", {
	Name = "Percent", AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, 0, 0, 104), Size = UDim2.fromOffset(70, 26), BackgroundTransparency = 1,
	Text = "0%", FontFace = FONT, TextSize = 20, TextColor3 = TEXT, TextXAlignment = Enum.TextXAlignment.Right, Parent = center,
})
local track = make("Frame", { Name = "Track", Position = UDim2.fromOffset(0, 140), Size = UDim2.new(1, 0, 0, 28), BackgroundColor3 = CREAM, BorderSizePixel = 0, Parent = center }, {
	make("UICorner", { CornerRadius = UDim.new(1, 0) }),
	make("UIStroke", { Color = SKY_LIP, Thickness = 3 }),
})
local fill = make("Frame", { Name = "Fill", Size = UDim2.new(0, 0, 1, 0), BackgroundColor3 = ACCENT, BorderSizePixel = 0, Parent = track }, {
	make("UICorner", { CornerRadius = UDim.new(1, 0) }),
})
make("TextLabel", {
	Name = "Tip", AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -36), Size = UDim2.new(1, -40, 0, 24), BackgroundTransparency = 1,
	Text = TIPS[math.random(1, #TIPS)], FontFace = FONT_BODY, TextSize = 18, TextColor3 = Color3.new(1, 1, 1), Parent = root,
}, { make("UIStroke", { Color = SKY_LIP, Thickness = 2 }) })
gui.Parent = playerGui
ReplicatedFirst:RemoveDefaultLoadingScreen()

-- phones: shrink the centre block on narrow screens
local scale = center:FindFirstChildOfClass("UIScale")
local function fit()
	local size = gui.AbsoluteSize
	scale.Scale = math.clamp(math.min(size.X / 520, size.Y / 360), 0.5, 1.2)
end
gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(fit)
fit()

-- Steps ----------------------------------------------------------------------------------------------

local imagesDone = false
task.spawn(function()
	local ok = pcall(function()
		local shared = ReplicatedStorage:WaitForChild("Shared", 20)
		local assets = shared and shared:WaitForChild("Config", 20) and shared.Config:WaitForChild("UIAssets", 20)
		if not assets then
			return
		end
		local list = {}
		local function collect(t: any)
			for _, v in t do
				if type(v) == "table" then
					collect(v)
				elseif type(v) == "string" and v ~= "rbxassetid://0" and string.sub(v, 1, 13) == "rbxassetid://" then
					table.insert(list, v)
				end
			end
		end
		collect(require(assets))
		ContentProvider:PreloadAsync(list)
	end)
	imagesDone = true
	if not ok then
		warn("[Loading] image preload failed, continuing")
	end
end)

local function attribute(name: string): () -> boolean
	return function()
		return player:GetAttribute(name) == true
	end
end

local STEPS = {
	{ Label = "Connecting", Weight = 1, Done = function() return game:IsLoaded() end },
	{ Label = "Loading images", Weight = 4, Done = function() return imagesDone end },
	{ Label = "Loading sounds", Weight = 2, Done = attribute("SoundsReady") },
	{ Label = "Loading music", Weight = 3, Done = attribute("MusicReady") },
	{ Label = "Loading your save", Weight = 2, Done = attribute("DataReady") },
	{ Label = "Setting up the lake", Weight = 1, Done = attribute("ClientReady") },
}
local total = 0
for _, s in STEPS do
	total += s.Weight
end

local shown = 0
local started = os.clock()
local finishing = false
local connection
connection = RunService.RenderStepped:Connect(function(dt)
	local doneWeight, label = 0, "Ready!"
	local current = nil
	for _, s in STEPS do
		if s.Done() then
			doneWeight += s.Weight
		elseif not current then
			current = s
			label = s.Label .. "..."
		end
	end
	-- the step in flight creeps toward (never reaches) its share so the bar keeps moving
	local creep = 0
	if current then
		creep = current.Weight * 0.6 * (1 - math.exp(-(os.clock() - started) / 6)) / #STEPS
	end
	local timedOut = os.clock() - started > MAX_WAIT
	local target = if current and not timedOut then math.min(0.97, (doneWeight + creep) / total) else 1
	shown += (target - shown) * math.min(1, dt * 5)
	fill.Size = UDim2.new(math.clamp(shown, 0, 1), 0, 1, 0)
	percent.Text = `{math.floor(shown * 100 + 0.5)}%`
	status.Text = if timedOut and current then "Almost there..." else label
	if (not current or timedOut) and shown > 0.985 and not finishing then
		finishing = true
		connection:Disconnect()
		fill.Size = UDim2.fromScale(1, 1)
		percent.Text = "100%"
		status.Text = "Ready!"
		task.delay(0.25, function()
			local tween = TweenService:Create(root, TweenInfo.new(0.5), { GroupTransparency = 1 })
			tween.Completed:Once(function()
				gui:Destroy()
			end)
			tween:Play()
		end)
	end
end)
