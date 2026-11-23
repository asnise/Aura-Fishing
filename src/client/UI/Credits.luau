--!nonstrict
-- Settings & Credits window (C10). Opened from Main Menu > Settings: Music / Sound effects volume sliders on top
-- (Controllers/SoundController, saved in Settings.MusicVolume / SFXVolume), then the credit rows from Config/Credits.
-- Rows come from Config/Credits. Shell (title, X, open/close, scale) = Window core; placeholder until a Figma screen.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Registry = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Registry"))
local New = require(script.Parent.New)
local Window = require(script.Parent.Window)
local UserInputService = game:GetService("UserInputService")
local SoundController = require(script.Parent.Parent.Controllers.SoundController)

local T = New.Theme

local Credits = {}

local shell = Window.Shell({ Name = "Credits", Title = "Settings & Credits", Size = Vector2.new(520, 540), Padding = 20 })
local window = shell.Frame
-- Volume slider row: label + percent on top, draggable track below. Applies live, SoundController saves it.
local function volumeRow(y: number, label: string, bus: string)
	local row = New.Panel({ Name = label .. " Volume", Position = UDim2.fromOffset(0, y), Size = UDim2.new(1, 0, 0, 64), BackgroundColor3 = T.PanelLight, Parent = window })
	New.Title({ Position = UDim2.fromOffset(14, 6), Size = UDim2.new(1, -100, 0, 24), Text = label, MaxTextSize = 20, TextXAlignment = Enum.TextXAlignment.Left, Parent = row })
	local value = New.Title({ AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -14, 0, 6), Size = UDim2.fromOffset(70, 24), Text = "", MaxTextSize = 20, TextXAlignment = Enum.TextXAlignment.Right, Parent = row })
	local track = New("TextButton", { Name = "Track", Position = UDim2.fromOffset(14, 38), Size = UDim2.new(1, -28, 0, 16), Text = "", AutoButtonColor = false, BackgroundColor3 = T.Track, BorderSizePixel = 0, Parent = row, [New.Children] = { New.Pill() } })
	local fill = New("Frame", { Name = "Fill", Size = UDim2.fromScale(0, 1), BackgroundColor3 = T.Accent, BorderSizePixel = 0, Parent = track, [New.Children] = { New.Pill() } })
	local knob = New("Frame", { Name = "Knob", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0, 0.5), Size = UDim2.fromOffset(26, 26), BackgroundColor3 = T.Panel, Parent = track, [New.Children] = { New.Pill(), New.Stroke(T.Accent, 3) } })
	local function show(v: number)
		fill.Size = UDim2.fromScale(v, 1)
		knob.Position = UDim2.fromScale(v, 0.5)
		value.Text = `{math.floor(v * 100 + 0.5)}%`
	end
	local dragging = false
	local function setFrom(x: number)
		local width = track.AbsoluteSize.X
		if width <= 0 then
			return
		end
		local v = math.clamp((x - track.AbsolutePosition.X) / width, 0, 1)
		show(v)
		SoundController.SetVolume(bus, v)
	end
	track.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			setFrom(input.Position.X)
		end
	end)
	UserInputService.InputChanged:Connect(function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			setFrom(input.Position.X)
		end
	end)
	UserInputService.InputEnded:Connect(function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
			dragging = false
			if bus == "SFX" then
				SoundController.Play("ui_confirm") -- hear the new level
			end
		end
	end)
	-- show the current value every time the window opens
	return function()
		show(SoundController.GetVolume(bus))
	end
end
local refreshMusic = volumeRow(62, "Music", "Music")
local refreshSfx = volumeRow(136, "Sound effects", "SFX")
local baseOpen = shell.Open
shell.Open = function(...)
	refreshMusic()
	refreshSfx()
	baseOpen(...)
end
local list = New("Frame", {
	Name = "List",
	BackgroundTransparency = 1,
	Position = UDim2.fromOffset(0, 214),
	Size = UDim2.new(1, 0, 1, -214),
	Parent = window,
	[New.Children] = { New("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }) },
})
for i, c in Registry.Credits do
	local row = New.Panel({
		Name = "Credit" .. i,
		LayoutOrder = i,
		Size = UDim2.new(1, 0, 0, 74),
		BackgroundColor3 = T.PanelLight,
		Parent = list,
	})
	New.Padding(10).Parent = row
	New.Title({ Size = UDim2.new(1, 0, 0, 22), Text = c.Name, TextColor3 = T.Text, MaxTextSize = 20, TextXAlignment = Enum.TextXAlignment.Left, Parent = row })
	New.Text({
		Position = UDim2.fromOffset(0, 24),
		Size = UDim2.new(1, 0, 0, 30),
		Text = `{c.Use} | by {c.Author} | {c.License} | {c.Url}`,
		TextColor3 = T.SubText,
		MaxTextSize = 15,
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = row,
	})
end

Credits.Open = shell.Open
Credits.Close = shell.Close
Credits.IsOpen = shell.IsOpen

return Credits
