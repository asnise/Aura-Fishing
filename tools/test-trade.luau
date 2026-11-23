local TradeJournal = require("../src/server/Services/TradeJournal")
local ProfileLease = require("../src/server/Services/ProfileLease")
local BaitBinding = require("../src/shared/Items/BaitBinding")

local function copy(value)
	if type(value) ~= "table" then
		return value
	end
	local result = {}
	for key, entry in value do
		result[key] = copy(entry)
	end
	return result
end

local function profile(uuid, baitCount, boundCount)
	return {
		Coins = 100,
		Bag = { { UUID = uuid } },
		Consumables = { Baits = { Worm = baitCount } },
		BoundBaits = { Worm = boundCount },
		Equipped = {},
	}
end

local function fixture()
	local profiles = { profile("fish-a", 3, 2), profile("rod-b", 0, 0) }
	local records = {}
	local function update(id, transform)
		local changed = transform(copy(records[id]))
		if changed then
			records[id] = copy(changed)
		end
		return true, copy(changed)
	end
	local record = {
		Id = "deal",
		Status = "Preparing",
		Fee = 7,
		Offers = {
			{ UserId = 1, Items = { { UUID = "fish-a" } }, Baits = { Worm = 1 } },
			{ UserId = 2, Items = { { UUID = "rod-b" } }, Baits = {} },
		},
	}
	local function prepare(userId, tradeId)
		profiles[userId].PendingTrade = tradeId
		return true
	end
	return profiles, records, update, record, prepare
end

do
	local profiles, _, update, record, prepare = fixture()
	local outcome = TradeJournal.Begin(update, record, prepare)
	assert(outcome and outcome.Status == "Committed")
	TradeJournal.Settle(profiles[1], 1, outcome)
	assert(profiles[1].Coins == 93 and profiles[1].Bag[1].UUID == "rod-b")
	assert(profiles[1].Consumables.Baits.Worm == 2 and profiles[1].BoundBaits.Worm == 2)
	-- The second profile write failed. A new server reads the journal and recovers it later.
	assert(profiles[2].Bag[1].UUID == "rod-b" and profiles[2].PendingTrade == "deal")
	local recovered = TradeJournal.Decide(update, "deal", false)
	assert(recovered and recovered.Status == "Committed")
	TradeJournal.Settle(profiles[2], 2, recovered)
	assert(profiles[2].Coins == 93 and profiles[2].Bag[1].UUID == "fish-a")
	assert(profiles[2].Consumables.Baits.Worm == 1)
	table.clear(profiles[1].Bag) -- The recipient has since sold the rod.
	TradeJournal.Settle(profiles[1], 1, recovered)
	TradeJournal.Settle(profiles[2], 2, recovered)
	assert(#profiles[1].Bag == 0 and profiles[1].Coins == 93, "Replay restored a sold item")
	assert(#profiles[2].Bag == 1 and profiles[2].Coins == 93 and profiles[2].Consumables.Baits.Worm == 1)
end

do
	local profiles, _, update, record, prepare = fixture()
	local outcome = TradeJournal.Begin(update, record, function(userId, tradeId)
		prepare(userId, tradeId)
		return userId == 1 -- The second write reached storage, but its acknowledgment was lost.
	end)
	assert(outcome and outcome.Status == "Aborted")
	for userId, saved in profiles do
		TradeJournal.Settle(saved, userId, outcome)
		assert(saved.PendingTrade == nil and saved.Coins == 100 and #saved.Bag == 1)
	end
	assert(profiles[1].Bag[1].UUID == "fish-a" and profiles[2].Bag[1].UUID == "rod-b")
end

do
	local profiles, records, update, record, prepare = fixture()
	local outcome, touched = TradeJournal.Begin(function(id, transform)
		local ok, changed = update(id, transform)
		if changed and changed.Status == "Committed" then
			return false, nil -- The journal commit succeeded, but its acknowledgment was lost.
		end
		return ok, changed
	end, record, prepare)
	assert(not outcome and touched and records.deal.Status == "Committed")
	local recovered = TradeJournal.Decide(update, "deal", false)
	assert(recovered and recovered.Status == "Committed")
	for userId, saved in profiles do
		TradeJournal.Settle(saved, userId, recovered)
	end
	assert(profiles[1].Bag[1].UUID == "rod-b" and profiles[2].Bag[1].UUID == "fish-a")
end

do
	local profiles, _, update, record, prepare = fixture()
	local outcome = TradeJournal.Begin(update, record, function(userId, tradeId)
		prepare(userId, tradeId)
		if userId == 1 then
			local recovered = TradeJournal.Decide(update, tradeId, false)
			assert(recovered and recovered.Status == "Aborted")
		end
		return true
	end)
	assert(outcome and outcome.Status == "Aborted", "A disconnected player's recovery must win or see a committed deal")
	TradeJournal.Settle(profiles[1], 1, outcome)
	assert(profiles[1].Bag[1].UUID == "fish-a")
end

do
	local saved = profile("fish", 0, 0)
	assert(ProfileLease.Claim(saved, "server-a", 0, 20))
	assert(not ProfileLease.Claim(saved, "server-b", 19, 20))
	assert(ProfileLease.CanWrite(saved, "server-a", nil))
	saved.PendingTrade = "deal"
	assert(not ProfileLease.CanWrite(saved, "server-a", nil), "Autosave could overwrite a prepared trade")
	assert(ProfileLease.Claim(saved, "server-b", 20, 20))
	assert(not ProfileLease.CanWrite(saved, "server-a", "deal"), "Old server could overwrite the new session")
	assert(ProfileLease.CanWrite(saved, "server-b", "deal"))
end

do
	local autosave = profile("fish-a", 3, 2)
	local frozen = copy(autosave)
	table.insert(frozen.Bag, { UUID = "caught-since-autosave" })
	ProfileLease.Claim(autosave, "server-a", 0, 20)
	local closed = ProfileLease.CloseTrade(copy(autosave), "server-a", "deal", copy(frozen))
	assert(closed.ServerLease == nil and #closed.Bag == 2, "Disconnect before prepare discarded recent progress")

	local pending = copy(frozen)
	ProfileLease.Claim(pending, "server-a", 0, 20)
	pending.PendingTrade = "deal"
	local released = ProfileLease.CloseTrade(copy(pending), "server-a", "deal", copy(frozen))
	assert(released.ServerLease == nil and released.PendingTrade == "deal", "Disconnect erased a pending trade")

	local _, _, update, record, prepare = fixture()
	local outcome = assert(TradeJournal.Begin(update, record, prepare))
	TradeJournal.Settle(pending, 1, outcome)
	-- The write applied the swap, but the disconnect handler never received its acknowledgment.
	local recovered = ProfileLease.CloseTrade(copy(pending), "server-a", "deal", copy(frozen))
	assert(recovered.ServerLease == nil and recovered.Coins == 93, "Disconnect overwrote an applied trade")
	assert(#recovered.Bag == 2 and recovered.Bag[2].UUID == "rod-b")
end

do
	local saved = profile("fish", 2, 0)
	BaitBinding.Add(saved, "Worm", 3, true) -- Daily/Login or promo reward.
	assert(BaitBinding.Free(saved, "Worm") == 2)
	saved.Equipped.Baits = "Worm"
	BaitBinding.Bind(saved, "Worm")
	BaitBinding.Add(saved, "Worm", 2)
	BaitBinding.Consume(saved, "Worm")
	saved.Equipped.Baits = nil
	assert(BaitBinding.Free(saved, "Worm") == 0, "Used bait became tradable after unequip")
	BaitBinding.Add(saved, "Worm", 3)
	assert(BaitBinding.Free(saved, "Worm") == 3 and saved.Consumables.Baits.Worm == 9)
	local legacy = { Equipped = {}, Consumables = { Baits = { Worm = 8 } } }
	BaitBinding.Migrate(legacy)
	assert(legacy.Consumables.Baits.Worm == 8 and BaitBinding.Free(legacy, "Worm") == 0)
end

print("Trade recovery, ownership fencing, and bait binding passed")
