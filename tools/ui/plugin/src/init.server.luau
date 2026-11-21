--!nonstrict
-- "Aura UI" Studio panel: one place to open every baked screen of Aura Fishing for viewing/editing.
--   * Click a screen -> it is shown in the viewport with Figma's sample data (UI/SampleData) and
--     selected in Explorer, so Properties shows it right away. Every other baked screen is hidden.
--   * Lock -> sets attribute Locked on the ScreenGui, so `node tools/ui/bake.mjs` won't overwrite your edits.
--   * "Hide all" before saving the place (screens are hidden/disabled at game start anyway).
-- Needs the Client scripts synced into Studio (scripts\serve.bat + Rojo Connect).
-- Build/install: tools\ui\install-plugin.bat (then restart Studio once).

local ChangeHistoryService = game:GetService("ChangeHistoryService")
local Selection = game:GetService("Selection")
local StarterGui = game:GetService("StarterGui")

local toolbar = plugin:CreateToolbar("Aura Fishing")
local button = toolbar:CreateButton("AuraUI", "Open the Aura UI screen list", "", "Aura UI")
button.ClickableWhenViewportHidden = true

local widget = plugin:CreateDockWidgetPluginGui(
	"AuraUIScreens",
	DockWidgetPluginGuiInfo.new(Enum.InitialDockState.Right, false, false, 300, 460, 240, 300)
)
widget.Title = "Aura UI"
button:SetActive(widget.Enabled)
button.Click:Connect(function()
	widget.Enabled = not widget.Enabled
end)
widget:GetPropertyChangedSignal("Enabled"):Connect(function()
	button:SetActive(widget.Enabled)
end)

local function theme(c: Enum.StudioStyleGuideColor, m: Enum.StudioStyleGuideModifier?): Color3
	return (settings() :: any).Studio.Theme:GetColor(c, m or Enum.StudioStyleGuideModifier.Default)
end

local function new(className: string, props: { [string]: any }, parent: Instance?): any
	local inst = Instance.new(className)
	for k, v in props do
		(inst :: any)[k] = v
	end
	inst.Parent = parent
	return inst
end

local scroll = new("ScrollingFrame", {
	Size = UDim2.fromScale(1, 1),
	BackgroundColor3 = theme(Enum.StudioStyleGuideColor.MainBackground),
	BorderSizePixel = 0,
	ScrollBarThickness = 6,
	AutomaticCanvasSize = Enum.AutomaticSize.Y,
	CanvasSize = UDim2.new(),
}, widget)
new("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }, scroll)
new("UIPadding", { PaddingTop = UDim.new(0, 8), PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 14), PaddingBottom = UDim.new(0, 8) }, scroll)

local order = 0
local function nextOrder()
	order += 1
	return order
end

local function label(text: string, bold: boolean?, color: Color3?)
	return new("TextLabel", {
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		Text = text,
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextColor3 = color or theme(Enum.StudioStyleGuideColor.MainText),
		FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json", if bold then Enum.FontWeight.Bold else Enum.FontWeight.Regular),
		TextSize = if bold then 16 else 14,
		LayoutOrder = nextOrder(),
	}, scroll)
end

local function btn(parent: Instance, text: string, width: UDim, onClick: () -> ()): TextButton
	local b = new("TextButton", {
		Size = UDim2.new(width, UDim.new(0, 30)),
		BackgroundColor3 = theme(Enum.StudioStyleGuideColor.Button),
		TextColor3 = theme(Enum.StudioStyleGuideColor.ButtonText),
		Text = text,
		TextSize = 14,
		FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json", Enum.FontWeight.SemiBold),
		AutoButtonColor = true,
	}, parent)
	new("UICorner", { CornerRadius = UDim.new(0, 4) }, b)
	b.Activated:Connect(onClick)
	return b
end

local status = nil

local function setStatus(text: string, bad: boolean?)
	status.Text = text
	status.TextColor3 = if bad then Color3.fromRGB(230, 90, 80) else theme(Enum.StudioStyleGuideColor.DimmedText)
end

-- Fresh copies of the game's UI modules (Rojo-synced client scripts), so edits in src/ show up.
local function loadUI(): (Instance?, any)
	local client = game:GetService("StarterPlayer").StarterPlayerScripts:FindFirstChild("Client")
	local ui = client and client:FindFirstChild("UI")
	if not ui or not ui:FindFirstChild("SampleData") then
		return nil, nil
	end
	local copy = ui:Clone()
	copy.Parent = nil
	return copy, require(copy:FindFirstChild("SampleData"))
end

local function show(viewId: string)
	local ui, SampleData = loadUI()
	if not ui then
		setStatus("ไม่เจอสคริปต์ Client — เปิด scripts\\serve.bat แล้วกด Rojo → Connect ก่อน", true)
		return
	end
	local rec = ChangeHistoryService:TryBeginRecording("Aura UI: show " .. viewId)
	local ok, res = pcall(SampleData.Show, viewId, ui)
	if rec then
		ChangeHistoryService:FinishRecording(rec, Enum.FinishRecordingOperation.Commit)
	end
	ui:Destroy()
	if not ok then
		setStatus(tostring(res), true)
	elseif res then
		Selection:Set({ res })
		setStatus("เปิด " .. res:GetFullName() .. " แล้ว — เลือกไว้ใน Explorer ให้แล้ว แก้ใน Properties หรือลากในจอได้เลย")
	else
		Selection:Set({})
		setStatus("ซ่อนทุกหน้าจอแล้ว — Save (Ctrl+S) ได้")
	end
end

local lockRows = nil

local function refreshLocks()
	for _, c in lockRows:GetChildren() do
		if c:IsA("GuiObject") then
			c:Destroy()
		end
	end
	for _, g in StarterGui:GetChildren() do
		if g:IsA("ScreenGui") and g:GetAttribute("BakedFrom") then
			local locked = g:GetAttribute("Locked") == true
			btn(lockRows, (if locked then "🔒 " else "🔓 ") .. g.Name .. (if locked then "  (ล็อก: bake จะไม่ทับ)" else ""), UDim.new(1, 0), function()
				local rec = ChangeHistoryService:TryBeginRecording("Aura UI: lock " .. g.Name)
				g:SetAttribute("Locked", if locked then nil else true)
				if rec then
					ChangeHistoryService:FinishRecording(rec, Enum.FinishRecordingOperation.Commit)
				end
				refreshLocks()
			end)
		end
	end
end

local function build()
	label("หน้าจอของเกม (เก็บใน StarterGui)", true)
	label("คลิกชื่อหน้าจอ → เปิดพร้อมข้อมูลตัวอย่างแบบใน Figma + เลือกให้ใน Explorer → แก้ค่าใน Properties ได้เลย")
	local ui, SampleData = loadUI()
	local views = if SampleData then SampleData.Views else {}
	if ui then
		ui:Destroy()
	end
	if #views == 0 then
		label("ยังไม่เจอสคริปต์ Client: เปิด scripts\\serve.bat → Plugins → Rojo → Connect แล้วกด Reload ด้านล่าง", false, Color3.fromRGB(230, 90, 80))
	end
	for _, v in views do
		local holder = new("Frame", { Size = UDim2.new(1, 0, 0, 30), BackgroundTransparency = 1, LayoutOrder = nextOrder() }, scroll)
		btn(holder, v.Label, UDim.new(1, 0), function()
			show(v.Id)
		end)
	end
	local row = new("Frame", { Size = UDim2.new(1, 0, 0, 30), BackgroundTransparency = 1, LayoutOrder = nextOrder() }, scroll)
	new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 6) }, row)
	btn(row, "ซ่อนทั้งหมด (ก่อน Save)", UDim.new(0.62, -3), function()
		show("off")
	end)
	btn(row, "Reload", UDim.new(0.38, -3), function()
		for _, c in scroll:GetChildren() do
			if c:IsA("GuiObject") then
				c:Destroy()
			end
		end
		order = 0
		build()
	end)
	status = label("", false)
	setStatus("พร้อม")

	label("ล็อกหน้าจอที่แก้เอง", true)
	label("ล็อกแล้ว คำสั่ง bake ของ Claude จะไม่เขียนทับหน้าจอนั้น (บอก Claude ได้ว่าแก้อะไรไป)")
	lockRows = new("Frame", { Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, LayoutOrder = nextOrder() }, scroll)
	new("UIListLayout", { Padding = UDim.new(0, 4) }, lockRows)
	refreshLocks()

	label("ทิป", true)
	label("• ดูแบบมือถือ: แท็บ Test → Device → เลือกมือถือ (มุมมองในจอจะย่อตาม)\n• ย้อนการเปลี่ยนแปลง: Ctrl+Z\n• ลากชิ้นส่วนในจอ: เลือกใน Explorer ก่อน แล้วลากด้วยเมาส์ (ใช้แท็บ UI/Home → Select)")
end

build()
