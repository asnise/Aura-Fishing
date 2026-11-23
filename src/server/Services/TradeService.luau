--!strict
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Inventory = require(Shared.Inventory)
local Registry = require(Shared.Registry)
local Remotes = require(Shared.Remotes)
local TradeRules = require(Shared.TradeRules)
local DataService = require(script.Parent.DataService)
local TradeJournal = require(script.Parent.TradeJournal)

local TradeService = {}
local config = Registry.GameConfig.Trade
local studio = RunService:IsStudio()
local tradeUpdate = Remotes.Event("TradeUpdate")

type Session = {
	Id: string,
	Players: { Player },
	Offers: { { TradeRules.Selection } },
	Ready: { boolean },
	Revision: number,
	Phase: "Invited" | "Offering" | "Saving",
	ExpiresAt: number,
}
local sessions: { [Player]: Session } = {}
local lastAction: { [Player]: number } = {}

local function send(trade: Session)
	local fee = TradeRules.Fee(trade.Offers[1], trade.Offers[2])
	for i, player in trade.Players do
		if player.Parent == Players then
			local other = trade.Players[3 - i]
			tradeUpdate:FireClient(player, {
				Id = trade.Id,
				Phase = trade.Phase,
				Revision = trade.Revision,
				Other = other.Name,
				Invited = i == 2,
				Mine = trade.Offers[i],
				Theirs = trade.Offers[3 - i],
				Ready = trade.Ready[i],
				OtherReady = trade.Ready[3 - i],
				Fee = fee,
			})
		end
	end
end

local function close(trade: Session, message: string)
	for _, player in trade.Players do
		sessions[player] = nil
		if player.Parent == Players then
			tradeUpdate:FireClient(player, nil, message)
		end
	end
end

local function invite(player: Player, targetId: any): (boolean, string)
	if type(targetId) ~= "number" or targetId % 1 ~= 0 or targetId == player.UserId then
		return false, "Choose another player"
	end
	if not DataService.TradeAvailable() then
		return false, "Trade storage is unavailable"
	end
	if not TradeRules.HasLicense(DataService.Get(player), studio) then
		return false, "A Trade License is required to send a request"
	end
	local target = Players:GetPlayerByUserId(targetId)
	if not target or target.Parent ~= Players or not DataService.Get(target) then
		return false, "That player is unavailable"
	end
	if sessions[player] or sessions[target] then
		return false, "A player is already in a trade"
	end
	local trade: Session = {
		Id = Inventory.NewUUID(),
		Players = { player, target },
		Offers = { {}, {} },
		Ready = { false, false },
		Revision = 0,
		Phase = "Invited",
		ExpiresAt = os.clock() + config.InviteSeconds,
	}
	sessions[player] = trade
	sessions[target] = trade
	send(trade)
	return true, "Trade request sent"
end

local function resetReady(trade: Session)
	trade.Ready[1] = false
	trade.Ready[2] = false
	trade.Revision += 1
	send(trade)
end

local function finish(trade: Session, record: TradeJournal.Record)
	local first, second = trade.Players[1], trade.Players[2]
	local outcome, touched = TradeJournal.Begin(DataService.UpdateTradeJournal, record, function(userId, id)
		return DataService.PrepareTrade(if first.UserId == userId then first else second, id)
	end)
	if touched then
		while not outcome do
			if not first.Parent and not second.Parent then
				close(trade, "Trade will recover on rejoin")
				return
			end
			task.wait(4)
			outcome = TradeJournal.Decide(DataService.UpdateTradeJournal, record.Id, false)
		end
	end

	local firstDone, secondDone = false, false
	repeat
		firstDone = firstDone or DataService.FinishTrade(first, trade.Id, outcome)
		secondDone = secondDone or DataService.FinishTrade(second, trade.Id, outcome)
		if not (firstDone and secondDone) then
			task.wait(4)
		end
	until firstDone and secondDone
	close(trade, if outcome and outcome.Status == "Committed" then "Trade complete" else "Trade cancelled. Your items and Coins were kept.")
end

local function commit(trade: Session): (boolean, string)
	local first, second = trade.Players[1], trade.Players[2]
	local a, b = DataService.Get(first), DataService.Get(second)
	if not a or not b or first.Parent ~= Players or second.Parent ~= Players then
		return false, "A player is unavailable"
	end
	if not TradeRules.HasLicense(a, studio) then
		return false, "The sender needs a Trade License"
	end
	local outgoingA, reasonA = TradeRules.Offer(a, first.UserId, trade.Offers[1])
	if not outgoingA then
		return false, `{first.Name}: {reasonA or "Offer changed"}`
	end
	local outgoingB, reasonB = TradeRules.Offer(b, second.UserId, trade.Offers[2])
	if not outgoingB then
		return false, `{second.Name}: {reasonB or "Offer changed"}`
	end
	local fee = TradeRules.Fee(trade.Offers[1], trade.Offers[2])
	local canReceiveA, receiveA = TradeRules.CanReceive(a, outgoingA, outgoingB, fee)
	if not canReceiveA then
		return false, `{first.Name}: {receiveA or "Cannot receive offer"}`
	end
	local canReceiveB, receiveB = TradeRules.CanReceive(b, outgoingB, outgoingA, fee)
	if not canReceiveB then
		return false, `{second.Name}: {receiveB or "Cannot receive offer"}`
	end
	for _, offer in { outgoingA, outgoingB } do
		for _, item in offer.Items do
			Inventory.MarkNew(item)
		end
	end
	local record: TradeJournal.Record = { Id = trade.Id, Status = "Preparing", Fee = fee, Offers = { outgoingA, outgoingB } }
	local locked, reason = DataService.LockTrade(first, second, record)
	if not locked then
		return false, reason or "A save is in progress"
	end
	trade.Phase = "Saving"
	send(trade)
	task.spawn(finish, trade, record)
	return true, "Saving trade"
end

local function action(player: Player, verb: any, request: any): (boolean, string)
	if type(request) ~= "table" then
		return false, "Invalid request"
	end
	if verb == "Invite" then
		return invite(player, request.UserId)
	end
	local trade = sessions[player]
	if not trade or request.Id ~= trade.Id then
		return false, "Trade is no longer active"
	end
	if trade.Phase == "Saving" then
		return false, "Saving trade. Please wait."
	end
	if os.clock() >= trade.ExpiresAt then
		close(trade, "Trade expired")
		return false, "Trade expired"
	end
	if verb == "Cancel" then
		close(trade, "Trade cancelled")
		return true, ""
	end
	local side = if trade.Players[1] == player then 1 else 2
	if trade.Phase == "Invited" then
		if verb ~= "Accept" or side ~= 2 then
			return false, "Waiting for the invited player"
		end
		trade.Phase = "Offering"
		trade.ExpiresAt = os.clock() + config.OfferSeconds
		send(trade)
		return true, ""
	end
	if request.Revision ~= trade.Revision then
		return false, "Offer changed. Review it again."
	end
	local mine = trade.Offers[side]
	local count = #mine + #trade.Offers[3 - side]
	if verb == "Remove" then
		local slot = request.Slot
		if type(slot) ~= "number" or slot % 1 ~= 0 or slot < 1 or slot > #mine then
			return false, "Unknown offer slot"
		end
		table.remove(mine, slot)
		resetReady(trade)
	elseif verb == "Add" then
		if #mine >= config.MaxPerSide then
			return false, `You can offer up to {config.MaxPerSide} items`
		end
		local data = DataService.Get(player)
		if not data then
			return false, "Your save is unavailable"
		end
		local selection, reason = TradeRules.Select(data, request.Kind, request.Key)
		if not selection then
			return false, reason or "Cannot offer this item"
		end
		local copies = 0
		for _, existing in mine do
			if existing.Kind == selection.Kind and existing.Key == selection.Key then
				copies += 1
			end
		end
		local available = if selection.Kind == "Bait" then TradeRules.BaitAvailable(data, selection.Key) else 1
		if copies >= available then
			return false, "You have already offered all available copies"
		end
		table.insert(mine, selection)
		resetReady(trade)
	elseif verb == "Confirm" and type(request.Ready) == "boolean" then
		if count == 0 then
			return false, "Add an item first"
		end
		trade.Ready[side] = request.Ready
		if trade.Ready[1] and trade.Ready[2] then
			local ok, message = commit(trade)
			if not ok then
				resetReady(trade)
				local other = trade.Players[3 - side]
				if other.Parent == Players then
					Remotes.Event("Notify"):FireClient(other, message)
				end
			end
			return ok, message
		end
		send(trade)
	else
		return false, "Invalid trade action"
	end
	return true, ""
end

function TradeService.Init()
	Remotes.Func("TradeAction").OnServerInvoke = function(player, verb, request)
		local now = os.clock()
		if lastAction[player] and now - lastAction[player] < 0.15 then
			return false, "Please wait a moment"
		end
		lastAction[player] = now
		return action(player, verb, request)
	end
	Players.PlayerRemoving:Connect(function(player)
		lastAction[player] = nil
		local trade = sessions[player]
		if trade and trade.Phase ~= "Saving" then
			close(trade, "The other player left")
		end
	end)
	task.spawn(function()
		while true do
			task.wait(1)
			local now = os.clock()
			for player, trade in sessions do
				if player == trade.Players[1] and trade.Phase ~= "Saving" and now >= trade.ExpiresAt then
					close(trade, "Trade expired")
				end
			end
		end
	end)
end

return TradeService
