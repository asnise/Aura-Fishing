--!nonstrict
-- Main Menu hub (Figma 12). Screen is baked in StarterGui "MainMenu" (UI/Screens/MainMenu); this
-- controller opens/closes it, keeps the clock/day phase/avatar live and routes tiles:
-- Shop/Auras/Fishdex open their windows, Bag opens the Inventory, Friends opens the Roblox invite
-- prompt. Planned systems (Quests/Rebirth/Events/Settings) read Config/Features: when Enabled = false
-- the tile shows that feature's Notice; flip Enabled when the system exists and add its action here.
-- Red dots: Auras = enough gems to roll, Bag = new items or full. Badge: Rebirth "Lv.N" until unlocked.

local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local SocialService = game:GetService("SocialService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Registry = require(Shared.Registry)
local Inventory = require(Shared.Inventory)
local Rebirth = require(Shared.Rebirth)
local DailyLogin = require(Shared.DailyLogin)
local Remotes = require(Shared.Remotes)

local New = require(script.Parent.Parent.UI.New)
local Baked = require(script.Parent.Parent.UI.Baked)
local MenuManager = require(script.Parent.Parent.UI.MenuManager)
local Modal = require(script.Parent.Parent.UI.Modal)
local Credits = require(script.Parent.Parent.UI.Credits)
local StatsCodex = require(script.Parent.Parent.UI.StatsCodex)
local MainMenuScreen = require(script.Parent.Parent.UI.Screens.MainMenu)
local HUD = require(script.Parent.HUDController)
local DataController = require(script.Parent.DataController)

local T = New.Theme
local WHITE = Color3.new(1, 1, 1)

local MainMenuController = {}

local gui: any = nil
local refs: any = {}

local Features = Registry.Features

-- Tile id -> what it does. Windows go through MenuController; features through Config/Features.
local function invite()
	local ok, can = pcall(function()
		return SocialService:CanSendGameInviteAsync(Players.LocalPlayer)
	end)
	if ok and can then
		pcall(function()
			SocialService:PromptGameInvite(Players.LocalPlayer)
		end)
	else
		HUD.Notify(Features.Friends.Notice, T.SubText)
	end
end

local ACTIONS: { [string]: () -> () } = {
	Shop = function()
		HUD.MenuRequested:Fire("Shop")
	end,
	Auras = function()
		HUD.InventoryRequested:Fire("Auras") -- B21: auras live in the Inventory (Auras tab)
	end,
	Fishdex = function()
		HUD.MenuRequested:Fire("Fishdex")
	end,
	Bag = function()
		HUD.InventoryRequested:Fire()
	end,
	Character = function()
		HUD.CharacterRequested:Fire()
	end,
	Aquarium = function()
		HUD.AquariumRequested:Fire()
	end,
	Store = function()
		HUD.StoreRequested:Fire()
	end,
	Mastery = function()
		HUD.MasteryRequested:Fire()
	end,
	Quests = function()
		HUD.QuestsRequested:Fire()
	end,
	DailyLogin = function()
		HUD.DailyLoginRequested:Fire()
	end,
	Friends = invite,
	Events = function()
		HUD.EventsRequested:Fire()
	end,
	-- C10: no real settings yet - the tile opens "Settings & Credits" (licence credits + where Low FX is)
	Settings = Credits.Open,
	StatsCodex = StatsCodex.Open,
	-- C3: confirm, then the server checks the level again and resets
	Rebirth = function()
		local profile = DataController.Profile
		if not profile then
			return
		end
		local need = Rebirth.RequiredLevel(profile)
		if profile.Level < need then
			HUD.Notify(`Rebirth unlocks at Lv.{need} - you are Lv.{profile.Level}`, T.SubText)
			return
		end
		local nextCount = Rebirth.Count(profile) + 1
		local title = Rebirth.Title(nextCount)
		Modal.Confirm({
			Title = `Rebirth {nextCount}?`,
			Message = `Level, coins and the fish in your bag reset. You keep gear, auras, Fishdex, Mastery, Aquarium and Gems.`
				.. ` Coins and Pearls become {New.Highlight("x" .. tostring(1 + Rebirth.Bonus(nextCount)))}`
				.. (if title then `, title {New.Highlight(title)}.` else "."),
			ConfirmText = "Rebirth",
			ConfirmColor = T.Gold,
			Icon = false,
		}, function()
			local ok, msg = Remotes.Func("Rebirth"):InvokeServer()
			HUD.Notify(msg, if ok then T.Gold else T.Bad)
		end)
	end,
}

-- Planned feature tile: truthful notice (Rebirth also says how far the player is from unlocking).
local function featureNotice(id: string)
	local f = Features[id]
	if not f then
		HUD.Notify(`{id}: coming soon!`, T.SubText)
		return
	end
	local text = f.Notice
	local profile = DataController.Profile
	if id == "Rebirth" and profile then
		text ..= ` (unlocks at Lv.{Rebirth.RequiredLevel(profile)} - you are Lv.{profile.Level})`
	end
	HUD.Notify(text, T.SubText)
end

local function phaseFor(clock: number): string
	if clock >= 5 and clock < 7.5 then
		return "Dawn"
	elseif clock >= 7.5 and clock < 17.5 then
		return "Day"
	elseif clock >= 17.5 and clock < 20 then
		return "Dusk"
	end
	return "Night"
end

local function refreshClock()
	if not gui then
		return
	end
	local c = Lighting.ClockTime
	refs.Clock.Text = string.format("%02d:%02d", math.floor(c) % 24, math.floor((c % 1) * 60))
	local now = phaseFor(c)
	for _, holder in refs.DayPhase:GetChildren() do
		if holder:IsA("Frame") then
			local current = holder.Name == now
			holder.BackgroundTransparency = if current then 0 else 1
			holder.Size = UDim2.fromOffset(if current then 36 else holder.Icon.Size.X.Offset, 22)
			holder.Icon.ImageColor3 = if current then T.SkyLip else WHITE
			holder.Icon.ImageTransparency = if holder.Name == "Dusk" and not current then 0.25 else 0
		end
	end
	-- re-flow: current pill is wider than the plain icons
	local x = 0
	for _, name in { "Night", "Dawn", "Day", "Dusk" } do
		local h = refs.DayPhase:FindFirstChild(name)
		if h then
			h.Position = UDim2.fromOffset(x, 0)
			x += h.Size.X.Offset + 8
		end
	end
end

local function refreshData(profile: any)
	if not gui or not profile then
		return
	end
	local canRoll = profile[Registry.GameConfig.AuraRollCurrency] >= Registry.GameConfig.AuraRollCost
	refs.Tiles.Auras.Dot.Visible = canRoll
	-- Bag: something new in the bag, or no room left
	local bagNew = false
	for _, s in profile.Bag do
		if s.New then
			bagNew = true
		end
	end
	local bag = refs.Tiles.Bag
	if bag and bag:FindFirstChild("Dot") then
		bag.Dot.Visible = bagNew or Inventory.IsFull(profile)
	end
	-- Rebirth: level requirement badge (Figma 12 "Lv.100") until the player can rebirth
	local rb = refs.Tiles.Rebirth
	local need = Rebirth.RequiredLevel(profile)
	if rb and rb:FindFirstChild("Badge") then
		rb.Badge.Text = `Lv.{need}`
		rb.Badge.Visible = profile.Level < need
	end
	-- VIP pill under the avatar
	local vip = refs.VipBadge
	if vip then
		vip.Visible = profile.Passes ~= nil and profile.Passes.VIP ~= nil
	end
	-- Daily Login: red dot while today's check-in is unclaimed
	local dl = refs.Tiles.DailyLogin
	if dl and dl:FindFirstChild("Dot") then
		dl.Dot.Visible = DailyLogin.GetState(profile).CanClaim
	end
	-- Quests: dot when daily quests exist and have unclaimed rewards (system not built yet)
	local q = refs.Tiles.Quests
	if q and q:FindFirstChild("Dot") then
		q.Dot.Visible = Features.Quests.Enabled and profile.Quests ~= nil and profile.Quests.Unclaimed == true
	end
end

local function ensure()
	if gui then
		return
	end
	gui = Baked.Get("MainMenu")
	local hub = Baked.Find(gui, "Hub")
	refs.Hub = hub
	refs.Clock = Baked.Find(hub, "Glass/Phone/Header/Clock")
	refs.DayPhase = Baked.Find(hub, "Glass/Phone/Header/DayPhase")
	refs.Avatar = Baked.Find(hub, "Glass/Phone/Header/Avatar")
	refs.VipBadge = Baked.Find(hub, "Glass/Phone/Header"):FindFirstChild("VipBadge") -- nil on an older bake
	-- B21: the avatar opens the Character window (17)
	refs.Avatar.Active = true
	refs.Avatar.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			HUD.CharacterRequested:Fire() -- MenuManager closes Main Menu
		end
	end)
	refs.Tiles = {}
	local grid = Baked.Find(hub, "Glass/Phone/Grid")
	MainMenuScreen.EnsureCodexTile(grid)
	MainMenuScreen.EnsureDailyTile(grid)
	if not grid:FindFirstChild("Mastery") then
		local quests = grid:FindFirstChild("Quests")
		if quests and quests:IsA("GuiButton") then
			quests.Name = "Mastery"
			local circ = quests:FindFirstChild("Circle")
			if circ and circ:IsA("Frame") then
				circ.BackgroundColor3 = T.TintMint
				local icon = circ:FindFirstChild("Icon")
				if icon then
					New.SetImageKey(icon, "ui/icons/mastery", T.TintMint)
				end
			end
			local lbl = quests:FindFirstChild("Label")
			if lbl and lbl:IsA("TextLabel") then
				lbl.Text = "Mastery"
			end
		end
	end
	for _, t in grid:GetChildren() do
		if t:IsA("GuiButton") then
			refs.Tiles[t.Name] = t
			t.Activated:Connect(function()
				MainMenuController.Close()
				local action = ACTIONS[t.Name]
				local feature = Features[t.Name]
				if action and (feature == nil or feature.Enabled) then
					action()
				else
					featureNotice(t.Name)
				end
			end)
		end
	end
	Baked.Find(hub, "Close").Activated:Connect(MainMenuController.Close)
	New.FitWindow(hub, Vector2.new(440, 614))

	-- player's headshot in the avatar circle (falls back to the Pip art / cream circle)
	task.spawn(function()
		local ok, id = pcall(function()
			return Players:GetUserThumbnailAsync(Players.LocalPlayer.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size150x150)
		end)
		if ok and id then
			refs.Avatar:SetAttribute("ImageKey", nil)
			refs.Avatar.Image = id
			local fb = refs.Avatar:FindFirstChild("Fallback")
			if fb then
				fb.Visible = false
			end
		end
	end)
	Lighting:GetPropertyChangedSignal("ClockTime"):Connect(refreshClock)
end

function MainMenuController.IsOpen(): boolean
	return gui ~= nil and gui.Enabled
end

function MainMenuController.Open()
	MenuManager.WillOpen("MainMenu")
	ensure()
	refreshClock()
	refreshData(DataController.Profile)
	gui.Enabled = true
end

function MainMenuController.Close()
	if gui then
		gui.Enabled = false
	end
	MenuManager.Closed("MainMenu")
end

function MainMenuController.Toggle()
	if MainMenuController.IsOpen() then
		MainMenuController.Close()
	else
		MainMenuController.Open()
	end
end

function MainMenuController.Init()
	HUD.HubRequested:Connect(MainMenuController.Toggle)
	DataController.Changed:Connect(function()
		refreshData(DataController.Profile)
	end)
	UserInputService.InputBegan:Connect(function(input, processed)
		if not processed and input.KeyCode == Enum.KeyCode.M then
			MainMenuController.Toggle()
		end
	end)
	task.spawn(ensure)
end

MenuManager.Register("MainMenu", { Layer = "Hub", Open = MainMenuController.Open, Close = MainMenuController.Close, IsOpen = MainMenuController.IsOpen })

return MainMenuController
