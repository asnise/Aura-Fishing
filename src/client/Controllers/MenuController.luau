--!nonstrict
-- Shop / Auras / Fishdex windows (Figma 05/06, 07, 09). The windows are baked into the place
-- (StarterGui "Menus", built by UI/Screens/Menus); this controller only fills the fixed slots from
-- Config + profile (UI/MenuFill) and drives the pagers. New content shows up automatically (more pages).
-- Add a new window: add its layout to UI/Screens/Menus, a filler to UI/MenuFill + FILLERS, a button in HUDController.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Remotes = require(Shared.Remotes)

local New = require(script.Parent.Parent.UI.New)
local Baked = require(script.Parent.Parent.UI.Baked)
local MenuManager = require(script.Parent.Parent.UI.MenuManager)
local MenuFill = require(script.Parent.Parent.UI.MenuFill)
local AuraReel = require(script.Parent.Parent.UI.AuraReel)
local ItemDetail = require(script.Parent.Parent.UI.ItemDetail)
local HUD = require(script.Parent.HUDController)
local DataController = require(script.Parent.DataController)

local T = New.Theme

local MenuController = {}

local gui: any = nil
local windows: { [string]: any } = {}
local currentMenu: string? = nil
local pages: { [string]: number } = { Shop = 1, Auras = 1, Fishdex = 1 }
local pageCount: { [string]: number } = { Shop = 1, Auras = 1, Fishdex = 1 }
-- per-slot click handlers (buttons are connected once; the handler changes with the data)
local handlers: { [Instance]: (() -> ())? } = {}

local function invoke(name: string, ...: any)
	local ok, msg = Remotes.Func(name):InvokeServer(...)
	if type(msg) == "string" and msg ~= "OK" then
		HUD.Notify(msg, ok and T.Good or T.Bad)
	end
	return ok, msg
end

local function bindClick(button: GuiButton)
	button.Activated:Connect(function()
		local h = handlers[button]
		if h then
			h()
		end
	end)
end

local FILLERS = {
	Shop = MenuFill.Shop,
	Auras = MenuFill.Auras,
	Fishdex = MenuFill.Fishdex,
}

-- Window plumbing -------------------------------------------------------------------------------

local function ensure()
	if gui then
		return
	end
	gui = Baked.Get("Menus")
	gui.Enabled = true -- windows show/hide themselves; the ScreenGui may have been left disabled by a Studio preview
	MenuFill.Setup({
		windows = windows,
		pages = pages,
		pageCount = pageCount,
		handlers = handlers,
		currentTab = nil,
		invoke = invoke,
		refresh = function()
			MenuController.Refresh()
		end,
		rollAura = function()
			-- ROLL AURA opens the Aura Altar gacha page (pity, x1/x10, rates) instead of a blind roll.
			-- The page stacks on this window (MenuManager StackOn), so closing it comes back here.
			HUD.BannerRequested:Fire("Altar")
		end,
		setSetting = function(key, value)
			Remotes.Func("SetSetting"):InvokeServer(key, value)
		end,
	})
	for name in FILLERS do
		local w = Baked.Find(gui, name)
		windows[name] = w
		w.Visible = false
		New.FitWindow(w, Vector2.new(760, 610))
		Baked.Find(w, "Header/Close").Activated:Connect(MenuController.Close)
		local pager = w.Footer:FindFirstChild("Pager")
		if pager then
			pager.Prev.Activated:Connect(function()
				if pages[name] > 1 then
					pages[name] -= 1
					MenuController.Refresh()
				end
			end)
			pager.Next.Activated:Connect(function()
				if pages[name] < pageCount[name] then
					pages[name] += 1
					MenuController.Refresh()
				end
			end)
		end
		-- B21: invisible "Hit" button on every item picture -> Item Card (MenuFill sets the handler)
		for _, d in w:GetDescendants() do
			if d.Name == "Picture" and d:IsA("GuiObject") and not d:FindFirstChild("Hit") then
				local hit = Instance.new("TextButton")
				hit.Name = "Hit"
				hit.Size = UDim2.fromScale(1, 1)
				hit.BackgroundTransparency = 1
				hit.Text = ""
				hit.ZIndex = d.ZIndex + 5
				hit.Parent = d
			end
		end
		if name == "Auras" then
			-- B21: auras live in the Inventory; this window is the Aura Dex (every aura, found or not)
			local title = w:FindFirstChild("Header") and w.Header:FindFirstChild("Title")
			if title then
				title.Text = "Aura Dex"
			end
		end
		for _, d in w:GetDescendants() do
			if d:IsA("GuiButton") and d.Name ~= "Close" and d.Name ~= "Prev" and d.Name ~= "Next" then
				bindClick(d)
			end
		end
	end
end

function MenuController.Close()
	ItemDetail.Hide()
	local was = currentMenu
	if was and windows[was] then
		windows[was].Visible = false
	end
	currentMenu = nil
	if was then
		MenuManager.Closed(was)
	end
end

function MenuController.Refresh()
	if not currentMenu then
		return
	end
	local profile = DataController.Profile
	if not profile then
		return
	end
	ensure()
	for name, w in windows do
		w.Visible = name == currentMenu
	end
	FILLERS[currentMenu](profile)
end

function MenuController.Open(name: string)
	if currentMenu == name then
		MenuController.Close()
		return
	end
	if not FILLERS[name] then
		return
	end
	ensure()
	MenuManager.WillOpen(name) -- closes Main Menu, the other windows and the item card
	currentMenu = name
	MenuController.Refresh()
end

-- Roll an aura and play the Reel Slot reveal (Figma: Aura Gacha concept B).
function MenuController.RollAura()
	if AuraReel.IsPlaying() then
		return
	end
	local ok, result, isNew, equipped = Remotes.Func("RollAura"):InvokeServer()
	if not ok then
		HUD.Notify(result, T.Bad)
		return
	end
	MenuController.PlayReveal(result, isNew, equipped)
end

function MenuController.PlayReveal(auraId: string, isNew: boolean?, equipped: boolean?)
	AuraReel.Play(auraId, {
		isNew = isNew,
		equipped = equipped,
		onEquip = function()
			invoke("EquipAura", auraId)
		end,
		onRollAgain = MenuController.RollAura,
	})
end

function MenuController.Init()
	Remotes.Event("AuraRolled").OnClientEvent:Connect(function(auraId, isNew, equipped)
		MenuController.PlayReveal(auraId, isNew, equipped)
	end)
	HUD.MenuRequested:Connect(MenuController.Open)
	DataController.Changed:Connect(function()
		MenuController.Refresh()
	end)
	task.spawn(ensure) -- find the baked screen early so the first open is instant
end

-- Shop / Fishdex / Aura Dex share the baked "Menus" ScreenGui; each one is its own MenuManager entry.
local MENU_STACK: { [string]: { string }? } = {
	Auras = { "Inventory" }, -- AURA DEX button in the Inventory footer opens it on top of the bag
}
for name in FILLERS do
	MenuManager.Register(name, {
		Layer = "Main",
		StackOn = MENU_STACK[name],
		Open = function()
			if currentMenu ~= name then
				MenuController.Open(name)
			end
		end,
		Close = function()
			if currentMenu == name then
				MenuController.Close()
			end
		end,
		IsOpen = function()
			return currentMenu == name
		end,
		Gui = function()
			return gui
		end,
	})
end

return MenuController
