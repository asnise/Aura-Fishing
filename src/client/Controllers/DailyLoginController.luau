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

-- Layout for the screen size (docs/RESPONSIVE_MENU_PLAN.md 8.4):
--   wide      680 x 480, 4 + 3 cards (the Figma layout)
--   landscape short phones (height < 520): same 4 + 3 grid, lower cards, nothing taller than ~360
--   portrait  narrow phones (width < 600): 3 + 3 cards, then day 7 across the bottom, chips under the title
local function applyLayout()
	local camera = workspace.CurrentCamera
	local vp = if camera then camera.ViewportSize else Vector2.new(1280, 720)
	local portrait = vp.X < 600
	local short = not portrait and vp.Y < 520
	local touch = portrait or short

	local window = (gui :: any).Backdrop.Window
	local content = window.Content
	local header = content.Header
	local grid = content.Grid
	local footer = content.Footer

	local winW = if portrait then math.min(420, vp.X - 16) else math.min(680, vp.X - 24)
	local inner = winW - 40
	local cols = if portrait then 3 else 4
	local gap = if portrait then 8 else 10
	local cardH = if portrait then 118 elseif short then 100 else 136
	local cardW = math.floor((inner - (cols - 1) * gap) / cols)
	local day7W = if portrait then inner else cardW * 2 + gap
	if not portrait and not short then
		cardW, day7W = 152, 270
	end
	local iconSize = if portrait then 44 elseif short then 36 else 56

	-- rows: portrait has a third row for day 7
	local row1, row2 = grid.Row1, grid.Row2
	local row3 = grid:FindFirstChild("Row3")
	if portrait and not row3 then
		row3 = row2:Clone()
		row3.Name = "Row3"
		for _, c in row3:GetChildren() do
			if c:IsA("Frame") then
				c:Destroy()
			end
		end
		row3.Parent = grid
	end
	for i = 1, 7 do
		local card = (gui :: any):FindFirstChild(`DayCard{i}`, true)
		if card then
			local target = if portrait then (if i <= 3 then row1 elseif i <= 6 then row2 else row3) else (if i <= 4 then row1 else row2)
			if card.Parent ~= target then
				card.Parent = target
			end
			card.LayoutOrder = i
			card.Size = UDim2.fromOffset(if i == 7 then day7W else cardW, cardH)
			card.IconBox.Size = UDim2.fromOffset(iconSize, iconSize)
			card.IconBox.Icon.Size = UDim2.fromOffset(iconSize - 10, iconSize - 10)
			card.IconBox.Position = UDim2.new(0.5, 0, 0, if portrait then 22 elseif short then 18 else 24)
			card.RewardText.Position = UDim2.fromOffset(0, iconSize + (if portrait then 28 elseif short then 20 else 28))
		end
	end
	local rowsUsed = if portrait then 3 else 2
	for i, row in { row1, row2, row3 } do
		if row then
			row.Position = UDim2.fromOffset(0, (i - 1) * (cardH + 8))
			row.Size = UDim2.new(1, 0, 0, cardH)
			row.Visible = i <= rowsUsed
			local list = row:FindFirstChildOfClass("UIListLayout")
			if list then
				list.Padding = UDim.new(0, gap)
			end
		end
	end

	-- header: chips sit under the title on a narrow screen
	local headerH = if portrait then 84 else 52
	header.Size = UDim2.new(1, 0, 0, headerH)
	header.Chips.AnchorPoint = if portrait then Vector2.new(0, 1) else Vector2.new(1, 0.5)
	header.Chips.Position = if portrait then UDim2.new(0, 0, 1, 0) else UDim2.new(1, -44, 0.5, 0)
	header.Chips.Size = UDim2.fromOffset(if portrait then inner else 340, 32)
	header.Chips.UIListLayout.HorizontalAlignment = if portrait then Enum.HorizontalAlignment.Left else Enum.HorizontalAlignment.Right
	local closeSize = if touch then 44 else 36
	header.Close.Size = UDim2.fromOffset(closeSize, closeSize)

	local gridTop = headerH + 10
	grid.Position = UDim2.fromOffset(0, gridTop)
	local gridH = rowsUsed * cardH + (rowsUsed - 1) * 8
	grid.Size = UDim2.new(1, 0, 0, gridH)
	footer.Size = UDim2.new(1, 0, 0, if touch then 56 else 52)
	local claim = footer.ClaimBtn
	claim.Size = UDim2.fromOffset(math.min(280, inner), if touch then 52 else 48)
	window.Size = UDim2.fromOffset(winW, 16 + gridTop + gridH + 8 + footer.Size.Y.Offset + 16)
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
	applyLayout() -- before the window shows, so it never appears at the wrong size
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
