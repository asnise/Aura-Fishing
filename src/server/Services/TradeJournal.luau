--!strict
-- The journal's terminal decision is the same for both profile keys.
local TradeJournal = {}

export type Offer = { UserId: number, Items: { any }, Baits: { [string]: number } }
export type Record = {
	Id: string,
	Status: "Preparing" | "Committed" | "Aborted",
	Fee: number,
	Offers: { Offer },
}
export type Update = (string, (any) -> any) -> (boolean, any)

function TradeJournal.Decide(update: Update, id: string, commit: boolean): Record?
	local ok, record = update(id, function(current: Record?)
		if current and current.Status == "Preparing" then
			current.Status = if commit then "Committed" else "Aborted"
		end
		return current
	end)
	return if ok then record else nil
end

-- The second return value indicates that a profile write may need recovery.
function TradeJournal.Begin(update: Update, record: Record, prepare: (number, string) -> boolean): (Record?, boolean)
	local ok, created = update(record.Id, function(current)
		return current or record
	end)
	if not ok or not created then
		return nil, false
	end
	if created.Status ~= "Preparing" then
		return created, true
	end
	local ready = prepare(record.Offers[1].UserId, record.Id)
		and prepare(record.Offers[2].UserId, record.Id)
	return TradeJournal.Decide(update, record.Id, ready), true
end

-- Used only inside the profile's update callback. Clearing PendingTrade and moving the items
-- in the same write makes recovery safe even if the last update succeeded without an acknowledgment.
function TradeJournal.Settle(profile: any, userId: number, record: Record): any
	if profile.PendingTrade == nil then
		return profile
	end
	assert(profile.PendingTrade == record.Id and (record.Status == "Committed" or record.Status == "Aborted"), "Wrong trade decision")
	local first, second = record.Offers[1], record.Offers[2]
	local outgoing = if first.UserId == userId then first else second
	local incoming = if first.UserId == userId then second else first
	assert(outgoing.UserId == userId, "Wrong trade participant")
	if record.Status == "Committed" then
		local removing = {}
		for _, item in outgoing.Items do
			removing[item.UUID] = true
		end
		local bag = {}
		local present = {}
		for _, item in profile.Bag do
			if removing[item.UUID] then
				removing[item.UUID] = nil
			else
				present[item.UUID] = true
				table.insert(bag, item)
			end
		end
		for _, item in (profile.Aquarium and profile.Aquarium.Fish) or {} do
			present[item.UUID] = true
		end
		for _, item in incoming.Items do
			assert(not present[item.UUID], "Trade item UUID already exists in recipient inventory")
			table.insert(bag, item)
		end
		assert(next(removing) == nil and profile.Coins >= record.Fee, "Prepared trade inventory no longer matches")

		local baits = profile.Consumables.Baits
		local bound = profile.BoundBaits
		for id, count in outgoing.Baits do
			assert((baits[id] or 0) - (bound[id] or 0) >= count, "Prepared bait quantity no longer matches")
			baits[id] -= count
		end
		for id, count in incoming.Baits do
			baits[id] = (baits[id] or 0) + count
			if profile.Equipped.Baits == id then
				bound[id] = baits[id]
			end
		end
		profile.Bag = bag
		profile.Coins -= record.Fee
	end
	profile.PendingTrade = nil
	profile.LastTrade = record.Id
	return profile
end

return TradeJournal
