--!nonstrict
-- Daily Quests window, built to match Figma "C7 · Daily Quests — 3 Design Layouts" Option 1 (Classic Cozy Deck).
-- 760x610 cream window, r24:
--   Header          Title "Daily Quests" (Fredoka 26) + reset timer pill + Gems chip + red close button
--   QuestCards      daily quests and one milestone row

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Registry = require(Shared.Registry)
local Quests = require(Shared.Quests)
local Format = require(Shared.Util.Format)

local New = require(script.Parent.New)
local Window = require(script.Parent.Window)

local T = New.Theme
local WHITE = Color3.new(1, 1, 1)

export type QuestsScreenCallbacks = {
	OnClaim: (index: number) -> (),
	OnClose: () -> (),
}

local QuestsScreen = {}

local function pill(props: { [string]: any }): Frame
	local f = New("Frame", {
		Name = props.Name or "Pill",
		Size = UDim2.fromOffset(0, props.Height or 24),
		AutomaticSize = Enum.AutomaticSize.X,
		BackgroundColor3 = props.Color or T.Panel,
		BackgroundTransparency = props.Transparent and 1 or 0,
		LayoutOrder = props.Order or 0,
		[New.Children] = {
			New.Pill(),
			New("UIPadding", {
				PaddingLeft = UDim.new(0, props.PadL or 10),
				PaddingRight = UDim.new(0, props.PadR or 12),
				PaddingTop = UDim.new(0, props.PadT or 4),
				PaddingBottom = UDim.new(0, props.PadB or 4),
			}),
			New("UIListLayout", {
				FillDirection = Enum.FillDirection.Horizontal,
				Padding = UDim.new(0, props.Gap or 6),
				VerticalAlignment = Enum.VerticalAlignment.Center,
				HorizontalAlignment = Enum.HorizontalAlignment.Center,
				SortOrder = Enum.SortOrder.LayoutOrder,
			}),
		},
	}) :: Frame
	if props.Stroke then
		New.Stroke(props.StrokeColor or T.Track, props.StrokeW or 2).Parent = f
	end
	return f
end

-- Auto-width label measured with the real font (AutomaticSize ran before Fredoka/Nunito loaded,
-- so "Daily Quests" overlapped the timer pill).
local function fit(label: TextLabel): TextLabel
	New.FitTextWidth(label)
	return label
end

local function questIcon(q: any): string
	if q.Icon and q.Icon ~= "" then
		return q.Icon
	end
	local cfg = Registry.Quests[q.Id]
	if cfg then
		if cfg.Kind == "SellFish" then
			return "ui/icons/bag"
		elseif cfg.Kind == "CatchRarity" or cfg.Kind == "CatchMutated" then
			return "fish/AncientCoelacanth"
		elseif cfg.Kind == "Streak" then
			return "ui/status/pearl"
		elseif cfg.Kind == "PullAura" then
			return "ui/icons/auras"
		end
	end
	return "ui/icons/daily_login"
end

function QuestsScreen.Create(callbacks: QuestsScreenCallbacks)
	local screen = {}
	local gui: ScreenGui? = nil
	local timerLabel: TextLabel? = nil
	local gemsLabel: TextLabel? = nil
	local cardsHolder: Frame? = nil

	-- shell = Window core (ScreenGui in PlayerGui, panel, scale, open/close/register); header + X are its own
	local shell = Window.Shell({ Name = "Quests", WindowName = "WindowDailyQuests", Close = false, Padding = 0, Radius = 24, DisplayOrder = 15, Clip = true, Size = Vector2.new(760, 500) })
	gui = shell.Gui
	local card = shell.Frame
	card.Active = true

	local container = New("Frame", {
		Name = "Container",
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Parent = card,
		[New.Children] = {
			New("UIPadding", {
				PaddingTop = UDim.new(0, 20),
				PaddingBottom = UDim.new(0, 20),
				PaddingLeft = UDim.new(0, 22),
				PaddingRight = UDim.new(0, 22),
			}),
			New("UIListLayout", {
				FillDirection = Enum.FillDirection.Vertical,
				Padding = UDim.new(0, 12),
				SortOrder = Enum.SortOrder.LayoutOrder,
			}),
		},
	})

	-- 1. Header (Title + Timer + Gems + Close)
	local header = New("Frame", {
		Name = "Header",
		Size = UDim2.new(1, 0, 0, 57),
		BackgroundTransparency = 1,
		LayoutOrder = 1,
		Parent = container,
	})

	local titleGroup = New("Frame", {
		Name = "TitleGroup",
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.fromScale(0, 0.5),
		Size = UDim2.fromOffset(400, 30),
		BackgroundTransparency = 1,
		Parent = header,
		[New.Children] = {
			New("UIListLayout", {
				FillDirection = Enum.FillDirection.Horizontal,
				Padding = UDim.new(0, 12),
				VerticalAlignment = Enum.VerticalAlignment.Center,
				SortOrder = Enum.SortOrder.LayoutOrder,
			}),
		},
	})

	fit(New.Title({
		Name = "Title",
		Size = UDim2.fromOffset(0, 30),
		AutomaticSize = Enum.AutomaticSize.X,
		Text = "Daily Quests",
		TextSize = 26,
		TextColor3 = T.Text,
		LayoutOrder = 1,
		Parent = titleGroup,
	}))

	local timerPill = pill({
		Name = "TimerPill",
		Color = T.PanelLight,
		Height = 22,
		PadL = 8,
		PadR = 10,
		Gap = 6,
		Order = 2,
	})
	timerPill.Parent = titleGroup

	New.Image({
		Name = "TimerIcon",
		Key = "icon_timer",
		Size = UDim2.fromOffset(14, 14),
		ImageColor3 = T.SubText,
		LayoutOrder = 1,
		Parent = timerPill,
	})
	timerLabel = fit(New.Text({
		Name = "TimerLabel",
		Size = UDim2.new(0, 0, 1, 0),
		AutomaticSize = Enum.AutomaticSize.X,
		Text = "Resets in --h --m",
		TextSize = 12,
		FontFace = T.FontBadge,
		TextColor3 = T.SubText,
		LayoutOrder = 2,
		Parent = timerPill,
	}))

	local rightGroup = New("Frame", {
		Name = "RightGroup",
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, 0, 0.5, 0),
		Size = UDim2.fromOffset(240, 57),
		BackgroundTransparency = 1,
		Parent = header,
		[New.Children] = {
			New("UIListLayout", {
				FillDirection = Enum.FillDirection.Horizontal,
				Padding = UDim.new(0, 10),
				VerticalAlignment = Enum.VerticalAlignment.Center,
				HorizontalAlignment = Enum.HorizontalAlignment.Right,
				SortOrder = Enum.SortOrder.LayoutOrder,
			}),
		},
	})

	local gemsChip = pill({
		Name = "GemsChip",
		Color = T.Panel,
		Stroke = true,
		StrokeColor = T.Track,
		Height = 40,
		PadL = 8,
		PadR = 16,
		PadT = 6,
		PadB = 6,
		Gap = 8,
		Order = 1,
	})
	gemsChip.Parent = rightGroup

	New.Image({
		Name = "GemIcon",
		Key = "ui/status/gem",
		Size = UDim2.fromOffset(24, 24),
		LayoutOrder = 1,
		Parent = gemsChip,
	})
	gemsLabel = fit(New.Title({
		Name = "GemsVal",
		Size = UDim2.new(0, 0, 1, 0),
		AutomaticSize = Enum.AutomaticSize.X,
		Text = "0",
		TextSize = 20,
		TextColor3 = T.Text,
		LayoutOrder = 2,
		Parent = gemsChip,
	}))

	local closeBtn = New.Button({
		Name = "BtnClose",
		Size = UDim2.fromOffset(73, 57),
		Text = "X",
		BackgroundColor3 = T.Bad,
		TextSize = 22,
		TextColor3 = WHITE,
		Radius = 16,
		LayoutOrder = 2,
		Parent = rightGroup,
	})
	closeBtn.Activated:Connect(function()
		if callbacks.OnClose then
			callbacks.OnClose()
		end
	end)

	-- 2. Quest list
	cardsHolder = New("Frame", {
		Name = "CardsHolder",
		Size = UDim2.new(1, 0, 1, -69),
		BackgroundTransparency = 1,
		LayoutOrder = 2,
		Parent = container,
		[New.Children] = {
			New("UIListLayout", {
				FillDirection = Enum.FillDirection.Vertical,
				Padding = UDim.new(0, 10),
				SortOrder = Enum.SortOrder.LayoutOrder,
			}),
		},
	})

	-- Render functions
	function screen.Render(profile: any)
		if not profile then
			return
		end

		if gemsLabel then
			gemsLabel.Text = Format.Number(profile.Gems or 0)
		end

		local questsState = Quests.State(profile)
		local completedCount = 0
		for _, q in questsState do
			if q.Claimed then
				completedCount += 1
			end
		end

		-- Render Cards
		if cardsHolder then
			cardsHolder:ClearAllChildren()
			New("UIListLayout", {
				FillDirection = Enum.FillDirection.Vertical,
				Padding = UDim.new(0, 10),
				SortOrder = Enum.SortOrder.LayoutOrder,
				Parent = cardsHolder,
			})

			if #questsState == 0 then
				local _empty = New("Frame", {
					Name = "Empty",
					Size = UDim2.new(1, 0, 0, 120),
					BackgroundColor3 = T.PanelLight,
					Parent = cardsHolder,
					[New.Children] = {
						New.Corner(16),
						New.Title({
							Name = "Lbl",
							AnchorPoint = Vector2.new(0.5, 0.5),
							Position = UDim2.fromScale(0.5, 0.5),
							Size = UDim2.new(1, -40, 0, 30),
							Text = "No daily quests yet today. Check back tomorrow!",
							TextSize = 18,
							TextColor3 = T.SubText,
						}),
					},
				})
				return
			end

			local goal = #questsState
			table.insert(questsState, {
				Index = 0,
				Id = "DailyMilestone",
				Text = "Daily Milestone",
				Progress = completedCount,
				Target = goal,
				Done = completedCount >= goal,
				Claimed = completedCount >= goal,
				RewardGems = 0,
				Icon = "ui/icons/quests",
			})
			for idx, q in questsState do
				local isMilestone = q.Id == "DailyMilestone"
				local isClaimed = q.Claimed
				local isDone = q.Done and not isClaimed

				local cardFrame = New("Frame", {
					Name = if isMilestone then "DailyMilestone" else `QuestCard_{idx}`,
					Size = UDim2.new(1, 0, 0, 88),
					BackgroundColor3 = T.Panel,
					LayoutOrder = idx,
					Parent = cardsHolder,
					[New.Children] = {
						New.Corner(16),
						New.Stroke(if isDone then T.Gold else T.Track, if isClaimed then 1 else 2),
						New("UIPadding", {
							PaddingTop = UDim.new(0, 12),
							PaddingBottom = UDim.new(0, 12),
							PaddingLeft = UDim.new(0, 16),
							PaddingRight = UDim.new(0, 16),
						}),
						New("UIListLayout", {
							FillDirection = Enum.FillDirection.Horizontal,
							VerticalAlignment = Enum.VerticalAlignment.Center,
							Padding = UDim.new(0, 16),
							SortOrder = Enum.SortOrder.LayoutOrder,
						}),
					},
				})

				if isClaimed then
					cardFrame.BackgroundTransparency = 0.25
				end

				-- 1. Icon
				New.Image({
					Name = "Icon",
					Key = questIcon(q),
					Size = UDim2.fromOffset(48, 48),
					LayoutOrder = 1,
					Parent = cardFrame,
				})

				-- 2. Info (Title + Sub + Progress)
				local infoCol = New("Frame", {
					Name = "Info",
					Size = UDim2.new(0, 0, 1, 0),
					BackgroundTransparency = 1,
					LayoutOrder = 2,
					Parent = cardFrame,
					[New.Children] = {
						-- takes the width left after icon, reward chip and action (Figma: fill)
						New("UIFlexItem", { FlexMode = Enum.UIFlexMode.Fill }),
						New("UIListLayout", {
							FillDirection = Enum.FillDirection.Vertical,
							Padding = UDim.new(0, 4),
							VerticalAlignment = Enum.VerticalAlignment.Center,
							SortOrder = Enum.SortOrder.LayoutOrder,
						}),
					},
				})

				New.Title({
					Name = "QuestTitle",
					Size = UDim2.new(1, 0, 0, 24),
					Text = q.Text,
					TextSize = 20,
					TextColor3 = if isClaimed then T.SubText else T.Text,
					TextXAlignment = Enum.TextXAlignment.Left,
					TextTruncate = Enum.TextTruncate.AtEnd,
					LayoutOrder = 1,
					Parent = infoCol,
				})

				local descText = if isMilestone then "Claim all daily quests" elseif q.Done
					then "Goal reached!"
					else `Progress toward goal ({q.Progress}/{q.Target})`
				New.Text({
					Name = "QuestSub",
					Size = UDim2.new(1, 0, 0, 14),
					Text = descText,
					TextSize = 12,
					FontFace = T.FontBadge,
					TextColor3 = T.SubText,
					TextXAlignment = Enum.TextXAlignment.Left,
					LayoutOrder = 2,
					Parent = infoCol,
				})

				local progRow = New("Frame", {
					Name = "ProgressRow",
					Size = UDim2.new(1, 0, 0, 14),
					BackgroundTransparency = 1,
					LayoutOrder = 3,
					Parent = infoCol,
					[New.Children] = {
						New("UIListLayout", {
							FillDirection = Enum.FillDirection.Horizontal,
							Padding = UDim.new(0, 10),
							VerticalAlignment = Enum.VerticalAlignment.Center,
							SortOrder = Enum.SortOrder.LayoutOrder,
						}),
					},
				})

				local track = New("Frame", {
					Name = "Track",
					Size = UDim2.fromOffset(160, 10),
					BackgroundColor3 = T.Track,
					LayoutOrder = 1,
					Parent = progRow,
					[New.Children] = { New.Pill() },
				})

				local ratio = math.clamp(q.Progress / math.max(1, q.Target), 0, 1)
				New("Frame", {
					Name = "Fill",
					Size = UDim2.new(ratio, 0, 1, 0),
					BackgroundColor3 = if isDone then T.Gold elseif isClaimed and not isMilestone then T.Track else T.Good,
					Parent = track,
					[New.Children] = { New.Pill() },
				})

				local valText = if isClaimed
					then `{Format.Number(q.Target)} / {Format.Number(q.Target)}`
					elseif isDone then `{Format.Number(q.Target)} / {Format.Number(q.Target)} COMPLETED`
					else `{Format.Number(q.Progress)} / {Format.Number(q.Target)}`
				local valCol = if isClaimed then T.SubText elseif isDone then T.GoldLip else T.GoodLip
				fit(New.Text({
					Name = "Val",
					Size = UDim2.new(0, 0, 1, 0),
					AutomaticSize = Enum.AutomaticSize.X,
					Text = valText,
					TextSize = 12,
					FontFace = T.FontBadge,
					TextColor3 = valCol,
					LayoutOrder = 2,
					Parent = progRow,
				}))

				if not isMilestone then
					-- 3. Reward Chip
					local rewardChip = pill({
						Name = "RewardChip",
						Color = if isClaimed then T.Track else T.PanelLight,
						Height = 26,
						PadL = 8,
						PadR = 12,
						Gap = 6,
						Order = 3,
					})
					rewardChip.Parent = cardFrame
					New.Image({
						Name = "GemIcon",
						Key = "ui/status/gem",
						Size = UDim2.fromOffset(18, 18),
						LayoutOrder = 1,
						Parent = rewardChip,
					})
					fit(New.Title({
						Name = "Amount",
						Size = UDim2.new(0, 0, 1, 0),
						AutomaticSize = Enum.AutomaticSize.X,
						Text = `+{q.RewardGems} Gems`,
						TextSize = 13,
						TextColor3 = if isClaimed then T.SubText else Color3.fromHex("8C6FD6"),
						LayoutOrder = 2,
						Parent = rewardChip,
					}))
				end

				-- 4. Action
				if isDone then
					local claimBtn = New.Button({
						Name = "BtnClaim",
						Size = UDim2.fromOffset(110, 42),
						Text = "CLAIM",
						BackgroundColor3 = T.Good,
						TextSize = 16,
						TextColor3 = WHITE,
						Radius = 14,
						LayoutOrder = 4,
						Parent = cardFrame,
					})
					claimBtn.Activated:Connect(function()
						if callbacks.OnClaim then
							callbacks.OnClaim(q.Index)
						end
					end)
				elseif isClaimed then
					local claimedPill = pill({
						Name = "StatusClaimed",
						Color = T.Track,
						Height = 26,
						PadL = 16,
						PadR = 16,
						Order = 4,
					})
					claimedPill.Parent = cardFrame
					fit(New.Text({
						Name = "Tag",
						Size = UDim2.new(0, 0, 1, 0),
						AutomaticSize = Enum.AutomaticSize.X,
						Text = if isMilestone then "COMPLETED" else "CLAIMED",
						TextSize = 12,
						FontFace = T.FontBadge,
						TextColor3 = T.SubText,
						Parent = claimedPill,
					}))
				else
					local inProgPill = pill({
						Name = "StatusInProgress",
						Color = T.PanelLight,
						Height = 26,
						PadL = 14,
						PadR = 14,
						Order = 4,
					})
					inProgPill.Parent = cardFrame
					fit(New.Text({
						Name = "Tag",
						Size = UDim2.new(0, 0, 1, 0),
						AutomaticSize = Enum.AutomaticSize.X,
						Text = "IN PROGRESS",
						TextSize = 12,
						FontFace = T.FontBadge,
						TextColor3 = T.SubText,
						Parent = inProgPill,
					}))
				end
			end
		end
	end

	function screen.Tick()
		if timerLabel and gui and gui.Enabled then
			local leftSec = Quests.ResetsIn()
			local h = math.floor(leftSec / 3600)
			local m = math.floor((leftSec % 3600) / 60)
			timerLabel.Text = `Resets in {h}h {m}m`
		end
	end

	screen.Open = shell.Open
	screen.Close = shell.Close
	screen.IsOpen = shell.IsOpen

	return screen
end

return QuestsScreen
