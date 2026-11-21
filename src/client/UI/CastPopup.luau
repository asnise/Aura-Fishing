--!nonstrict
-- Depth popup controller (see UI/Screens/CastPopup.luau). Opened by the HUD Depth icon button.
-- CastPopup.Open({ Get = () -> number, Max = () -> number, Set = (number) -> () })

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Registry = require(Shared.Registry)

local New = require(script.Parent.New)
local Baked = require(script.Parent.Baked)
local MenuManager = require(script.Parent.MenuManager)

local T = New.Theme
local CastPopup = {}

-- One pastel band per Registry.DepthZones entry (the config colours are dark scene colours).
local BAND_COLORS = {
	Color3.fromRGB(211, 236, 250),
	Color3.fromRGB(154, 212, 245),
	Color3.fromRGB(111, 176, 230),
	Color3.fromRGB(143, 134, 217),
	Color3.fromRGB(107, 95, 168),
}
local SHALLOW_PRESET, MID_PRESET = 20, 80

local gui: ScreenGui? = nil
local refs: any = nil
local opts: any = nil
local dragging = false

local function zoneIndex(depth: number): number
	for i, z in Registry.DepthZones do
		if depth >= z.Min and depth <= z.Max then
			return i
		end
	end
	return #Registry.DepthZones
end

local function buildBands(max: number)
	for _, child in refs.Track:GetChildren() do
		if child.Name == "Band" then
			child:Destroy()
		end
	end
	local zones = Registry.DepthZones
	for i, zone in zones do
		if zone.Min >= max then
			break
		end
		local nextMin = if zones[i + 1] then zones[i + 1].Min else max
		local stop = math.min(nextMin, max)
		New("Frame", {
			Name = "Band",
			Position = UDim2.fromScale(zone.Min / max, 0),
			Size = UDim2.fromScale((stop - zone.Min) / max, 1),
			BackgroundColor3 = BAND_COLORS[i] or BAND_COLORS[#BAND_COLORS],
			BorderSizePixel = 0,
			ZIndex = 3,
			Parent = refs.Track,
		})
	end
end

local function speciesAt(depth: number): number
	local n = 0
	for _, fish in Registry.Fish do
		if depth >= fish.DepthMin and depth <= fish.DepthMax then
			n += 1
		end
	end
	return n
end

local function render()
	if not opts then
		return
	end
	local max = math.max(opts.Max(), 1)
	local depth = math.clamp(opts.Get(), 0, max)
	refs.Value.Text = `{depth}m`
	refs.Knob.Position = UDim2.new(depth / max, 0, 0.5, 0)
	local index = zoneIndex(depth)
	refs.ZoneLabel.Text = string.upper(Registry.DepthZones[index].Name)
	refs.Zone.BackgroundColor3 = BAND_COLORS[index] or BAND_COLORS[#BAND_COLORS]
	refs.Max.Text = `{max}m (line)`
	local count = speciesAt(depth)
	refs.Species.Text = `{count} {if count == 1 then "species lives" else "species live"} here`

	local values = { Shallow = math.min(SHALLOW_PRESET, max), Mid = math.min(MID_PRESET, max), Max = max }
	local labels = { Shallow = "Shallow", Mid = "Mid", Max = "Max" }
	for name, value in values do
		local button = refs.Presets[name]
		button.Text = `{labels[name]} {value}m`
		New.SetButtonColor(button, if depth == value then T.Accent else T.PanelLight)
	end
end

local function setDepth(value: number)
	opts.Set(math.clamp(math.round(value), 0, math.max(opts.Max(), 1)))
	render()
end

local function dragTo(x: number)
	local track = refs.Track
	local width = track.AbsoluteSize.X
	if width <= 0 then
		return
	end
	setDepth(math.clamp((x - track.AbsolutePosition.X) / width, 0, 1) * math.max(opts.Max(), 1))
end

function CastPopup.Close()
	dragging = false
	opts = nil
	if gui then
		gui.Enabled = false
	end
	MenuManager.Closed("CastPopup")
end

function CastPopup.IsOpen(): boolean
	return gui ~= nil and gui.Enabled
end

local function ensure()
	if gui then
		return
	end
	local g = Baked.Get("CastPopup")
	local function find(path: string): any
		return Baked.Find(g, path)
	end
	New.FitWindow(find("Window")) -- a baked UIScale has no listeners
	refs = {
		Shield = find("Shield"),
		Close = find("Window/Header/Close"),
		Value = find("Window/Value"),
		Zone = find("Window/Zone"),
		ZoneLabel = find("Window/Zone/Label"),
		Holder = find("Window/SliderHolder"),
		Track = find("Window/SliderHolder/Track"),
		Knob = find("Window/SliderHolder/Knob"),
		Max = find("Window/Scale/Max"),
		Species = find("Window/Species"),
		Presets = {
			Shallow = find("Window/Presets/Shallow"),
			Mid = find("Window/Presets/Mid"),
			Max = find("Window/Presets/Max"),
		},
	}
	refs.Shield.Activated:Connect(CastPopup.Close)
	refs.Close.Activated:Connect(CastPopup.Close)
	for name, button in refs.Presets do
		button.Activated:Connect(function()
			if opts then
				local max = math.max(opts.Max(), 1)
				setDepth(if name == "Shallow" then math.min(SHALLOW_PRESET, max) elseif name == "Mid" then math.min(MID_PRESET, max) else max)
			end
		end)
	end

	local function isPointer(input: InputObject): boolean
		return input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch
	end
	refs.Holder.InputBegan:Connect(function(input)
		if opts and isPointer(input) then
			dragging = true
			dragTo(input.Position.X)
		end
	end)
	UserInputService.InputChanged:Connect(function(input)
		if dragging and opts and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			dragTo(input.Position.X)
		end
	end)
	UserInputService.InputEnded:Connect(function(input)
		if isPointer(input) then
			dragging = false
		end
	end)
	gui = g
end

function CastPopup.Open(options: any)
	MenuManager.WillOpen("CastPopup")
	ensure()
	opts = options
	buildBands(math.max(opts.Max(), 1))
	render()
	local screen = gui :: ScreenGui
	screen.Enabled = true
end

MenuManager.Register("CastPopup", { Layer = "Popup", Close = CastPopup.Close, IsOpen = CastPopup.IsOpen })

return CastPopup
