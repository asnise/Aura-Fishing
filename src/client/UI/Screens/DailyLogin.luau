--!strict
-- Screen builder for Daily Login calendar (7-day rewards).
-- Baked into StarterGui.DailyLogin.

local New = require(script.Parent.Parent.New)
local Config = game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("Config")

local T = New.Theme

local Screen = { Name = "DailyLogin" }

function Screen.MakeClaimedOverlay(card: Frame): Frame
	local overlay = New("Frame", {
		Name = "ClaimedOverlay",
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = T.Text,
		BackgroundTransparency = 0.5,
		Visible = false,
		ZIndex = 2,
		Parent = card,
		[New.Children] = { New.Corner(18) },
	}) :: Frame
	local stamp = New("Frame", {
		Name = "ClaimedStamp",
		Size = UDim2.fromOffset(42, 42),
		Position = UDim2.new(0.5, 0, 0.5, 2),
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundColor3 = T.Good,
		ZIndex = 3,
		Parent = overlay,
		[New.Children] = { New.Pill(), New.Stroke(T.GoodLip, 3) } :: { Instance },
	})
	New.Image({
		Name = "Check",
		Key = "icon_check",
		Tint = T.OnAccent,
		Size = UDim2.fromScale(0.67, 0.67),
		Position = UDim2.fromScale(0.5, 0.5),
		AnchorPoint = Vector2.new(0.5, 0.5),
		ZIndex = 4,
		Parent = stamp,
	})
	return overlay
end

function Screen.Layout(gui: any, viewport: Vector2)
	local portrait = viewport.X < 600
	local short = not portrait and viewport.Y < 520
	local compact = portrait or short
	local width = math.min(if portrait then 420 else 744, viewport.X - (if portrait then 16 else 24))
	local inner = width - 40
	local gap = if portrait then 8 else 10
	local shelfGap = 12
	local shelfWidth = if portrait then inner else math.floor(inner * 270 / 704)
	local trayWidth = if portrait then inner else inner - shelfWidth - shelfGap
	local cardWidth = math.floor((trayWidth - 2 * gap) / 3)
	local cardHeight = if portrait then 118 elseif short then 104 else 148
	local trayHeight = 2 * cardHeight + gap
	local gridHeight = if portrait then trayHeight + gap + cardHeight else trayHeight
	local headerHeight = if portrait then 84 elseif short then 44 else 57
	local footerHeight = if portrait then 52 elseif short then 44 else 57

	local window = gui.Backdrop.Window
	local content = window.Content
	local header, grid, footer = content.Header, content.Grid, content.Footer
	local row1, row2 = grid.Row1, grid.Row2
	local closeWidth = if compact then 44 else 73
	header.Size = UDim2.new(1, 0, 0, headerHeight)
	header.Close.Size = UDim2.fromOffset(closeWidth, if compact then 44 else 57)
	header.Chips.AnchorPoint = if portrait then Vector2.new(0, 1) else Vector2.new(1, 0.5)
	header.Chips.Position = if portrait then UDim2.new(0, 0, 1, 0) else UDim2.new(1, -closeWidth - 8, 0.5, 0)
	header.Chips.Size = UDim2.fromOffset(if portrait then inner else math.min(264, inner - closeWidth - 240), 32)
	header.Chips.UIListLayout.HorizontalAlignment = if portrait then Enum.HorizontalAlignment.Left else Enum.HorizontalAlignment.Right

	grid.Position = UDim2.fromOffset(0, headerHeight + 12)
	grid.Size = UDim2.new(1, 0, 0, gridHeight)
	row1.Size = UDim2.fromOffset(trayWidth, cardHeight)
	row2.Size = row1.Size
	row2.Position = UDim2.fromOffset(0, cardHeight + gap)
	row1.UIListLayout.Padding = UDim.new(0, gap)
	row2.UIListLayout.Padding = UDim.new(0, gap)
	for day = 1, 7 do
		local grand = day == 7
		local card = grid:FindFirstChild("DayCard" .. day, true)
		card.Parent = if grand then grid elseif day <= 3 then row1 else row2
		card.LayoutOrder = day
		card.Size = UDim2.fromOffset(if grand then shelfWidth else cardWidth, if grand and not portrait then trayHeight else cardHeight)
		card.Position = if grand then UDim2.fromOffset(if portrait then 0 else trayWidth + shelfGap, if portrait then trayHeight + gap else 0) else UDim2.fromOffset(0, 0)

		local tallGrand = grand and not compact
		local offset = if grand and short then math.floor((trayHeight - cardHeight) / 2) else 0
		local iconSize = if tallGrand then 96 elseif portrait then 40 elseif short then 32 else 52
		local iconTop = (if tallGrand then 104 elseif short then 31 elseif portrait then 33 else 46) + offset
		local amountTop = iconTop + iconSize + (if tallGrand then 14 elseif compact then 3 else 6)
		local tab = card:FindFirstChild("HeaderTab")
		if tab then
			tab.Size = UDim2.new(1, 0, 0, if tallGrand then 40 elseif compact then 26 else 34)
			tab.Peg1.Visible = not compact
			tab.Peg2.Visible = not compact
			if grand then
				tab.Peg3.Visible = not compact
			end
		end
		local grandTitle = card:FindFirstChild("GrandTitle")
		if grandTitle then
			grandTitle.Visible = tallGrand
		end
		card.DayTitle.Text = if grand and not tallGrand then "DAY 7 - GRAND REWARD" else "Day " .. day
		card.DayTitle.Position = UDim2.fromOffset(0, if compact then 4 elseif tallGrand then 12 else 10)
		card.DayTitle.Size = UDim2.new(1, 0, 0, if tallGrand then 22 else 19)
		card.DayTitle.TextSize = New.FigmaSize(T.Font, if tallGrand then 20 elseif compact then 13 else 16)
		card.IconBox.Position = UDim2.new(0.5, 0, 0, iconTop)
		card.IconBox.Size = UDim2.fromOffset(iconSize, iconSize)
		card.IconBox.Icon.Size = UDim2.fromScale(1, 1)
		card.RewardText.Position = UDim2.fromOffset(0, amountTop)
		local amountHeight = if tallGrand then 31 elseif compact then 17 else 16
		card.RewardText.Size = UDim2.new(1, 0, 0, amountHeight)
		card.RewardText.FontFace = if tallGrand then T.Font else T.FontBody
		card.RewardText.TextSize = New.FigmaSize(card.RewardText.FontFace, if tallGrand then 26 elseif compact then 12 else 14)
		card.StatusBadge.AnchorPoint = Vector2.new(0.5, 0)
		card.StatusBadge.Position = UDim2.new(0.5, 0, 0, amountTop + amountHeight + (if compact then 0 else 4))
		card.StatusBadge.Size = UDim2.fromOffset(58, if compact then 18 else 20)
	end

	footer.Size = UDim2.new(1, 0, 0, footerHeight)
	footer.ClaimBtn.Size = UDim2.fromOffset(math.min(296, inner), footerHeight)
	window.Size = UDim2.fromOffset(width, 42 + headerHeight + gridHeight + footerHeight + 24)
end

function Screen.Build(): ScreenGui
	local gui = New("ScreenGui", {
		Name = "DailyLogin",
		ResetOnSpawn = false,
		IgnoreGuiInset = false,
		Enabled = false,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		DisplayOrder = 20,
	}) :: ScreenGui

	-- Transparent input shield
	local backdrop = New("TextButton", {
		Name = "Backdrop",
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color3.new(0, 0, 0),
		BackgroundTransparency = 1, -- no black overlay (still blocks clicks behind)
		Text = "",
		AutoButtonColor = false,
		Parent = gui,
	})

	-- Main window
	local window = New.Panel({
		Name = "Window",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(744, 486),
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
				PaddingTop = UDim.new(0, 20),
				PaddingBottom = UDim.new(0, 22),
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
		TextSize = 26,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = header,
	})

	New.Text({
		Name = "Subtitle",
		Position = UDim2.fromOffset(0, 28),
		Size = UDim2.fromOffset(240, 18),
		Text = "Log in every day for free rewards",
		TextColor3 = T.SubText,
		TextSize = 14,
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
		LayoutOrder = 2,
		Size = UDim2.fromOffset(0, 30),
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
		LayoutOrder = 1,
		Size = UDim2.fromOffset(0, 30),
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

	-- Standard close button
	New.Button({
		Name = "Close",
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, 0, 0, 0),
		Size = UDim2.fromOffset(73, 57),
		BackgroundColor3 = T.Bad,
		Text = "X",
		TextColor3 = T.OnAccent,
		TextSize = 22,
		Parent = header,
	})

	-- Grid Container for 7 Days
	local grid = New("Frame", {
		Name = "Grid",
		Position = UDim2.fromOffset(0, 62),
		Size = UDim2.new(1, 0, 0, 290),
		BackgroundTransparency = 1,
		Parent = content,
	})

	local function rewardRow(name: string): Frame
		return New("Frame", {
			Name = name,
			BackgroundTransparency = 1,
			Parent = grid,
			[New.Children] = {
				New("UIListLayout", {
					FillDirection = Enum.FillDirection.Horizontal,
					SortOrder = Enum.SortOrder.LayoutOrder,
				}),
			},
		}) :: Frame
	end
	local row1 = rewardRow("Row1")
	local row2 = rewardRow("Row2")

	local cfgClone = Config:WaitForChild("DailyLogin"):Clone()
	local daysConfig = (require(cfgClone) :: any).Days
	cfgClone:Destroy()
	for i = 1, 7 do
		local dayData = daysConfig[i]
		local isDay7 = i == 7
		local parentRow = if isDay7 then grid elseif i <= 3 then row1 else row2
		local card = New("Frame", {
			Name = `DayCard{i}`,
			BackgroundColor3 = T.PanelPale,
			Parent = parentRow,
			[New.Children] = {
				New.Corner(18),
				New.Stroke(if isDay7 then T.Gold else T.Track, 2),
			} :: { Instance },
		}) :: Frame

		local tabColor = if isDay7 then T.Gold else T.SkyLip
		local tab = New("Frame", {
			Name = "HeaderTab",
			BackgroundColor3 = tabColor,
			Parent = card,
			[New.Children] = {
				New.Corner(18),
				New("Frame", {
					Name = "SquareEdge",
					Position = UDim2.fromScale(0, 0.5),
					Size = UDim2.fromScale(1, 0.5),
					BorderSizePixel = 0,
					BackgroundColor3 = tabColor,
				}),
			} :: { Instance },
		})
		local pegCount = if isDay7 then 3 else 2
		for peg = 1, pegCount do
			New("Frame", {
				Name = "Peg" .. peg,
				Position = UDim2.new(peg / (pegCount + 1), 0, 0, 4),
				AnchorPoint = Vector2.new(0.5, 0),
				Size = UDim2.fromOffset(16, 7),
				BackgroundColor3 = T.PanelPale,
				Parent = tab,
				[New.Children] = { New.Pill() },
			})
		end

		-- Day Header Label
		New.Title({
			Name = "DayTitle",
			Size = UDim2.new(1, 0, 0, 18),
			Text = dayData.Title,
			TextColor3 = T.OnAccent,
			TextSize = 13,
			Parent = card,
		})

		if isDay7 then
			New.Text({
				Name = "GrandTitle",
				Position = UDim2.new(0.5, 0, 0, 60),
				AnchorPoint = Vector2.new(0.5, 0),
				Size = UDim2.fromOffset(121, 25),
				BackgroundColor3 = T.TintButter,
				BackgroundTransparency = 0,
				Text = "GRAND REWARD",
				TextColor3 = T.GoldLip,
				FontFace = T.FontBadge,
				TextSize = 11,
				[New.Children] = { New.Pill(), New.Stroke(T.GoldLip, 1) } :: { Instance },
				Parent = card,
			})
		end

		New("Frame", {
			Name = "IconBox",
			AnchorPoint = Vector2.new(0.5, 0),
			Position = UDim2.new(0.5, 0, 0, 24),
			Size = UDim2.fromOffset(56, 56),
			BackgroundTransparency = 1,
			Parent = card,
			[New.Children] = {
				New.Image({
					Name = "Icon",
					Key = dayData.Reward.Icon,
					Size = UDim2.fromOffset(46, 46),
					AnchorPoint = Vector2.new(0.5, 0.5),
					Position = UDim2.fromScale(0.5, 0.5),
				}),
			} :: { Instance },
		})
		Screen.MakeClaimedOverlay(card)

		-- Reward Text Label
		New.Text({
			Name = "RewardText",
			Position = UDim2.fromOffset(0, 84),
			Size = UDim2.new(1, 0, 0, 20),
			Text = dayData.Reward.Title,
			TextColor3 = if isDay7 then T.GoldLip else T.Text,
			FontFace = if isDay7 then T.Font else T.FontBody,
			TextSize = 14,
			Parent = card,
		})

		-- Ready badge
		local statusBadge = New("Frame", {
			Name = "StatusBadge",
			AnchorPoint = Vector2.new(0.5, 1),
			Position = UDim2.new(0.5, 0, 1, 0),
			Size = UDim2.fromOffset(if isDay7 then 120 else 80, 20),
			BackgroundColor3 = T.Accent,
			Visible = false,
			Parent = card,
			[New.Children] = {
				New.Pill(),
			} :: { Instance },
		})

		New.Text({
			Name = "StatusText",
			Size = UDim2.fromScale(1, 1),
			Text = "READY",
			TextColor3 = T.OnAccent,
			FontFace = T.FontBadge,
			TextSize = 10,
			Parent = statusBadge,
		})
	end

	-- Claim footer
	local footer = New("Frame", {
		Name = "Footer",
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, 0),
		Size = UDim2.new(1, 0, 0, 52),
		BackgroundTransparency = 1,
		Parent = content,
	})

	New.Button({
		Name = "ClaimBtn",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(280, 48),
		BackgroundColor3 = T.Good,
		Text = "CLAIM REWARD",
		TextColor3 = T.OnAccent,
		TextSize = 22,
		Parent = footer,
	})

	Screen.Layout(gui, Vector2.new(1280, 720))
	return gui
end

return Screen
