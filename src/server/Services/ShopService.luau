--!strict
-- Buying / equipping equipment and selling fish. Works for any category in Config/Equipment.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Registry = require(Shared.Registry)
local Remotes = require(Shared.Remotes)
local Stats = require(Shared.Stats)
local Inventory = require(Shared.Inventory)
local Format = require(Shared.Util.Format)
local Enhance = require(Shared.Enhance)
local Signal = require(Shared.Util.Signal)
local Boosts = require(Shared.Boosts)
local RodDrop = require(Shared.Items.RodDrop)
local HotFish = require(Shared.HotFish)
local HttpService = game:GetService("HttpService")

local DataService = require(script.Parent.DataService)
local AquariumService = require(script.Parent.AquariumService)

local ShopService = {}
local rng = Random.new()
ShopService.FishSold = Signal.new() -- (player, fishCount, coins) hook for quests/events

local lastCall: { [Player]: number } = {}
local function throttled(player: Player): boolean
	local now = os.clock()
	if lastCall[player] and now - lastCall[player] < 0.15 then
		return true
	end
	lastCall[player] = now
	return false
end

function ShopService.Buy(player: Player, categoryId: any, itemId: any): (boolean, string)
	local data = DataService.Get(player)
	if not data or type(categoryId) ~= "string" or type(itemId) ~= "string" then
		return false, "Invalid request"
	end
	local cat = Registry.Equipment[categoryId]
	local item = cat and cat.Items[itemId]
	if not item then
		return false, "Unknown item"
	end
	if item.Exclusive then
		return false, "Not sold in the shop"
	end
	if item.RequiredLevel and data.Level < item.RequiredLevel then
		return false, `Requires level {item.RequiredLevel}`
	end
	local isGear = Inventory.IsGearCategory(categoryId)
	if cat.Kind == "Permanent" and not isGear and data.Owned[categoryId][itemId] then
		return false, "Already owned"
	end
	-- B21: bags are upgrades, never buy a bag that is not bigger than the one in use
	if categoryId == "Bags" and Inventory.BagCapacity(itemId) <= Inventory.BagCapacity(data.Equipped.Bags) then
		return false, "You already have a bigger bag"
	end
	-- The free starter rod / line: one is enough (it sells for 0 coins, you can only hold one at a time).
	if isGear and item.Price == 0 and Inventory.CountGear(data, categoryId, itemId) > 0 then
		return false, "You already have it"
	end
	-- Rods and Lines can be bought again and again; every purchase is its own item and needs a bag slot.
	if isGear and Inventory.IsFull(data) then
		return false, "Bag full - sell something first"
	end
	-- a bait you do not have yet takes a slot (more of a bait you have does not)
	if cat.Kind == "Consumable" and (data.Consumables[categoryId][itemId] or 0) <= 0 and Inventory.IsFull(data) then
		return false, "Bag full - sell something first"
	end
	if data[item.Currency] < item.Price then
		return false, `Not enough {item.Currency}`
	end
	data[item.Currency] -= item.Price

	if isGear then
		local bought = Inventory.NewGear(categoryId, itemId, "Shop")
		Inventory.Add(data, bought, true)
		-- A better piece is worn right away; a copy of something you already outgrow stays in the bag.
		local worn = Inventory.Worn(data, categoryId)
		local wornDef = if worn then cat.Items[worn.Id] else nil
		if not wornDef or item.Order > wornDef.Order then
			data.Equipped[categoryId] = bought.UUID
		end
	elseif cat.Kind == "Permanent" then
		data.Owned[categoryId][itemId] = true
		data.Equipped[categoryId] = itemId
	else
		local stack = data.Consumables[categoryId]
		stack[itemId] = (stack[itemId] or 0) + (item.BuyAmount or 1)
		data.Equipped[categoryId] = itemId
	end
	DataService.MarkDirty(player)
	return true, `Bought {item.Name}!`
end

-- Gear Enhance (C16): one Rod/Line item +1 (the level belongs to that item). Coins (+ Pearls for levels in GameConfig.Enhance.PearlCosts).
function ShopService.Enhance(player: Player, uuid: any): (boolean, string, any)
	local data = DataService.Get(player)
	local gear = data and Inventory.Find(data, uuid)
	local categoryId = gear and Inventory.GearCategory(gear.Kind)
	if not data or not gear or not categoryId then
		return false, "Not owned", nil
	end
	if not Enhance.CanEnhance(categoryId, gear.Id) then
		return false, "This item cannot be enhanced", nil
	end
	local item = Registry.Equipment[categoryId].Items[gear.Id]
	local level = Enhance.Level(gear)
	local coins, pearls = Enhance.Cost(categoryId, gear.Id, level)
	if not coins then
		return false, `{item.Name} is already +{level} (MAX)`, Enhance.State(gear)
	end
	if data.Coins < coins then
		return false, `Need {Format.Number(coins)} coins`, Enhance.State(gear)
	end
	if pearls then
		AquariumService.Settle(player)
		if data.Pearls < pearls then
			return false, `Need {Format.Number(pearls)} Pearls`, Enhance.State(gear)
		end
		data.Pearls -= pearls
	end
	data.Coins -= coins
	gear.Enhance = level + 1
	DataService.MarkDirty(player)
	return true, `{item.Name} +{level + 1}!`, Enhance.State(gear)
end

-- Rods / Lines: itemId is the UUID of a bag item. Bags / Baits: the Config/Equipment id.
function ShopService.Equip(player: Player, categoryId: any, itemId: any): (boolean, string)
	local data = DataService.Get(player)
	if not data or type(categoryId) ~= "string" then
		return false, "Invalid request"
	end
	local cat = Registry.Equipment[categoryId]
	if not cat then
		return false, "Unknown category"
	end
	if itemId == nil and cat.Kind == "Consumable" then
		data.Equipped[categoryId] = nil
		DataService.MarkDirty(player)
		return true, "Unequipped"
	end
	if Inventory.IsGearCategory(categoryId) then
		local gear = Inventory.Find(data, itemId)
		if not gear or gear.Kind ~= Inventory.GearKind(categoryId) then
			return false, "Not owned"
		end
		data.Equipped[categoryId] = gear.UUID
		DataService.MarkDirty(player)
		return true, `Equipped {cat.Items[gear.Id].Name}`
	end
	if type(itemId) ~= "string" or not cat.Items[itemId] then
		return false, "Unknown item"
	end
	if cat.Kind == "Permanent" and not data.Owned[categoryId][itemId] then
		return false, "Not owned"
	end
	if cat.Kind == "Consumable" and (data.Consumables[categoryId][itemId] or 0) <= 0 then
		return false, "None left"
	end
	if categoryId == "Bags" and Inventory.BagCapacity(itemId) < Inventory.BagCapacity(data.Equipped.Bags) then
		return false, "Bags are upgrades: you cannot go back to a smaller bag"
	end
	data.Equipped[categoryId] = itemId
	DataService.MarkDirty(player)
	return true, `Equipped {cat.Items[itemId].Name}`
end

-- Sells every fish; treasure chests, rods and lines stay.
function ShopService.SellAll(player: Player): (boolean, string)
	local data = DataService.Get(player)
	if not data then
		return false, "Invalid request"
	end
	local mult = Stats.Compute(data).Values.SellMultiplier * Boosts.Multiplier(data, "Coins")
	local total, count = Inventory.SellAllPreview(data, mult)
	if count == 0 then
		return false, "No fish to sell"
	end
	local hotBonus = Inventory.HotBonus(data, mult)
	local keep = {}
	for _, s in data.Bag do
		if s.Kind ~= "Fish" then
			table.insert(keep, s)
		end
	end
	data.Bag = keep
	data.Coins += total
	data.Lifetime.CoinsEarned += total
	DataService.MarkDirty(player)
	ShopService.FishSold:Fire(player, count, total)
	if hotBonus > 0 then
		return true, `Sold {count} fish for {Format.Number(total)} coins! (hot fish +{Format.Number(hotBonus)})`
	end
	return true, `Sold {count} fish for {Format.Number(total)} coins!`
end

-- Sells one bag item by UUID: a fish, or a spare Rod / Line (never the one you wear).
function ShopService.SellItem(player: Player, uuid: any, confirmed: any): (boolean, string)
	local data = DataService.Get(player)
	local item = data and Inventory.Find(data, uuid)
	if not data or not item or (item.Kind ~= "Fish" and item.Kind ~= "Rod" and item.Kind ~= "Line") then
		return false, "Nothing to sell"
	end
	local block = Inventory.SellBlock(data, item)
	if block then
		return false, block
	end
	-- enhanced / modded gear: the client asks first and sends confirmed = true
	local invested = Inventory.Investment(item)
	if invested and confirmed ~= true then
		return false, `Confirm to sell: it has {invested}`
	end
	local total = Inventory.SellValue(item, Stats.Compute(data).Values.SellMultiplier * Boosts.Multiplier(data, "Coins"))
	Inventory.Remove(data, uuid)
	data.Coins += total
	data.Lifetime.CoinsEarned += total
	DataService.MarkDirty(player)
	if item.Kind == "Fish" then
		ShopService.FishSold:Fire(player, 1, total)
	end
	local name = Inventory.Describe(item)
	return true, `Sold {name} for {Format.Number(total)} coins!`
end

local function chestOf(data: any, uuid: any): (any, any)
	local s = data and Inventory.Find(data, uuid)
	return s, s and s.Kind == "Treasure" and Registry.Treasures[s.Id]
end

local function rollReward(t: any, totalWeight: number): any
	local pick = rng:NextNumber() * totalWeight
	for _, r in t.Rewards do
		pick -= r.Weight
		if pick <= 0 then
			return r
		end
	end
	return t.Rewards[#t.Rewards]
end

-- A Rod reward: the rod goes into the bag; with no free slot it is paid as its sell value instead.
-- Returns rodName, coinsPaid (coinsPaid > 0 = bag was full).
local function giveRod(data: any, reward: any): (string, number)
	local rod = RodDrop.Create(reward.Profile :: string, data.Level, rng)
	if not rod then
		return "rod", 0
	end
	local name = Registry.Equipment.Rods.Items[rod.Id].Name
	if Inventory.Add(data, rod) then
		return name, 0
	end
	local coins = Inventory.SellValue(rod, 1)
	data.Coins += coins
	data.Lifetime.CoinsEarned += coins
	return name, coins
end

-- Opens one chest of a treasure stack and pays one reward rolled by Weight (Config/Treasures).
function ShopService.OpenTreasure(player: Player, uuid: any): (boolean, string, any)
	local data = DataService.Get(player)
	local s, t = chestOf(data, uuid)
	if not data or not s or not t then
		return false, "Nothing to open", nil
	end
	local total = 0
	for _, r in t.Rewards do
		total += r.Weight
	end
	local reward = rollReward(t, total)
	s.Count = (s.Count or 1) - 1
	if s.Count <= 0 then
		Inventory.Remove(data, uuid)
	end
	local msg
	local out: any
	if reward.Kind == "Coins" or reward.Kind == "Gems" then
		local amount = rng:NextInteger(reward.Min :: number, reward.Max :: number)
		if reward.Kind == "Coins" then
			data.Coins += amount
			data.Lifetime.CoinsEarned += amount
		else
			data.Gems += amount
		end
		msg = `{t.Name}: +{Format.Number(amount)} {string.lower(reward.Kind)}!`
		out = { Kind = reward.Kind, Amount = amount }
	elseif reward.Kind == "Rod" then
		local name, paid = giveRod(data, reward)
		msg = if paid > 0 then `{t.Name}: {name} (bag full, sold for {Format.Number(paid)} coins)` else `{t.Name}: a {name} with mods!`
		out = { Kind = "Rod", Amount = 1 }
	else
		local id = reward.Id :: string
		local baits = data.Consumables.Baits
		baits[id] = (baits[id] or 0) + (reward.Count or 1)
		msg = `{t.Name}: +{reward.Count or 1} {Registry.Equipment.Baits.Items[id].Name}!`
		out = { Kind = "Bait", Id = id, Amount = reward.Count or 1 }
	end
	DataService.MarkDirty(player)
	return true, msg, out
end

function ShopService.OpenAllTreasure(player: Player, uuid: any): (boolean, string, any)
	local data = DataService.Get(player)
	local s, t = chestOf(data, uuid)
	if not data or not s or not t or (s.Count or 1) <= 0 then
		return false, "Nothing to open", nil
	end
	local totalWeight = 0
	for _, r in t.Rewards do
		totalWeight += r.Weight
	end

	local count = s.Count or 1
	local earnedCoins = 0
	local earnedGems = 0
	local earnedBaits: { [string]: number } = {}
	local earnedRods, rodNotes = 0, 0

	for _ = 1, count do
		local reward = rollReward(t, totalWeight)
		if reward.Kind == "Coins" then
			earnedCoins += rng:NextInteger(reward.Min :: number, reward.Max :: number)
		elseif reward.Kind == "Gems" then
			earnedGems += rng:NextInteger(reward.Min :: number, reward.Max :: number)
		elseif reward.Kind == "Rod" then
			local _, paid = giveRod(data, reward)
			earnedRods += 1
			rodNotes += if paid > 0 then 1 else 0
		else
			local id = reward.Id :: string
			earnedBaits[id] = (earnedBaits[id] or 0) + (reward.Count or 1)
		end
	end

	Inventory.Remove(data, uuid)

	if earnedCoins > 0 then
		data.Coins += earnedCoins
		data.Lifetime.CoinsEarned += earnedCoins
	end
	if earnedGems > 0 then
		data.Gems += earnedGems
	end
	for id, amt in earnedBaits do
		local baits = data.Consumables.Baits
		baits[id] = (baits[id] or 0) + amt
	end

	DataService.MarkDirty(player)

	local summaryParts = {}
	if earnedCoins > 0 then
		table.insert(summaryParts, `+{Format.Number(earnedCoins)} coins`)
	end
	if earnedGems > 0 then
		table.insert(summaryParts, `+{Format.Number(earnedGems)} gems`)
	end
	for id, amt in earnedBaits do
		local bDef = Registry.Equipment.Baits.Items[id]
		table.insert(summaryParts, `+{amt} {bDef and bDef.Name or id}`)
	end
	if earnedRods > 0 then
		table.insert(summaryParts, `+{earnedRods} rod{if earnedRods == 1 then "" else "s"}{if rodNotes > 0 then " (some sold, bag full)" else ""}`)
	end

	local msg = `{t.Name} x{count}: {table.concat(summaryParts, ", ")}!`
	return true, msg, { Coins = earnedCoins, Gems = earnedGems, Baits = earnedBaits }
end

-- HOT FISH (C18) -----------------------------------------------------------------------------

local function hotNames(list: { HotFish.Entry }): string
	local parts = {}
	for _, e in list do
		local f = Registry.Fish[e.FishId]
		table.insert(parts, `{f and f.Name or e.FishId} x{e.Mult}`)
	end
	return table.concat(parts, ", ")
end

-- Dev: force a hot fish list until `seconds` from now (nil fishId clears it).
function ShopService.SetHotFishOverride(fishId: string?, mult: number?, seconds: number?)
	if not fishId then
		ReplicatedStorage:SetAttribute(HotFish.OVERRIDE_ATTRIBUTE, nil)
		return
	end
	local list = { { FishId = fishId, Mult = mult or 3, EndsAt = os.time() + (seconds or 3600) } }
	ReplicatedStorage:SetAttribute(HotFish.OVERRIDE_ATTRIBUTE, HttpService:JSONEncode(list))
end

function ShopService.Init()
	-- Broadcast the hot fish list when it changes (every IntervalMinutes, or a Dev override).
	local hotEvent = Remotes.Event("HotFish")
	Remotes.Event("ClientReady").OnServerEvent:Connect(function(player)
		hotEvent:FireClient(player, HotFish.Current())
	end)
	task.spawn(function()
		local lastKey = HotFish.Key()
		while true do
			task.wait(5)
			local key = HotFish.Key()
			if key ~= lastKey then
				lastKey = key
				local list = HotFish.Current()
				hotEvent:FireAllClients(list)
				Remotes.Event("Notify"):FireAllClients(`Hot fish at the Merchant: {hotNames(list)}!`, Color3.fromRGB(242, 140, 56))
			end
		end
	end)

	Remotes.Func("Buy").OnServerInvoke = function(player, cat, id)
		if throttled(player) then
			return false, "Slow down"
		end
		return ShopService.Buy(player, cat, id)
	end
	Remotes.Func("Equip").OnServerInvoke = function(player, cat, id)
		if throttled(player) then
			return false, "Slow down"
		end
		return ShopService.Equip(player, cat, id)
	end
	Remotes.Func("Enhance").OnServerInvoke = function(player, uuid)
		if throttled(player) then
			return false, "Slow down", nil
		end
		return ShopService.Enhance(player, uuid)
	end
	Remotes.Func("SellAll").OnServerInvoke = function(player)
		if throttled(player) then
			return false, "Slow down"
		end
		return ShopService.SellAll(player)
	end
	Remotes.Func("SellItem").OnServerInvoke = function(player, uuid, confirmed)
		if throttled(player) then
			return false, "Slow down"
		end
		return ShopService.SellItem(player, uuid, confirmed)
	end
	Remotes.Func("OpenTreasure").OnServerInvoke = function(player, uuid)
		if throttled(player) then
			return false, "Slow down", nil
		end
		return ShopService.OpenTreasure(player, uuid)
	end
	Remotes.Func("OpenAllTreasure").OnServerInvoke = function(player, uuid)
		if throttled(player) then
			return false, "Slow down", nil
		end
		return ShopService.OpenAllTreasure(player, uuid)
	end
	Remotes.Event("BagSeen").OnServerEvent:Connect(function(player, tokens)
		local data = DataService.Get(player)
		if data and Inventory.MarkSeen(data, tokens) then
			DataService.MarkDirty(player)
		end
	end)
	Remotes.Func("SetSetting").OnServerInvoke = function(player, key, value)
		local data = DataService.Get(player)
		if not data then
			return false
		end
		if key == "LowFX" and type(value) == "boolean" then
			data.Settings.LowFX = value
		elseif key == "AutoDepth" and type(value) == "boolean" then
			data.Settings.AutoDepth = value
		elseif key == "TargetDepth" and type(value) == "number" and value == value then
			data.Settings.TargetDepth = math.clamp(math.floor(value), 0, 100000)
		else
			return false
		end
		DataService.MarkDirty(player)
		return true
	end

	-- World merchant prompt
	local notify = Remotes.Event("Notify")
	task.spawn(function()
		local map = Workspace:WaitForChild("Map", 30)
		local merchant = map and map:FindFirstChild("Merchant", true)
		local prompt = merchant and merchant:FindFirstChild("SellPrompt")
		if prompt and prompt:IsA("ProximityPrompt") then
			-- B7: talk to Old Marlin (Config/Dialogues.Marlin); "Sell All Fish" is a dialogue choice (remote SellAll)
			local npc = Registry.Dialogues.Marlin
			if npc then
				prompt.ActionText = "Talk"
				prompt.ObjectText = npc.Name
				prompt.Triggered:Connect(function(player)
					Remotes.Event("OpenDialogue"):FireClient(player, "Marlin")
				end)
			else
				prompt.Triggered:Connect(function(player)
					local ok, msg = ShopService.SellAll(player)
					notify:FireClient(player, msg, ok and Color3.fromRGB(201, 139, 30) or nil)
				end)
			end
		end
	end)

	Players.PlayerRemoving:Connect(function(p)
		lastCall[p] = nil
	end)
end

return ShopService
