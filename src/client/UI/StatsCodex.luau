--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local StatDefs = require(Shared.Config.StatDefs)
local ModifierDefs = require(Shared.Config.ModifierDefs)
local Mutations = require(Shared.Config.Mutations)

local New = require(script.Parent.New)
local Window = require(script.Parent.Window)
local Codex = require(script.Parent.StatsCodexEntries)

type Entry = Codex.Entry

local T = New.Theme
local TABS = { "All", "Stats", "Rod Mods", "Attributes" }
local StatsCodex = {}
local window: any

local function scroller(name: string, parent: Instance): ScrollingFrame
	return New("ScrollingFrame", {
		Name = name,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		CanvasSize = UDim2.fromOffset(0, 0),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollingDirection = Enum.ScrollingDirection.Y,
		ScrollBarThickness = 4,
		ScrollBarImageColor3 = T.Track,
		Parent = parent,
		[New.Children] = {
			New("UIListLayout", {
				Padding = UDim.new(0, 6),
				SortOrder = Enum.SortOrder.LayoutOrder,
			}),
			New("UIPadding", {
				PaddingTop = UDim.new(0, 8),
				PaddingLeft = UDim.new(0, 8),
				PaddingRight = UDim.new(0, 14),
				PaddingBottom = UDim.new(0, 12),
			}),
		},
	}) :: ScrollingFrame
end

local function detailText(name: string, order: number, parent: Instance, size: number, color: Color3, font: Font?): TextLabel
	return New.Text({
		Name = name,
		LayoutOrder = order,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Top,
		FontFace = font or T.FontBody,
		TextColor3 = color,
		TextSize = size,
		Parent = parent,
	})
end

local function build()
	local w = Window.Shell({ Name = "StatsCodex", Title = "Stats Codex", Size = Vector2.new(704, 440), Padding = 18 })
	local tabs = New("Frame", {
		Name = "Categories", BackgroundTransparency = 1,
		Position = UDim2.fromOffset(0, 62), Size = UDim2.new(1, 0, 0, 34), Parent = w.Frame,
	})
	local browse = New("Frame", {
		Name = "Index", BackgroundTransparency = 1, Position = UDim2.fromOffset(0, 108), Parent = w.Frame,
	})
	local search = New("TextBox", {
		Name = "Search", Size = UDim2.new(1, 0, 0, 38), BackgroundColor3 = T.OnAccent,
		BorderSizePixel = 0, ClearTextOnFocus = false, Text = "", PlaceholderText = "Search all entries",
		PlaceholderColor3 = T.SubText, TextColor3 = T.Text, FontFace = T.FontBody,
		TextSize = New.FigmaSize(T.FontBody, 15), TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd, Parent = browse,
		[New.Children] = { New.Corner(12) :: Instance, New.Stroke(T.Track, 2), New.Padding(9) },
	}) :: TextBox
	local list = scroller("Entries", browse)
	list.Position = UDim2.fromOffset(0, 48)
	list.Size = UDim2.new(1, 0, 1, -48)
	local empty = New.Text({
		Name = "Empty", Size = UDim2.new(1, 0, 0, 36), Text = "No matching entries.",
		TextSize = 14, TextColor3 = T.SubText, Parent = list,
	})
	local card = New.Panel({
		Name = "EntryDetail", BackgroundColor3 = T.OnAccent, Radius = 14, Parent = w.Frame,
		[New.Children] = { New.Padding(12) },
	})
	local detail = scroller("Explanation", card)
	local title = detailText("EntryTitle", 1, detail, 24, T.Text, T.Font)
	local group = detailText("Group", 2, detail, 14, T.SubText)
	local effect = detailText("Effect", 3, detail, 16, T.Text)
	local exampleBox = New.Panel({
		Name = "ExampleCard", LayoutOrder = 4, Size = UDim2.new(1, -2, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y, BackgroundColor3 = T.TintSky, Radius = 10,
		Parent = detail, [New.Children] = { New.Padding(10) },
	})
	local example = detailText("ExampleOrLimit", 1, exampleBox, 15, T.Text)
	local related = detailText("RelatedMods", 5, detail, 14, T.SubText)
	local back = New.Button({
		Name = "Btn Back", Text = "< All entries", TextSize = 14, BackgroundColor3 = T.PanelLight,
		TextColor3 = T.Text, Size = UDim2.fromOffset(112, 34), Parent = card,
	})
	local category = "All"
	local compact = false
	local reading = false
	local selected: Entry? = nil
	local groups: { [string]: TextLabel } = {}
	local rows: { { Entry: Entry, Button: TextButton } } = {}
	local tabButtons: { [string]: TextButton } = {}

	local function showReading()
		browse.Visible = not compact or not reading
		card.Visible = not compact or reading
		back.Visible = compact
		detail.Position = UDim2.fromOffset(0, if compact then 43 else 0)
		detail.Size = UDim2.new(1, 0, 1, if compact then -43 else 0)
	end

	local function selectEntry(entry: Entry?)
		if selected == entry then
			return
		end
		selected = entry
		for _, row in rows do
			row.Button.BackgroundColor3 = if row.Entry == entry then T.TintSky else T.PanelLight
		end
		title.Text = if entry then entry.Title else "No matching entries"
		group.Text = if entry then entry.Group .. (if entry.Rarity then "  /  " .. entry.Rarity else "") else ""
		group.Visible = group.Text ~= ""
		effect.Text = if entry then entry.Effect else "Try a different search or category."
		example.Text = if entry then entry.Detail or "" else ""
		exampleBox.Visible = example.Text ~= ""
		related.Text = if entry and entry.Related then "Related mods: " .. entry.Related else ""
		related.Visible = related.Text ~= ""
		detail.CanvasPosition = Vector2.zero
	end

	local function filter()
		for _, label in groups do
			label.Visible = false
		end
		local first: Entry? = nil
		local keepSelection = false
		for _, row in rows do
			local entry = row.Entry
			local matches = Codex.Matches(entry, category, search.Text)
			row.Button.Visible = matches
			if matches then
				groups[entry.Group].Visible = true
				first = first or entry
				keepSelection = keepSelection or selected == entry
			end
		end
		empty.Visible = first == nil
		if not keepSelection then
			selectEntry(first)
		end
		list.CanvasPosition = Vector2.zero
	end

	local order = 0
	for _, entry in Codex.Build(StatDefs, ModifierDefs, Mutations) do
		if not groups[entry.Group] then
			order += 1
			groups[entry.Group] = detailText("GroupTitle", order, list, 15, T.Text, T.Font)
			groups[entry.Group].Text = entry.Group
		end
		order += 1
		local button = New("TextButton", {
			Name = entry.Id, LayoutOrder = order, Size = UDim2.new(1, 0, 0, 36),
			Text = entry.Title, TextXAlignment = Enum.TextXAlignment.Left,
			TextColor3 = T.Text, FontFace = T.FontBody, TextSize = New.FigmaSize(T.FontBody, 15),
			TextTruncate = Enum.TextTruncate.AtEnd, BackgroundColor3 = T.PanelLight, BorderSizePixel = 0,
			Parent = list,
			[New.Children] = { New.Corner(9) :: Instance, New.Padding(8) },
		}) :: TextButton
		table.insert(rows, { Entry = entry, Button = button })
		button.Activated:Connect(function()
			selectEntry(entry)
			reading = true
			showReading()
		end)
	end

	for i, tab in TABS do
		local button = New.Button({
			Name = "Btn " .. tab, Text = tab, TextSize = 14, BackgroundColor3 = T.PanelLight, TextColor3 = T.Text,
			Position = UDim2.new((i - 1) / #TABS, 2, 0, 0), Size = UDim2.new(1 / #TABS, -4, 1, 0), Parent = tabs,
		})
		tabButtons[tab] = button
		button.Activated:Connect(function()
			category = tab
			search.PlaceholderText = if tab == "All" then "Search all entries" else "Search " .. string.lower(tab)
			for label, tabButton in tabButtons do
				New.SetButtonColor(tabButton, if label == tab then T.TintSky else T.PanelLight, T.Text)
			end
			reading = false
			showReading()
			filter()
		end)
	end
	New.SetButtonColor(tabButtons.All, T.TintSky, T.Text)
	search:GetPropertyChangedSignal("Text"):Connect(filter)
	back.Activated:Connect(function()
		reading = false
		showReading()
	end)

	local function layout()
		local viewport: Vector2 = w.Gui.AbsoluteSize
		compact = viewport.X > 0 and viewport.X < 630
		local width = if compact then math.clamp(viewport.X - 32, 282, 404) else 704
		local preferredHeight = if compact then 508 else 440
		local height = if viewport.Y > 0 then math.clamp(viewport.Y - 30, 286, preferredHeight) else preferredHeight
		w.Frame.Size = UDim2.fromOffset(width, height)
		browse.Size = if compact then UDim2.new(1, 0, 1, -108) else UDim2.new(0, 220, 1, -108)
		card.Position = UDim2.fromOffset(if compact then 0 else 232, 108)
		card.Size = UDim2.new(1, if compact then 0 else -232, 1, -108)
		showReading()
	end
	w.Gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(layout)
	w.OnOpen = function()
		reading = false
		layout()
	end
	w.OnClose = function()
		search:ReleaseFocus()
	end
	layout()
	filter()
	return w
end

function StatsCodex.Open()
	if not window then
		window = build()
	end
	window.Open()
end

return StatsCodex
