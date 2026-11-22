--!strict
-- Instructional copy for the Codex. Build catches up with changes to the live catalogs.
local Codex = {}

export type Entry = {
	Id: string,
	Title: string,
	Category: string,
	Group: string,
	Effect: string,
	Detail: string?,
	Related: string?,
	Keywords: string?,
	Rarity: string?,
}

local STATS: { [string]: { string } } = {
	Luck = { "Fishing", "Raises the relative weight of rarer eligible fish. Also helps rod and treasure drop rolls.", "Base 0%. Location and depth still decide which fish can appear." },
	MaxDepth = { "Fishing", "Sets how deep you can fish. Your line provides depth and the fishing area can cap it.", "Measured in metres. Fishing deeper can change the eligible fish pool." },
	CastRange = { "Fishing", "Sets the farthest your cast can reach when fully charged.", "Base 14 studs. A shorter charge casts closer." },
	BiteSpeed = { "Fishing", "Shortens the manual bite wait. Half of the reduction also applies to Auto Fishing's cycle.", "+20% makes manual wait 20% shorter and cuts the auto cycle by a further 10%. Normal cap 80%." },
	ExtraLines = { "Fishing", "Each extra line independently has a 35% chance to hook a bonus fish at the same depth.", "Multi-Cast adds lines. Base 0, up to 9." },
	MutationChance = { "Fishing", "Adds percentage points to mutations already eligible from their natural chance or a matching bonus.", "+2 percentage points raises an eligible 2% roll to 4%. Higher priority mutations roll first." },
	CatchBarSize = { "Reeling", "Widens the catch zone so it is easier to keep the fish inside.", "Base 22% of the reel bar. Normal cap 60%, hard limit 75%." },
	ReelPower = { "Reeling", "Speeds up progress while the fish is inside the catch zone.", "Base 1.00x. 1.25x fills progress 25% faster." },
	Resilience = { "Reeling", "Reduces how quickly progress drains while the fish is outside the catch zone.", "50% halves progress loss. Normal cap 90%, hard limit 95%." },
	FishStability = { "Reeling", "Slows the fish's movement during the reel minigame.", "20% slows its movement by 20%. Normal cap 80%." },
	AutoSpeed = { "Auto Fishing", "Shortens the time between Auto Fishing catches.", "A 14s cycle becomes 11.2s with -20% Auto Wait at 0% Bite Speed. Normal cap 75%, hard limit 85%." },
	AutoMultiplier = { "Auto Fishing", "Scales the coin value stored on automatically caught fish and Multi-Cast bonus fish.", "Base 1.00x. 1.20x gives 20% more base coin value for those catches." },
	SellMultiplier = { "Rewards", "Multiplies the coin value used when eligible items are sold.", "Base 1.00x. 1.20x turns a 100 Coins sale into 120 before other bonuses and rounding." },
	XPMultiplier = { "Rewards", "Multiplies XP gained from catching fish.", "Base 1.00x. 1.25x gives 25% more catch XP before other bonuses." },
	PearlRate = { "Rewards", "Multiplies the Aquarium's Pearl income while online and when calculating offline income.", "Base 1.00x. At 1.20x, +10/s becomes +12/s before other boosts." },
	OfflineCapHours = { "Rewards", "Sets the maximum time the Aquarium can earn Pearls while you are offline.", "Base 4h, up to 48h. A 4h cap pays for up to 4h of a 6h absence." },
}

local CAPS: { [string]: { string } } = {
	MaxCatchBarSize = { "Max Catch Bar", "Raises the normal catch-zone cap of 60%, up to a hard limit of 75%." },
	MaxResilience = { "Max Resilience", "Raises the normal progress-loss reduction cap of 90%, up to a hard limit of 95%." },
	MaxFishStability = { "Max Fish Stability", "Raises the normal fish movement reduction cap of 80%." },
	MaxBiteSpeed = { "Max Bite Speed", "Raises the normal bite-wait reduction cap of 80%." },
	MaxAutoSpeed = { "Max Auto Wait", "Raises the maximum wait reduction above its normal 75% cap, up to 85%." },
}

local ATTRIBUTES = {
	{ "Prefix", "Prefix", "A rod can have up to 2. A Prefix can change a stat or its cap. The exact roll is shown on the item." },
	{ "Suffix", "Suffix", "A rod can have up to 2. Suffixes occupy their own slots and can change a stat or its cap." },
	{ "CursedRoll", "Cursed Roll", "A negative Modifier roll reduces the named stat or its cap. Auto Wait is displayed as an increase when the roll makes waiting longer." },
	{ "CapBreaker", "Cap Breaker", "Changes a stat's maximum. The equipped item's separate stat bonuses still determine how much of that cap you reach." },
	{ "Rarity", "Rarity", "Fish rarity affects base odds and rewards. Rod Modifier rarity identifies its roll tier and possible range." },
	{ "Weight", "Fish Weight", "The caught fish's weight in kg. Heavier fish of the same species generally sell for more." },
	{ "FishValue", "Fish Value", "Base coin value for a particular catch. Weight, mutation and catch modifiers contribute to it. The sale applies current Sell Mult and other sale bonuses." },
	{ "Mutation", "Mutation", "A fish variant stored on the catch. At most one mutation is applied, and it changes the fish's coin value." },
	{ "Enhance", "Enhance Level", "The upgrade level of the individual rod or line. It scales eligible base gear stats. Max Depth and rolled Mod values use their own rules." },
	{ "BagCapacity", "Bag Capacity", "The number of occupied item slots allowed. Fish and spare gear use slots, equipped rods and lines free their slots." },
	{ "StackSize", "Stack Size", "The quantity in one stack. Eligible items such as treasure can stack up to their item limit. Fish use one slot per catch." },
	{ "BaitQuantity", "Bait Quantity", "Each regular bait use spends one unit. Bonus fish from extra lines share the original catch's bait." },
	{ "Binding", "Bound / Unbound", "Bound items are restricted by their item rules. Unbound gear can qualify for trade if its item allows it." },
	{ "BoundOnUse", "Bound on Use", "This item flag represents a binding-on-use rule. Items with a bound state cannot be traded." },
	{ "RebirthProtected", "Rebirth Protected", "This item flag represents Rebirth protection. Protected items are treated as bound by trade rules." },
	{ "CatchMethod", "Manual / Auto", "Identifies how a fish was caught. Manual and Auto catches can use different reward multipliers." },
	{ "CatchTags", "Perfect / Hotspot", "Records a Perfect Cast or a catch from a hotspot on the item." },
	{ "DepthRange", "Depth Range", "The minimum and maximum depth where a species may appear, subject to the fishing area." },
	{ "Difficulty", "Fish Difficulty", "Adjusts challenge in the reel minigame. Higher difficulty makes fish movement more demanding." },
	{ "MovementPattern", "Movement Pattern", "The movement behavior of a species in the reel minigame." },
	{ "Tradeable", "Tradable", "An item must allow trading, be unbound, and be unequipped before it can qualify for a trade." },
	{ "Sellable", "Sellable", "Controls whether an item can be sold. Bound equipment and equipment with no sell price cannot be sold." },
	{ "AuraStars", "Aura Stars", "Stars scale the equipped aura's stat bonuses. Mutation-specific bonuses stay the same." },
}

local GROUP_ORDER: { [string]: number } = {
	Fishing = 1, Reeling = 2, ["Auto Fishing"] = 3, Rewards = 4, ["Cap Breakers"] = 5,
	Prefixes = 6, Suffixes = 7, ["Item Attributes"] = 8, Mutations = 9,
}

local function signed(value: number): string
	return string.format("%+g", value)
end

function Codex.Build(statDefs: any, modDefs: any, mutations: any): { Entry }
	local entries: { Entry } = {}
	local related: { [string]: { string } } = {}
	for _, group in { "Prefixes", "Suffixes" } do
		for _, mod in modDefs[group] do
			local isCap = string.sub(mod.Stat, 1, 3) == "Max"
				and statDefs[string.sub(mod.Stat, 4)] ~= nil
			local targetId = if isCap then string.sub(mod.Stat, 4) else mod.Stat
			local target = statDefs[targetId]
			local cap = CAPS[mod.Stat]
			local caption = if cap then cap[1] else if target then target.Display else targetId
			local factor = if target and target.Percent then 100 else 1
			local unit = if factor == 100 then " pp" else if targetId == "CastRange" then " studs" else ""
			local range = signed(mod.Min * factor) .. " to " .. signed(mod.Max * factor) .. unit
			local effect = if isCap
				then "Changes the maximum of " .. (if targetId == "AutoSpeed" then "the Auto Wait reduction" else target.Display) .. "."
				else "Adds the rolled amount to " .. caption .. " when the rod is equipped."
			local names = related[mod.Stat] or {}
			table.insert(names, mod.Name)
			related[mod.Stat] = names
			table.insert(entries, {
				Id = mod.Id, Title = mod.Name, Category = "Rod Mods", Group = group, Rarity = mod.Rarity,
				Effect = effect, Keywords = mod.Stat .. " " .. caption .. (if isCap then " cap breaker" else ""),
				Detail = "Roll range " .. range .. ". "
					.. (if targetId == "AutoSpeed" then "Positive rolls shorten Auto Wait or raise its reduction cap." else "Negative rolls decrease the stat or cap."),
			})
		end
	end
	for id, def in statDefs do
		local copy = STATS[id]
		table.insert(entries, {
			Id = id, Title = def.Display, Category = "Stats", Group = if copy then copy[1] else "Fishing",
			Effect = if copy then copy[2] else "Equipment, auras, and other bonuses can change this stat.",
			Detail = if copy then copy[3] else nil,
			Related = if related[id] then table.concat(related[id], ", ") else nil,
		})
	end
	for id, names in related do
		local cap = CAPS[id]
		if cap then
			table.insert(entries, {
				Id = id, Title = cap[1], Category = "Stats", Group = "Cap Breakers", Effect = cap[2],
				Detail = "This changes the limit. Separate stat bonuses determine how much of that limit you reach.",
				Keywords = "cap maximum limit", Related = table.concat(names, ", "),
			})
		end
	end
	for _, attribute in ATTRIBUTES do
		table.insert(entries, {
			Id = attribute[1], Title = attribute[2], Category = "Attributes",
			Group = "Item Attributes", Effect = attribute[3],
		})
	end
	for id, mutation in mutations do
		local eligibility = if mutation.BaseChance > 0
			then string.format("%g%% natural chance before bonuses.", mutation.BaseChance * 100)
			else "Needs a matching mutation bonus before it can roll."
		table.insert(entries, {
			Id = id, Title = mutation.Name, Category = "Attributes", Group = "Mutations",
			Effect = string.format("Multiplies the fish's coin value by %gx.", mutation.ValueMultiplier),
			Detail = eligibility .. " Only one mutation is applied to a catch.",
			Keywords = "mutation",
		})
	end
	table.sort(entries, function(a, b)
		if a.Group == b.Group then
			return a.Title < b.Title
		end
		return GROUP_ORDER[a.Group] < GROUP_ORDER[b.Group]
	end)
	return entries
end

function Codex.Matches(entry: Entry, category: string, query: string): boolean
	if category ~= "All" and entry.Category ~= category then
		return false
	end
	local haystack = string.lower(table.concat({
		entry.Id, entry.Title, entry.Group, entry.Effect,
		entry.Detail or "", entry.Related or "", entry.Keywords or "", entry.Rarity or "",
	}, " "))
	for term in string.gmatch(string.lower(query), "%S+") do
		if not string.find(haystack, term, 1, true) then
			return false
		end
	end
	return true
end

return Codex
