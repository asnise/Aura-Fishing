--!strict
-- Tide event HUD (C5). Server: TideEventService.
-- Compact event HUD along the left edge during gameplay:
--   - Uses baked StarterGui.TideEvent (UI/Screens/TideEvent.luau)
--   - Event avatar badge (Naga icon) + Title ("Naga Tide")
--   - Dynamic time pill (M:SS countdown)
--   - Outside state: Distance/compass heading + Anglers count pill
--   - Inside state: Glowing mint highlight banner ("IN TIDE: +50% LUCK")
--   - Rare target catches preview chips (Naga Hatchling, Coral Seahorse)

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Remotes = require(Shared.Remotes)
local Registry = require(Shared.Registry)

local New = require(script.Parent.Parent.UI.New)
local Baked = require(script.Parent.Parent.UI.Baked)
local MenuManager = require(script.Parent.Parent.UI.MenuManager)
local TideScreen = require(script.Parent.Parent.UI.Screens.TideEvent)
local HUD = require(script.Parent.HUDController)

local T = New.Theme

local TideEventController = {}

local state: any = { Active = false }
local gui: ScreenGui
local panelStroke: UIStroke?
local titleLabel: TextLabel
local timePill: Frame
local timeLabel: TextLabel
local outsideRow: Frame
local navLabel: TextLabel
local anglersLabel: TextLabel
local insideRow: Frame
local insideLabel: TextLabel

local DIRS = { "N", "NE", "E", "SE", "S", "SW", "W", "NW" }

local function bind()
	gui = Baked.Get("TideEvent")
	local top = gui:WaitForChild("Top") :: Frame
	TideScreen.Compact(top)
	local scale = New("UIScale", { Parent = top }) :: UIScale
	local stats = if HUD.Gui then HUD.Gui:FindFirstChild("Stats") :: GuiObject? else nil
	local function place()
		scale.Scale = math.clamp(gui.AbsoluteSize.X / 760, 0.8, 1)
		local belowStats = if stats then (stats.AbsolutePosition.Y + stats.AbsoluteSize.Y - gui.AbsolutePosition.Y + 8) else 104
		top.Position = UDim2.fromOffset(12, math.max(8, math.ceil(belowStats)))
	end
	gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(place)
	if stats then
		stats:GetPropertyChangedSignal("AbsolutePosition"):Connect(place)
		stats:GetPropertyChangedSignal("AbsoluteSize"):Connect(place)
	end
	place()
	panelStroke = top:FindFirstChildWhichIsA("UIStroke") :: UIStroke?
	titleLabel = top:FindFirstChild("Title", true) :: TextLabel
	timePill = top:FindFirstChild("TimePill", true) :: Frame
	timeLabel = top:FindFirstChild("TimeText", true) :: TextLabel
	outsideRow = top:FindFirstChild("OutsideRow", true) :: Frame
	navLabel = top:FindFirstChild("NavText", true) :: TextLabel
	anglersLabel = top:FindFirstChild("AnglersText", true) :: TextLabel
	insideRow = top:FindFirstChild("InsideRow", true) :: Frame
	insideLabel = top:FindFirstChild("InsideText", true) :: TextLabel
end

local function tick()
	if not gui then
		return
	end
	local active = state.Active == true and MenuManager.Top() == nil
	gui.Enabled = active
	if not active then
		return
	end

	local now = Workspace:GetServerTimeNow()
	local left = math.max(0, math.floor((state.EndsAt or 0) - now))
	timeLabel.Text = string.format("%d:%02d", left // 60, left % 60)
	if left <= 30 then
		timePill.BackgroundColor3 = T.Bad
		timeLabel.TextColor3 = T.OnAccent
	else
		timePill.BackgroundColor3 = T.PanelLight
		timeLabel.TextColor3 = T.Text
	end

	titleLabel.Text = state.Name or "Naga Tide"

	local char = Players.LocalPlayer.Character
	local root = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
	local where = "Unknown"
	local inside = false

	if root and state.Center then
		local rootPos = root.Position
		local d = (state.Center - rootPos) * Vector3.new(1, 0, 1)
		-- C25: the bobber lands where the player aimed; use the real one when it is out
		local bobbers = workspace:FindFirstChild("Bobbers")
		local real = bobbers and bobbers:FindFirstChild(Players.LocalPlayer.Name)
		local bobPos = if real and real:IsA("BasePart") then real.Position else rootPos + root.CFrame.LookVector * Registry.GameConfig.CastDistance
		local bob = (bobPos - state.Center) * Vector3.new(1, 0, 1)
		inside = bob.Magnitude <= (state.Radius or 0)

		if d.Magnitude > (state.Radius or 0) then
			local ang = math.deg(math.atan2(d.X, -d.Z)) % 360
			local dir = DIRS[(math.floor((ang + 22.5) / 45) % 8) + 1]
			where = string.format("%d studs %s", math.floor(d.Magnitude), dir)
		else
			where = "Near tide"
		end
	end

	local anglers = state.Anglers or 0
	if inside then
		outsideRow.Visible = false
		insideRow.Visible = true
		if panelStroke then
			panelStroke.Color = T.GoodLip
		end
		local bonus = math.floor((state.LuckBonus or 0) * 100)
		insideLabel.Text = string.format("+%d%% luck | %d anglers", bonus, anglers)
	else
		outsideRow.Visible = true
		insideRow.Visible = false
		if panelStroke then
			panelStroke.Color = T.Track
		end
		navLabel.Text = where
		anglersLabel.Text = string.format("%d anglers", anglers)
	end
end

function TideEventController.Init()
	bind()
	Remotes.Event("TideEvent").OnClientEvent:Connect(function(s)
		state = s
		tick()
	end)
	MenuManager.Changed:Connect(tick)
	local elapsed = 0
	RunService.Heartbeat:Connect(function(dt)
		elapsed += dt
		if elapsed >= 0.2 then
			elapsed %= 0.2
			tick()
		end
	end)
end

return TideEventController
