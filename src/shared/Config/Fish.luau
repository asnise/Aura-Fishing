--!strict
-- Fish catalogue. Add a fish = add one entry. Registry validates every entry at startup
-- (unknown rarity/pattern/location or bad depth range = clear error in Output).
--
-- DepthMin/DepthMax : metres. A fish can bite only when the player's target depth is inside.
-- BaseValue         : coins at average weight, before mutation/manual/sell multipliers.
-- Weight            : {min, max} kg. Heavier than average = worth more.
-- Difficulty        : 1..10, drives minigame speed.
-- Pattern           : movement style key in Config/MinigamePatterns.
-- Locations         : optional list of Location ids; nil = any location.
-- RollWeight        : optional, overrides the rarity's base weight for this fish.

export type FishDef = {
	Name: string,
	Rarity: string,
	DepthMin: number,
	DepthMax: number,
	BaseValue: number,
	Weight: { number },
	Difficulty: number,
	Pattern: string,
	Locations: { string }?,
	RollWeight: number?,
	Description: string?,
}

local Fish: { [string]: FishDef } = {
	-- Shallow 0-50m
	PebbleMinnow = { Name = "Pebble Minnow", Rarity = "Common", DepthMin = 0, DepthMax = 40, BaseValue = 40, Weight = { 0.1, 0.4 }, Difficulty = 1, Pattern = "Calm" },
	BubbleCarp = { Name = "Bubble Carp", Rarity = "Common", DepthMin = 0, DepthMax = 50, BaseValue = 60, Weight = { 0.8, 3 }, Difficulty = 1, Pattern = "Calm" },
	ReedPerch = { Name = "Reed Perch", Rarity = "Common", DepthMin = 5, DepthMax = 60, BaseValue = 80, Weight = { 0.4, 1.6 }, Difficulty = 2, Pattern = "Calm" },
	SunscaleSardine = { Name = "Sunscale Sardine", Rarity = "Common", DepthMin = 0, DepthMax = 30, BaseValue = 50, Weight = { 0.1, 0.3 }, Difficulty = 2, Pattern = "Darting" },
	PearlClam = { Name = "Pearl Clam", Rarity = "Uncommon", DepthMin = 10, DepthMax = 50, BaseValue = 220, Weight = { 0.2, 0.8 }, Difficulty = 1, Pattern = "Sinker" },
	LilyTrout = { Name = "Lily Trout", Rarity = "Uncommon", DepthMin = 0, DepthMax = 45, BaseValue = 180, Weight = { 1, 4 }, Difficulty = 3, Pattern = "Darting" },
	DewdropKoi = { Name = "Dewdrop Koi", Rarity = "Rare", DepthMin = 0, DepthMax = 35, BaseValue = 700, Weight = { 2, 6 }, Difficulty = 4, Pattern = "Erratic" },
	GoldenKoi = { Name = "Golden Koi", Rarity = "Legendary", DepthMin = 0, DepthMax = 40, BaseValue = 12000, Weight = { 3, 10 }, Difficulty = 7, Pattern = "Erratic", Description = "A shimmering carp with glistening golden scales said to bring fortune to those who reel it in." },
	CrystalGuppy = { Name = "Crystal Guppy", Rarity = "Epic", DepthMin = 0, DepthMax = 50, BaseValue = 2400, Weight = { 0.1, 0.2 }, Difficulty = 6, Pattern = "Darting" },

	-- Mid 51-200m
	StripeBass = { Name = "Stripe Bass", Rarity = "Common", DepthMin = 40, DepthMax = 140, BaseValue = 140, Weight = { 2, 7 }, Difficulty = 2, Pattern = "Calm" },
	TideSnapper = { Name = "Tide Snapper", Rarity = "Common", DepthMin = 50, DepthMax = 160, BaseValue = 160, Weight = { 1.5, 5 }, Difficulty = 3, Pattern = "Darting" },
	ArmoredCrab = { Name = "Armored Crab", Rarity = "Uncommon", DepthMin = 60, DepthMax = 120, BaseValue = 340, Weight = { 1, 4 }, Difficulty = 3, Pattern = "Sinker" },
	SilverRay = { Name = "Silver Ray", Rarity = "Uncommon", DepthMin = 70, DepthMax = 200, BaseValue = 400, Weight = { 5, 20 }, Difficulty = 4, Pattern = "Calm" },
	RazorPike = { Name = "Razor Pike", Rarity = "Rare", DepthMin = 60, DepthMax = 180, BaseValue = 1100, Weight = { 4, 12 }, Difficulty = 5, Pattern = "Darting" },
	MoonJelly = { Name = "Moon Jelly", Rarity = "Rare", DepthMin = 80, DepthMax = 200, BaseValue = 950, Weight = { 0.5, 2 }, Difficulty = 4, Pattern = "Erratic" },
	EmberTuna = { Name = "Ember Tuna", Rarity = "Epic", DepthMin = 100, DepthMax = 200, BaseValue = 4200, Weight = { 30, 90 }, Difficulty = 7, Pattern = "Erratic" },
	CoralSeahorse = { Name = "Coral Seahorse", Rarity = "Legendary", DepthMin = 50, DepthMax = 150, BaseValue = 15000, Weight = { 0.1, 0.3 }, Difficulty = 8, Pattern = "Erratic" },

	-- Deep 201m+ (needs line upgrades)
	GloomSprat = { Name = "Gloom Sprat", Rarity = "Common", DepthMin = 200, DepthMax = 400, BaseValue = 600, Weight = { 0.2, 0.6 }, Difficulty = 4, Pattern = "Darting", Description = "A plain little deep-sea fish with one glowing dot." },
	LanternAngler = { Name = "Lantern Angler", Rarity = "Uncommon", DepthMin = 200, DepthMax = 400, BaseValue = 900, Weight = { 2, 8 }, Difficulty = 5, Pattern = "Sinker" },
	GlowEel = { Name = "Glow Eel", Rarity = "Rare", DepthMin = 220, DepthMax = 500, BaseValue = 2600, Weight = { 3, 10 }, Difficulty = 6, Pattern = "Darting" },
	AncientCoelacanth = { Name = "Ancient Coelacanth", Rarity = "Legendary", DepthMin = 250, DepthMax = 600, BaseValue = 32000, Weight = { 40, 90 }, Difficulty = 8, Pattern = "Sinker" },
	NagaHatchling = { Name = "Naga Hatchling", Rarity = "Mythic", DepthMin = 200, DepthMax = 300, BaseValue = 120000, Weight = { 5, 15 }, Difficulty = 9, Pattern = "Erratic", RollWeight = 0.2, Description = "A young serpent of the river. Its parent still sleeps below." },
	-- Deep 300m+ / Abyssal Trench (2026-11-18: art was uploaded; needs Abyss Line 600m / Star Line 1000m)
	InkletSquid = { Name = "Inklet Squid", Rarity = "Common", DepthMin = 220, DepthMax = 500, BaseValue = 750, Weight = { 0.3, 1.2 }, Difficulty = 4, Pattern = "Darting", Description = "A small round squid with curly tentacles. It puffs a tiny cloud of ink when surprised." },
	BoneCarp = { Name = "Bone Carp", Rarity = "Uncommon", DepthMin = 280, DepthMax = 560, BaseValue = 1400, Weight = { 2, 6 }, Difficulty = 5, Pattern = "Calm", Description = "Its pale scales show a gentle skeleton pattern. Cute, not scary." },
	PearlNautilus = { Name = "Pearl Nautilus", Rarity = "Uncommon", DepthMin = 320, DepthMax = 620, BaseValue = 1700, Weight = { 1, 3 }, Difficulty = 4, Pattern = "Sinker", Description = "A striped shell with a lavender pearl glinting in its opening." },
	LanternJellyfish = { Name = "Lantern Jellyfish", Rarity = "Rare", DepthMin = 350, DepthMax = 700, BaseValue = 4000, Weight = { 0.5, 2 }, Difficulty = 6, Pattern = "Erratic", Description = "A soft gold light glows in its core, lighting the dark water." },
	FrostRay = { Name = "Frost Ray", Rarity = "Rare", DepthMin = 450, DepthMax = 850, BaseValue = 5500, Weight = { 15, 40 }, Difficulty = 6, Pattern = "Calm", Description = "A pale manta ray with frosty white wing tips, cold to the touch." },
	StarlightEel = { Name = "Starlight Eel", Rarity = "Epic", DepthMin = 500, DepthMax = 950, BaseValue = 15000, Weight = { 4, 12 }, Difficulty = 7, Pattern = "Darting", Description = "A long deep-purple eel speckled with tiny gold stars." },
	VoidKoi = { Name = "Void Koi", Rarity = "Legendary", DepthMin = 650, DepthMax = 1000, BaseValue = 65000, Weight = { 5, 14 }, Difficulty = 8, Pattern = "Erratic", Description = "Wisps of purple smoke trail from its fins. Some say it swims between worlds." },
	AbyssLeviathan = { Name = "Abyss Leviathan", Rarity = "Mythic", DepthMin = 800, DepthMax = 1000, BaseValue = 320000, Weight = { 200, 600 }, Difficulty = 10, Pattern = "Erratic", RollWeight = 0.3, Description = "A great sea serpent of the trench. Its mint eyes are the last light before the dark." },
}

return Fish
