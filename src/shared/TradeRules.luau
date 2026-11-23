--!strict
local Registry = require(script.Parent.Registry)
local Inventory = require(script.Parent.Inventory)
local BaitBinding = require(script.Parent.Items.BaitBinding)
local ItemTypes = require(script.Parent.Items.ItemTypes)

local TradeRules = {}
local config = Registry.GameConfig.Trade
local license = Registry.Products.Passes.TradeLicense

export type Selection = { Kind: "Item" | "Bait", Key: string, Item: ItemTypes.Item? }
export type Offer = { UserId: number, Items: { ItemTypes.Item }, Baits: { [string]: number } }

function TradeRules.HasLicense(profile: any, studio: boolean): boolean
	local pass = profile and profile.Passes.TradeLicense
	return (license.PassId > 0 and pass == "Owned") or (studio and pass == "Dev")
end

function TradeRules.BaitAvailable(profile: any, id: string): number
	if not config.TradableBaits[id] or profile.Equipped.Baits == id then
		return 0
	end
	return BaitBinding.Free(profile, id)
end

local function copy(value: any): any
	if type(value) ~= "table" then
		return value
	end
	local result = {}
	for key, entry in value do
		result[key] = copy(entry)
	end
	return result
end

function TradeRules.Select(profile: any, kind: any, key: any): (Selection?, string?)
	if type(key) ~= "string" or #key > 64 then
		return nil, "Invalid item"
	end
	if kind == "Bait" then
		if TradeRules.BaitAvailable(profile, key) <= 0 then
			return nil, "No unbound bait available"
		end
		return { Kind = "Bait", Key = key }
	end
	if kind ~= "Item" then
		return nil, "Invalid item"
	end
	local item = Inventory.Find(profile, key)
	if not item then
		return nil, "Item is no longer in your bag"
	end
	local allowed, reason = Inventory.CanTrade(profile, item)
	if not allowed then
		return nil, reason
	end
	local snapshot = copy(item)
	snapshot.New = nil
	return { Kind = "Item", Key = key, Item = snapshot }
end

local function equal(a: any, b: any): boolean
	if a == b then
		return true
	end
	if type(a) ~= "table" or type(b) ~= "table" then
		return false
	end
	for key, value in a do
		if not equal(value, b[key]) then
			return false
		end
	end
	for key in b do
		if a[key] == nil then
			return false
		end
	end
	return true
end

function TradeRules.Offer(profile: any, userId: number, selections: { Selection }): (Offer?, string?)
	local offer: Offer = { UserId = userId, Items = {}, Baits = {} }
	local seen: { [string]: boolean } = {}
	for _, selection in selections do
		local current, reason = TradeRules.Select(profile, selection.Kind, selection.Key)
		if not current then
			return nil, reason
		end
		if current.Kind == "Bait" then
			local count = (offer.Baits[current.Key] or 0) + 1
			if count > TradeRules.BaitAvailable(profile, current.Key) then
				return nil, "Not enough unbound bait"
			end
			offer.Baits[current.Key] = count
		else
			local item = current.Item :: ItemTypes.Item
			if seen[item.UUID] or not equal(item, selection.Item) then
				return nil, "An offered item changed. Remove it and add it again."
			end
			seen[item.UUID] = true
			table.insert(offer.Items, item)
		end
	end
	return offer
end

function TradeRules.Fee(first: { Selection }, second: { Selection }): number
	local value = 0
	for _, side in { first, second } do
		for _, selection in side do
			local item = selection.Item
			if item then
				local def = Registry.Items[item.Id]
				local itemValue = item.Value or def.BasePrice
				if item.Kind == "Rod" then
					itemValue = math.max(itemValue, Inventory.SellValue(item, 1, true) / Registry.GameConfig.Inventory.GearSellFraction)
				end
				value += itemValue * Registry.Rarities[def.Rarity].Tier
			else
				local bait = Registry.Equipment.Baits.Items[selection.Key]
				value += bait.Price / (bait.BuyAmount or 1)
			end
		end
	end
	return math.floor(math.max(0, value - config.TaxFreeValue) * config.TaxRate)
end

function TradeRules.CanReceive(profile: any, outgoing: Offer, incoming: Offer, fee: number): (boolean, string?)
	if profile.Coins < fee then
		return false, "Not enough Coins for the trade fee"
	end
	for _, item in incoming.Items do
		if Inventory.Find(profile, item.UUID) then
			return false, "An incoming item already exists in the bag"
		end
		for _, fish in profile.Aquarium.Fish do
			if fish.UUID == item.UUID then
				return false, "An incoming fish already exists in the tank"
			end
		end
	end
	local baits = profile.Consumables.Baits
	local used = Inventory.Used(profile) - #outgoing.Items + #incoming.Items
	for id, count in outgoing.Baits do
		if baits[id] == count and not incoming.Baits[id] then
			used -= 1
		end
	end
	for id in incoming.Baits do
		if (baits[id] or 0) == 0 then
			used += 1
		end
	end
	if (#incoming.Items > 0 or next(incoming.Baits)) and used > Inventory.Capacity(profile) then
		return false, "Not enough bag space for the incoming items"
	end
	return true
end

return TradeRules
