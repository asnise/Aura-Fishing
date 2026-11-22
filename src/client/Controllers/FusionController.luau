--!nonstrict
-- Rod Fusion window (Figma "Screen 19 - Rod Fusion steps" 3782:24507), opened from Old Marlin's dialogue
-- (Config/Dialogues action "Fusion"). Four steps, then a result:
--   1 Base      the rod that keeps its Enhance and gets the new mod
--   2 Material  a rod of the same model, not worn (destroyed)
--   3 Type      Prefix or Suffix
--   4 Compare   one Base slot + one Material mod (a pick locks the other options of its side), cost, FUSE
--   5 Result    FUSED or FUSION FAILED (5%: only the Material rod is lost)
-- The window only previews (Shared/Items/Fusion); the server rolls and charges (FusionService, remote FuseRods).

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Registry = require(Shared.Registry)
local Remotes = require(Shared.Remotes)
local Inventory = require(Shared.Inventory)
local Fusion = require(Shared.Items.Fusion)
local Format = require(Shared.Util.Format)

local UI = script.Parent.Parent.UI
local New = require(UI.New)
local Window = require(UI.Window)
local Modal = require(UI.Modal)
local HUD = require(script.Parent.HUDController)
local DataController = require(script.Parent.DataController)

local T = New.Theme

local FusionController = {}

local STEP_NAMES = { "Base", "Material", "Type", "Compare" }

local shell: any = nil
local body: Frame? = nil
local busy = false

local step = 1
local baseUuid: string? = nil
local matUuid: string? = nil
local kind: string? = nil -- "Prefixes" | "Suffixes"
local baseIdx: number? = nil
local matIdx: number? = nil
local result: any = nil
local guard = false -- pay Gems for a sure success (optional)

local render: () -> ()

-- Small builders ---------------------------------------------------------------------------------------

local function profile(): any
	return DataController.Profile
end

local function modText(mod: any): string
	return `{mod.Name}  {Format.Mod(mod.Stat, Registry.StatDefs, mod.Value)}`
end

local function modColor(mod: any, sectionKind: string): Color3
	if mod.Value < 0 then
		return T.Bad -- cursed roll
	end
	return if sectionKind == "Prefixes" then T.Sky else T.Gem
end

local function label(parent: Instance, text: string, size: number, color: Color3?, order: number?, font: Font?): TextLabel
	local l = New.Text({
		Size = UDim2.new(1, 0, 0, size + 6),
		Text = text,
		TextSize = size,
		TextColor3 = color or T.Text,
		TextXAlignment = Enum.TextXAlignment.Left,
		LayoutOrder = order or 0,
		Parent = parent,
	})
	if font then
		l.FontFace = font
	end
	return l
end

local function chipRow(parent: Instance, rod: any, order: number): Frame
	local row = New("Frame", {
		Name = "Mods",
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		LayoutOrder = order,
		Parent = parent,
		[New.Children] = { New("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Wraps = true, Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }) },
	})
	local n = 0
	for _, sec in { { "Prefixes", rod.Prefixes }, { "Suffixes", rod.Suffixes } } do
		for _, mod in sec[2] or {} do
			n += 1
			local c = New.Text({
				Size = UDim2.fromOffset(0, 24),
				AutomaticSize = Enum.AutomaticSize.X,
				BackgroundTransparency = 0,
				BackgroundColor3 = modColor(mod, sec[1]),
				Text = modText(mod),
				TextSize = 13,
				TextColor3 = Color3.new(1, 1, 1),
				LayoutOrder = n,
				Parent = row,
				[New.Children] = { New.Pill(), New("UIPadding", { PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10) }) },
			})
			c.TextScaled = false
			c.AutomaticSize = Enum.AutomaticSize.X
		end
	end
	if n == 0 then
		label(row, "No mods", 13, T.SubText)
	end
	return row
end

local function rodCell(parent: Instance, rod: any, color: Color3?, onPress: () -> ()): TextButton
	local b = New("TextButton", {
		Name = "Rod",
		Size = UDim2.fromOffset(64, 64),
		BackgroundColor3 = Color3.new(1, 1, 1),
		Text = "",
		AutoButtonColor = false,
		Parent = parent,
		[New.Children] = { New.Corner(14), New.Stroke(color or T.Track, if color then 3 else 1) },
	}) :: TextButton
	New.Image({ Key = `equipment/{rod.Id}`, Fallback = T.PanelLight, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(52, 52), Parent = b })
	if (rod.Enhance or 0) > 0 then
		New.Text({ AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 4, 1, -2), Size = UDim2.fromOffset(28, 16), Text = `+{rod.Enhance}`, TextSize = 12, TextColor3 = T.GemLip, ZIndex = 3, Parent = b })
	end
	b.Activated:Connect(onPress)
	return b
end

-- count = how many rods: the grid is only as tall as its rows (5 per row, 3 rows visible, then it scrolls)
local function grid(parent: Instance, order: number, count: number): ScrollingFrame
	return New("ScrollingFrame", {
		Name = "Rods",
		Size = UDim2.new(1, 0, 0, math.clamp(math.ceil(math.max(count, 1) / 5), 1, 3) * 72 + 4),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollBarThickness = 3,
		LayoutOrder = order,
		Parent = parent,
		[New.Children] = { New("UIGridLayout", { CellSize = UDim2.fromOffset(64, 64), CellPadding = UDim2.fromOffset(8, 8), SortOrder = Enum.SortOrder.LayoutOrder }), New("UIPadding", { PaddingTop = UDim.new(0, 3), PaddingLeft = UDim.new(0, 3) }) },
	}) :: ScrollingFrame
end

local function button(parent: Instance, text: string, color: Color3, enabled: boolean, onClick: (() -> ())?, widthScale: number, order: number): TextButton
	local b = New.Button({
		Size = UDim2.new(widthScale, -6, 0, 48),
		Text = text,
		TextSize = 16,
		BackgroundColor3 = if enabled then color else T.Disabled,
		LayoutOrder = order,
		Parent = parent,
	})
	if not enabled then
		New.SetButtonColor(b, T.Disabled, T.DisabledText)
	end
	b.Activated:Connect(function()
		if enabled and onClick and not busy then
			onClick()
		end
	end)
	return b
end

local function footer(parent: Instance, backText: string, onBack: () -> (), nextText: string?, nextEnabled: boolean?, onNext: (() -> ())?)
	local row = New("Frame", {
		Name = "Footer",
		Size = UDim2.new(1, 0, 0, 48),
		BackgroundTransparency = 1,
		LayoutOrder = 100,
		Parent = parent,
		[New.Children] = { New("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 12), HorizontalAlignment = Enum.HorizontalAlignment.Center, SortOrder = Enum.SortOrder.LayoutOrder }) },
	})
	button(row, backText, T.PanelLight, true, onBack, 0.5, 1)
	if nextText then
		button(row, nextText, T.Good, nextEnabled == true, onNext, 0.5, 2)
	end
end

local function stepBar(parent: Instance)
	local row = New("Frame", {
		Name = "Steps",
		Size = UDim2.new(1, 0, 0, 28),
		BackgroundTransparency = 1,
		LayoutOrder = 1,
		Parent = parent,
		[New.Children] = { New("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 6), HorizontalAlignment = Enum.HorizontalAlignment.Center, VerticalAlignment = Enum.VerticalAlignment.Center, SortOrder = Enum.SortOrder.LayoutOrder }) },
	})
	for i, name in STEP_NAMES do
		local face = if i == step then T.Gold elseif i < step then T.Good else T.PanelLight
		New.Text({ Size = UDim2.fromOffset(26, 26), BackgroundTransparency = 0, BackgroundColor3 = face, Text = tostring(i), TextSize = 13, TextColor3 = if i <= step then Color3.new(1, 1, 1) else T.SubText, LayoutOrder = i * 2, Parent = row, [New.Children] = { New.Pill() } })
		New.Text({ Size = UDim2.fromOffset(0, 20), AutomaticSize = Enum.AutomaticSize.X, Text = name, TextSize = 12, TextColor3 = if i == step then T.Text else T.SubText, LayoutOrder = i * 2 + 1, Parent = row }).TextScaled = false
	end
end

-- State helpers ----------------------------------------------------------------------------------------

local function findRod(uuid: string?): any
	local p = profile()
	local item = p and uuid and Inventory.Find(p, uuid)
	return if item and item.Kind == "Rod" then item else nil
end

local function reset()
	step, baseUuid, matUuid, kind, baseIdx, matIdx, result, guard = 1, nil, nil, nil, nil, nil, nil, false
end

local function currentPlan(): (any, string?)
	local p, base, mat = profile(), findRod(baseUuid), findRod(matUuid)
	if not (p and base and mat and kind and baseIdx and matIdx) then
		return nil, nil
	end
	return Fusion.Plan(p, base, mat, kind, baseIdx, matIdx)
end

local doFuse: () -> ()

-- The Material rod is destroyed: ask first when it carries Enhance or more mods than the one being taken.
local function fuse()
	local mat = findRod(matUuid)
	if not mat or busy then
		return
	end
	local mods = #(mat.Prefixes or {}) + #(mat.Suffixes or {})
	local plus = mat.Enhance or 0
	if plus <= 0 and mods <= 1 then
		doFuse()
		return
	end
	local what = if plus > 0 then `+{plus}` else ""
	if mods > 1 then
		what ..= (if plus > 0 then " and " else "") .. `{mods} mods`
	end
	Modal.Confirm({
		Title = "Destroy the Material rod?",
		Message = `The Material rod has {what}. It is destroyed when you fuse, and only one mod moves over.`,
		ConfirmText = "Fuse",
		ConfirmColor = T.Good,
		Icon = "ui/status/sell_bag",
		IconColor = T.Bad,
	}, doFuse)
end

doFuse = function()
	local plan = currentPlan()
	if not plan or busy then
		return
	end
	busy = true
	local ok, a, msg, res = pcall(function()
		return Remotes.Func("FuseRods"):InvokeServer(baseUuid, matUuid, kind, baseIdx, matIdx, guard and plan.GuardGems > 0)
	end)
	busy = false
	if not ok or not a then
		HUD.Notify(if ok and type(msg) == "string" then msg else "Something went wrong, try again", T.Bad)
		return
	end
	result = res or { Success = false }
	result.Mod = plan.Mod
	result.RodId = findRod(baseUuid) and findRod(baseUuid).Id
	step = 5
	render()
end

-- Steps ------------------------------------------------------------------------------------------------

local function stepBase(parent: Instance)
	local p = profile()
	label(parent, "Choose base rod", 14, T.SubText, 2)
	local rodCount = 0
	for _, item in p.Bag do
		if item.Kind == "Rod" then
			rodCount += 1
		end
	end
	local g = grid(parent, 3, rodCount)
	local any = false
	for i, item in p.Bag do
		if item.Kind == "Rod" then
			any = true
			local cell = rodCell(g, item, if item.UUID == baseUuid then T.Good else nil, function()
				baseUuid = item.UUID
				matUuid = nil
				render()
			end)
			cell.LayoutOrder = i
		end
	end
	if not any then
		label(parent, "You have no rods.", 14, T.SubText, 4)
	end
	local base = findRod(baseUuid)
	if base then
		chipRow(parent, base, 5)
	end
	footer(parent, "Close", function()
		shell.Close()
	end, "NEXT", base ~= nil, function()
		step = 2
		render()
	end)
end

local function stepMaterial(parent: Instance)
	local p = profile()
	local base = findRod(baseUuid)
	label(parent, `Base: {Registry.Equipment.Rods.Items[base.Id].Name}`, 14, T.GemLip, 2)
	label(parent, "Choose material rod (same type)", 14, T.SubText, 3)
	local matCount = 0
	for _, item in p.Bag do
		if Fusion.CanUseAsMaterial(p, base, item) then
			matCount += 1
		end
	end
	local g = grid(parent, 4, matCount)
	local any = false
	for i, item in p.Bag do
		if Fusion.CanUseAsMaterial(p, base, item) then
			any = true
			local cell = rodCell(g, item, if item.UUID == matUuid then T.Bad else nil, function()
				matUuid = item.UUID
				render()
			end)
			cell.LayoutOrder = i
		end
	end
	if not any then
		label(parent, "No matching rod. You need a second one that is not worn.", 13, T.SubText, 5)
	end
	local mat = findRod(matUuid)
	if mat then
		chipRow(parent, mat, 6)
	end
	footer(parent, "Back", function()
		step = 1
		render()
	end, "NEXT", mat ~= nil, function()
		step = 3
		kind, baseIdx, matIdx = nil, nil, nil
		render()
	end)
end

local function stepType(parent: Instance)
	local mat = findRod(matUuid)
	label(parent, "Choose mod type", 16, T.Text, 2, T.Font)
	for i, k in { "Prefixes", "Suffixes" } do
		local n = #Fusion.ModList(mat, k)
		local nice = if k == "Prefixes" then "Prefix" else "Suffix"
		button(parent, if n > 0 then `{nice}  ({n})` else `{nice}  (none)`, if k == "Prefixes" then T.Sky else T.Gem, n > 0, function()
			kind, baseIdx, matIdx = k, nil, nil
			step = 4
			render()
		end, 1, 2 + i).Size = UDim2.new(1, 0, 0, 52)
	end
	footer(parent, "Back", function()
		step = 2
		render()
	end)
end

local function checkbox(parent: Instance, on: boolean, tint: Color3, locked: boolean)
	local box = New("Frame", {
		Name = "Check",
		Size = UDim2.fromOffset(20, 20),
		BackgroundColor3 = Color3.new(1, 1, 1),
		Parent = parent,
		[New.Children] = { New.Corner(5), New.Stroke(if locked then T.Track else tint, 2) },
	})
	if on then
		New("Frame", { Name = "Selected", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(10, 10), BackgroundColor3 = tint, Parent = box, [New.Children] = { New.Corner(3) } })
	end
end

-- One selectable option in a Compare column. mod = nil: an empty Base slot.
local function option(parent: Instance, mod: any, sub: string, selected: boolean, locked: boolean, tint: Color3, onToggle: () -> ()): TextButton
	local b = New("TextButton", {
		Size = UDim2.new(1, 0, 0, 46),
		BackgroundColor3 = if selected then T.Good elseif locked then T.PanelLight else Color3.new(1, 1, 1),
		Text = "",
		AutoButtonColor = false,
		Parent = parent,
		[New.Children] = { New.Corner(12), New.Stroke(if selected then T.GoodLip else T.Track, if selected then 2 else 1), New("UIPadding", { PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 6) }), New("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 6), VerticalAlignment = Enum.VerticalAlignment.Center, SortOrder = Enum.SortOrder.LayoutOrder }) },
	}) :: TextButton
	checkbox(b, selected, if mod and mod.Value < 0 then T.Bad else tint, locked)
	local texts = New("Frame", { Size = UDim2.new(1, -30, 1, 0), BackgroundTransparency = 1, LayoutOrder = 2, Parent = b, [New.Children] = { New("UIListLayout", { VerticalAlignment = Enum.VerticalAlignment.Center, SortOrder = Enum.SortOrder.LayoutOrder }) } })
	local top = label(texts, if mod then modText(mod) else "Empty slot", 12, if locked then T.SubText else T.Text, 1)
	top.Size = UDim2.new(1, 0, 0, 18)
	local s = label(texts, sub, 11, T.SubText, 2)
	s.Size = UDim2.new(1, 0, 0, 14)
	b.Activated:Connect(function()
		if not locked then
			onToggle()
		end
	end)
	return b
end

local function costRow(parent: Instance, plan: any, order: number)
	local p = profile()
	local row = New("Frame", { Name = "Cost", Size = UDim2.new(1, 0, 0, 24), BackgroundTransparency = 1, LayoutOrder = order, Parent = parent, [New.Children] = { New("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 12), HorizontalAlignment = Enum.HorizontalAlignment.Center, VerticalAlignment = Enum.VerticalAlignment.Center, SortOrder = Enum.SortOrder.LayoutOrder }) } })
	New.Text({ Size = UDim2.fromOffset(34, 20), Text = "Cost", TextSize = 12, TextColor3 = T.SubText, LayoutOrder = 1, Parent = row })
	local function cur(key: string, amount: number, have: number, o: number)
		local f = New("Frame", { Size = UDim2.fromOffset(0, 22), AutomaticSize = Enum.AutomaticSize.X, BackgroundTransparency = 1, LayoutOrder = o, Parent = row, [New.Children] = { New("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 4), VerticalAlignment = Enum.VerticalAlignment.Center, SortOrder = Enum.SortOrder.LayoutOrder }) } })
		New.Image({ Key = key, Fallback = T.Gold, Size = UDim2.fromOffset(20, 20), LayoutOrder = 1, Parent = f })
		local t = New.Text({ Size = UDim2.fromOffset(0, 20), AutomaticSize = Enum.AutomaticSize.X, Text = if plan then Format.Number(amount) else "-", TextSize = 15, TextColor3 = if plan and have < amount then T.Bad else T.Text, LayoutOrder = 2, Parent = f })
		t.TextScaled = false
	end
	cur("ui/status/coin", plan and plan.Coins or 0, p.Coins, 2)
	if plan and plan.Pearls > 0 then
		cur("ui/status/pearl", plan.Pearls, math.floor(p.Pearls), 3)
	end
end

-- Optional Guard row: tick to pay Gems and skip the fail chance.
local function guardRow(parent: Instance, plan: any, order: number)
	if not plan or plan.GuardGems <= 0 then
		guard = false
		return
	end
	local p = profile()
	local afford = p.Gems >= plan.GuardGems
	if not afford then
		guard = false
	end
	local row = New("TextButton", {
		Name = "Guard",
		Size = UDim2.new(1, 0, 0, 34),
		BackgroundColor3 = if guard then T.Good else Color3.new(1, 1, 1),
		Text = "",
		AutoButtonColor = false,
		LayoutOrder = order,
		Parent = parent,
		[New.Children] = { New.Corner(10), New.Stroke(if guard then T.GoodLip else T.Track, 2), New("UIPadding", { PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8) }), New("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 8), VerticalAlignment = Enum.VerticalAlignment.Center, SortOrder = Enum.SortOrder.LayoutOrder }) },
	}) :: TextButton
	checkbox(row, guard, T.Good, not afford)
	local t = New.Text({ Size = UDim2.new(1, -100, 0, 20), Text = "Guard: sure success", TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = if afford then T.Text else T.SubText, LayoutOrder = 2, Parent = row })
	t.TextScaled = false
	New.Image({ Key = "ui/status/gem", Fallback = T.Gem, Size = UDim2.fromOffset(18, 18), LayoutOrder = 3, Parent = row })
	local g = New.Text({ Size = UDim2.fromOffset(0, 20), AutomaticSize = Enum.AutomaticSize.X, Text = Format.Number(plan.GuardGems), TextSize = 14, TextColor3 = if afford then T.Text else T.Bad, LayoutOrder = 4, Parent = row })
	g.TextScaled = false
	row.Activated:Connect(function()
		if afford then
			guard = not guard
			render()
		end
	end)
end

local function failNotice(parent: Instance, order: number)
	local box = New("Frame", {
		Name = "Fail notice",
		Size = UDim2.new(1, 0, 0, 34),
		BackgroundColor3 = Color3.fromRGB(255, 236, 236),
		LayoutOrder = order,
		Parent = parent,
		[New.Children] = { New.Corner(10), New.Stroke(Color3.fromRGB(242, 165, 165), 2), New("UIPadding", { PaddingLeft = UDim.new(0, 8) }), New("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 8), VerticalAlignment = Enum.VerticalAlignment.Center, SortOrder = Enum.SortOrder.LayoutOrder }) },
	})
	local pct = math.floor(Fusion.FailChance * 100 + 0.5)
	local tag = New.Text({ Size = UDim2.fromOffset(0, 20), AutomaticSize = Enum.AutomaticSize.X, BackgroundTransparency = 0, BackgroundColor3 = T.Bad, Text = `{pct}% FAIL`, TextSize = 12, TextColor3 = Color3.new(1, 1, 1), LayoutOrder = 1, Parent = box, [New.Children] = { New.Corner(8), New("UIPadding", { PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8) }) } })
	tag.TextScaled = false
	local t = New.Text({ Size = UDim2.new(1, -90, 0, 20), Text = "Only the Material rod is lost.", TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left, LayoutOrder = 2, Parent = box })
	t.TextScaled = false
end

local function stepCompare(parent: Instance)
	local base, mat = findRod(baseUuid), findRod(matUuid)
	local kind: string = kind :: string
	local isPrefix = kind == "Prefixes"
	local tint = if isPrefix then T.Sky else T.Gem
	label(parent, `Compare {if isPrefix then "Prefix" else "Suffix"}`, 16, T.Text, 2, T.Font)
	label(parent, "Uncheck a pick to unlock its other options.", 11, T.SubText, 3)

	local cols = New("Frame", { Name = "Columns", Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, LayoutOrder = 4, Parent = parent, [New.Children] = { New("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }) } })
	local function column(title: string, order: number): Frame
		return New("Frame", { Size = UDim2.new(0.5, -4, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, LayoutOrder = order, Parent = cols, [New.Children] = { New("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }) } })
	end
	local left, right = column("Base slot", 1), column("Material mod", 2)
	label(left, "Base slot", 12, T.SubText, 0)
	label(right, "Material mod", 12, T.SubText, 0)

	local baseList = Fusion.ModList(base, kind)
	for i = 1, Fusion.MaxSlots(kind) do
		local mod = baseList[i]
		local picked = baseIdx == i
		option(left, mod, `Slot {i}`, picked, baseIdx ~= nil and not picked, tint, function()
			baseIdx = if picked then nil else i
			render()
		end).LayoutOrder = i
	end
	for i, mod in Fusion.ModList(mat, kind) do
		local picked = matIdx == i
		option(right, mod, Registry.StatDefs[(string.gsub(mod.Stat, "^Max", ""))] and Registry.StatDefs[(string.gsub(mod.Stat, "^Max", ""))].Display or mod.Stat, picked, matIdx ~= nil and not picked, tint, function()
			matIdx = if picked then nil else i
			render()
		end).LayoutOrder = i
	end

	local plan, reason = currentPlan()
	local preview = New.Text({ Name = "Preview", Size = UDim2.new(1, 0, 0, 30), BackgroundTransparency = 0, BackgroundColor3 = T.PanelLight, Text = "", TextSize = 13, LayoutOrder = 5, Parent = parent, [New.Children] = { New.Corner(10) } })
	preview.TextScaled = false
	if plan then
		preview.Text = `Slot {plan.BaseIndex}  {if plan.Replaced then modText(plan.Replaced) else "Empty"}  >  {modText(plan.Mod)}`
	elseif reason and baseIdx and matIdx then
		preview.Text = reason
		preview.TextColor3 = T.Bad
	else
		preview.Text = "Pick a base slot and a material mod."
		preview.TextColor3 = T.SubText
	end
	costRow(parent, plan, 6)
	guardRow(parent, plan, 7)
	if not guard then
		failNotice(parent, 8)
	end

	local p = profile()
	local canPay = plan ~= nil and p.Coins >= plan.Coins and p.Pearls >= plan.Pearls
	footer(parent, "Back", function()
		step = 3
		baseIdx, matIdx = nil, nil
		render()
	end, "FUSE", canPay, fuse)
end

local function stepResult(parent: Instance)
	local ok = result and result.Success
	local banner = New.Text({ Size = UDim2.new(1, 0, 0, 48), BackgroundTransparency = 0, BackgroundColor3 = if ok then T.Good else T.Bad, Text = if ok then "FUSED" else "FUSION FAILED", TextSize = 24, TextColor3 = Color3.new(1, 1, 1), LayoutOrder = 2, Parent = parent, [New.Children] = { New.Corner(14) } })
	banner.TextScaled = false
	local base = findRod(baseUuid)
	if base then
		local cell = rodCell(parent, base, T.Good, function() end)
		cell.LayoutOrder = 3
		cell.Size = UDim2.fromOffset(72, 72)
		chipRow(parent, base, 4)
	end
	label(parent, if ok then `{result.Mod.Name} is now on your rod.` else "Material rod lost. Base rod unchanged.", 14, T.Text, 5)
	if ok then
		label(parent, `Paid {Format.Number(result.Coins)} coins{if result.Pearls > 0 then `, {Format.Number(result.Pearls)} Pearls` else ""}{if (result.Gems or 0) > 0 then ` and {Format.Number(result.Gems)} Gems (Guard)` else ""}.`, 12, T.SubText, 6)
	else
		label(parent, "Nothing was charged.", 12, T.SubText, 6)
	end
	local row = New("Frame", { Size = UDim2.new(1, 0, 0, 48), BackgroundTransparency = 1, LayoutOrder = 100, Parent = parent, [New.Children] = { New("UIListLayout", { HorizontalAlignment = Enum.HorizontalAlignment.Center, SortOrder = Enum.SortOrder.LayoutOrder }) } })
	button(row, "OK", T.Good, true, function()
		reset()
		render()
	end, 0.6, 1)
end

-- Window -----------------------------------------------------------------------------------------------

render = function()
	if not body then
		return
	end
	local p = profile()
	if not p then
		return
	end
	-- selections that disappeared (sold, fused) send the player back
	if step < 5 then
		if (baseUuid and not findRod(baseUuid)) or (matUuid and not findRod(matUuid)) then
			baseUuid, matUuid, kind, baseIdx, matIdx = if findRod(baseUuid) then baseUuid else nil, nil, nil, nil, nil
			step = if baseUuid then 2 else 1
		end
	end
	for _, c in body:GetChildren() do
		if not c:IsA("UIListLayout") then
			c:Destroy()
		end
	end
	if step < 5 then
		stepBar(body)
	end
	if step == 1 then
		stepBase(body)
	elseif step == 2 then
		stepMaterial(body)
	elseif step == 3 then
		stepType(body)
	elseif step == 4 then
		stepCompare(body)
	else
		stepResult(body)
	end
end

local function ensure()
	if shell then
		return
	end
	shell = Window.Shell({ Name = "RodFusion", Title = "Rod Fusion", Size = Vector2.new(400, 0), AutoHeight = true, WindowName = "Window Rod Fusion" })
	body = New("Frame", {
		Name = "Body",
		Position = UDim2.fromOffset(0, 66),
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		Parent = shell.Frame,
		[New.Children] = { New("UIListLayout", { Padding = UDim.new(0, 10), HorizontalAlignment = Enum.HorizontalAlignment.Center, SortOrder = Enum.SortOrder.LayoutOrder }) },
	}) :: Frame
	shell.OnOpen = function()
		reset()
		render()
	end
end

function FusionController.Open()
	ensure()
	shell.Open()
end

function FusionController.Init()
	DataController.Changed:Connect(function()
		if shell and shell.IsOpen() and step < 5 then
			render()
		end
	end)
	task.spawn(ensure)
end

return FusionController
