--!nonstrict
-- VirtualGrid: virtualized grid/list for big scrolling collections (Roblox port of the Global Visualizer
-- concept, F:\GameProject\Pale Vertica\Packages\com.globalvisualizer.core).
--   * Only the cells you can see (+ Buffer rows) exist. 500 bag stacks cost about as much as 20.
--   * Views are pooled per kind and REUSED: scrolling or a data change only rebinds, never Destroy/Clone.
--   * Views are positioned by this module (absolute offsets); a UIGridLayout / UIListLayout already in the
--     scroll frame is read for CellSize / CellPadding / FillDirectionMaxCells and then removed.
--
-- local grid = VirtualGrid.new(scrollingFrame, {
--     Create = function(kind, grid) -> GuiObject      build ONE view (connect events here, once)
--     Bind   = function(view, item, index, kind)      fill a view for item (cheap: set props only)
--     Unbind = function(view, kind)?                  view returned to the pool
--     KindOf = function(item, index) -> string?       per-kind pools (default "Item")
--     CellSize = Vector2?, Gap = Vector2?, Columns = number? (default: from layout, else fit to width),
--     Buffer = number? (extra rows above/below, default 1),
-- })
-- grid:SetItems(list)        new data (same views, visible cells rebound)
-- grid:Refresh()             rebind the visible cells (data changed in place)
-- grid:NotifyChanged(i)      rebind one cell if it is visible
-- grid:ItemOf(view)          -> item, index   (use from click handlers connected in Create)
-- grid:ForEachVisible(fn)    fn(view, item, index, kind) for live per-frame updates (Tick)
-- grid:ScrollToTop() / grid:ScrollTo(i)
-- grid.Content               Frame holding the views (sized to the full collection height)
--
-- Rules (same as the Unity package): keep state in your data, not on views (views move between indices);
-- never connect events inside Bind (connect once in Create and look the item up with ItemOf).
--
-- Nested use: the scroll frame may be a plain Frame inside a ScrollingFrame (e.g. a Window body with a
-- bar above the grid); the nearest ScrollingFrame ancestor is used as the viewport.

local VirtualGrid = {}
VirtualGrid.__index = VirtualGrid

local DEFAULT_KIND = "Item"

local function offsetOf(u: UDim2?): Vector2?
	if not u then
		return nil
	end
	return Vector2.new(u.X.Offset, u.Y.Offset)
end

function VirtualGrid.new(parent: GuiObject, opts: { [string]: any })
	assert(opts.Create and opts.Bind, "[VirtualGrid] opts.Create and opts.Bind are required")
	local self = setmetatable({}, VirtualGrid)
	self.Opts = opts
	self.Items = {}
	self.Active = {} -- index -> { View, Kind }
	self.ViewIndex = {} -- view -> index
	self.Pools = {} -- kind -> { view }
	self.Buffer = opts.Buffer or 1
	self.Connections = {}

	local cell, gap, columns = opts.CellSize, opts.Gap, opts.Columns
	for _, c in parent:GetChildren() do
		if c:IsA("UIGridLayout") then
			cell = cell or offsetOf(c.CellSize)
			gap = gap or offsetOf(c.CellPadding)
			if not columns and c.FillDirectionMaxCells > 0 then
				columns = c.FillDirectionMaxCells
			end
			c:Destroy()
		elseif c:IsA("UIListLayout") then
			gap = gap or Vector2.new(0, c.Padding.Offset)
			columns = columns or 1
			c:Destroy()
		end
	end
	assert(cell, `[VirtualGrid] {parent:GetFullName()}: no CellSize (pass opts.CellSize or keep a UIGridLayout)`)
	self.Cell = cell
	self.Gap = gap or Vector2.zero
	self.FixedColumns = columns

	-- the canvas (or a nested holder frame) is sized by us: pooled hidden views never stretch it
	self.Holder = parent
	if parent:IsA("ScrollingFrame") then
		parent.AutomaticCanvasSize = Enum.AutomaticSize.None
		parent.CanvasSize = UDim2.new()
	else
		parent.AutomaticSize = Enum.AutomaticSize.None
	end
	local pad = parent:FindFirstChildOfClass("UIPadding")
	self.PadY = if pad then pad.PaddingTop.Offset + pad.PaddingBottom.Offset else 0
	self.Scroll = if parent:IsA("ScrollingFrame") then parent else parent:FindFirstAncestorWhichIsA("ScrollingFrame")

	local content = Instance.new("Frame")
	content.Name = "VirtualContent"
	content.BackgroundTransparency = 1
	content.BorderSizePixel = 0
	content.Size = UDim2.new(1, 0, 0, 0)
	content.LayoutOrder = opts.LayoutOrder or 0
	content.Parent = parent
	self.Content = content

	-- 100px probe: absolute/offset ratio of every UIScale above us (FitToScreen shrinks windows on phones)
	local probe = Instance.new("Frame")
	probe.Name = "ScaleProbe"
	probe.BackgroundTransparency = 1
	probe.Size = UDim2.fromOffset(0, 100)
	probe.Visible = false -- AbsoluteSize still updates; invisible = never counted in any auto size
	probe.Parent = content
	self.Probe = probe

	local function update()
		self:_update()
	end
	table.insert(self.Connections, content:GetPropertyChangedSignal("AbsoluteSize"):Connect(update))
	if self.Scroll then
		table.insert(self.Connections, self.Scroll:GetPropertyChangedSignal("CanvasPosition"):Connect(update))
		table.insert(self.Connections, self.Scroll:GetPropertyChangedSignal("AbsoluteSize"):Connect(update))
	end
	return self
end

function VirtualGrid:_scale(): number
	local s = self.Probe.AbsoluteSize.Y / 100
	return if s > 0 then s else 1
end

function VirtualGrid:_columns(): number
	if self.FixedColumns then
		return self.FixedColumns
	end
	local width = self.Content.AbsoluteSize.X / self:_scale()
	return math.max(1, math.floor((width + self.Gap.X) / (self.Cell.X + self.Gap.X)))
end

function VirtualGrid:_kind(item: any, index: number): string
	local k = self.Opts.KindOf and self.Opts.KindOf(item, index)
	return k or DEFAULT_KIND
end

function VirtualGrid:_release(index: number)
	local a = self.Active[index]
	if not a then
		return
	end
	self.Active[index] = nil
	self.ViewIndex[a.View] = nil
	if self.Opts.Unbind then
		self.Opts.Unbind(a.View, a.Kind)
	end
	a.View.Visible = false
	a.View.Position = UDim2.new()
	local pool = self.Pools[a.Kind]
	if not pool then
		pool = {}
		self.Pools[a.Kind] = pool
	end
	table.insert(pool, a.View)
end

function VirtualGrid:_acquire(kind: string): GuiObject
	local pool = self.Pools[kind]
	local view = pool and table.remove(pool)
	if not view then
		view = self.Opts.Create(kind, self)
		view.AnchorPoint = Vector2.zero
		view.Size = UDim2.fromOffset(self.Cell.X, self.Cell.Y)
		view.Parent = self.Content
	end
	view.Visible = true
	return view
end

function VirtualGrid:_place(view: GuiObject, index: number, columns: number)
	local i = index - 1
	local col, row = i % columns, i // columns
	view.Position = UDim2.fromOffset(col * (self.Cell.X + self.Gap.X), row * (self.Cell.Y + self.Gap.Y))
	view.LayoutOrder = index
end

function VirtualGrid:_bind(view: GuiObject, index: number, kind: string)
	self.Opts.Bind(view, self.Items[index], index, kind)
end

-- Show exactly the rows inside the viewport (+ buffer); reuse every view that leaves it.
function VirtualGrid:_update(rebindAll: boolean?)
	local count = #self.Items
	local columns = self:_columns()
	local rows = math.ceil(count / columns)
	local stepY = self.Cell.Y + self.Gap.Y
	local height = if rows > 0 then rows * stepY - self.Gap.Y else 0
	if self.Content.Size.Y.Offset ~= height then
		self.Content.Size = UDim2.new(1, 0, 0, height) -- re-fires _update through AbsoluteSize
		local holder = self.Holder
		if holder:IsA("ScrollingFrame") then
			holder.CanvasSize = UDim2.new(0, 0, 0, height + self.PadY)
		else
			holder.Size = UDim2.new(holder.Size.X.Scale, holder.Size.X.Offset, 0, height + self.PadY)
		end
	end

	local first, last = 1, 0
	if count > 0 then
		local scale = self:_scale()
		local top, viewH = 0, 0
		if self.Scroll then
			top = (self.Scroll.AbsolutePosition.Y - self.Content.AbsolutePosition.Y) / scale
			viewH = self.Scroll.AbsoluteWindowSize.Y / scale
		end
		if viewH <= 0 then
			viewH = 4 * stepY -- not laid out yet (window still closed): fill a few rows
		end
		local firstRow = math.max(0, math.floor(top / stepY) - self.Buffer)
		local lastRow = math.min(rows - 1, math.floor((top + viewH) / stepY) + self.Buffer)
		first = firstRow * columns + 1
		last = math.min(count, (lastRow + 1) * columns)
	end

	-- release views that left the range or changed kind
	for index, a in self.Active do
		if index < first or index > last or a.Kind ~= self:_kind(self.Items[index], index) then
			self:_release(index)
		end
	end
	for index = first, last do
		local a = self.Active[index]
		if a then
			if rebindAll then
				self:_bind(a.View, index, a.Kind)
			end
			self:_place(a.View, index, columns)
		else
			local kind = self:_kind(self.Items[index], index)
			local view = self:_acquire(kind)
			self.Active[index] = { View = view, Kind = kind }
			self.ViewIndex[view] = index
			self:_place(view, index, columns)
			self:_bind(view, index, kind)
		end
	end
	self.First, self.Last = first, last
end

function VirtualGrid:SetItems(items: { any })
	self.Items = items
	self:_update(true)
end

function VirtualGrid:Refresh()
	self:_update(true)
end

function VirtualGrid:NotifyChanged(index: number)
	local a = self.Active[index]
	if a then
		if a.Kind ~= self:_kind(self.Items[index], index) then
			self:_update(false)
		else
			self:_bind(a.View, index, a.Kind)
		end
	end
end

function VirtualGrid:ItemOf(view: Instance): (any, number?)
	local index = self.ViewIndex[view]
	if index then
		return self.Items[index], index
	end
	return nil, nil
end

function VirtualGrid:ForEachVisible(fn: (GuiObject, any, number, string) -> ())
	for index, a in self.Active do
		fn(a.View, self.Items[index], index, a.Kind)
	end
end

function VirtualGrid:Count(): number
	return #self.Items
end

-- The viewport height is in unscaled layout pixels, including the holder's padding.
function VirtualGrid:CountFitting(viewportHeight: number): number
	local rowHeight = self.Cell.Y + self.Gap.Y
	local rows = math.max(0, math.floor((viewportHeight - self.PadY + self.Gap.Y) / rowHeight))
	return rows * self:_columns()
end

-- number of views ever created (pool + visible): stays small however long the list is
function VirtualGrid:CreatedViewCount(): number
	local n = 0
	for _ in self.ViewIndex do
		n += 1
	end
	for _, pool in self.Pools do
		n += #pool
	end
	return n
end

function VirtualGrid:ScrollToTop()
	if self.Scroll then
		self.Scroll.CanvasPosition = Vector2.zero
	end
end

function VirtualGrid:ScrollTo(index: number)
	if not self.Scroll then
		return
	end
	local row = (index - 1) // self:_columns()
	local scale = self:_scale()
	local contentTop = (self.Content.AbsolutePosition.Y - self.Scroll.AbsolutePosition.Y) / scale + self.Scroll.CanvasPosition.Y / scale
	local y = (contentTop + row * (self.Cell.Y + self.Gap.Y)) * scale
	self.Scroll.CanvasPosition = Vector2.new(self.Scroll.CanvasPosition.X, math.max(0, y))
end

function VirtualGrid:Destroy()
	for _, c in self.Connections do
		c:Disconnect()
	end
	table.clear(self.Connections)
	self.Content:Destroy()
end

return VirtualGrid
