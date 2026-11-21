--!strict
-- Credits window (C10). Opened from Main Menu > Settings until a real Settings screen exists.
-- Rows come from Config/Credits. Shell (title, X, open/close, scale) = Window core; placeholder until a Figma screen.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Registry = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Registry"))
local New = require(script.Parent.New)
local Window = require(script.Parent.Window)

local T = New.Theme

local Credits = {}

local shell = Window.Shell({ Name = "Credits", Title = "Settings & Credits", Size = Vector2.new(520, 400), Padding = 20 })
local window = shell.Frame
New.Text({
	Position = UDim2.fromOffset(0, 62),
	Size = UDim2.new(1, 0, 0, 22),
	Text = "More settings are coming soon. Low FX is in the Auras window.",
	TextColor3 = T.SubText,
	MaxTextSize = 16,
	Parent = window,
})
local list = New("Frame", {
	Name = "List",
	BackgroundTransparency = 1,
	Position = UDim2.fromOffset(0, 94),
	Size = UDim2.new(1, 0, 1, -94),
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
