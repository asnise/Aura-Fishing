--!strict
-- Screen builder for Daily Login calendar (7-day rewards).
-- Baked into StarterGui.DailyLogin.

local New = require(script.Parent.Parent.New)
local Config = game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("Config")

local T = New.Theme

local Screen = { Name = "DailyLogin" }

function Screen.Build(): ScreenGui
	local gui = New("ScreenGui", {
		Name = "DailyLogin",
		ResetOnSpawn = false,
		IgnoreGuiInset = false,
		Enabled = false,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		DisplayOrder = 20,
	}) :: ScreenGui

	-- Dim background backdrop
	local backdrop = New("TextButton", {
		Name = "Backdrop",
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color3.new(0, 0, 0),
		BackgroundTransparency = 1, -- no black overlay (still blocks clicks behind)
		Text = "",
		AutoButtonColor = false,
		Parent = gui,
	})

	-- Main Window Panel (680 x 480)
	local window = New.Panel({
		Name = "Window",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(680, 480),
		Radius = 24,
		Parent = backdrop,
	})

	local content = New("Frame", {
		Name = "Content",
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Parent = window,
		[New.Children] = {
			New("UIPadding", {
				PaddingLeft = UDim.new(0, 20),
				PaddingRight = UDim.new(0, 20),
				PaddingTop = UDim.new(0, 16),
				PaddingBottom = UDim.new(0, 16),
			}),
		},
	})

	-- Header: Title, Subtitle, Streak & Timer, Close button
	local header = New("Frame", {
		Name = "Header",
		Size = UDim2.new(1, 0, 0, 52),
		BackgroundTransparency = 1,
		Parent = content,
	})

	New.Title({
		Name = "Title",
		Position = UDim2.fromOffset(0, 0),
		Size = UDim2.fromOffset(240, 28),
		Text = "Daily Login",
		TextColor3 = T.Text,
		TextSize = 24,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = header,
	})

	New.Text({
		Name = "Subtitle",
		Position = UDim2.fromOffset(0, 28),
		Size = UDim2.fromOffset(240, 18),
		Text = "Log in every day for free rewards",
		TextColor3 = T.SubText,
		TextSize = 13,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = header,
	})

	-- Chips Container (Streak & Resets In)
	local chips = New("Frame", {
		Name = "Chips",
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -44, 0.5, 0),
		Size = UDim2.fromOffset(340, 32),
		BackgroundTransparency = 1,
		Parent = header,
		[New.Children] = {
			New("UIListLayout", {
				FillDirection = Enum.FillDirection.Horizontal,
				HorizontalAlignment = Enum.HorizontalAlignment.Right,
				VerticalAlignment = Enum.VerticalAlignment.Center,
				Padding = UDim.new(0, 8),
			}),
		},
	})

	-- Streak Chip
	local streakChip = New("Frame", {
		Name = "StreakChip",
		Size = UDim2.fromOffset(0, 28),
		AutomaticSize = Enum.AutomaticSize.X,
		BackgroundColor3 = T.TintButter,
		Parent = chips,
		[New.Children] = {
			New.Pill(),
			New.Stroke(T.GoldLip, 1),
			New("UIPadding", {
				PaddingLeft = UDim.new(0, 10),
				PaddingRight = UDim.new(0, 10),
			}),
		} :: { Instance },
	})
	New.Text({
		Name = "StreakText",
		Size = UDim2.fromOffset(0, 26),
		AutomaticSize = Enum.AutomaticSize.X,
		Text = "Streak: 1 Day",
		TextColor3 = T.GoldLip,
		FontFace = T.FontBadge,
		TextSize = 12,
		Parent = streakChip,
	})

	-- Reset Timer Chip
	local resetChip = New("Frame", {
		Name = "ResetChip",
		Size = UDim2.fromOffset(0, 28),
		AutomaticSize = Enum.AutomaticSize.X,
		BackgroundColor3 = T.PanelLight,
		Parent = chips,
		[New.Children] = {
			New.Pill(),
			New.Stroke(T.Track, 1),
			New("UIPadding", {
				PaddingLeft = UDim.new(0, 10),
				PaddingRight = UDim.new(0, 10),
			}),
		} :: { Instance },
	})
	New.Text({
		Name = "ResetText",
		Size = UDim2.fromOffset(0, 26),
		AutomaticSize = Enum.AutomaticSize.X,
		Text = "Resets in --:--",
		TextColor3 = T.SubText,
		FontFace = T.FontBadge,
		TextSize = 12,
		Parent = resetChip,
	})

	-- Close Button (36x36)
	local closeBtn = New.Button({
		Name = "Close",
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, 0, 0, 0),
		Size = UDim2.fromOffset(36, 36),
		BackgroundColor3 = T.Bad,
		Text = "X",
		TextColor3 = T.OnAccent,
		TextSize = 16,
		Parent = header,
	})
	New.Corner(18).Parent = closeBtn

	-- Grid Container for 7 Days
	local grid = New("Frame", {
		Name = "Grid",
		Position = UDim2.fromOffset(0, 62),
		Size = UDim2.new(1, 0, 0, 290),
		BackgroundTransparency = 1,
		Parent = content,
	})

	-- Row 1: Days 1 to 4
	local row1 = New("Frame", {
		Name = "Row1",
		Position = UDim2.fromOffset(0, 0),
		Size = UDim2.new(1, 0, 0, 138),
		BackgroundTransparency = 1,
		Parent = grid,
		[New.Children] = {
			New("UIListLayout", {
				FillDirection = Enum.FillDirection.Horizontal,
				HorizontalAlignment = Enum.HorizontalAlignment.Center,
				Padding = UDim.new(0, 10),
			}),
		},
	})

	-- Row 2: Days 5, 6, 7
	local row2 = New("Frame", {
		Name = "Row2",
		Position = UDim2.fromOffset(0, 146),
		Size = UDim2.new(1, 0, 0, 138),
		BackgroundTransparency = 1,
		Parent = grid,
		[New.Children] = {
			New("UIListLayout", {
				FillDirection = Enum.FillDirection.Horizontal,
				HorizontalAlignment = Enum.HorizontalAlignment.Center,
				Padding = UDim.new(0, 10),
			}),
		},
	})

	-- Builder for a Day Card (clone config module to avoid Studio require caching)
	local cfgClone = Config:WaitForChild("DailyLogin"):Clone()
	local daysConfig = (require(cfgClone) :: any).Days
	cfgClone:Destroy()
	for i = 1, 7 do
		local dayData = daysConfig[i]
		local isDay7 = (i == 7)
		local cardWidth = if isDay7 then 270 else 152
		local parentRow = if i <= 4 then row1 else row2

		local card = New("Frame", {
			Name = `DayCard{i}`,
			Size = UDim2.fromOffset(cardWidth, 136),
			BackgroundColor3 = if isDay7 then T.TintButter else T.PanelLight,
			Parent = parentRow,
			[New.Children] = {
				New.Corner(16),
				New.Stroke(if isDay7 then T.GoldLip else T.Track, if isDay7 then 2 else 1.5),
				New("UIPadding", {
					PaddingTop = UDim.new(0, 8),
					PaddingBottom = UDim.new(0, 8),
					PaddingLeft = UDim.new(0, 8),
					PaddingRight = UDim.new(0, 8),
				}),
			} :: { Instance },
		})

		-- Day Header Label
		New.Title({
			Name = "DayTitle",
			Size = UDim2.new(1, 0, 0, 18),
			Text = if isDay7 then "DAY 7 - GRAND REWARD" else dayData.Title,
			TextColor3 = if isDay7 then T.GoldLip else T.Text,
			TextSize = 13,
			Parent = card,
		})

		-- Reward Icon Box
		New("Frame", {
			Name = "IconBox",
			AnchorPoint = Vector2.new(0.5, 0),
			Position = UDim2.new(0.5, 0, 0, 24),
			Size = UDim2.fromOffset(56, 56),
			BackgroundColor3 = Color3.new(1, 1, 1),
			Parent = card,
			[New.Children] = {
				New.Corner(12),
				New.Stroke(T.Track, 1),
				New.Image({
					Name = "Icon",
					Key = dayData.Reward.Icon,
					Size = UDim2.fromOffset(46, 46),
					AnchorPoint = Vector2.new(0.5, 0.5),
					Position = UDim2.fromScale(0.5, 0.5),
				}),
			} :: { Instance },
		})

		-- Reward Text Label
		New.Text({
			Name = "RewardText",
			Position = UDim2.fromOffset(0, 84),
			Size = UDim2.new(1, 0, 0, 20),
			Text = dayData.Reward.Title,
			TextColor3 = T.Text,
			FontFace = T.FontBadge,
			TextSize = 12,
			Parent = card,
		})

		-- Status Pill Badge (Claimed / Ready / Locked)
		local statusBadge = New("Frame", {
			Name = "StatusBadge",
			AnchorPoint = Vector2.new(0.5, 1),
			Position = UDim2.new(0.5, 0, 1, 0),
			Size = UDim2.fromOffset(if isDay7 then 120 else 80, 20),
			BackgroundColor3 = T.Track,
			Parent = card,
			[New.Children] = {
				New.Pill(),
			} :: { Instance },
		})

		New.Text({
			Name = "StatusText",
			Size = UDim2.fromScale(1, 1),
			Text = "LOCKED",
			TextColor3 = T.SubText,
			FontFace = T.FontBadge,
			TextSize = 10,
			Parent = statusBadge,
		})
	end

	-- Bottom Footer: Main Claim Button (48px height)
	local footer = New("Frame", {
		Name = "Footer",
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, 0),
		Size = UDim2.new(1, 0, 0, 52),
		BackgroundTransparency = 1,
		Parent = content,
	})

	local claimBtn = New.Button({
		Name = "ClaimBtn",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(280, 48),
		BackgroundColor3 = T.Good,
		Text = "CLAIM REWARD",
		TextColor3 = T.OnAccent,
		TextSize = 18,
		Parent = footer,
	})
	New.Corner(16).Parent = claimBtn

	return gui
end

return Screen
