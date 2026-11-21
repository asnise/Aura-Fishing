--!strict
-- Fish mutations (GDD 5.3). On every catch each mutation is checked in Priority order
-- (highest first); the first that succeeds is applied. Chance = BaseChance + MutationChance stat
-- + aura-specific bonus for this mutation id.

export type MutationDef = {
	Name: string,
	ValueMultiplier: number,
	BaseChance: number,
	Priority: number,
	Color: Color3,
}

local Mutations: { [string]: MutationDef } = {
	Glowing = { Name = "Glowing", ValueMultiplier = 1.8, BaseChance = 0.02, Priority = 1, Color = Color3.fromRGB(60, 196, 176) },
	SunForged = { Name = "Sun-Forged", ValueMultiplier = 2.5, BaseChance = 0, Priority = 2, Color = Color3.fromRGB(242, 140, 56) },
	Golden = { Name = "Golden", ValueMultiplier = 3.0, BaseChance = 0.005, Priority = 3, Color = Color3.fromRGB(224, 168, 46) },
	VoidTouched = { Name = "Void-Touched", ValueMultiplier = 5.0, BaseChance = 0, Priority = 4, Color = Color3.fromRGB(138, 92, 200) },
}

return Mutations
