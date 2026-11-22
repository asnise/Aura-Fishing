--!strict
-- Rods found while playing (fishing catches, treasure chests; later boss and quest rewards).
-- Picks a rod model the player can use and rolls its mods from a drop profile (Config/ModifierDefs.Profiles).
-- Rarer (more expensive) rods drop less often. Gifts, gem rods and rods above the player's level never drop.

local Registry = require(script.Parent.Parent.Registry)
local Inventory = require(script.Parent.ItemContainer)
local ItemTypes = require(script.Parent.ItemTypes)

local CFG = Registry.GameConfig.RodDrop

local RodDrop = {}

-- Profile for a catch: deep water or a hotspot rolls the better table.
function RodDrop.ProfileFor(depth: number, hotspot: boolean?): string
	return if hotspot == true or depth >= CFG.DeepDepth then "DeepSea" else "Fishing"
end

-- Rod id weighted by 1 / Price rank, or nil when nothing is eligible.
function RodDrop.PickRod(level: number, rng: Random): string?
	local ids, weights, total = {}, {}, 0
	for id, item in Registry.Equipment.Rods.Items do
		if not item.Exclusive and item.Currency == "Coins" and item.Price > 0 and (item.RequiredLevel or 0) <= level then
			local rank = table.find(Registry.SortedItems("Rods"), id) or 1
			local w = 1 / (rank * rank)
			table.insert(ids, id)
			table.insert(weights, w)
			total += w
		end
	end
	if #ids == 0 then
		return nil
	end
	local roll = rng:NextNumber() * total
	for i, w in weights do
		roll -= w
		if roll <= 0 then
			return ids[i]
		end
	end
	return ids[#ids]
end

-- A new rod item with rolled mods (not added to any bag), or nil.
function RodDrop.Create(profileName: string, level: number, rng: Random): ItemTypes.Item?
	local id = RodDrop.PickRod(level, rng)
	if not id then
		return nil
	end
	return Inventory.NewGear("Rods", id, profileName)
end

return RodDrop
