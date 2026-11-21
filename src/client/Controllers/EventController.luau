--!nonstrict
-- Events hub (Figma E0). The window is baked (StarterGui "Events", UI/Screens/Events); this controller
-- clones Templates.Card once per visible Config/Events entry (sorted by Order, hidden outside its dates,
-- see UI/EventHub) and runs the entry's Action on OPEN via UI/EventActions/<Kind>.Run(event, ctx).
--   Add an event      = add a Config/Events entry (no code).
--   Add an action kind = add UI/EventActions/<Kind>.luau (header comment of EventActions/Gacha explains ctx).
-- Opened by HUD.EventsRequested (Main Menu Events tile). EventController.OpenBanner(bannerId) opens a gacha page.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Registry = require(Shared.Registry)
local Format = require(Shared.Util.Format)

local UI = script.Parent.Parent.UI
local New = require(UI.New)
local Baked = require(UI.Baked)
local MenuManager = require(UI.MenuManager)
local EventHub = require(UI.EventHub)
local CardScreen = require(UI.Screens:WaitForChild("Events")) :: any
local Actions = UI:WaitForChild("EventActions")
local HUD = require(script.Parent.HUDController)
local DataController = require(script.Parent.DataController)
local GachaPageController = require(script.Parent.GachaPageController)

local T = New.Theme
local TICK = 5 -- seconds: timers + start/end of events

local EventController = {}

local gui: any = nil
local refs: any = nil
local isOpen = false
local cards: { [string]: any } = {} -- event id -> card
local shownKey = "" -- ids currently shown, in order (rebuild only when it changes)

local ctx = {
	openBanner = function(bannerId: string)
		GachaPageController.Open(bannerId)
	end,
	notify = function(text: string, color: Color3?)
		HUD.Notify(text, color)
	end,
	hud = HUD,
	theme = T,
}

local function runAction(id: string)
	local event = Registry.Events[id]
	if not event or event.Disabled then
		return
	end
	local kind = event.Action and event.Action.Kind
	local module = kind and Actions:FindFirstChild(kind)
	if not module then
		warn(`[Events] no UI/EventActions/{tostring(kind)} for event {id}`)
		HUD.Notify("Coming soon", T.SubText)
		return
	end
	local ok, err = pcall(function()
		(require(module) :: any).Run(event, ctx)
	end)
	if not ok then
		warn(`[Events] {id} action failed: {err}`)
	end
end

local function ensure()
	if gui then
		return
	end
	gui = Baked.Get("Events")
	gui.Enabled = false
	local w = Baked.Find(gui, "Window")
	w.Visible = true
	refs = {
		Window = w,
		List = Baked.Find(w, "List"),
		Gems = Baked.Find(w, "Header/Right/Gems/Value"),
		Card = Baked.Find(gui, "Templates/Card"),
	}
	New.FormatCurrencyChip(Baked.Find(w, "Header/Right/Gems"), 20)
	New.FitWindow(w, Vector2.new(920, 540))
	for _, c in refs.List:GetChildren() do -- baked Figma sample cards
		if c:IsA("GuiObject") then
			c:Destroy()
		end
	end
	Baked.Find(w, "Header/Right/Close").Activated:Connect(EventController.Close)
end

local function rebuild(list: { any })
	for _, c in cards do
		c:Destroy()
	end
	table.clear(cards)
	for i, e in list do
		local card = refs.Card:Clone()
		card.Name = e.Id
		card.Visible = true
		card.LayoutOrder = i
		card.Parent = refs.List
		New.ApplyImages(card)
		New.HookButtons(card)
		local id = e.Id
		card.Bottom.Open.Activated:Connect(function()
			runAction(id)
		end)
		cards[id] = card
	end
end

function EventController.Refresh()
	if not isOpen or not gui then
		return
	end
	local profile = DataController.Profile
	refs.Gems.Text = Format.Number(profile and profile.Gems or 0)
	local now = os.time()
	local list = EventHub.Sorted(now)
	local ids = {}
	for _, e in list do
		table.insert(ids, e.Id)
	end
	local key = table.concat(ids, ",")
	if key ~= shownKey or next(cards) == nil then
		shownKey = key
		rebuild(list)
	end
	for _, e in list do
		CardScreen.SetCard(cards[e.Id], EventHub.CardInfo(e.Event, now))
	end
end

function EventController.IsOpen(): boolean
	return isOpen
end

function EventController.Open()
	MenuManager.WillOpen("Events")
	ensure()
	isOpen = true
	gui.Enabled = true
	EventController.Refresh()
end

function EventController.Close()
	if not isOpen then
		return
	end
	isOpen = false
	if gui then
		gui.Enabled = false
	end
	MenuManager.Closed("Events")
end

function EventController.Toggle()
	if isOpen then
		EventController.Close()
	else
		EventController.Open()
	end
end

-- Open the gacha page of a banner (other code: Auras window, altar prompt, ...).
function EventController.OpenBanner(bannerId: string)
	GachaPageController.Open(bannerId) -- stacks on Events (MenuManager StackOn): closing it goes back here
end

function EventController.Init()
	local requested = (HUD :: any).EventsRequested
	if requested then
		requested:Connect(EventController.Open)
	end
	DataController.Changed:Connect(EventController.Refresh)
	task.spawn(function()
		while true do
			task.wait(TICK)
			if isOpen then
				EventController.Refresh()
			end
		end
	end)
	task.spawn(ensure)
end

MenuManager.Register("Events", { Layer = "Main", Open = EventController.Open, Close = EventController.Close, IsOpen = EventController.IsOpen, Gui = function()
	return gui
end })

return EventController
