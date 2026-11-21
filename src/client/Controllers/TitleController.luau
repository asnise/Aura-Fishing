--!strict
-- Rebirth title over every player's head (C3, GDD 7.2). Reads the Player attribute "Title"
-- (set by RebirthService) and keeps a BillboardGui on that player's character head.
-- VIP name tag (C6, Figma Economy 1 "VIP over the head"): players with attribute Pass_VIP get a gold
-- name + crown (ui/icons/vip) above the title; their default Roblox name is hidden. Others keep the
-- default white name.

local Players = game:GetService("Players")

local New = require(script.Parent.Parent.UI.New)
local T = New.Theme

local TitleController = {}

local TAG = "RebirthTitle"
local VIP_TAG = "VipNameTag"

local function buildVip(player: Player)
	local char = player.Character
	local head = char and char:FindFirstChild("Head")
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if not head then
		return
	end
	local old = head:FindFirstChild(VIP_TAG)
	if old then
		old:Destroy()
	end
	local vip = player:GetAttribute("Pass_VIP") == true
	if hum then
		hum.DisplayDistanceType = if vip then Enum.HumanoidDisplayDistanceType.None else Enum.HumanoidDisplayDistanceType.Viewer
	end
	if not vip then
		return
	end
	local gui = Instance.new("BillboardGui")
	gui.Name = VIP_TAG
	gui.Size = UDim2.fromOffset(240, 30)
	gui.StudsOffset = Vector3.new(0, 2.6, 0) -- above the rebirth title (1.7)
	gui.MaxDistance = 100
	gui.LightInfluence = 0
	local row = New("Frame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Parent = gui,
		[New.Children] = {
			New("UIListLayout", {
				FillDirection = Enum.FillDirection.Horizontal,
				Padding = UDim.new(0, 4),
				HorizontalAlignment = Enum.HorizontalAlignment.Center,
				VerticalAlignment = Enum.VerticalAlignment.Center,
				SortOrder = Enum.SortOrder.LayoutOrder,
			}),
		},
	})
	New.Image({ Name = "Crown", Key = "ui/icons/vip", Fallback = T.Gold, Size = UDim2.fromOffset(22, 22), LayoutOrder = 1, Parent = row })
	local label = New("TextLabel", {
		Name = "Name",
		Size = UDim2.fromOffset(0, 28),
		AutomaticSize = Enum.AutomaticSize.X,
		BackgroundTransparency = 1,
		Text = player.DisplayName,
		TextColor3 = T.Gold,
		FontFace = T.Font,
		TextSize = 22,
		LayoutOrder = 2,
		Parent = row,
	})
	local stroke = New.Stroke(T.GoldLip, 2)
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual
	stroke.Parent = label
	New.ApplyImages(gui)
	gui.Parent = head
end

local function build(player: Player)
	local char = player.Character
	local head = char and char:FindFirstChild("Head")
	if not head then
		return
	end
	local old = head:FindFirstChild(TAG)
	if old then
		old:Destroy()
	end
	local title = player:GetAttribute("Title")
	if type(title) ~= "string" or title == "" then
		return
	end
	local gui = Instance.new("BillboardGui")
	gui.Name = TAG
	gui.Size = UDim2.fromOffset(220, 28)
	gui.StudsOffset = Vector3.new(0, 1.7, 0)
	gui.AlwaysOnTop = false
	gui.MaxDistance = 80
	gui.LightInfluence = 0
	local label = New.Text({
		Size = UDim2.fromScale(1, 1),
		Text = title,
		FontFace = T.Font,
		TextColor3 = T.Gold,
		MaxTextSize = 22,
	})
	local stroke = New.Stroke(T.GoldLip, 2)
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual
	stroke.Parent = label
	label.Parent = gui
	gui.Parent = head
end

local function watch(player: Player)
	player.CharacterAdded:Connect(function(char)
		char:WaitForChild("Head", 10)
		build(player)
		buildVip(player)
	end)
	player:GetAttributeChangedSignal("Pass_VIP"):Connect(function()
		buildVip(player)
	end)
	player:GetAttributeChangedSignal("Title"):Connect(function()
		build(player)
	end)
	if player.Character then
		task.spawn(build, player)
		task.spawn(buildVip, player)
	end
end

function TitleController.Init()
	Players.PlayerAdded:Connect(watch)
	for _, p in Players:GetPlayers() do
		watch(p)
	end
end

return TitleController
