--!strict
-- Small dock widget: status dot + text, On/Off toggle, port box, recent command log.

local Widget = {}
Widget.__index = Widget

local STATE_COLORS = {
	connected = Color3.fromRGB(76, 195, 120),
	waiting = Color3.fromRGB(240, 180, 60),
	blocked = Color3.fromRGB(230, 80, 70),
	off = Color3.fromRGB(130, 130, 130),
}

export type Widget = typeof(setmetatable(
	{} :: {
		widget: DockWidgetPluginGui,
		state: string,
		onToggle: (() -> ())?,
		onPortChanged: ((number) -> ())?,
		getStats: (() -> any)?,
		_dot: Frame,
		_status: TextLabel,
		_toggle: TextButton,
		_port: TextBox,
		_log: TextLabel,
		_lines: { string },
	},
	Widget
))

local function themeColor(style: Enum.StudioStyleGuideColor): Color3
	local ok, c = pcall(function()
		return (settings() :: any).Studio.Theme:GetColor(style)
	end)
	return if ok then c else Color3.new(0.15, 0.15, 0.15)
end

local function new(className: string, props: { [string]: any }, parent: Instance?): any
	local inst = Instance.new(className)
	for k, v in props do
		(inst :: any)[k] = v
	end
	inst.Parent = parent
	return inst
end

function Widget.new(plugin: Plugin): Widget
	local info = DockWidgetPluginGuiInfo.new(Enum.InitialDockState.Float, false, false, 300, 220, 240, 160)
	local okAsync, created = pcall(function()
		return (plugin :: any):CreateDockWidgetPluginGuiAsync("AuraStudioBridge", info)
	end)
	local widget: DockWidgetPluginGui = if okAsync and created
		then created
		else (plugin :: any):CreateDockWidgetPluginGui("AuraStudioBridge", info)
	widget.Title = "Studio Bridge (MCP)"

	local bg = themeColor(Enum.StudioStyleGuideColor.MainBackground)
	local fg = themeColor(Enum.StudioStyleGuideColor.MainText)
	local dim = themeColor(Enum.StudioStyleGuideColor.DimmedText)
	local inputBg = themeColor(Enum.StudioStyleGuideColor.InputFieldBackground)
	local btnBg = themeColor(Enum.StudioStyleGuideColor.Button)

	local root = new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = bg, BorderSizePixel = 0 }, widget)
	new("UIPadding", {
		PaddingLeft = UDim.new(0, 8),
		PaddingRight = UDim.new(0, 8),
		PaddingTop = UDim.new(0, 8),
		PaddingBottom = UDim.new(0, 8),
	}, root)
	new("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }, root)

	local row = new("Frame", { Size = UDim2.new(1, 0, 0, 20), BackgroundTransparency = 1, LayoutOrder = 1 }, root)
	local dot = new("Frame", {
		Size = UDim2.fromOffset(12, 12),
		Position = UDim2.fromOffset(0, 4),
		BackgroundColor3 = STATE_COLORS.off,
		BorderSizePixel = 0,
	}, row)
	new("UICorner", { CornerRadius = UDim.new(1, 0) }, dot)
	local status = new("TextLabel", {
		Size = UDim2.new(1, -18, 1, 0),
		Position = UDim2.fromOffset(18, 0),
		BackgroundTransparency = 1,
		Text = "Starting…",
		TextColor3 = fg,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Font = Enum.Font.SourceSansSemibold,
		TextSize = 15,
	}, row)

	local controls = new("Frame", { Size = UDim2.new(1, 0, 0, 24), BackgroundTransparency = 1, LayoutOrder = 2 }, root)
	local toggle = new("TextButton", {
		Size = UDim2.fromOffset(110, 24),
		BackgroundColor3 = btnBg,
		TextColor3 = fg,
		Text = "Turn off",
		Font = Enum.Font.SourceSans,
		TextSize = 14,
		AutoButtonColor = true,
	}, controls)
	new("UICorner", { CornerRadius = UDim.new(0, 4) }, toggle)
	new("TextLabel", {
		Size = UDim2.fromOffset(34, 24),
		Position = UDim2.new(1, -100, 0, 0),
		BackgroundTransparency = 1,
		Text = "Port",
		TextColor3 = dim,
		Font = Enum.Font.SourceSans,
		TextSize = 14,
	}, controls)
	local portBox = new("TextBox", {
		Size = UDim2.fromOffset(62, 24),
		Position = UDim2.new(1, -62, 0, 0),
		BackgroundColor3 = inputBg,
		TextColor3 = fg,
		Text = "3060",
		Font = Enum.Font.Code,
		TextSize = 14,
		ClearTextOnFocus = false,
	}, controls)
	new("UICorner", { CornerRadius = UDim.new(0, 4) }, portBox)

	local log = new("TextLabel", {
		Size = UDim2.new(1, 0, 1, -60),
		BackgroundTransparency = 1,
		Text = "",
		TextColor3 = dim,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Top,
		Font = Enum.Font.Code,
		TextSize = 12,
		TextWrapped = true,
		LayoutOrder = 3,
	}, root)

	local self = setmetatable({
		widget = widget,
		state = "off",
		onToggle = nil,
		onPortChanged = nil,
		getStats = nil,
		_dot = dot,
		_status = status,
		_toggle = toggle,
		_port = portBox,
		_log = log,
		_lines = {},
	}, Widget)

	toggle.Activated:Connect(function()
		if self.onToggle then
			self.onToggle()
		end
	end)
	portBox.FocusLost:Connect(function()
		local n = tonumber(portBox.Text)
		if n and n >= 1024 and n <= 65535 and self.onPortChanged then
			self.onPortChanged(math.floor(n))
		end
	end)
	return self
end

function Widget.setState(self: Widget, state: string, text: string)
	self.state = state
	self._dot.BackgroundColor3 = STATE_COLORS[state] or STATE_COLORS.off
	local label = if state == "connected" then "Connected " .. text else text
	self._status.Text = label
	self._toggle.Text = if state == "off" then "Turn on" else "Turn off"
end

function Widget.setPort(self: Widget, port: number)
	self._port.Text = tostring(port)
end

function Widget.log(self: Widget, line: string)
	table.insert(self._lines, 1, os.date("%H:%M:%S") .. "  " .. line)
	while #self._lines > 12 do
		table.remove(self._lines)
	end
	self._log.Text = table.concat(self._lines, "\n")
end

return Widget
