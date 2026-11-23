--!strict

local View = {}

export type Row = {
	name: string,
	fileName: string,
	status: string,
	imageId: string?,
	choose: () -> (),
	useId: (string) -> (),
}

local studio = (settings() :: any).Studio

local function color(key: Enum.StudioStyleGuideColor, modifier: Enum.StudioStyleGuideModifier?): Color3
	if modifier then return studio.Theme:GetColor(key, modifier) end
	return studio.Theme:GetColor(key)
end

local function new(class: string, properties: { [string]: any }, parent: Instance?): any
	local instance = Instance.new(class)
	for key, value in properties do (instance :: any)[key] = value end
	instance.Parent = parent
	return instance
end

local function label(text: string, size: UDim2, parent: Instance, x: number?, y: number?): TextLabel
	return new("TextLabel", {
		Size = size, Position = UDim2.fromOffset(x or 0, y or 0), BackgroundTransparency = 1,
		Text = text, TextSize = 14, TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd, Font = Enum.Font.SourceSans,
		TextColor3 = color(Enum.StudioStyleGuideColor.MainText),
	}, parent)
end

local function button(name: string, text: string, size: UDim2, position: UDim2, parent: Instance): TextButton
	return new("TextButton", {
		Name = name, Text = text, Size = size, Position = position, BorderSizePixel = 0,
		Font = Enum.Font.SourceSansSemibold, TextSize = 14,
		BackgroundColor3 = color(Enum.StudioStyleGuideColor.Button),
		TextColor3 = color(Enum.StudioStyleGuideColor.ButtonText),
	}, parent)
end

local function input(name: string, placeholder: string, size: UDim2, position: UDim2, parent: Instance): TextBox
	local entry = new("TextBox", {
		Name = name, Size = size, Position = position, BorderSizePixel = 0, Text = "", PlaceholderText = placeholder,
		TextXAlignment = Enum.TextXAlignment.Left, ClearTextOnFocus = false, Font = Enum.Font.SourceSans,
		TextSize = 14, BackgroundColor3 = color(Enum.StudioStyleGuideColor.InputFieldBackground),
		TextColor3 = color(Enum.StudioStyleGuideColor.MainText),
	}, parent)
	new("UIPadding", { PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8) }, entry)
	return entry
end

function View.setEnabled(control: TextButton, enabled: boolean)
	control.Active = enabled
	control.Interactable = enabled
	control.AutoButtonColor = enabled
	control.TextColor3 = if enabled then color(Enum.StudioStyleGuideColor.ButtonText) else color(Enum.StudioStyleGuideColor.DimmedText)
end

function View.new(pluginInstance: Plugin)
	local info = DockWidgetPluginGuiInfo.new(Enum.InitialDockState.Right, false, false, 440, 570, 360, 400)
	local widget = pluginInstance:CreateDockWidgetPluginGuiAsync("AuraParticleImporter", info)
	widget.Title = "Aura Particle Importer"

	local background = new("Frame", {
		Size = UDim2.fromScale(1, 1), BackgroundColor3 = color(Enum.StudioStyleGuideColor.MainBackground), BorderSizePixel = 0,
	}, widget)
	local body = new("Frame", { Size = UDim2.new(1, -24, 1, -24), Position = UDim2.fromOffset(12, 12), BackgroundTransparency = 1 }, background)
	local open = button("OpenProject", "Open project + PNGs", UDim2.new(0.5, -4, 0, 28), UDim2.fromOffset(0, 0), body)
	local choose = button("ChoosePNGs", "Choose PNGs", UDim2.new(0.5, -4, 0, 28), UDim2.new(0.5, 4, 0, 0), body)
	local projectName = label("Select a Particle Editor project.json", UDim2.new(1, 0, 0, 28), body, 0, 34)
	projectName.Font = Enum.Font.SourceSansSemibold
	projectName.TextSize = 17
	label("Aura ID", UDim2.fromOffset(64, 26), body, 0, 70)
	local auraId = input("AuraId", "TidalBloom", UDim2.new(1, -64, 0, 26), UDim2.fromOffset(64, 70), body)
	local owner = button("UploadOwner", "", UDim2.new(1, 0, 0, 26), UDim2.fromOffset(0, 104), body)
	local count = label("Textures", UDim2.new(1, 0, 0, 25), body, 0, 135)
	local bulk = input("PastedIds", "Paste image IDs here, one per line (in row order, or 'file.png 123456')", UDim2.new(1, 0, 0, 54), UDim2.fromOffset(0, 164), body)
	bulk.MultiLine = true
	bulk.TextWrapped = true
	bulk.TextYAlignment = Enum.TextYAlignment.Top
	local rows: ScrollingFrame = new("ScrollingFrame", {
		Name = "Textures", Size = UDim2.new(1, 0, 1, -343), Position = UDim2.fromOffset(0, 224),
		BorderSizePixel = 0, BackgroundTransparency = 1, ScrollBarThickness = 5, ScrollingDirection = Enum.ScrollingDirection.Y,
		CanvasSize = UDim2.fromOffset(0, 0), AutomaticCanvasSize = Enum.AutomaticSize.Y,
	}, body)
	local applyIds = button("ApplyIds", "Apply pasted IDs", UDim2.new(1, 0, 0, 28), UDim2.new(0, 0, 1, -106), body)
	local upload = button("UploadPNGs", "Upload PNGs", UDim2.new(0.5, -4, 0, 28), UDim2.new(0, 0, 1, -72), body)
	local import = button("ImportAura", "Import aura", UDim2.new(0.5, -4, 0, 28), UDim2.new(0.5, 4, 1, -72), body)
	local status = label("Open a project to start.", UDim2.new(1, 0, 0, 38), body)
	status.Position = UDim2.new(0, 0, 1, -37)
	status.TextWrapped = true
	status.TextYAlignment = Enum.TextYAlignment.Top
	return {
		widget = widget, open = open, choose = choose, projectName = projectName, auraId = auraId, owner = owner,
		count = count, rows = rows, bulk = bulk, applyIds = applyIds, upload = upload, import = import, status = status,
	}
end

function View.fill(frame: ScrollingFrame, rows: { Row }, enabled: boolean)
	local position = frame.CanvasPosition
	frame:ClearAllChildren()
	new("UIListLayout", { Padding = UDim.new(0, 5), SortOrder = Enum.SortOrder.LayoutOrder }, frame)
	for index, row in rows do
		local panel = new("Frame", {
			Name = "Texture" .. index, Size = UDim2.new(1, -8, 0, 101), LayoutOrder = index, BorderSizePixel = 0,
			BackgroundColor3 = color(Enum.StudioStyleGuideColor.InputFieldBackground),
		}, frame)
		local name = label(row.name, UDim2.new(1, -16, 0, 22), panel, 8, 3)
		name.Font = Enum.Font.SourceSansSemibold
		local fileName = label(row.fileName, UDim2.new(1, -16, 0, 18), panel, 8, 24)
		fileName.TextColor3 = color(Enum.StudioStyleGuideColor.DimmedText)
		label(row.status, UDim2.new(1, -16, 0, 18), panel, 8, 43)
		local choose = button("ChoosePNG", "Choose PNG", UDim2.fromOffset(86, 25), UDim2.fromOffset(8, 68), panel)
		local entry = input("AssetId", "Existing image ID", UDim2.new(1, -172, 0, 25), UDim2.fromOffset(102, 68), panel)
		entry.BackgroundColor3 = color(Enum.StudioStyleGuideColor.MainBackground)
		entry.Text = row.imageId or ""
		entry.TextEditable = enabled
		local use = button("UseId", "Use ID", UDim2.fromOffset(54, 25), UDim2.new(1, -62, 0, 68), panel)
		View.setEnabled(choose, enabled)
		View.setEnabled(use, enabled)
		choose.Activated:Connect(row.choose)
		use.Activated:Connect(function() row.useId(entry.Text) end)
	end
	frame.CanvasPosition = position
end

return View
