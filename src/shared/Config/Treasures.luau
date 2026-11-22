--!strict
-- Treasure chests (GDD 2: "...or you reel up a treasure chest"). A chest is a bonus drop on a catch
-- (DropChance, raised by Luck) and goes into a bag slot (stack up to Inventory.TreasureStackMax).
-- Open it from the Inventory: one reward is rolled from Rewards by Weight.
--   Kind = "Coins" | "Gems" : Min..Max amount
--   Kind = "Bait"           : Id (Equipment.Baits item) x Count
--   Kind = "Rod"            : a rod with rolled mods from drop table Profile (Config/ModifierDefs.Profiles)
-- Add a chest: add an entry (Icon = UIAssets key).

export type Reward = { Kind: string, Weight: number, Min: number?, Max: number?, Id: string?, Count: number?, Profile: string? }
export type Treasure = {
	Name: string,
	Rarity: string,
	Icon: string,
	DropChance: number, -- per catch, before Luck
	MinDepth: number?, -- only drops at/below this depth
	Rewards: { Reward },
}

local Treasures: { [string]: Treasure } = {
	TreasureChest = {
		Name = "Treasure Chest",
		Rarity = "Epic",
		Icon = "ui/status/treasure_chest",
		DropChance = 0.03,
		Rewards = {
			{ Kind = "Coins", Weight = 60, Min = 1500, Max = 6000 },
			{ Kind = "Gems", Weight = 25, Min = 3, Max = 10 },
			{ Kind = "Bait", Weight = 15, Id = "Shrimp", Count = 3 },
			{ Kind = "Rod", Weight = 5, Profile = "Fishing" },
		},
	},
}

return Treasures
