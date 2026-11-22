--!strict
-- Item model types (Item rework, docs/ITEM_REWORK_PLAN.md).
--   Layer 1 "Definition" = static blueprint, built from Config by Registry (Registry.Items[id]), never saved.
--   Layer 2 "Item"       = a plain record in profile.Bag (UUID, per-item data). Plain tables only: the
--                          profile is deep-copied to the DataStore and replicated to the client, so no metatables.

export type ItemCategory = "Fish" | "Rod" | "Line" | "Bait" | "Bag" | "Treasure"
export type BoundType = "Unbound" | "Bound" | "RebirthProtected" | "BoundOnUse"

export type ItemDef = {
	Id: string,
	Name: string,
	Description: string,
	Category: ItemCategory,
	Rarity: string,
	Icon: string,
	BasePrice: number,
	IsStackable: boolean,
	MaxStack: number,
	IsTradable: boolean,
	IsSellable: boolean,
	Bound: BoundType, -- status a fresh copy starts with ("Bound" for Starter Pack gifts)
	Equipment: string?, -- Config/Equipment category id for Rod / Line / Bag / Bait
}

export type ModEntry = {
	Id: string,
	Name: string,
	Stat: string,
	Value: number,
}

-- One bag entry. Kind = "Fish" | "Rod" | "Line" | "Treasure".
export type Item = {
	UUID: string,
	Id: string,
	Kind: string,
	Count: number?, -- stackables only (Treasure); everything else is 1
	Bound: BoundType?, -- nil = definition default
	Tradable: boolean?, -- nil = definition default
	Sellable: boolean?,
	New: string?, -- token of the most recent addition (Inventory "new" dot)
	-- Fish
	Weight: number?,
	Mutation: string?,
	Tags: { string }?, -- "Perfect" | "Hotspot" | "Manual" | "Auto"
	Value: number?, -- base coins (Roll.Value(entry, 1)); selling multiplies it
	-- Rod / Line
	Enhance: number?,
	Prefixes: { ModEntry }?,
	Suffixes: { ModEntry }?,
}

return {}
