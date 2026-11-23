--!strict
-- Daily Login Controller (Client).
-- Binds UI/Screens/DailyLogin.luau with server rewards via Remotes "ClaimDailyLogin".

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Remotes = require(Shared.Remotes)
local DailyLogin = require(Shared.DailyLogin)

local New = require(script.Parent.Parent.UI.New)
local Baked = require(script.Parent.Parent.UI.Baked)
local Screen = require(script.Parent.Parent.UI.Screens.DailyLogin)
local MenuManager = require(script.Parent.Parent.UI.MenuManager)
local HUD = require(script.Parent.HUDController)
local DataController = require(script.Parent.DataController)

local T = New.Theme

local DailyLoginController = {}

local gui: ScreenGui
local isOpen = false
local claimBtn: TextButton
local streakText: TextLabel
local resetText: TextLabel
local dayCards: { [number]: { Stroke: UIStroke?, Badge: Frame, Tab: Frame?, Overlay: Frame } } = {}

local function formatTimer(sec: number): string
	local h = sec // 3600
	local m = (sec % 3600) // 60
	local s = sec % 60
	return string.format("%02d:%02d:%02d", h, m, s)
end

local function refresh()
	if not gui or not isOpen then
		return
	end
	local profile = DataController.Profile
	local state = DailyLogin.GetState(profile)

	if streakText then
		streakText.Text = string.format("Streak: %d Day%s", state.Streak, if state.Streak == 1 then "" else "s")
	end
	if resetText then
		resetText.Text = "Resets in " .. formatTimer(state.ResetsIn)
	end

	for d = 1, 7 do
		local ref = dayCards[d]
		if not ref then
			continue
		end

		local claimed = d < state.CurrentDay or (d == state.CurrentDay and not state.CanClaim)
		local ready = d == state.CurrentDay and state.CanClaim
		local grand = d == 7
		ref.Overlay.Visible = claimed
		ref.Badge.Visible = ready
		local tabColor = if grand then T.Gold elseif ready then T.Accent else T.SkyLip
		if ref.Tab then
			ref.Tab.BackgroundColor3 = tabColor
			local squareEdge = ref.Tab:FindFirstChild("SquareEdge") :: Frame
			squareEdge.BackgroundColor3 = tabColor
		end
		if ref.Stroke then
			ref.Stroke.Color = if grand then T.Gold elseif ready then T.Accent else T.Track
			ref.Stroke.Thickness = 2
		end
	end

	if claimBtn then
		if state.CanClaim then
			claimBtn.Text = `CLAIM DAY {state.CurrentDay}`
			New.SetButtonColor(claimBtn, T.Good)
		else
			claimBtn.Text = "CLAIMED TODAY"
			New.SetButtonColor(claimBtn, T.Disabled)
		end
	end
end

local function ensure()
	if gui then
		return
	end
	local g = Baked.Get("DailyLogin")
	gui = g
	g.Enabled = false

	(g:WaitForChild("Backdrop") :: GuiObject).BackgroundTransparency = 1 -- no black overlay (older bakes still have it)
	local window = g:WaitForChild("Backdrop"):WaitForChild("Window")
	local header = window:WaitForChild("Content"):WaitForChild("Header")
	streakText = header:WaitForChild("Chips"):WaitForChild("StreakChip"):WaitForChild("StreakText") :: TextLabel
	resetText = header:WaitForChild("Chips"):WaitForChild("ResetChip"):WaitForChild("ResetText") :: TextLabel

	local closeBtn = header:WaitForChild("Close") :: TextButton
	closeBtn.Activated:Connect(function()
		DailyLoginController.Close()
	end)

	New.FitWindow(window :: GuiObject) -- scales down on small screens (and pops up at the right size)
	local grid = window:WaitForChild("Content"):WaitForChild("Grid")
	for i = 1, 7 do
		local card = assert(grid:FindFirstChild("DayCard" .. i, true)) :: Frame
		local badge = card:WaitForChild("StatusBadge") :: Frame
		local tab = card:FindFirstChild("HeaderTab") :: Frame?
		local overlay = card:FindFirstChild("ClaimedOverlay") :: Frame?
		if not overlay then
			local built = Screen.MakeClaimedOverlay(card)
			New.ApplyImages(built)
			overlay = built
		end
		local stroke = card:FindFirstChildWhichIsA("UIStroke") :: UIStroke?
		dayCards[i] = { Stroke = stroke, Badge = badge, Tab = tab, Overlay = overlay :: Frame }
	end

	local footer = window:WaitForChild("Content"):WaitForChild("Footer")
	claimBtn = footer:WaitForChild("ClaimBtn") :: TextButton

	claimBtn.Activated:Connect(function()
		local profile = DataController.Profile
		local state = DailyLogin.GetState(profile)
		if not state.CanClaim then
			HUD.Notify("Already claimed today!", T.SubText)
			return
		end

		local ok, msg = Remotes.Func("ClaimDailyLogin"):InvokeServer()
		if ok then
			HUD.Notify(msg, T.GoodLip)
			refresh()
		else
			HUD.Notify(msg or "Failed to claim", T.Bad)
		end
	end)
end

function DailyLoginController.Open()
	MenuManager.WillOpen("DailyLogin")
	ensure()
	isOpen = true
	local camera = workspace.CurrentCamera
	Screen.Layout(gui, if camera then camera.ViewportSize else Vector2.new(1280, 720))
	gui.Enabled = true
	New.Pop(Baked.Find(gui :: any, "Backdrop/Window")) -- elastic pop
	refresh()
end

function DailyLoginController.Close()
	if not gui then
		return
	end
	isOpen = false
	gui.Enabled = false
	MenuManager.Closed("DailyLogin")
end

function DailyLoginController.Init()
	HUD.DailyLoginRequested:Connect(function()
		DailyLoginController.Open()
	end)

	DataController.Changed:Connect(function()
		if isOpen then
			refresh()
		end
	end)

	-- Check auto-notification if player has an unclaimed reward
	task.spawn(function()
		task.wait(2)
		local profile = DataController.Profile
		if profile then
			local state = DailyLogin.GetState(profile)
			if state.CanClaim then
				HUD.Notify("Daily login gift available! Tap the Daily button", T.GoldLip)
			end
		end
	end)

	-- Timer tick every second while open to update countdown
	task.spawn(function()
		while true do
			task.wait(1)
			if isOpen then
				refresh()
			end
		end
	end)
end

MenuManager.Register("DailyLogin", { Layer = "Main", Open = DailyLoginController.Open, Close = DailyLoginController.Close, IsOpen = function()
	return isOpen
end, Gui = function()
	return gui
end })

return DailyLoginController
