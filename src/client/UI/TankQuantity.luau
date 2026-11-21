--!nonstrict
-- Figma C14 (3569:41334). Confirm edits the picker selection; only the picker sends it to the server.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local Aquarium = require(ReplicatedStorage:WaitForChild("Shared").Aquarium)
local New = require(script.Parent.New)
local Window = require(script.Parent.Window)
local Components = require(script.Parent.Screens.Components)
local T = New.Theme

local TankQuantity = {}

function TankQuantity.Create()
	local window = Window.Shell({
		Name = "TankQuantity", WindowName = "Quantity", Size = Vector2.new(480, 528),
		Layer = "Modal", Close = false, Padding = 0,
	})
	New("TextButton", {
		Name = "InputShield", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1,
		Text = "", Active = true, AutoButtonColor = false, Selectable = false, ZIndex = 0, Parent = window.Gui,
	})
	local panel = window.Frame
	local function area(name: string, x: number, y: number, width: number, height: number, parent: Instance): Frame
		return New("Frame", {
			Name = name, Position = UDim2.fromOffset(x, y), Size = UDim2.fromOffset(width, height),
			BackgroundTransparency = 1, Parent = parent,
		})
	end
	local body = area("Body", 0, 0, 480, 433, panel)
	local photo = Components.Make.ItemSlot(104)
	photo.Name = "Picture"
	photo.Position = UDim2.fromOffset(188, 36)
	photo.Icon.Position = UDim2.fromOffset(8, 8)
	photo.Icon.Size = UDim2.fromOffset(88, 88)
	photo.Tile.BackgroundColor3 = Color3.new(1, 1, 1)
	New("UIGradient", { Color = ColorSequence.new(T.TintSky, T.Sky), Rotation = 90, Parent = photo.Tile })
	photo.Selectable = false
	photo.Parent = body
	local title = New.Title({ Name = "Title", Position = UDim2.fromOffset(30, 150), Size = UDim2.fromOffset(420, 30), TextSize = 26, TextTruncate = Enum.TextTruncate.AtEnd, Parent = body })
	local owned = New.Text({ Name = "Owned", Position = UDim2.fromOffset(30, 190), Size = UDim2.fromOffset(420, 19), TextSize = 15, TextColor3 = T.SubText, Parent = body })
	local value = area("Value", 30, 219, 420, 53, body)
	New("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, HorizontalAlignment = Enum.HorizontalAlignment.Center, VerticalAlignment = Enum.VerticalAlignment.Center, Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder, Parent = value })
	local amount = New.Title({ Name = "Amount", Size = UDim2.fromOffset(0, 53), AutomaticSize = Enum.AutomaticSize.X, TextSize = 44, LayoutOrder = 1, Parent = value })
	local maxLabel = New.Text({ Name = "Max", Size = UDim2.fromOffset(0, 27), AutomaticSize = Enum.AutomaticSize.X, TextSize = 22, TextColor3 = T.SubText, LayoutOrder = 2, Parent = value })
	New.FitTextWidth(amount)
	New.FitTextWidth(maxLabel)

	local sliderRow = area("Slider Row", 48, 282, 384, 45, body)
	local minus = New.Button({ Name = "Btn Minus", Size = UDim2.fromOffset(48, 45), Text = "-", TextSize = 24, BackgroundColor3 = T.Sky, Parent = sliderRow })
	local plus = New.Button({ Name = "Btn Plus", Position = UDim2.fromOffset(336, 0), Size = UDim2.fromOffset(48, 45), Text = "+", TextSize = 24, BackgroundColor3 = T.Sky, Parent = sliderRow })
	local slider = New("TextButton", {
		Name = "Slider", Position = UDim2.fromOffset(62, 0), Size = UDim2.fromOffset(260, 45),
		Text = "", BackgroundTransparency = 1, AutoButtonColor = false, Parent = sliderRow,
	})
	local track = New("Frame", {
		Name = "Track", Position = UDim2.fromOffset(0, 15), Size = UDim2.new(1, 0, 0, 14),
		BackgroundColor3 = T.Track, Parent = slider, [New.Children] = { New.Pill() },
	})
	local fill = New("Frame", { Name = "Fill", BackgroundColor3 = T.Accent, Parent = track, [New.Children] = { New.Pill() } })
	local knob = New("Frame", {
		Name = "Knob", AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.fromOffset(32, 32),
		BackgroundColor3 = T.Panel, Parent = slider, [New.Children] = { New.Pill(), New.Stroke(T.Accent, 2) },
	})

	local quick = area("Quick", 126, 337, 228, 36, body)
	local quickButtons = {}
	for i, spec in { { "1", 0, 41 }, { "Half", 49, 73 }, { "MAX", 130, 98 } } do
		quickButtons[i] = New("TextButton", {
			Name = "Quick " .. spec[1], Text = spec[1], Position = UDim2.fromOffset(spec[2], 0),
			Size = UDim2.fromOffset(spec[3], 36), FontFace = T.Font, TextSize = 16,
			BackgroundColor3 = T.PanelLight, TextColor3 = T.SubText, Parent = quick,
			[New.Children] = { New.Pill() },
		})
	end
	local gain = area("Gain", 30, 383, 420, 24, body)
	New("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, HorizontalAlignment = Enum.HorizontalAlignment.Center, VerticalAlignment = Enum.VerticalAlignment.Center, Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder, Parent = gain })
	New.Image({ Name = "Pearl", Key = "ui/status/pearl", Size = UDim2.fromOffset(20, 20), LayoutOrder = 1, Parent = gain })
	local rate = New.Title({ Name = "Value", Size = UDim2.fromOffset(0, 24), AutomaticSize = Enum.AutomaticSize.X, TextSize = 17, TextColor3 = T.GoodLip, LayoutOrder = 2, Parent = gain })
	New.FitTextWidth(rate)

	local footer = area("Footer", 2, 433, 476, 93, panel)
	footer.BackgroundTransparency = 0
	footer.BackgroundColor3 = T.PanelLight
	New.Corner(22).Parent = footer
	local cancel = New.Button({ Name = "Btn Cancel", Position = UDim2.fromOffset(32, 16), Size = UDim2.fromOffset(198, 57), Text = "Cancel", TextSize = 20, BackgroundColor3 = T.Panel, TextColor3 = T.Text, Parent = footer })
	local confirm = New.Button({ Name = "Btn Confirm", Position = UDim2.fromOffset(246, 16), Size = UDim2.fromOffset(198, 57), Text = "CONFIRM", TextSize = 20, BackgroundColor3 = T.Good, Parent = footer })

	local current, draft, pending = nil, 0, nil
	local drag: InputObject? = nil
	local function setDraft(n: number)
		draft = math.clamp(n, 0, current.MaxPick)
		local fraction = if current.MaxPick > 0 then draft / current.MaxPick else 0
		amount.Text = tostring(draft)
		maxLabel.Text = `/ {current.MaxPick}`
		fill.Size = UDim2.fromScale(fraction, 1)
		knob.Position = UDim2.fromScale(fraction, 0.5)
		rate.Text = Aquarium.FormatRate(current.RatePer * draft)
		quickButtons[3].Text = `MAX {current.MaxPick}`
	end
	local function refresh(item: any)
		current = item
		owned.Text = `You have {item.G.Count} | {item.Room} free slots left`
		setDraft(draft)
	end
	local function slide(x: number)
		local width = slider.AbsoluteSize.X
		if width > 0 then
			local fraction = math.clamp((x - slider.AbsolutePosition.X) / width, 0, 1)
			setDraft(math.round(fraction * current.MaxPick))
		end
	end
	slider.InputBegan:Connect(function(input)
		if not drag and current and (input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1) then
			drag = input
			slide(input.Position.X)
		end
	end)
	UserInputService.InputChanged:Connect(function(input)
		if drag and (input == drag or (drag.UserInputType == Enum.UserInputType.MouseButton1 and input.UserInputType == Enum.UserInputType.MouseMovement)) then
			slide(input.Position.X)
		end
	end)
	UserInputService.InputEnded:Connect(function(input)
		if input == drag then
			drag = nil
		end
	end)
	minus.Activated:Connect(function() setDraft(draft - 1) end)
	plus.Activated:Connect(function() setDraft(draft + 1) end)
	quickButtons[1].Activated:Connect(function() setDraft(1) end)
	quickButtons[2].Activated:Connect(function() setDraft(math.ceil(current.MaxPick / 2)) end)
	quickButtons[3].Activated:Connect(function() setDraft(current.MaxPick) end)
	cancel.Activated:Connect(window.Close)
	confirm.Activated:Connect(function()
		local callback = pending
		window.Close()
		if callback then
			callback(draft)
		end
	end)
	window.OnClose = function()
		drag, pending = nil, nil
	end
	return {
		Open = function(item: any, name: string, rarityColor: Color3, onConfirm: (number) -> ())
			Components.SetItemSlot(photo, { Icon = "fish/" .. item.G.Id, CornerColor = rarityColor })
			title.Text = name
			draft = if item.Mine > 0 then item.Mine else 1
			pending = onConfirm
			refresh(item)
			window.Open()
		end,
		Close = window.Close,
		IsOpen = window.IsOpen,
		Refresh = refresh,
	}
end

return TankQuantity
