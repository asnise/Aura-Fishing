--!strict
-- Bag capacity (inventory SLOTS). Balance here only; Equipment.Bags and GameConfig.Inventory read this file.
-- One slot = one item (fish, rod, line, chest, bait type). Auras and bags use no slots.

local BagCapacity = {
	-- Slots per bag id (keys must match Config/Equipment.Bags.Items). The shop ladder is ordered by these numbers.
	Slots = {
		StarterPouch = 10,
		WovenBasket = 16,
		Crate = 24,
		Coolbox = 36,
		Hold = 50,
	} :: { [string]: number },

	InfiniteBagSlots = 999, -- Infinite Bag pass (C6); UI shows it as "Inf"
	Fallback = 10, -- used when the equipped bag id is unknown
}

return BagCapacity
