--!nonstrict
-- Gacha page (full screen, Figma concept D "Glass Card" for every banner; UI/GachaPage does the filling + pull logic).
-- Opened by: Events hub card OPEN (EventActions/Gacha), HUD.BannerRequested(bannerId) (Auras window
-- ROLL AURA), RemoteEvent "OpenBanner"(bannerId) (Aura Altar prompt). Other code: GachaPageController.Open(id)
-- (or EventController.OpenBanner(id)).

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Registry = require(Shared.Registry)
local Remotes = require(Shared.Remotes)

local UI = script.Parent.Parent.UI
local New = require(UI.New)
local Baked = require(UI.Baked)
local MenuManager = require(UI.MenuManager)
local AuraReel = require(UI.AuraReel)
local GachaPage = require(UI.GachaPage)
local HUD = require(script.Parent.HUDController)
local SoundController = require(script.Parent.SoundController)
local DataController = require(script.Parent.DataController)

local T = New.Theme
local TICK = 5 -- seconds between timer updates

local GachaPageController = {}

local gui: any = nil
local isOpen = false

local function invoke(name: string, ...: any): (any, any, any)
	local ok, a, b, c = pcall(function(...)
		return Remotes.Func(name):InvokeServer(...)
	end, ...)
	if not ok then
		warn("[GachaPage]", name, a)
		return false, "Something went wrong, try again", nil
	end
	return a, b, c
end

local ctx = {
	invoke = invoke,
	notify = function(text: string, color: Color3?)
		HUD.Notify(text, color)
	end,
	playReveal = function(auraId: string, opts: any)
		local aura = Registry.Auras[auraId]
		local tier = aura and Registry.Rarities[aura.Rarity] and Registry.Rarities[aura.Rarity].Tier or 1
		SoundController.Play("gacha_buildup")
		local result = if tier >= 5 then "gacha_legendary" elseif tier >= 4 then "gacha_epic" else "gacha_common"
		task.delay(1.2, SoundController.Play, result) -- after the build-up
		AuraReel.Play(auraId, opts)
	end,
	reelPlaying = function(): boolean
		return AuraReel.IsPlaying()
	end,
	profile = function()
		return DataController.Profile
	end,
	isOpen = function(): boolean
		return isOpen
	end,
	close = function()
		GachaPageController.Close()
	end,
	back = function()
		GachaPageController.Close()
		-- stacked on a window (Events / Inventory / Aura Dex): closing shows it again; otherwise go to Events
		if #MenuManager.OpenList("Main") > 0 then
			return
		end
		local ev = (HUD :: any).EventsRequested
		if ev then
			ev:Fire()
		end
	end,
	refresh = function()
		GachaPageController.Refresh()
	end,
	openStore = function(tab: string?)
		-- lazy: EconomyController requires this controller too
		local Economy = require(script.Parent.EconomyController) :: any
		Economy.OpenStore(tab) -- MenuManager closes the gacha page
	end,
}

local ensuring = false
local function ensure()
	-- Init and the first Open both call this and Baked.Get can yield: without the guard two copies of the page get
	-- built and the one the controller does not track stays on screen.
	while ensuring do
		task.wait()
	end
	if gui then
		return
	end
	ensuring = true
	local ok, err = pcall(function()
		local built = Baked.Get("GachaPage")
		built.Enabled = false
		gui = built
		local w = Baked.Find(gui, "Window")
		w.Visible = true
		for _, path in { "Canvas/Rail", "Canvas/InfoCard/PityNote", "Canvas/RollBar/Roll1", "Canvas/Options/Auto", "Canvas/PayToggle/Tokens", "RatesPopup/Panel/List", "MilestonesPopup/Panel/Grid", "Summary/Panel/Grid" } do
			Baked.Find(w, path) -- fail early with a clear message if the baked screen is outdated (concept D layout)
		end
		GachaPage.Bind(gui, ctx) -- scales the 1280x720 canvas itself
	end)
	ensuring = false
	if not ok then
		error(err, 0)
	end
end

local function bannerOpen(b: any): boolean
	local now = os.time()
	return (b.StartsUTC == nil or now >= b.StartsUTC) and (b.EndsUTC == nil or now < b.EndsUTC)
end

function GachaPageController.Refresh()
	if isOpen and gui then
		GachaPage.Fill(DataController.Profile)
	end
end

function GachaPageController.IsOpen(): boolean
	return isOpen
end

function GachaPageController.Open(bannerId: string?)
	local id = bannerId or "Altar"
	local b = Registry.AuraBanners[id]
	if not b then
		warn(`[GachaPage] unknown banner "{tostring(bannerId)}"`)
		return
	end
	if not bannerOpen(b) then
		HUD.Notify(`{b.Name} is not open right now`, T.Bad)
		return
	end
	MenuManager.WillOpen("GachaPage")
	ensure()
	GachaPage.Show(id)
	isOpen = true
	gui.Enabled = true
	GachaPageController.Refresh()
end

function GachaPageController.Close()
	if not isOpen then
		return
	end
	isOpen = false
	GachaPage.Stop()
	if gui then
		gui.Enabled = false
	end
	MenuManager.Closed("GachaPage")
end

function GachaPageController.Init()
	local banner = (HUD :: any).BannerRequested
	if banner then
		banner:Connect(GachaPageController.Open)
	end
	task.spawn(function()
		local ok, ev = pcall(Remotes.Event, "OpenBanner")
		if ok and ev then
			ev.OnClientEvent:Connect(GachaPageController.Open)
		else
			warn("[GachaPage] RemoteEvent OpenBanner missing:", ev)
		end
	end)
	DataController.Changed:Connect(GachaPageController.Refresh)
	task.spawn(function()
		while true do
			task.wait(TICK)
			if isOpen then
				GachaPage.Tick()
			end
		end
	end)
	task.spawn(ensure) -- find the baked screen early so the first open is instant
end

MenuManager.Register("GachaPage", {
	Layer = "Main",
	StackOn = { "Events", "Inventory", "Auras" }, -- back button returns to where the player came from
	Open = GachaPageController.Open,
	Close = GachaPageController.Close,
	IsOpen = GachaPageController.IsOpen,
	Gui = function()
		return gui
	end,
})

return GachaPageController
