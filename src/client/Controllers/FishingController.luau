--!nonstrict
-- Client side of fishing: hold-to-cast (C25, Figma 01 HUD "Cast Charge"), "!" bite prompt, and the reel minigame (GDD 3.2, Figma 03).
-- The minigame result is validated on the server (see FishingService.onReelResult).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Registry = require(Shared.Registry)
local Remotes = require(Shared.Remotes)
local FishingSpot = require(Shared.FishingSpot)

local New = require(script.Parent.Parent.UI.New)
local Baked = require(script.Parent.Parent.UI.Baked)
local MenuManager = require(script.Parent.Parent.UI.MenuManager)
local HUD = require(script.Parent.HUDController)
local DataController = require(script.Parent.DataController)

local T = New.Theme
local MG = Registry.GameConfig.Minigame
local player = Players.LocalPlayer

local FishingController = {}

local phase = "Idle"
local biteToken: string? = nil
local holding = false
local minigameActive = false

-- Reel minigame: "Twin tubes" (Figma: 03 · Reel Minigame, A2 CHOSEN 2026-11-17) ----------
-- Hold to lift the catch bar in the water tube, release to let it sink; keep it over the
-- (mystery) fish. The gold reel tube fills while the fish is inside; the bobber floats on it.
-- Tension shows on the catch bar colour: mint = on the fish, gold = slipping, red = about to snap.
-- Same mechanic/numbers as Pond Card, so the server's min-duration validation is unchanged.
-- Layout is baked into StarterGui.Minigame (UI/Screens/Minigame.luau); this only binds + simulates.

local WATER_H, METER_H = 300, 300 -- must match UI/Screens/Minigame.luau (Twin tubes: both tubes 300 tall)

local mg: { [string]: any }? = nil

local function minigameUI(): { [string]: any }
	if mg then
		return mg
	end
	local gui = Baked.Get("Minigame")
	local function find(path: string)
		return Baked.Find(gui, path)
	end
	local ui = {
		Gui = gui,
		Panel = find("Panel"),
		Rarity = find("Panel/Header/Rarity"),
		Depth = gui.Panel.Header:FindFirstChild("Depth"), -- optional (Pond Card had it, Twin tubes not)
		Timer = find("Panel/Header/Timer"),
		Bar = find("Panel/Body/Lane/Bar"),
		Fish = find("Panel/Body/Lane/Fish"),
		Fill = find("Panel/Body/Meter/Track/Fill"),
		Bobber = find("Panel/Body/Meter/Bobber"),
		Chips = {}, -- optional tension chips (Panel/Tension/LOOSE|GOOD|SNAP); Twin tubes shows tension on the bar colour
		Hint = find("Panel/Hint"),
	}
	-- FitToScreen hooks the ScreenGui's size only when the panel is (re)parented, so attach it that way
	ui.Panel.Parent = nil
	New.FitToScreen(ui.Panel)
	ui.Panel.Parent = gui
	mg = ui
	return ui
end

local function runMinigame(token: string, p: any)
	minigameActive = true
	local rarity = Registry.Rarities[p.Rarity]
	local ui = minigameUI()
	local gui = ui.Gui
	local bar, fishIcon, meterFill, bobber, timer = ui.Bar, ui.Fish, ui.Fill, ui.Bobber, ui.Timer

	-- reset the baked panel for this fish
	ui.Rarity.Text = string.upper(rarity.Name)
	ui.Rarity.BackgroundColor3 = rarity.Color
	ui.Rarity.TextColor3 = T.OnAccent
	if ui.Depth then
		ui.Depth.Text = `{p.Depth or 0}m`
	end
	timer.Text = ""
	bar.Size = UDim2.new(1, 6, p.CatchBarSize, 0) -- 3px wider than the tube each side
	bar.Position = UDim2.new(0, -3, 1, 0)
	bar.BackgroundTransparency = 0.2
	fishIcon.Position = UDim2.fromScale(0.5, 0.5)
	meterFill.Size = UDim2.fromScale(1, MG.StartProgress)
	bobber.Position = UDim2.new(0.5, 0, 0, (WATER_H - METER_H) + METER_H * (1 - MG.StartProgress))
	ui.Hint.Text = if UserInputService.TouchEnabled then "HOLD TO REEL" else "HOLD CLICK / SPACE"

	-- tension chips
	local chips = ui.Chips
	local chipColors = { LOOSE = T.Gold, GOOD = T.Good, SNAP = T.Bad }
	for _, c in chips do
		c.BackgroundColor3 = T.PanelLight
		c.TextColor3 = T.SubText
	end
	local tension = ""
	local function setTension(state: string)
		if state == tension then
			return
		end
		tension = state
		for k, c in chips do
			local on = k == state
			c.BackgroundColor3 = if on then chipColors[k] else T.PanelLight
			c.TextColor3 = if on then T.OnAccent else T.SubText
		end
		bar.BackgroundColor3 = chipColors[state] or T.Good
	end

	gui.Enabled = true

	-- simulation (0..1 along the water column, 0 = bottom)
	local pattern = p.PatternDef
	local barSize = p.CatchBarSize
	local rng = Random.new()
	-- Open with the catch bar centred on the fish (see GameConfig.Minigame.StartGrace).
	local fishPos = rng:NextNumber(MG.StartFishRange[1], MG.StartFishRange[2])
	local fishTarget = fishPos
	local barPos, barVel = math.clamp(fishPos - barSize / 2, 0, 1 - barSize), 0
	local burstTime = 0
	local progress = MG.StartProgress
	local perfect = true
	local elapsed = 0
	local speed = pattern.Speed * (1 + (p.Difficulty - 1) * MG.DifficultySpeedScale) * (1 - p.FishStability)

	local function pickTarget()
		local t = rng:NextNumber()
		if pattern.Bias then
			t = (t + pattern.Bias * 2) / 3
		end
		fishTarget = math.clamp(t, 0.06, 0.94)
	end

	local conn
	local function finish(success: boolean)
		if not minigameActive then
			return
		end
		minigameActive = false
		conn:Disconnect()
		gui.Enabled = false -- baked panel is reused next time
		Remotes.Event("ReelResult"):FireServer(token, success, success and perfect)
	end

	conn = RunService.RenderStepped:Connect(function(dt)
		dt = math.min(dt, 0.1)
		elapsed += dt
		local grace = elapsed < MG.StartGrace

		if holding then
			barVel += MG.BarLift * dt
		elseif not grace then
			barVel -= MG.BarGravity * dt
		end
		barVel = math.clamp(barVel, -1.6, 1.6)
		barPos += barVel * dt
		if barPos < 0 then
			barPos, barVel = 0, 0
		elseif barPos > 1 - barSize then
			barPos, barVel = 1 - barSize, 0
		end

		if not grace then
			if rng:NextNumber() < pattern.Jitter * dt then
				pickTarget()
			end
			if burstTime <= 0 and rng:NextNumber() < pattern.BurstChance * dt then
				burstTime = 0.35
				pickTarget()
			end
			local s = speed * (if burstTime > 0 then 3 else 1)
			burstTime -= dt
			fishPos += math.clamp(fishTarget - fishPos, -s * dt, s * dt)
		end

		local inside = fishPos >= barPos and fishPos <= barPos + barSize
		if inside then
			progress += MG.GainPerSecond * p.ReelPower * dt
		else
			perfect = false
			progress -= MG.LossPerSecond * (1 - p.Resilience) * dt
		end

		local pc = math.clamp(progress, 0, 1)
		bar.Position = UDim2.new(0, -3, 1 - barPos, 0)
		bar.BackgroundTransparency = if inside then 0.15 else 0.45
		fishIcon.Position = UDim2.fromScale(0.5, 1 - fishPos)
		meterFill.Size = UDim2.fromScale(1, pc)
		bobber.Position = UDim2.new(0.5, 0, 0, (WATER_H - METER_H) + METER_H * (1 - pc))
		setTension(if inside then "GOOD" elseif progress > MG.SnapWarning then "LOOSE" else "SNAP")
		local left = math.max(0, MG.MaxDuration - elapsed)
		timer.Text = string.format("%d:%02d", math.floor(left / 60), math.floor(left % 60))

		if progress >= 1 then
			finish(true)
		elseif progress <= 0 or elapsed > MG.MaxDuration then
			finish(false)
		end
	end)
end

-- Input: hold-to-cast (C25) ------------------------------------------------------------
-- PC: click the world (gamepad R2), touch: the round CAST button. Aim = camera direction.
-- Hold: the needle on the power bar goes 0 -> 1 -> 0; release sets the distance (MinDistance..CastRange).
-- A quick tap casts at TapPower. Gold zone = Perfect (shorter bite wait). No water there = the bobber
-- lands, reels back, nothing else happens. While fishing the same press hooks "!" / reels in.

local CAST = Registry.GameConfig.Cast
local charging = false
local chargeStart = 0
local chargeInput: InputObject? = nil
local chargeConn: RBXScriptConnection? = nil
local marker: Part? = nil

local function rootPart(): BasePart?
	local char = player.Character
	return char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
end

local function aimDir(): Vector3?
	local cam = workspace.CurrentCamera
	local look = cam and cam.CFrame.LookVector * Vector3.new(1, 0, 1)
	return if look and look.Magnitude > 0.01 then look.Unit else nil
end

-- needle position after holding t seconds: 0 -> 1 -> 0 -> ...
local function powerAt(t: number): number
	local x = (t / CAST.ChargeCycle) % 2
	return if x <= 1 then x else 2 - x
end

-- same distance math as FishingService.castPoint
local function castDistance(power: number): number
	local stats = DataController.Stats
	local range = math.max(CAST.MinDistance, stats and stats.Values.CastRange or CAST.MinDistance)
	return CAST.MinDistance + (range - CAST.MinDistance) * power
end

-- where the bobber lands: (point, isFishableWater); point = ground when it is not water
local function landing(root: BasePart, dir: Vector3, power: number): (Vector3, boolean)
	local dist = castDistance(power)
	local water = FishingSpot.WaterAt(root, dir, dist)
	if water then
		return water, true
	end
	local params = RaycastParams.new()
	params.FilterDescendantsInstances = { root.Parent :: Instance }
	local target = root.Position + dir * dist
	local hit = workspace:Raycast(target + Vector3.new(0, 20, 0), Vector3.new(0, -60, 0), params)
	return if hit then hit.Position else target - Vector3.new(0, 3, 0), false
end

local function aimMarker(): Part
	if not marker then
		local m = Instance.new("Part")
		m.Name = "CastAim"
		m.Shape = Enum.PartType.Cylinder
		m.Size = Vector3.new(0.2, 3, 3)
		m.Material = Enum.Material.Neon
		m.Transparency = 0.35
		m.Anchored = true
		m.CanCollide = false
		m.CanQuery = false
		m.CanTouch = false
		-- "HOTSPOT" tag over the marker while it aims into one (Figma 01 HUD Hotspot mock)
		local bb = Instance.new("BillboardGui")
		bb.Name = "HotspotTag"
		bb.Size = UDim2.fromOffset(110, 28)
		bb.StudsOffsetWorldSpace = Vector3.new(0, 2.5, 0)
		bb.AlwaysOnTop = true
		bb.Enabled = false
		bb.Parent = m
		local label = Instance.new("TextLabel")
		label.Size = UDim2.fromScale(1, 1)
		label.BackgroundTransparency = 1
		label.Text = "HOTSPOT"
		label.TextColor3 = Color3.new(1, 1, 1)
		label.FontFace = T.Font
		label.TextSize = 18
		label.Parent = bb
		local stroke = Instance.new("UIStroke")
		stroke.Color = T.Text
		stroke.Thickness = 2
		stroke.Parent = label
		marker = m
	end
	return marker :: Part
end

-- C26: is this point inside a fish hotspot (server parts in Workspace.Hotspots)?
local function inHotspot(point: Vector3): boolean
	local folder = workspace:FindFirstChild("Hotspots")
	if not folder then
		return false
	end
	for _, spot in folder:GetChildren() do
		if spot:IsA("BasePart") then
			local d = spot.Position - point
			if Vector3.new(d.X, 0, d.Z).Magnitude <= (spot:GetAttribute("Radius") or 0) then
				return true
			end
		end
	end
	return false
end

-- Client-only bobber flying in an arc; on a miss it rests on the ground, then reels back.
local function flyBobber(from: Vector3, to: Vector3, miss: boolean)
	local ball = Instance.new("Part")
	ball.Name = "CastBobber"
	ball.Shape = Enum.PartType.Ball
	ball.Size = Vector3.new(0.8, 0.8, 0.8)
	ball.Color = Color3.fromRGB(255, 60, 60)
	ball.Anchored = true
	ball.CanCollide = false
	ball.CanQuery = false
	ball.CanTouch = false
	ball.Position = from
	ball.Parent = workspace
	local t = 0
	local conn
	conn = RunService.RenderStepped:Connect(function(dt)
		t += dt
		local a = math.min(t / CAST.FlightTime, 1)
		ball.Position = from:Lerp(to, a) + Vector3.new(0, math.sin(a * math.pi) * 6, 0)
		if a < 1 then
			return
		end
		conn:Disconnect()
		if not miss then
			ball:Destroy() -- the server's bobber appears here now
			return
		end
		task.delay(0.4, function()
			local back = TweenService:Create(ball, TweenInfo.new(0.3), { Position = from })
			back:Play()
			back.Completed:Wait()
			ball:Destroy()
		end)
	end)
end

local function setAutoRotate(on: boolean)
	local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	if hum then
		hum.AutoRotate = on
	end
end

local function stopCharge()
	charging = false
	chargeInput = nil
	if chargeConn then
		chargeConn:Disconnect()
		chargeConn = nil
	end
	if HUD.CastCharge then
		HUD.CastCharge.Visible = false
	end
	if marker then
		marker.Parent = nil
	end
	setAutoRotate(true)
end

local function showPerfect()
	local pop = HUD.PerfectPop
	if not pop then
		return
	end
	pop.Visible = true
	task.delay(0.9, function()
		pop.Visible = false
	end)
end

local function releaseCast()
	if not charging then
		return
	end
	local held = os.clock() - chargeStart
	stopCharge()
	local root, dir = rootPart(), aimDir()
	if not root or not dir or phase ~= "Idle" or minigameActive or MenuManager.BlocksWorldInput() then
		return
	end
	local power, perfect = CAST.TapPower, false
	if CAST.HoldCharge and held >= CAST.TapTime then
		power = powerAt(held)
		perfect = power >= CAST.PerfectMin and power <= CAST.PerfectMax
	end
	root.CFrame = CFrame.lookAt(root.Position, root.Position + dir)
	local point, water = landing(root, dir, power)
	local char = root.Parent :: Model
	local hand = char:FindFirstChild("RightHand") or char:FindFirstChild("Right Arm")
	flyBobber(if hand and hand:IsA("BasePart") then hand.Position else root.Position, point, not water)
	if not water then
		HUD.Notify("Cast into the water!", T.Bad)
		return
	end
	if perfect then
		showPerfect()
	end
	Remotes.Event("Cast"):FireServer(HUD.TargetDepth, dir, power, perfect)
end

local function startCharge(input: InputObject)
	HUD.HideCatch()
	charging = true
	chargeStart = os.clock()
	chargeInput = input
	if not CAST.HoldCharge then
		releaseCast()
		return
	end
	setAutoRotate(false)
	local ui = HUD.CastCharge :: any
	if ui then
		ui.PerfectZone.Position = UDim2.fromScale(0, 1 - CAST.PerfectMax)
		ui.PerfectZone.Size = UDim2.fromScale(1, CAST.PerfectMax - CAST.PerfectMin)
	end
	chargeConn = RunService.RenderStepped:Connect(function()
		local held = os.clock() - chargeStart
		local root, dir = rootPart(), aimDir()
		if held < CAST.TapTime or not root or not dir then
			return -- a tap shows no bar
		end
		local power = powerAt(held)
		root.CFrame = CFrame.lookAt(root.Position, root.Position + dir)
		if ui then
			ui.Visible = true
			ui.Fill.Size = UDim2.fromScale(1, power)
			ui.Needle.Position = UDim2.fromScale(0, 1 - power)
		end
		local point, water = landing(root, dir, power)
		local m = aimMarker()
		local hot = water and inHotspot(point)
		m.Color = if hot then T.Gold elseif water then T.Sky else T.SubText
		local tag = m:FindFirstChild("HotspotTag") :: BillboardGui?
		if tag then
			tag.Enabled = hot
		end
		m.CFrame = CFrame.new(point + Vector3.new(0, 0.15, 0)) * CFrame.Angles(0, 0, math.rad(90))
		m.Parent = workspace
	end)
end

-- A press: cast (hold) when idle, hook on "!", reel in while waiting.
local function onPress(input: InputObject, fromButton: boolean?)
	if minigameActive or charging or MenuManager.BlocksWorldInput() then
		return
	end
	if phase == "Idle" then
		if HUD.NearWater then
			startCharge(input)
		elseif fromButton then
			HUD.Notify("Go to the water to fish", T.Bad) -- the locked CAST button explains itself
		end
	elseif phase == "Bite" and biteToken then
		Remotes.Event("Hook"):FireServer(biteToken)
		biteToken = nil
	elseif phase == "Waiting" then
		Remotes.Event("CancelFishing"):FireServer()
	end
end

local function isChargeEnd(input: InputObject): boolean
	local c = chargeInput
	if not c then
		return false
	end
	if c.UserInputType == Enum.UserInputType.Touch then
		return input == c -- other fingers (thumbstick, camera) must not release the cast
	end
	return input.UserInputType == c.UserInputType and input.KeyCode == c.KeyCode
end

local function isHoldInput(input: InputObject): boolean
	return input.UserInputType == Enum.UserInputType.MouseButton1
		or input.UserInputType == Enum.UserInputType.Touch
		or input.KeyCode == Enum.KeyCode.Space
		or input.KeyCode == Enum.KeyCode.ButtonA
		or input.KeyCode == Enum.KeyCode.ButtonR2
end

-- Bite "!" above the character's head (Figma 02 HUD States BITE: ui/status/bite_alert), rarity-coloured ring.
-- Pops in, then bobs until the phase changes.
local biteAlert: BillboardGui? = nil
local function hideBiteAlert()
	if biteAlert then
		biteAlert:Destroy()
		biteAlert = nil
	end
end
local function showBiteAlert(color: Color3)
	hideBiteAlert()
	local char = player.Character
	local head = char and (char:FindFirstChild("Head") or char:FindFirstChild("HumanoidRootPart"))
	if not head then
		return
	end
	local bb = New("BillboardGui", {
		Name = "BiteAlert",
		Adornee = head,
		Size = UDim2.fromOffset(84, 84),
		StudsOffset = Vector3.new(0, 3, 0),
		AlwaysOnTop = true,
		ResetOnSpawn = false,
		Parent = player:WaitForChild("PlayerGui"),
	})
	local holder = New("Frame", { Name = "Pop", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(0.2, 0.2), BackgroundColor3 = T.Panel, Parent = bb, [New.Children] = { New.Corner(999), New.Stroke(color, 4) } })
	New.Image({ Name = "Img", Key = "ui/status/bite_alert", Fallback = color, FallbackText = "!", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(0.8, 0.8), Parent = holder })
	TweenService:Create(holder, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Size = UDim2.fromScale(1, 1) }):Play()
	TweenService:Create(holder, TweenInfo.new(0.45, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true, 0.25), { Position = UDim2.fromScale(0.5, 0.38) }):Play()
	biteAlert = bb
end

local function isCastKey(input: InputObject): boolean
	return input.UserInputType == Enum.UserInputType.MouseButton1 or input.KeyCode == Enum.KeyCode.ButtonR2 -- not E: ProximityPrompt key
end

function FishingController.Init()
	MenuManager.Changed:Connect(function(_, isOpen)
		if isOpen then
			holding = false
			if charging then
				stopCharge()
			end
		end
	end)
	HUD.AutoToggled:Connect(function(on)
		Remotes.Event("SetAuto"):FireServer(on, aimDir())
	end)
	local castButton = HUD.CastButton
	if castButton then
		castButton.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
				onPress(input, true)
			end
		end)
	end

	UserInputService.InputBegan:Connect(function(input, processed)
		if minigameActive then
			if isHoldInput(input) and not MenuManager.BlocksWorldInput() then
				holding = true -- reeling works even when the press lands on UI
			end
			return
		end
		if processed then
			return
		end
		if isCastKey(input) then
			onPress(input) -- clicking the world casts / hooks
		elseif input.KeyCode == Enum.KeyCode.Space and phase == "Bite" then
			onPress(input)
		end
	end)
	UserInputService.InputEnded:Connect(function(input)
		if isHoldInput(input) then
			holding = false
		end
		if charging and isChargeEnd(input) then
			releaseCast()
		end
	end)

	Remotes.Event("FishingState").OnClientEvent:Connect(function(newPhase, info)
		phase = newPhase
		hideBiteAlert()
		HUD.FishingActive = newPhase ~= "Idle" -- keep CAST/REEL visible mid-cast even if the player drifts
		if newPhase == "Idle" then
			HUD.SetStatus(nil)
			HUD.SetCastButton("CAST")
			HUD.SetAuto(false)
		elseif newPhase == "Waiting" then
			HUD.SetStatus(`Waiting... ({info and info.Depth or 0}m)`, T.SubText)
			HUD.SetCastButton("REEL IN", T.PanelLight)
		elseif newPhase == "Bite" then
			local r = info and Registry.Rarities[info.Rarity]
			HUD.SetStatus(nil)
			showBiteAlert(r and r.Color or T.Gold)
			HUD.SetCastButton("HOOK!", T.Gold)
		elseif newPhase == "Reeling" then
			HUD.SetStatus(nil)
			HUD.SetCastButton("REELING", T.PanelLight)
		elseif newPhase == "Auto" then
			HUD.SetStatus("Auto fishing...", T.Good)
			HUD.SetCastButton("AUTO", T.PanelLight)
			HUD.SetAuto(true)
		end
	end)

	Remotes.Event("Bite").OnClientEvent:Connect(function(token)
		biteToken = token
	end)
	Remotes.Event("StartMinigame").OnClientEvent:Connect(function(token, params)
		holding = UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1)
		runMinigame(token, params)
	end)

	player.CharacterRemoving:Connect(function()
		holding = false
		if charging then
			stopCharge()
		end
		hideBiteAlert()
	end)
end

return FishingController
