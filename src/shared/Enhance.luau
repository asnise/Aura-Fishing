--!strict
-- Gear Enhance (C16), shared by server and client. Numbers: GameConfig.Enhance.
--   Item rework: the level lives on each Rod / Line bag item (item.Enhance, missing = +0), not per config id.
-- Stats.Collect uses Enhance.ScaledStats for the worn rod and line, so the +N shows in all stat UI.
-- Requires only Registry (Stats requires this module).

local Registry = require(script.Parent.Registry)

local CFG = Registry.GameConfig.Enhance

-- What the UI needs for one item (Shop card / Enhance popup).
export type ItemState = {
	Level: number,
	MaxLevel: number,
	Coins: number?, -- price of the next level, nil = MAX
	Pearls: number?, -- extra Pearls for the next level (phase 2), nil = none
	Stats: { [string]: number }, -- stats now
	NextStats: { [string]: number }?, -- stats after the next level, nil = MAX
}

local Enhance = {}

Enhance.MaxLevel = CFG.MaxLevel

function Enhance.IsCategory(categoryId: string): boolean
	return table.find(CFG.Categories, categoryId) ~= nil
end

function Enhance.Level(item: any?): number
	return if item then item.Enhance or 0 else 0
end

-- Item stats at an Enhance level.
function Enhance.ScaledStats(stats: { [string]: number }, level: number): { [string]: number }
	if level <= 0 then
		return stats
	end
	local mult = 1 + CFG.StatPerLevel * level
	local out: { [string]: number } = {}
	for stat, v in stats do
		out[stat] = if CFG.ExcludeStats[stat] then v else v * mult
	end
	return out
end

-- True if enhancing this item changes anything (has a stat that scales).
function Enhance.CanEnhance(categoryId: string, itemId: string): boolean
	if not Enhance.IsCategory(categoryId) then
		return false
	end
	local cat = Registry.Equipment[categoryId]
	local item = cat and cat.Items[itemId]
	if not item then
		return false
	end
	for stat in item.Stats do
		if not CFG.ExcludeStats[stat] then
			return true
		end
	end
	return false
end

-- Cost of going from `level` to level + 1 -> coins, pearls? ; nil when maxed / not enhanceable.
function Enhance.Cost(categoryId: string, itemId: string, level: number): (number?, number?)
	if level >= CFG.MaxLevel or not Enhance.CanEnhance(categoryId, itemId) then
		return nil, nil
	end
	local item = Registry.Equipment[categoryId].Items[itemId]
	local coins = math.max(1, math.floor(item.Price * CFG.CostFraction * CFG.CostGrowth ^ level))
	return coins, CFG.PearlCosts[level + 1]
end

-- item = a Rod / Line bag item (Items/ItemTypes).
function Enhance.State(item: any): ItemState?
	local categoryId = if item.Kind == "Rod" then "Rods" elseif item.Kind == "Line" then "Lines" else nil
	if not categoryId or not Enhance.CanEnhance(categoryId, item.Id) then
		return nil
	end
	local def = Registry.Equipment[categoryId].Items[item.Id]
	local lv = Enhance.Level(item)
	local coins, pearls = Enhance.Cost(categoryId, item.Id, lv)
	return {
		Level = lv,
		MaxLevel = CFG.MaxLevel,
		Coins = coins,
		Pearls = pearls,
		Stats = Enhance.ScaledStats(def.Stats, lv),
		NextStats = if coins then Enhance.ScaledStats(def.Stats, lv + 1) else nil,
	}
end

return Enhance
