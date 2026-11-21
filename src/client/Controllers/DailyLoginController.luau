--!strict
-- Daily Login Controller (Client).
-- Binds UI/Screens/DailyLogin.luau with server rewards via Remotes "ClaimDailyLogin".

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Remotes = require(Shared.Remotes)
local DailyLogin = require(Shared.DailyLogin)

local New = require(script.Parent.Parent.UI.New)
local Baked = require(script.Parent.Parent.UI.Baked)
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
local dayCards: { [number]: { Stroke: UIStroke?, Badge: Frame, Text: TextLabel } } = {}

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

		local stroke = ref.Stroke
		local badge = ref.Badge
		local txt = ref.Text

		if d < state.CurrentDay then
			-- Past claimed day
			badge.BackgroundColor3 = T.Good
			txt.Text = "CLAIMED"
			txt.TextColor3 = T.OnAccent
			if stroke then
				stroke.Color = T.Track
				stroke.Thickness = 1.5
			end
		elseif d == state.CurrentDay then
			if state.CanClaim then
				-- Ready to claim today
				badge.BackgroundColor3 = T.Accent
				txt.Text = "READY"
				txt.TextColor3 = T.OnAccent
				if stroke then
					stroke.Color = T.Accent
					stroke.Thickness = 2
				end
			else
				-- Claimed today already
				badge.BackgroundColor3 = T.Good
				txt.Text = "CLAIMED"
				txt.TextColor3 = T.OnAccent
				if stroke then
					stroke.Color = T.Track
					stroke.Thickness = 1.5
				end
			end
		else
			-- Future locked day
			badge.BackgroundColor3 = T.Track
			txt.Text = "LOCKED"
			txt.TextColor3 = T.SubText
			if stroke then
				stroke.Color = if d == 7 then T.GoldLip else T.Track
				stroke.Thickness = if d == 7 then 2 else 1.5
			end
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

	local window = g:WaitForChild("Backdrop"):WaitForChild("Window")
	local header = window:WaitForChild("Content"):WaitForChild("Header")
	streakText = header:WaitForChild("Chips"):WaitForChild("StreakChip"):WaitForChild("StreakText") :: TextLabel
	resetText = header:WaitForChild("Chips"):WaitForChild("ResetChip"):WaitForChild("ResetText") :: TextLabel

	local closeBtn = header:WaitForChild("Close") :: TextButton
	closeBtn.Activated:Connect(function()
		DailyLoginController.Close()
	end)

	local grid = window:WaitForChild("Content"):WaitForChild("Grid")
	for i = 1, 7 do
		local rowName = if i <= 4 then "Row1" else "Row2"
		local row = grid:WaitForChild(rowName)
		local card = row:WaitForChild(`DayCard{i}`) :: Frame
		local badge = card:WaitForChild("StatusBadge") :: Frame
		local txt = badge:WaitForChild("StatusText") :: TextLabel
		local stroke = card:FindFirstChildWhichIsA("UIStroke") :: UIStroke?
		dayCards[i] = { Stroke = stroke, Badge = badge, Text = txt }
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
				HUD.Notify("Daily login gift available! Check Events", T.GoldLip)
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
