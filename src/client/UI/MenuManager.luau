--!strict
-- MenuManager: the one place that decides which screens may be open together.
-- Every screen registers once with a Layer; its controller calls WillOpen(name) at the top of its Open
-- and Closed(name) at the end of its Close. The manager closes whatever conflicts, keeps the stack
-- order, and sets DisplayOrder so a stacked window is always drawn above the window it sits on.
--
-- Layers (see docs/MENU_MANAGER.md):
--   Hub      Main Menu. Opening it closes Main / Popup / Dialogue.
--   Main     Full windows (Inventory, Shop, Character, Store...). Only one at a time, unless the new
--            window lists the open one in StackOn (Skills over Character, Aura Dex over Inventory).
--            Closing a Main also closes every window stacked on it and the Popup.
--   Dialogue NPC talk box. Opening it closes Hub / Main / Popup. Opening a Main closes it.
--   Popup    Small cards anchored to a window (Item Detail). One at a time; closed when a Main changes.
--   Modal    Confirm box, reveals, rewards. Never closes anything; stacks above everything.
--
--   MenuManager.Register("Inventory", { Layer = "Main", Close = InventoryController.Close,
--       IsOpen = InventoryController.IsOpen, Gui = function() return gui end })
--   function InventoryController.Open() MenuManager.WillOpen("Inventory") ... end
--   function InventoryController.Close() ... MenuManager.Closed("Inventory") end
--   MenuManager.CloseTop() -- closes the top-most screen (back button / Esc behaviour)

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Signal = require(Shared.Util.Signal)

export type Layer = "Hub" | "Main" | "Dialogue" | "Popup" | "Modal"

export type Def = {
	Layer: Layer,
	Close: () -> (),
	Open: ((...any) -> ())?, -- only needed for MenuManager.Open / Toggle
	IsOpen: (() -> boolean)?, -- lets the manager drop entries that were closed behind its back
	StackOn: { string }?, -- Main only: windows this one may stay on top of
	Gui: (() -> Instance?)?, -- ScreenGui whose DisplayOrder the manager may set (Main only)
}

local MenuManager = {}

MenuManager.Changed = Signal.new() -- (name, isOpen)

-- DisplayOrder bands. Main windows climb by STEP for each stacked window; keep under Hub.
local MAIN_BASE = 10
local MAIN_STEP = 2
local TOP_ORDER: { Layer } = { "Modal", "Popup", "Main", "Dialogue", "Hub" }
local DESCRIBE_ORDER: { Layer } = { "Hub", "Main", "Dialogue", "Popup", "Modal" }

local defs: { [string]: Def } = {}
local opened: { string } = {} -- every open managed screen, oldest first
local closing: { [string]: boolean } = {}
local blockThisTurn = false
local openedAt: { [string]: number } = {} -- WillOpen time: a screen enables its gui just AFTER WillOpen
local GUI_GRACE = 0.6 -- seconds a freshly opened screen keeps the backdrop even while its gui is still hidden

local function coverInputTurn()
	if blockThisTurn then
		return
	end
	blockThisTurn = true
	task.defer(function()
		blockThisTurn = false
	end)
end

local function indexOf(name: string): number?
	return table.find(opened, name)
end

local function layerOf(name: string): Layer?
	local d = defs[name]
	return d and d.Layer
end

local function prune()
	for i = #opened, 1, -1 do
		local d = defs[opened[i]]
		if d and d.IsOpen and not d.IsOpen() then
			local name = table.remove(opened, i) :: string
			coverInputTurn()
			MenuManager.Changed:Fire(name, false)
		end
	end
end

-- Full-screen black backdrop behind every full menu (Main / Hub layers). It ignores the top bar and the device
-- safe area, so it always covers the whole screen. Sits just under the lowest open menu.
local backdrop: ScreenGui? = nil
local recheckRunning = false
local function updateBackdrop()
	local low: number? = nil
	for _, name in opened do
		local d = defs[name]
		if d and (d.Layer == "Main" or d.Layer == "Hub") then
			local gui = d.Gui and d.Gui()
			-- a menu whose gui is already hidden must not keep the backdrop up (but one that is just opening may
			-- not have enabled its gui yet: without the grace the backdrop flashed off and on, or never showed)
			local fresh = os.clock() - (openedAt[name] or 0) < GUI_GRACE
			local hidden = if gui then gui:IsA("ScreenGui") and not gui.Enabled else d.Gui ~= nil -- Gui() gave nil: nothing on screen
			if fresh or not hidden then
				local order = if gui and gui:IsA("ScreenGui") then gui.DisplayOrder else (if d.Layer == "Hub" then 20 else 10)
				low = if low then math.min(low, order) else order
			end
		end
	end
	if not low then
		if backdrop then
			backdrop.Enabled = false
		end
		return
	end
	if not backdrop then
		local player = game:GetService("Players").LocalPlayer
		local pg = player and player:FindFirstChildOfClass("PlayerGui")
		if not pg then
			return
		end
		local g = Instance.new("ScreenGui")
		g.Name = "MenuBackdrop"
		g.ResetOnSpawn = false
		g.IgnoreGuiInset = true
		g.ScreenInsets = Enum.ScreenInsets.None
		g.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
		local f = Instance.new("TextButton") -- a button so taps do not fall through to the world
		f.Name = "Black"
		f.Size = UDim2.fromScale(1, 1)
		f.BackgroundColor3 = Color3.new(0, 0, 0)
		f.BackgroundTransparency = 0.35
		f.BorderSizePixel = 0
		f.Text = ""
		f.AutoButtonColor = false
		f.Parent = g
		g.Parent = pg
		backdrop = g
	end
	local bd = backdrop :: ScreenGui
	bd.DisplayOrder = math.max(1, low - 1)
	bd.Enabled = true
	-- Self-heal: events alone left the backdrop stuck on when a menu failed to show or hid itself silently,
	-- so re-check twice a second until the backdrop turns itself off.
	if not recheckRunning then
		recheckRunning = true
		task.spawn(function()
			while bd.Enabled do
				task.wait(0.5)
				updateBackdrop()
			end
			recheckRunning = false
		end)
	end
end

local function restack()
	local depth = 0
	for _, name in opened do
		local d = defs[name]
		if d and d.Layer == "Main" then
			local gui = d.Gui and d.Gui()
			if gui and gui:IsA("ScreenGui") then
				gui.DisplayOrder = MAIN_BASE + depth * MAIN_STEP
			end
			depth += 1
		end
	end
	updateBackdrop()
end

-- Close one screen through its own controller (which then reports back with Closed).
local function closeScreen(name: string)
	if closing[name] or not indexOf(name) then
		return
	end
	closing[name] = true
	local d = defs[name]
	local ok, err = pcall(function()
		d.Close()
	end)
	if not ok then
		warn(`[MenuManager] Close "{name}" failed: {err}`)
	end
	closing[name] = nil
	MenuManager.Closed(name) -- in case the controller did not report
end

local function closeLayer(layer: Layer, keep: { [string]: boolean }?)
	-- re-scan after every close: closing one window can cascade and remove others
	while true do
		local target: string? = nil
		for i = #opened, 1, -1 do
			local name = opened[i]
			if layerOf(name) == layer and not closing[name] and not (keep and keep[name]) then
				target = name
				break
			end
		end
		if not target then
			return
		end
		closeScreen(target)
	end
end

function MenuManager.Register(name: string, def: Def)
	if defs[name] and defs[name].Layer ~= def.Layer then
		warn(`[MenuManager] "{name}" registered twice with different layers`)
	end
	defs[name] = def
end

function MenuManager.IsRegistered(name: string): boolean
	return defs[name] ~= nil
end

-- Call at the top of a screen's Open. Closes whatever may not stay open with it.
function MenuManager.WillOpen(name: string)
	local d = defs[name]
	if not d then
		warn(`[MenuManager] WillOpen "{name}" is not registered`)
		return
	end
	coverInputTurn()
	prune()
	if indexOf(name) then
		if d.Layer == "Main" then
			-- already open: bring it to the top of the stack
			table.remove(opened, indexOf(name) :: number)
			table.insert(opened, name)
			restack()
		end
		return
	end

	if d.Layer == "Hub" then
		closeLayer("Popup")
		closeLayer("Main")
		closeLayer("Dialogue")
	elseif d.Layer == "Main" then
		local keep: { [string]: boolean } = {}
		local stackOn: { string } = d.StackOn or {}
		for _, other in stackOn do
			keep[other] = true
		end
		closeLayer("Popup")
		closeLayer("Main", keep)
		closeLayer("Dialogue")
		closeLayer("Hub")
	elseif d.Layer == "Dialogue" then
		closeLayer("Popup")
		closeLayer("Main")
		closeLayer("Hub")
		closeLayer("Dialogue")
	elseif d.Layer == "Popup" then
		closeLayer("Popup")
	end
	-- Modal: closes nothing

	table.insert(opened, name)
	openedAt[name] = os.clock()
	restack()
	MenuManager.Changed:Fire(name, true)
end

-- Call at the end of a screen's Close. Also closes windows stacked on it. Safe to call twice.
function MenuManager.Closed(name: string)
	local i = indexOf(name)
	if not i then
		return
	end
	coverInputTurn()
	table.remove(opened, i)
	if layerOf(name) == "Main" then
		closeLayer("Popup")
		-- windows that were stacked on this one go with it
		for j = #opened, 1, -1 do
			local other = opened[j]
			local od = other and defs[other]
			if od and od.Layer == "Main" and od.StackOn and table.find(od.StackOn, name) and j >= i then
				closeScreen(other)
			end
		end
	end
	restack()
	MenuManager.Changed:Fire(name, false)
end

function MenuManager.IsOpen(name: string): boolean
	return indexOf(name) ~= nil
end

-- Open / toggle by name (needs def.Open). Extra args go to the controller.
function MenuManager.Open(name: string, ...: any)
	local d = defs[name]
	if d and d.Open then
		d.Open(...)
	else
		warn(`[MenuManager] Open "{name}" has no Open function`)
	end
end

function MenuManager.Close(name: string)
	closeScreen(name)
end

function MenuManager.Toggle(name: string, ...: any)
	if MenuManager.IsOpen(name) then
		closeScreen(name)
	else
		MenuManager.Open(name, ...)
	end
end

-- Top-most open screen (Modal > Popup > top Main > Dialogue > Hub), or nil.
function MenuManager.Top(): string?
	prune()
	for _, layer in TOP_ORDER do
		for i = #opened, 1, -1 do
			if layerOf(opened[i]) == layer then
				return opened[i]
			end
		end
	end
	return nil
end

-- A click can close a menu before other InputBegan listeners see the same click.
function MenuManager.BlocksWorldInput(): boolean
	return MenuManager.Top() ~= nil or blockThisTurn
end

-- Back button: closes only the top-most screen. Returns false when nothing was open.
function MenuManager.CloseTop(): boolean
	local top = MenuManager.Top()
	if not top then
		return false
	end
	closeScreen(top)
	return true
end

-- Closes every screen of a layer, or everything (except Modal) when layer is nil.
function MenuManager.CloseAll(layer: Layer?)
	if layer then
		closeLayer(layer)
		return
	end
	closeLayer("Popup")
	closeLayer("Main")
	closeLayer("Dialogue")
	closeLayer("Hub")
end

-- Names of open screens, oldest first (optionally one layer).
function MenuManager.OpenList(layer: string?): { string }
	prune()
	local out = {}
	for _, name in opened do
		if layer == nil or layerOf(name) == layer then
			table.insert(out, name)
		end
	end
	return out
end

-- Back key (call once from the client bootstrap): gamepad ButtonB closes the top-most screen.
-- Escape only closes the NPC dialogue: Roblox always opens its own menu on Escape too.
local backBound = false
function MenuManager.BindBackKey()
	if backBound then
		return
	end
	backBound = true
	game:GetService("UserInputService").InputBegan:Connect(function(input, processed)
		if input.KeyCode == Enum.KeyCode.ButtonB then
			MenuManager.CloseTop()
		elseif not processed and input.KeyCode == Enum.KeyCode.Escape and MenuManager.Top() == "Dialogue" then
			MenuManager.CloseTop()
		end
	end)
end

-- "Inventory > Auras | Popup: ItemDetail" for Studio checks.
function MenuManager.Describe(): string
	local parts = {}
	for _, layer in DESCRIBE_ORDER do
		local list = MenuManager.OpenList(layer)
		if #list > 0 then
			table.insert(parts, `{layer}: {table.concat(list, " > ")}`)
		end
	end
	return if #parts > 0 then table.concat(parts, " | ") else "(none)"
end

-- Keeps the backdrop in step with what is really on screen: a screen may be enabled just after WillOpen, or closed
-- without telling the manager (the page was left open and hidden, leaving a black screen).
task.spawn(function()
	while true do
		task.wait(0.1)
		updateBackdrop() -- never prune() here: a screen is not "open" yet between WillOpen and its own Open finishing
	end
end)

return MenuManager
