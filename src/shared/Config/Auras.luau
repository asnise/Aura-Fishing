--!strict
-- Auras (GDD 5). Rolled with Gems/Coins at the Aura altar. `Chance` is "1 in N".
-- Stats       : additive stat bonuses while equipped.
-- Mutations   : extra chance per mutation id while equipped (e.g. { SunForged = 0.10 }).
-- Visual      : data-driven particle look; AuraService builds emitters from it.
-- To add an aura: add an entry. Rolling, equipping, UI and VFX pick it up automatically.

export type AuraVisual = {
	Color: { Color3 }, -- 1 or 2 colours (gradient)
	Rate: number,
	Size: number,
	Speed: number,
	Lifetime: number,
	LightEmission: number,
	Light: boolean?, -- add a PointLight
	Spin: boolean?,
	Texture: string?,
}

export type AuraDef = {
	Name: string,
	Rarity: string,
	Chance: number,
	Order: number,
	Stats: { [string]: number },
	Mutations: { [string]: number }?,
	Visual: AuraVisual,
	Description: string?,
}

local Auras: { [string]: AuraDef } = {
	SparklingDew = {
		Name = "Sparkling Dew", Rarity = "Common", Chance = 10, Order = 1,
		Stats = { Luck = 0.05 },
		Visual = { Color = { Color3.fromRGB(180, 240, 255) }, Rate = 8, Size = 0.25, Speed = 1, Lifetime = 1.2, LightEmission = 0.8 },
	},
	NeonWave = {
		Name = "Neon Wave", Rarity = "Rare", Chance = 100, Order = 5,
		Stats = { Luck = 0.15, CatchBarSize = 0.022 },
		Mutations = { Glowing = 0.03 },
		Visual = { Color = { Color3.fromRGB(0, 200, 255), Color3.fromRGB(0, 90, 255) }, Rate = 18, Size = 0.4, Speed = 2, Lifetime = 1, LightEmission = 1, Light = true },
	},
	SolarFlare = {
		Name = "Solar Flare", Rarity = "Epic", Chance = 750, Order = 8,
		Stats = { Luck = 0.35 },
		Mutations = { SunForged = 0.10 },
		Visual = { Color = { Color3.fromRGB(255, 220, 80), Color3.fromRGB(255, 80, 0) }, Rate = 30, Size = 0.6, Speed = 3, Lifetime = 0.9, LightEmission = 1, Light = true, Spin = true },
	},
	AbyssalShadow = {
		Name = "Abyssal Shadow", Rarity = "Legendary", Chance = 5000, Order = 11,
		Stats = { Luck = 0.5, AutoMultiplier = 0.2 },
		Mutations = { VoidTouched = 0.03 },
		Visual = { Color = { Color3.fromRGB(110, 40, 170), Color3.fromRGB(10, 0, 20) }, Rate = 35, Size = 1, Speed = 1.5, Lifetime = 1.6, LightEmission = 0.3, Spin = true },
	},
	DragonEmperor = {
		Name = "Dragon Emperor", Rarity = "Mythic", Chance = 50000, Order = 14,
		Stats = { Luck = 1.0, FishStability = 0.3 },
		Mutations = { Golden = 0.25 },
		Visual = { Color = { Color3.fromRGB(255, 215, 0), Color3.fromRGB(255, 140, 0) }, Rate = 50, Size = 0.8, Speed = 4, Lifetime = 1.4, LightEmission = 1, Light = true, Spin = true },
	},
	-- 2026-11-18: 10 auras whose art was already uploaded. Order = rarest last (Aura Dex / rates order).
	TidalBloom = {
		Name = "Tidal Bloom", Rarity = "Common", Chance = 15, Order = 2,
		Stats = { Luck = 0.06, BiteSpeed = 0.02 },
		Visual = { Color = { Color3.fromRGB(150, 235, 200), Color3.fromRGB(255, 190, 220) }, Rate = 8, Size = 0.3, Speed = 1, Lifetime = 1.3, LightEmission = 0.7 },
	},
	KelpWhisper = {
		Name = "Kelp Whisper", Rarity = "Uncommon", Chance = 40, Order = 3,
		Stats = { Luck = 0.1, FishStability = 0.05 },
		Visual = { Color = { Color3.fromRGB(110, 210, 120), Color3.fromRGB(40, 140, 80) }, Rate = 12, Size = 0.35, Speed = 1.2, Lifetime = 1.4, LightEmission = 0.6 },
	},
	CoralHeart = {
		Name = "Coral Heart", Rarity = "Uncommon", Chance = 60, Order = 4,
		Stats = { Luck = 0.1, SellMultiplier = 0.05 },
		Visual = { Color = { Color3.fromRGB(255, 150, 160), Color3.fromRGB(255, 100, 130) }, Rate = 12, Size = 0.35, Speed = 1.4, Lifetime = 1.2, LightEmission = 0.8 },
	},
	MoonlitRipple = {
		Name = "Moonlit Ripple", Rarity = "Rare", Chance = 250, Order = 6,
		Stats = { Luck = 0.2, AutoSpeed = 0.05 },
		Mutations = { Glowing = 0.04 },
		Visual = { Color = { Color3.fromRGB(200, 220, 255), Color3.fromRGB(40, 60, 160) }, Rate = 18, Size = 0.45, Speed = 1.5, Lifetime = 1.4, LightEmission = 1, Light = true },
	},
	StormCurrent = {
		Name = "Storm Current", Rarity = "Rare", Chance = 400, Order = 7,
		Stats = { Luck = 0.25, BiteSpeed = 0.08 },
		Visual = { Color = { Color3.fromRGB(150, 220, 255), Color3.fromRGB(255, 220, 90) }, Rate = 24, Size = 0.45, Speed = 3, Lifetime = 0.8, LightEmission = 1, Light = true, Spin = true },
	},
	FrostPearl = {
		Name = "Frost Pearl", Rarity = "Epic", Chance = 1500, Order = 9,
		Stats = { Luck = 0.4, Resilience = 0.1 },
		Mutations = { Glowing = 0.06 },
		Visual = { Color = { Color3.fromRGB(235, 250, 255), Color3.fromRGB(160, 210, 255) }, Rate = 26, Size = 0.5, Speed = 1.2, Lifetime = 1.6, LightEmission = 1, Light = true },
	},
	NebulaKoi = {
		Name = "Nebula Koi", Rarity = "Epic", Chance = 3000, Order = 10,
		Stats = { Luck = 0.45, XPMultiplier = 0.1 },
		Mutations = { Golden = 0.03 },
		Visual = { Color = { Color3.fromRGB(200, 170, 255), Color3.fromRGB(255, 160, 210) }, Rate = 30, Size = 0.6, Speed = 1.8, Lifetime = 1.5, LightEmission = 1, Light = true, Spin = true },
	},
	LotusNaga = {
		Name = "Lotus Naga", Rarity = "Legendary", Chance = 12000, Order = 12,
		Stats = { Luck = 0.6, FishStability = 0.15, AutoMultiplier = 0.1 },
		Mutations = { Golden = 0.08 },
		Visual = { Color = { Color3.fromRGB(60, 200, 130), Color3.fromRGB(255, 150, 200) }, Rate = 38, Size = 0.8, Speed = 1.6, Lifetime = 1.6, LightEmission = 0.9, Light = true, Spin = true },
	},
	SerpentOfTheVoid = {
		Name = "Serpent of the Void", Rarity = "Legendary", Chance = 25000, Order = 13,
		Stats = { Luck = 0.75, MutationChance = 0.03 },
		Mutations = { VoidTouched = 0.05 },
		Visual = { Color = { Color3.fromRGB(255, 120, 220), Color3.fromRGB(90, 220, 255) }, Rate = 42, Size = 0.9, Speed = 2.2, Lifetime = 1.5, LightEmission = 1, Light = true, Spin = true },
	},
	CelestialLeviathan = {
		Name = "Celestial Leviathan", Rarity = "Mythic", Chance = 150000, Order = 15,
		Stats = { Luck = 1.4, FishStability = 0.35, MutationChance = 0.05 },
		Mutations = { Golden = 0.3, VoidTouched = 0.05 },
		Visual = { Color = { Color3.fromRGB(255, 255, 255), Color3.fromRGB(180, 140, 255) }, Rate = 60, Size = 1, Speed = 4, Lifetime = 1.6, LightEmission = 1, Light = true, Spin = true },
	},
}

return Auras
