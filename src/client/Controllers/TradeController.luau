--!nonstrict
-- Trade window (C41 "Trade Grid", Figma 3807:1398).
--   No trade: invite list / license row (Window.Row list). Active trade: grid layout with
--   Your inventory (4 columns x 3 visible rows, VirtualGrid, scrolls by itself, worn gear locked) on the left and
--   two offers (2 slots each) on the right. Pressing any slot opens the normal Item Card (UI/ItemDetail):
--   inventory = ADD TO TRADE (grey when worn), own offer = REMOVE, partner's offer = read-only.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Registry = require(Shared.Registry)
local Inventory = require(Shared.Inventory)
local Remotes = require(Shared.Remotes)
local TradeRules = require(Shared.TradeRules)
local Format = require(Shared.Util.Format)
local DataController = require(script.Parent.DataController)
local HUD = require(script.Parent.HUDController)
local UI = script.Parent.Parent.UI
local Window = require(UI.Window)
local New = require(UI.New)
local ItemDetail = require(UI.ItemDetail)
local ItemSlots = require(UI.ItemSlots)
local Modal = require(UI.Modal)
local VirtualGrid = require(UI.VirtualGrid)
local T = New.Theme

local TradeController = {}
local config = Registry.GameConfig.Trade
local requestRemote = Remotes.Func("TradeAction")
local window: any
local ui: any = nil
local state: any = nil
local ordering = 0
local invoking = false
local selectedKey: string? = nil
local inviteModal: string? = nil

local function request(action: string, fields: any)
	if invoking then
		return
	end
	invoking = true
	local ok, accepted, message = pcall(function()
		return requestRemote:InvokeServer(action, fields)
	end)
	invoking = false
	if not ok or not accepted then
		HUD.Notify(if ok then (message or "Trade request failed") else "Trade is unavailable", T.Bad)
	end
end

local function command(view: any, action: string, fields: any?)
	local payload = fields or {}
	payload.Id = view.Id
	payload.Revision = view.Revision
	request(action, payload)
end

local function row(props: any)
	ordering += 1
	props.Order = ordering
	Window.Row(props).Parent = window.Body
end

-- Grid entry (ItemSlots.Bind) for an item or bait.
local function entryOf(selection: any, locked: boolean?, count: number?): any
	local item = selection.Item
	if item then
		local name, rarity, icon = Inventory.Describe(item)
		return { Key = item.UUID, Kind = item.Kind, Id = item.Id, UUID = item.UUID, Name = name, Rarity = rarity, Icon = icon, Mutation = item.Mutation, Plus = item.Enhance or 0, Equipped = locked }
	end
	local def = Registry.Equipment.Baits.Items[selection.Key]
	return { Key = selection.Key, Kind = "Bait", Id = selection.Key, Name = def.Name, Icon = `equipment/{selection.Key}`, Count = count }
end

-- Tradable items, worn gear (locked) and spare tradable baits; empty slots complete the last row (min 3 rows).
local function inventoryEntries(profile: any, mine: { any }): { any }
	local offered: { [string]: number } = {}
	for _, selection in mine do
		offered[selection.Key] = (offered[selection.Key] or 0) + 1
	end
	local result: { any } = {}
	for _, item in profile.Bag do
		local def = Registry.Items[item.Id]
		local worn = Inventory.IsWorn(profile, item)
		if not offered[item.UUID] and (Inventory.CanTrade(profile, item) or (worn and def and def.IsTradable and not Inventory.IsBound(item))) then
			table.insert(result, entryOf({ Kind = "Item", Key = item.UUID, Item = item }, worn))
		end
	end
	for id in config.TradableBaits do
		local left = TradeRules.BaitAvailable(profile, id) - (offered[id] or 0)
		if left > 0 then
			table.insert(result, entryOf({ Kind = "Bait", Key = id }, false, left))
		end
	end
	local total = math.max(12, math.ceil(#result / 4) * 4)
	for _ = #result + 1, total do
		table.insert(result, { Key = "", Kind = "Empty" })
	end
	return result
end

local function openCard(entry: any, holder: GuiObject, trade: any)
	selectedKey = entry.Key
	ItemDetail.Show({ Kind = entry.Kind, Id = entry.Id, UUID = entry.UUID, Trade = trade }, holder)
	if ui then
		ui.Grid:Refresh()
		for _, side in { "Mine", "Theirs" } do
			for _, cell in ui[side] do
				ItemSlots.Bind(cell.Holder, cell.Entry, selectedKey)
			end
		end
	end
end

local function buildGrid(): any
	local built: any = { Mine = {}, Theirs = {} }
	-- Figma "Window Trade" 760x610 (3808:1496); x/y below are Figma minus the 20px window padding, root starts under the header
	local root = New("Frame", { Name = "TradeGrid", Position = UDim2.fromOffset(0, 86), Size = UDim2.new(1, 0, 1, -86), BackgroundTransparency = 1, Visible = false, Parent = window.Frame })
	built.Root = root
	local function divider(y: number)
		New("Frame", { Position = UDim2.fromOffset(4, y), Size = UDim2.fromOffset(712, 2), BackgroundColor3 = T.Track, BorderSizePixel = 0, Parent = root })
	end
	divider(0)

	local inv = New.Panel({ Name = "Inventory", Position = UDim2.fromOffset(4, 20), Size = UDim2.fromOffset(440, 380), Parent = root })
	New.Title({ Position = UDim2.fromOffset(16, 13), Size = UDim2.fromOffset(250, 26), Text = "Your inventory", TextSize = 20, TextXAlignment = Enum.TextXAlignment.Left, Parent = inv })
	New.Text({ Position = UDim2.fromOffset(16, 40), Size = UDim2.fromOffset(344, 20), Text = "Tap an item to inspect it.", TextColor3 = T.SubText, TextSize = 14, TextXAlignment = Enum.TextXAlignment.Left, Parent = inv })
	-- 4 x 3 cells of 72 with 12px gaps; the padding keeps slot strokes and badges from being clipped by the scroller
	local scroll = New("ScrollingFrame", {
		Name = "Scroll",
		Position = UDim2.fromOffset(34, 70),
		Size = UDim2.fromOffset(372, 3 * 72 + 2 * 12 + 16),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 4,
		ScrollBarImageColor3 = T.Track,
		Parent = inv,
		[New.Children] = { New("UIPadding", { PaddingTop = UDim.new(0, 8), PaddingBottom = UDim.new(0, 8), PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8) }) },
	})
	local grid
	grid = VirtualGrid.new(scroll, {
		CellSize = Vector2.new(72, 72),
		Gap = Vector2.new(12, 12),
		Columns = 4,
		Create = function()
			return ItemSlots.NewCell(function(holder)
				local entry = grid:ItemOf(holder)
				local view = state
				if not entry or entry.Kind == "Empty" or not view then
					return
				end
				openCard(entry, holder, {
					Action = if entry.Equipped
						then { Text = "ADD TO TRADE", Color = T.Disabled }
						else { Text = "ADD TO TRADE", Color = T.Sky, Run = function()
							ItemDetail.Hide()
							command(view, "Add", { Kind = if entry.Kind == "Bait" then "Bait" else "Item", Key = entry.Key })
						end },
				})
			end)
		end,
		Bind = function(holder, entry)
			ItemSlots.Bind(holder, entry, selectedKey)
		end,
	})
	built.Grid = grid

	local offerPanel = New.Panel({ Name = "Offer", Position = UDim2.fromOffset(460, 20), Size = UDim2.fromOffset(256, 380), BackgroundColor3 = T.TintSand, Parent = root })
	New.Title({ Position = UDim2.fromOffset(16, 13), Size = UDim2.fromOffset(155, 26), Text = "Offer", TextSize = 20, TextXAlignment = Enum.TextXAlignment.Left, Parent = offerPanel })
	local function offer(y: number, side: string): TextLabel
		local label = New.Text({ Position = UDim2.fromOffset(16, y), Size = UDim2.fromOffset(224, 22), Text = "", TextSize = 16, TextXAlignment = Enum.TextXAlignment.Left, Parent = offerPanel })
		for slot = 1, config.MaxPerSide do
			local cell: any = { Entry = { Key = "", Kind = "Empty" } }
			cell.Holder = ItemSlots.NewCell(function()
				local view = state
				if cell.Entry.Kind == "Empty" or not view then
					return
				end
				if side == "Mine" then
					openCard(cell.Entry, cell.Holder, {
						Action = if view.Phase == "Saving" then nil else { Text = "REMOVE", Color = T.Bad, Run = function()
							ItemDetail.Hide()
							command(view, "Remove", { Slot = slot })
						end },
					})
				else
					local selection = view.Theirs[slot]
					if selection then
						openCard(cell.Entry, cell.Holder, { Foreign = selection.Item or { Kind = "Bait", Id = selection.Key } })
					end
				end
			end)
			cell.Holder.Size = UDim2.fromOffset(72, 72)
			cell.Holder.Position = UDim2.fromOffset(26 + (slot - 1) * 100, y + 34)
			cell.Holder.Parent = offerPanel
			built[side][slot] = cell
		end
		return label
	end
	built.MineLabel = offer(58, "Mine")
	New("Frame", { Position = UDim2.fromOffset(16, 193), Size = UDim2.fromOffset(224, 2), BackgroundColor3 = T.Track, BorderSizePixel = 0, Parent = offerPanel })
	built.TheirLabel = offer(213, "Theirs")
	local status = New("Frame", { Position = UDim2.fromOffset(16, 337), Size = UDim2.fromOffset(224, 28), BackgroundColor3 = T.Track, BorderSizePixel = 0, Parent = offerPanel, [New.Children] = { New.Pill() } })
	built.Status = New.Text({ Size = UDim2.fromScale(1, 1), Text = "", TextSize = 14, Parent = status })

	divider(418)
	local chip = New("Frame", { Position = UDim2.fromOffset(4, 442), Size = UDim2.fromOffset(123, 40), BackgroundColor3 = T.Panel, Parent = root, [New.Children] = { New.Pill(), New.Stroke(T.Track, 2) } })
	New.Image({ Key = "ui/status/coin", Fallback = T.Gold, Position = UDim2.fromOffset(10, 8), Size = UDim2.fromOffset(24, 24), Parent = chip })
	built.Fee = New.Title({ Position = UDim2.fromOffset(42, 9), Size = UDim2.fromOffset(75, 22), Text = "0", TextSize = 20, TextXAlignment = Enum.TextXAlignment.Left, Parent = chip })
	New.Text({ Position = UDim2.fromOffset(149, 438), Size = UDim2.fromOffset(200, 22), Text = "Coins each", TextSize = 16, TextXAlignment = Enum.TextXAlignment.Left, Parent = root })
	New.Text({ Position = UDim2.fromOffset(149, 462), Size = UDim2.fromOffset(260, 20), Text = "Charged on completion", TextColor3 = T.SubText, TextSize = 14, TextXAlignment = Enum.TextXAlignment.Left, Parent = root })
	built.Confirm = New.Button({ Position = UDim2.fromOffset(559, 434), Size = UDim2.fromOffset(157, 57), Text = "CONFIRM", BackgroundColor3 = T.Accent, MaxTextSize = 22, Parent = root })
	built.Confirm.Activated:Connect(function()
		local view = state
		if view and view.Phase ~= "Saving" and #view.Mine + #view.Theirs > 0 then
			command(view, "Confirm", { Ready = not view.Ready })
		end
	end)
	return built
end

local function renderGrid(view: any, profile: any?)
	local saving = view.Phase == "Saving"
	window.Header.Text = if saving then "Saving trade..." else `Trading with {view.Other}`
	ui.Grid:SetItems(if profile then inventoryEntries(profile, view.Mine) else {})
	for side, list in { Mine = view.Mine, Theirs = view.Theirs } do
		for slot = 1, config.MaxPerSide do
			local selection = list[slot]
			local cell = ui[side][slot]
			cell.Entry = if selection then entryOf(selection) else { Key = "", Kind = "Empty" }
			ItemSlots.Bind(cell.Holder, cell.Entry, selectedKey)
		end
	end
	ui.MineLabel.Text = "Your offer"
	ui.TheirLabel.Text = `{view.Other}'s offer`
	ui.Fee.Text = Format.Number(view.Fee)
	ui.Status.Text = if view.OtherReady then `{view.Other} confirmed` else "Waiting for confirmation"
	local blocked = saving or #view.Mine + #view.Theirs == 0
	New.SetButtonColor(ui.Confirm, if blocked then T.Disabled elseif view.Ready then T.Gold else T.Accent, if blocked then T.DisabledText else nil)
	ui.Confirm.Text = if view.Ready then "UNCONFIRM" else "CONFIRM"
end

local function render()
	if not window.IsOpen() then
		return
	end
	local view = state
	local profile = DataController.Profile
	local active = view ~= nil and view.Phase ~= "Invited"
	window.Body.Visible = not active
	if ui then
		ui.Root.Visible = active
	end
	if not view or view.Phase == "Invited" then
		ItemDetail.Hide()
	end
	ordering = 0
	Window.Clear(window.Body)
	Window.List(window.Body)
	if not view then
		window.Header.Text = "Choose a player in this server."
		if not profile then
			window.Header.Text = "Loading your save..."
			return
		end
		if not TradeRules.HasLicense(profile, RunService:IsStudio()) then
			local pass = Registry.Products.Passes.TradeLicense
			row({
				Title = "Trade License required",
				Sub = "With a license you can send requests. You can accept an invitation now.",
				Height = 86,
				Button = if pass.PassId > 0 then {
					Text = "GET LICENSE",
					OnClick = function()
						Remotes.Event("PromptPass"):FireServer("TradeLicense")
					end,
				} else nil,
			})
			return
		end
		for _, player in Players:GetPlayers() do
			if player ~= Players.LocalPlayer then
				row({ Title = player.Name, Button = { Text = "INVITE", OnClick = function()
					request("Invite", { UserId = player.UserId })
				end } })
			end
		end
		if ordering == 0 then
			window.Header.Text = "Join a server with another player to trade."
		end
		return
	end
	if view.Phase == "Invited" then
		-- the invited player answers in a Modal; the sender waits here (X cancels the request)
		window.Header.Text = if view.Invited then `{view.Other} invited you to trade.` else `Waiting for {view.Other}.`
		return
	end
	if not ui then
		ui = buildGrid()
		ui.Root.Visible = true
	end
	renderGrid(view, profile)
end

function TradeController.Init()
	window = Window.Create({ Name = "Trade", Title = "Trade", Size = Vector2.new(760, 640) })
	window.OnOpen = render
	window.OnClose = function()
		ItemDetail.Hide()
		-- closing the window ends the trade for both players (same as cancel)
		if state then
			command(state, "Cancel")
		end
	end
	ItemDetail.Hidden:Connect(function()
		if selectedKey then
			selectedKey = nil
			if ui and state then
				renderGrid(state, DataController.Profile)
			end
		end
	end)
	Remotes.Event("TradeUpdate").OnClientEvent:Connect(function(view, notice)
		local had = state ~= nil
		local incoming = view and view.Phase == "Invited" and view.Invited and (not state or state.Id ~= view.Id)
		state = view
		if notice then
			HUD.Notify(notice, if notice == "Trade complete" then T.Good else T.SubText)
		end
		if incoming then
			Modal.Confirm({
				Title = `{view.Other} wants to trade`,
				Message = `Accept the trade request from {New.Highlight(view.Other)}? Trades are final. We are not responsible for items or Coins you trade away, so check every item before you confirm.`,
				ConfirmText = "Accept",
				CancelText = "Decline",
				ConfirmColor = T.Good,
				Icon = "ui/icons/trade_license",
				IconColor = T.Sky,
				OnCancel = function()
					if state and state.Id == view.Id then
						command(state, "Cancel")
					end
				end,
			}, function()
				if state and state.Id == view.Id then
					command(state, "Accept")
				end
			end)
			inviteModal = view.Id
		elseif not view then
			-- the other player closed it, or it finished or expired: close everything on this side too
			if inviteModal then
				inviteModal = nil
				Modal.Close()
			end
			if had and window.IsOpen() then
				window.Close()
			end
			render()
		else
			if inviteModal == view.Id and view.Phase ~= "Invited" then
				inviteModal = nil
			end
			if view.Phase ~= "Invited" or not view.Invited then
				if not window.IsOpen() then
					window.Open()
				else
					render()
				end
			end
		end
	end)
	Players.PlayerAdded:Connect(function()
		if not state then
			render()
		end
	end)
	Players.PlayerRemoving:Connect(function()
		if not state then
			task.defer(render)
		end
	end)
	local previousLicense: boolean? = nil
	DataController.Changed:Connect(function(profile)
		local hasLicense = TradeRules.HasLicense(profile, RunService:IsStudio())
		if hasLicense ~= previousLicense and not state then
			render()
		end
		previousLicense = hasLicense
	end)
end

return TradeController
