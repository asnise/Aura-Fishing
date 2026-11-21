--!strict
-- Robux purchases (C13). Content: Config/Products.
--
-- Developer Products: MarketplaceService.ProcessReceipt. A receipt is granted exactly once:
--   1. profile not loaded yet         -> NotProcessedYet (Roblox retries later)
--   2. PurchaseId already in the save -> PurchaseGranted (duplicate, nothing given)
--   3. give rewards + store PurchaseId, save NOW; only a successful save returns PurchaseGranted.
--      If the save fails the grant is rolled back and Roblox retries.
-- Game Passes: checked on join (UserOwnsGamePassAsync) and on PromptGamePassPurchaseFinished.
--   Owned passes live in profile.Passes so Stats.Collect gives the same stats on server + client.
--
-- Client: Remotes "PromptPass"(passKey) / "PromptProduct"(productKey) open the Roblox buy dialog.

local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Registry = require(Shared.Registry)
local Remotes = require(Shared.Remotes)
local Signal = require(Shared.Util.Signal)
local ProductTypes = require(Shared.Config.Products)
local Boosts = require(Shared.Boosts)

local DataService = require(script.Parent.DataService)

local Products = Registry.Products

local MonetizationService = {}
MonetizationService.PassChanged = Signal.new() -- (player, passKey, owned)
MonetizationService.ProductGranted = Signal.new() -- (player, productKey)

local MAX_RECEIPTS = 100 -- recent PurchaseIds kept in the save for dedupe

local passByRobloxId: { [number]: string } = {}
local productByRobloxId: { [number]: string } = {}
for key, p in Products.Passes do
	if p.PassId > 0 then
		passByRobloxId[p.PassId] = key
	end
end
for key, p in Products.Products do
	if p.ProductId > 0 then
		productByRobloxId[p.ProductId] = key
	end
end

local GOOD = Color3.fromRGB(79, 175, 138)
local BAD = Color3.fromRGB(204, 84, 84)

local function notify(player: Player, text: string, color: Color3)
	Remotes.Event("Notify"):FireClient(player, text, color)
end

-- PASSES -------------------------------------------------------------------

function MonetizationService.HasPass(player: Player, passKey: string): boolean
	local data = DataService.Get(player)
	return data ~= nil and data.Passes[passKey] ~= nil
end

-- how = "Owned" | "Dev"; nil removes.
function MonetizationService.SetPass(player: Player, passKey: string, how: string?)
	local data = DataService.Get(player)
	if not data or not Products.Passes[passKey] then
		return
	end
	local before = data.Passes[passKey] ~= nil
	data.Passes[passKey] = how
	player:SetAttribute("Pass_" .. passKey, if how ~= nil then true else nil) -- other clients: VIP name tag (C6)
	DataService.MarkDirty(player)
	if before ~= (how ~= nil) then
		MonetizationService.PassChanged:Fire(player, passKey, how ~= nil)
	end
end

local function ownsOnRoblox(player: Player, passId: number): boolean?
	local ok, owns = pcall(function()
		return MarketplaceService:UserOwnsGamePassAsync(player.UserId, passId)
	end)
	if not ok then
		warn(`[Monetization] pass check failed for {player.Name} ({passId}): {owns}`)
		return nil -- unknown: keep what the save says
	end
	return owns
end

local function refreshPasses(player: Player, data: any)
	for key in data.Passes do
		player:SetAttribute("Pass_" .. key, true)
	end
	for key, pass in Products.Passes do
		if pass.PassId > 0 then
			local owns = ownsOnRoblox(player, pass.PassId)
			if not player.Parent then
				return
			end
			if owns == true and data.Passes[key] ~= "Owned" then
				MonetizationService.SetPass(player, key, "Owned")
			elseif owns == false and data.Passes[key] == "Owned" then
				MonetizationService.SetPass(player, key, nil) -- refunded / removed
			end
		end
	end
	-- Passes that were removed from config: drop them.
	for key in data.Passes do
		if not Products.Passes[key] then
			data.Passes[key] = nil
		end
	end
end

-- PRODUCTS -----------------------------------------------------------------

-- sign = 1 gives, -1 takes back (rollback after a failed save). Returns whether it changed anything
-- (an Item the player already owned is not taken back).
local function giveReward(data: any, r: ProductTypes.Reward, sign: number, changed: boolean?): boolean
	local amount = (r.Amount or 1) * sign
	if r.Kind == "Gems" then
		data.Gems += amount
	elseif r.Kind == "Coins" then
		data.Coins += amount
		data.Lifetime.CoinsEarned += amount
	elseif r.Kind == "Bait" then
		local stack = data.Consumables.Baits
		stack[r.Id :: string] = math.max(0, (stack[r.Id :: string] or 0) + amount)
	elseif r.Kind == "Boost" then
		-- rollback (sign -1) takes the same seconds back off the end time
		Boosts.Add(data, r.Id :: string, amount)
	elseif r.Kind == "Item" then
		local owned = data.Owned[r.Category :: string]
		if sign > 0 then
			local had = owned[r.Id :: string] == true
			owned[r.Id :: string] = true
			return not had
		elseif changed then
			owned[r.Id :: string] = nil
		end
	end
	return true
end

local inFlight: { [string]: boolean } = {}

local function hasReceipt(data: any, purchaseId: string): boolean
	return table.find(data.Purchases.Receipts, purchaseId) ~= nil
end

-- Grants one receipt. Used by ProcessReceipt and by the Dev command `receipt`.
-- Returns the decision + a short reason (for logs / Dev).
function MonetizationService.Grant(player: Player, productKey: string, purchaseId: string): (Enum.ProductPurchaseDecision, string)
	local product = Products.Products[productKey]
	if not product then
		return Enum.ProductPurchaseDecision.NotProcessedYet, `unknown product {productKey}`
	end
	local data = DataService.Get(player)
	if not data then
		return Enum.ProductPurchaseDecision.NotProcessedYet, "profile not loaded"
	end
	local purchases = data.Purchases
	if hasReceipt(data, purchaseId) then
		return Enum.ProductPurchaseDecision.PurchaseGranted, "duplicate receipt (already granted)"
	end
	if inFlight[purchaseId] then
		return Enum.ProductPurchaseDecision.NotProcessedYet, "same receipt is being processed"
	end
	inFlight[purchaseId] = true

	-- OncePerPlayer bought twice (should be blocked before the prompt): record it, give nothing.
	local skip = product.OncePerPlayer == true and purchases.Once[productKey] == true
	local changed: { boolean } = {}
	if not skip then
		for i, r in product.Rewards do
			changed[i] = giveReward(data, r, 1)
		end
		if product.OncePerPlayer then
			purchases.Once[productKey] = true
		end
	end
	purchases.Count[productKey] = (purchases.Count[productKey] or 0) + 1
	table.insert(purchases.Receipts, purchaseId)
	while #purchases.Receipts > MAX_RECEIPTS do
		table.remove(purchases.Receipts, 1)
	end
	DataService.MarkDirty(player)

	local saved = DataService.SaveNow(player)
	inFlight[purchaseId] = nil
	if not saved then
		-- Take the rewards back so the retry does not give them twice (subtract, so anything the
		-- player earned while the save was running is kept).
		if not skip then
			for i, r in product.Rewards do
				giveReward(data, r, -1, changed[i])
			end
			if product.OncePerPlayer then
				purchases.Once[productKey] = nil
			end
		end
		purchases.Count[productKey] = math.max(0, (purchases.Count[productKey] or 1) - 1)
		local i = table.find(purchases.Receipts, purchaseId)
		if i then
			table.remove(purchases.Receipts, i)
		end
		DataService.MarkDirty(player)
		return Enum.ProductPurchaseDecision.NotProcessedYet, "save failed, will retry"
	end

	if skip then
		return Enum.ProductPurchaseDecision.PurchaseGranted, "OncePerPlayer already owned (nothing given)"
	end
	notify(player, `Thanks! You got {product.Name}.`, GOOD)
	MonetizationService.ProductGranted:Fire(player, productKey)
	return Enum.ProductPurchaseDecision.PurchaseGranted, `granted {product.Name}`
end

local function processReceipt(info: { [string]: any }): Enum.ProductPurchaseDecision
	local player = Players:GetPlayerByUserId(info.PlayerId)
	if not player then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	local key = productByRobloxId[info.ProductId]
	if not key then
		warn(`[Monetization] receipt for unknown ProductId {info.ProductId} (add it to Config/Products)`)
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	if not DataService.Get(player) then
		DataService.WaitFor(player)
	end
	local decision, reason = MonetizationService.Grant(player, key, tostring(info.PurchaseId))
	print(`[Monetization] {player.Name} {key} ({info.PurchaseId}): {reason}`)
	return decision
end

-- INIT ---------------------------------------------------------------------

function MonetizationService.Init()
	MarketplaceService.ProcessReceipt = processReceipt

	MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, passId, purchased)
		local key = passByRobloxId[passId]
		if purchased and key then
			MonetizationService.SetPass(player, key, "Owned")
			notify(player, `Thanks! {Products.Passes[key].Name} is now active.`, GOOD)
		end
	end)

	Remotes.Event("PromptPass").OnServerEvent:Connect(function(player, key)
		local pass = if type(key) == "string" then Products.Passes[key] else nil
		if not pass then
			return
		end
		if MonetizationService.HasPass(player, key) then
			notify(player, `You already own {pass.Name}.`, GOOD)
		elseif pass.PassId <= 0 then
			notify(player, `{pass.Name} is coming soon.`, BAD)
		else
			MarketplaceService:PromptGamePassPurchase(player, pass.PassId)
		end
	end)

	Remotes.Event("PromptProduct").OnServerEvent:Connect(function(player, key)
		local product = if type(key) == "string" then Products.Products[key] else nil
		if not product then
			return
		end
		local data = DataService.Get(player)
		if product.OncePerPlayer and data and data.Purchases.Once[key] then
			notify(player, `You already bought {product.Name}.`, BAD)
		elseif product.ProductId <= 0 then
			notify(player, `{product.Name} is coming soon.`, BAD)
		else
			MarketplaceService:PromptProductPurchase(player, product.ProductId)
		end
	end)

	DataService.ProfileLoaded:Connect(function(player, data)
		task.spawn(refreshPasses, player, data)
	end)
	for _, player in Players:GetPlayers() do
		local data = DataService.Get(player)
		if data then
			task.spawn(refreshPasses, player, data)
		end
	end
end

return MonetizationService
