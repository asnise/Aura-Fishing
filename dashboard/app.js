// Aura Fishing - Game Balance & Project Manager Core Logic
(function() {
  const SEED_DATA = {"constants": [{"group": "Start", "key": "StartingCoins", "value": "500", "unit": "coins", "desc": "Coins a new player starts with", "source": "Config/GameConfig"}, {"group": "Start", "key": "StartingGems", "value": "15", "unit": "gems", "desc": "Gems a new player starts with", "source": "Config/GameConfig"}, {"group": "Casting", "key": "CastTapPower", "value": "0.55", "unit": "0-1", "desc": "Cast power of a tap / Auto cast (distance = MinDistance + (CastRange-MinDistance) x power)", "source": "Config/GameConfig.Cast"}, {"group": "Casting", "key": "CastMinDistance", "value": "6", "unit": "studs", "desc": "Cast distance at power 0", "source": "Config/GameConfig.Cast"}, {"group": "Casting", "key": "PerfectBiteBonus", "value": "0.3", "unit": "fraction", "desc": "Perfect cast: bite wait x (1 - this)", "source": "Config/GameConfig.Cast"}, {"group": "Casting", "key": "PerfectMin", "value": "0.78", "unit": "0-1", "desc": "Gold zone start on the power bar", "source": "Config/GameConfig.Cast"}, {"group": "Casting", "key": "PerfectMax", "value": "0.9", "unit": "0-1", "desc": "Gold zone end on the power bar", "source": "Config/GameConfig.Cast"}, {"group": "Casting", "key": "BiteWaitMin", "value": "2.5", "unit": "sec", "desc": "Shortest random bite wait (before BiteSpeed)", "source": "Config/GameConfig"}, {"group": "Casting", "key": "BiteWaitMax", "value": "6", "unit": "sec", "desc": "Longest random bite wait (before BiteSpeed)", "source": "Config/GameConfig"}, {"group": "Casting", "key": "BiteWindow", "value": "2.2", "unit": "sec", "desc": "Seconds to click the '!' before the fish escapes", "source": "Config/GameConfig"}, {"group": "Casting", "key": "CastCooldown", "value": "0.6", "unit": "sec", "desc": "Cooldown between casts", "source": "Config/GameConfig"}, {"group": "Casting", "key": "FlightTime", "value": "0.35", "unit": "sec", "desc": "Bobber flight time", "source": "Config/GameConfig.Cast"}, {"group": "Manual vs Auto", "key": "ManualMultiplier", "value": "1.5", "unit": "x", "desc": "Coin value and XP multiplier of a manual catch", "source": "Config/GameConfig"}, {"group": "Manual vs Auto", "key": "PerfectCatchBonus", "value": "0.25", "unit": "x added", "desc": "Added to the manual multiplier when the fish never left the catch bar", "source": "Config/GameConfig"}, {"group": "Manual vs Auto", "key": "AutoCycleTime", "value": "14", "unit": "sec", "desc": "Seconds per Auto catch (before AutoSpeed / BiteSpeed)", "source": "Config/GameConfig"}, {"group": "Manual vs Auto", "key": "AutoGemMultiplier", "value": "0.5", "unit": "share", "desc": "Auto catches give this share of rarity Gems (the fraction is the chance of +1)", "source": "Config/GameConfig"}, {"group": "Manual vs Auto", "key": "AutoTreasureMultiplier", "value": "0.5", "unit": "share", "desc": "Auto catches roll chests at this share of the chance", "source": "Config/GameConfig"}, {"group": "Hot Streak", "key": "HotStreakPerCatch", "value": "0.05", "unit": "x per catch", "desc": "Each manual catch in a row adds this to the coin value", "source": "Config/GameConfig.HotStreak"}, {"group": "Hot Streak", "key": "HotStreakMax", "value": "0.5", "unit": "x max", "desc": "Streak bonus cap (reached at x10)", "source": "Config/GameConfig.HotStreak"}, {"group": "Reel minigame", "key": "ReelStartProgress", "value": "0.25", "unit": "0-1", "desc": "Catch progress at the start", "source": "Config/GameConfig.Minigame"}, {"group": "Reel minigame", "key": "ReelGainPerSecond", "value": "0.32", "unit": "per sec", "desc": "Progress gain while on the fish (x ReelPower)", "source": "Config/GameConfig.Minigame"}, {"group": "Reel minigame", "key": "ReelLossPerSecond", "value": "0.22", "unit": "per sec", "desc": "Progress loss while off the fish (x (1 - Resilience))", "source": "Config/GameConfig.Minigame"}, {"group": "Reel minigame", "key": "DifficultySpeedScale", "value": "0.18", "unit": "x per level", "desc": "Fish speed = pattern speed x (1 + (Difficulty-1) x this)", "source": "Config/GameConfig.Minigame"}, {"group": "Reel minigame", "key": "ReelMaxDuration", "value": "60", "unit": "sec", "desc": "Max reel time", "source": "Config/GameConfig.Minigame"}, {"group": "Reel minigame", "key": "ValidationSlack", "value": "0.8", "unit": "fraction", "desc": "Server accepts a finish at this share of the theoretical minimum time", "source": "Config/GameConfig.Minigame"}, {"group": "Inventory", "key": "FishStackMax", "value": "10", "unit": "fish", "desc": "Same species + mutation stack up to this", "source": "Config/GameConfig.Inventory"}, {"group": "Inventory", "key": "TreasureStackMax", "value": "5", "unit": "chests", "desc": "Chest stack size", "source": "Config/GameConfig.Inventory"}, {"group": "Inventory", "key": "TreasureLuckScale", "value": "0.5", "unit": "x per Luck", "desc": "Chest drop chance x (1 + Luck x this)", "source": "Config/GameConfig.Inventory"}, {"group": "Inventory", "key": "InfiniteBagSlots", "value": "999", "unit": "slots", "desc": "Capacity with the Infinite Bag pass", "source": "Config/GameConfig.Inventory"}, {"group": "Boosts", "key": "BoostCoinsMult", "value": "2", "unit": "x", "desc": "2x Coins boost (fish sale price)", "source": "Config/GameConfig.Boosts"}, {"group": "Boosts", "key": "BoostPearlsMult", "value": "2", "unit": "x", "desc": "2x Pearls boost (Aquarium)", "source": "Config/GameConfig.Boosts"}, {"group": "Rolling", "key": "LuckTierExponent", "value": "0.6", "unit": "exponent", "desc": "Fish weight x (1 + Luck) ^ ((Tier - 1) x this)", "source": "Config/GameConfig"}, {"group": "Progression", "key": "XPBase", "value": "60", "unit": "xp", "desc": "XP to next level = floor(XPBase x Level ^ XPExponent)", "source": "Config/GameConfig"}, {"group": "Progression", "key": "XPExponent", "value": "1.3", "unit": "exponent", "desc": "XP curve steepness", "source": "Config/GameConfig"}, {"group": "Progression", "key": "GemsPerLevel", "value": "5", "unit": "gems", "desc": "Gems for each level-up", "source": "Config/GameConfig"}, {"group": "Progression", "key": "NewSpeciesGems", "value": "3", "unit": "gems", "desc": "Gems for the first catch of a species", "source": "Config/GameConfig"}, {"group": "Progression", "key": "SkillPointsPerLevel", "value": "1", "unit": "points", "desc": "Skill points per level-up", "source": "Config/Skills"}, {"group": "Mastery", "key": "MasteryPriceGrowth", "value": "1.15", "unit": "x per level", "desc": "Mastery price = floor(BasePrice x PriceGrowth ^ level) Pearls", "source": "Config/Mastery"}, {"group": "Enhance", "key": "EnhanceMaxLevel", "value": "10", "unit": "level", "desc": "Max Enhance level", "source": "Config/GameConfig.Enhance"}, {"group": "Enhance", "key": "EnhanceStatPerLevel", "value": "0.04", "unit": "x per level", "desc": "Stats x (1 + this x level); MaxDepth is excluded", "source": "Config/GameConfig.Enhance"}, {"group": "Enhance", "key": "EnhanceCostFraction", "value": "0.1", "unit": "of price", "desc": "Coins for level L->L+1 = floor(price x this x growth ^ L)", "source": "Config/GameConfig.Enhance"}, {"group": "Enhance", "key": "EnhanceCostGrowth", "value": "1.5", "unit": "x per level", "desc": "Enhance cost growth", "source": "Config/GameConfig.Enhance"}, {"group": "Aquarium", "key": "AquariumStartSlots", "value": "3", "unit": "slots", "desc": "Tank slots at start", "source": "Config/GameConfig.Aquarium"}, {"group": "Aquarium", "key": "AquariumMinOfflineSeconds", "value": "60", "unit": "sec", "desc": "Shorter absences give nothing", "source": "Config/GameConfig.Aquarium"}, {"group": "Auras", "key": "AuraRollCost", "value": "5", "unit": "gems", "desc": "Default cost of one aura roll", "source": "Config/GameConfig"}, {"group": "Auras", "key": "AuraStarsMax", "value": "5", "unit": "stars", "desc": "Max aura stars", "source": "Config/AuraStars"}, {"group": "Auras", "key": "AuraStatPerStar", "value": "0.2", "unit": "x per star", "desc": "Aura stats x (1 + this x stars)", "source": "Config/AuraStars"}, {"group": "Rebirth", "key": "RebirthRequiredLevel", "value": "50", "unit": "level", "desc": "Level needed for the first rebirth", "source": "Config/Features.Rebirth"}, {"group": "Rebirth", "key": "RebirthLevelStep", "value": "10", "unit": "levels", "desc": "Added to the required level per rebirth", "source": "Config/Features.Rebirth"}, {"group": "Rebirth", "key": "RebirthMaxLevel", "value": "100", "unit": "level", "desc": "Required level cap", "source": "Config/Features.Rebirth"}, {"group": "Rebirth", "key": "RebirthBonus", "value": "0.25", "unit": "x per rebirth", "desc": "Added to SellMultiplier and PearlRate per rebirth", "source": "Config/Features.Rebirth"}, {"group": "Skills", "key": "MultiCastChance", "value": "0.35", "unit": "chance", "desc": "Each extra line: chance of a bonus fish per catch", "source": "Config/Skills"}, {"group": "Hot fish", "key": "HotFishIntervalMin", "value": "60", "unit": "min", "desc": "Merchant hot list rotates this often", "source": "Config/GameConfig.HotFish"}, {"group": "Hot fish", "key": "HotFishCountMin", "value": "1", "unit": "species", "desc": "Fewest hot species", "source": "Config/GameConfig.HotFish"}, {"group": "Hot fish", "key": "HotFishCountMax", "value": "2", "unit": "species", "desc": "Most hot species", "source": "Config/GameConfig.HotFish"}, {"group": "Hot fish", "key": "HotFishMults", "value": "2 / 2.5 / 3", "unit": "x", "desc": "Possible sell multipliers (random)", "source": "Config/GameConfig.HotFish"}, {"group": "Hotspot", "key": "HotspotLuckBonus", "value": "0.5", "unit": "Luck", "desc": "Luck added when a manual cast lands in a hotspot", "source": "Config/GameConfig.Hotspot"}, {"group": "Hotspot", "key": "HotspotUses", "value": "2", "unit": "casts", "desc": "Casts a hotspot allows", "source": "Config/GameConfig.Hotspot"}, {"group": "Hotspot", "key": "HotspotMax", "value": "4", "unit": "spots", "desc": "Hotspots per server", "source": "Config/GameConfig.Hotspot"}, {"group": "Quests", "key": "QuestsPerDay", "value": "3", "unit": "quests", "desc": "Daily quests", "source": "Config/Features.Quests"}, {"group": "Quests", "key": "QuestRewardGems", "value": "5", "unit": "gems", "desc": "Gems per finished quest", "source": "Config/Features.Quests"}], "fish": [{"id": "PebbleMinnow", "name": "Pebble Minnow", "rarity": "Common", "tier": 1, "depthMin": 0.0, "depthMax": 40.0, "weightMin": 0.1, "weightMax": 0.4, "baseValue": 40.0, "difficulty": 1, "pattern": "Calm", "pearlsMin": 0.2}, {"id": "SunscaleSardine", "name": "Sunscale Sardine", "rarity": "Common", "tier": 1, "depthMin": 0.0, "depthMax": 30.0, "weightMin": 0.1, "weightMax": 0.3, "baseValue": 50.0, "difficulty": 2, "pattern": "Darting", "pearlsMin": 0.2}, {"id": "BubbleCarp", "name": "Bubble Carp", "rarity": "Common", "tier": 1, "depthMin": 0.0, "depthMax": 50.0, "weightMin": 0.8, "weightMax": 3.0, "baseValue": 60.0, "difficulty": 1, "pattern": "Calm", "pearlsMin": 0.2}, {"id": "ReedPerch", "name": "Reed Perch", "rarity": "Common", "tier": 1, "depthMin": 5.0, "depthMax": 60.0, "weightMin": 0.4, "weightMax": 1.6, "baseValue": 80.0, "difficulty": 2, "pattern": "Calm", "pearlsMin": 0.2}, {"id": "StripeBass", "name": "Stripe Bass", "rarity": "Common", "tier": 1, "depthMin": 40.0, "depthMax": 140.0, "weightMin": 2.0, "weightMax": 7.0, "baseValue": 140.0, "difficulty": 2, "pattern": "Calm", "pearlsMin": 0.2}, {"id": "TideSnapper", "name": "Tide Snapper", "rarity": "Common", "tier": 1, "depthMin": 50.0, "depthMax": 160.0, "weightMin": 1.5, "weightMax": 5.0, "baseValue": 160.0, "difficulty": 3, "pattern": "Darting", "pearlsMin": 0.2}, {"id": "GloomSprat", "name": "Gloom Sprat", "rarity": "Common", "tier": 1, "depthMin": 200.0, "depthMax": 400.0, "weightMin": 0.2, "weightMax": 0.6, "baseValue": 600.0, "difficulty": 4, "pattern": "Darting", "pearlsMin": 0.2}, {"id": "InkletSquid", "name": "Inklet Squid", "rarity": "Common", "tier": 1, "depthMin": 220.0, "depthMax": 500.0, "weightMin": 0.3, "weightMax": 1.2, "baseValue": 750.0, "difficulty": 4, "pattern": "Darting", "pearlsMin": 0.2}, {"id": "LilyTrout", "name": "Lily Trout", "rarity": "Uncommon", "tier": 2, "depthMin": 0.0, "depthMax": 45.0, "weightMin": 1.0, "weightMax": 4.0, "baseValue": 180.0, "difficulty": 3, "pattern": "Darting", "pearlsMin": 0.5}, {"id": "PearlClam", "name": "Pearl Clam", "rarity": "Uncommon", "tier": 2, "depthMin": 10.0, "depthMax": 50.0, "weightMin": 0.2, "weightMax": 0.8, "baseValue": 220.0, "difficulty": 1, "pattern": "Sinker", "pearlsMin": 0.5}, {"id": "ArmoredCrab", "name": "Armored Crab", "rarity": "Uncommon", "tier": 2, "depthMin": 60.0, "depthMax": 120.0, "weightMin": 1.0, "weightMax": 4.0, "baseValue": 340.0, "difficulty": 3, "pattern": "Sinker", "pearlsMin": 0.5}, {"id": "SilverRay", "name": "Silver Ray", "rarity": "Uncommon", "tier": 2, "depthMin": 70.0, "depthMax": 200.0, "weightMin": 5.0, "weightMax": 20.0, "baseValue": 400.0, "difficulty": 4, "pattern": "Calm", "pearlsMin": 0.5}, {"id": "LanternAngler", "name": "Lantern Angler", "rarity": "Uncommon", "tier": 2, "depthMin": 200.0, "depthMax": 400.0, "weightMin": 2.0, "weightMax": 8.0, "baseValue": 900.0, "difficulty": 5, "pattern": "Sinker", "pearlsMin": 0.5}, {"id": "BoneCarp", "name": "Bone Carp", "rarity": "Uncommon", "tier": 2, "depthMin": 280.0, "depthMax": 560.0, "weightMin": 2.0, "weightMax": 6.0, "baseValue": 1400.0, "difficulty": 5, "pattern": "Calm", "pearlsMin": 0.5}, {"id": "PearlNautilus", "name": "Pearl Nautilus", "rarity": "Uncommon", "tier": 2, "depthMin": 320.0, "depthMax": 620.0, "weightMin": 1.0, "weightMax": 3.0, "baseValue": 1700.0, "difficulty": 4, "pattern": "Sinker", "pearlsMin": 0.5}, {"id": "DewdropKoi", "name": "Dewdrop Koi", "rarity": "Rare", "tier": 3, "depthMin": 0.0, "depthMax": 35.0, "weightMin": 2.0, "weightMax": 6.0, "baseValue": 700.0, "difficulty": 4, "pattern": "Erratic", "pearlsMin": 1.5}, {"id": "MoonJelly", "name": "Moon Jelly", "rarity": "Rare", "tier": 3, "depthMin": 80.0, "depthMax": 200.0, "weightMin": 0.5, "weightMax": 2.0, "baseValue": 950.0, "difficulty": 4, "pattern": "Erratic", "pearlsMin": 1.5}, {"id": "RazorPike", "name": "Razor Pike", "rarity": "Rare", "tier": 3, "depthMin": 60.0, "depthMax": 180.0, "weightMin": 4.0, "weightMax": 12.0, "baseValue": 1100.0, "difficulty": 5, "pattern": "Darting", "pearlsMin": 1.5}, {"id": "GlowEel", "name": "Glow Eel", "rarity": "Rare", "tier": 3, "depthMin": 220.0, "depthMax": 500.0, "weightMin": 3.0, "weightMax": 10.0, "baseValue": 2600.0, "difficulty": 6, "pattern": "Darting", "pearlsMin": 1.5}, {"id": "LanternJellyfish", "name": "Lantern Jellyfish", "rarity": "Rare", "tier": 3, "depthMin": 350.0, "depthMax": 700.0, "weightMin": 0.5, "weightMax": 2.0, "baseValue": 4000.0, "difficulty": 6, "pattern": "Erratic", "pearlsMin": 1.5}, {"id": "FrostRay", "name": "Frost Ray", "rarity": "Rare", "tier": 3, "depthMin": 450.0, "depthMax": 850.0, "weightMin": 15.0, "weightMax": 40.0, "baseValue": 5500.0, "difficulty": 6, "pattern": "Calm", "pearlsMin": 1.5}, {"id": "CrystalGuppy", "name": "Crystal Guppy", "rarity": "Epic", "tier": 4, "depthMin": 0.0, "depthMax": 50.0, "weightMin": 0.1, "weightMax": 0.2, "baseValue": 2400.0, "difficulty": 6, "pattern": "Darting", "pearlsMin": 4.0}, {"id": "EmberTuna", "name": "Ember Tuna", "rarity": "Epic", "tier": 4, "depthMin": 100.0, "depthMax": 200.0, "weightMin": 30.0, "weightMax": 90.0, "baseValue": 4200.0, "difficulty": 7, "pattern": "Erratic", "pearlsMin": 4.0}, {"id": "StarlightEel", "name": "Starlight Eel", "rarity": "Epic", "tier": 4, "depthMin": 500.0, "depthMax": 950.0, "weightMin": 4.0, "weightMax": 12.0, "baseValue": 15000.0, "difficulty": 7, "pattern": "Darting", "pearlsMin": 4.0}, {"id": "GoldenKoi", "name": "Golden Koi", "rarity": "Legendary", "tier": 5, "depthMin": 0.0, "depthMax": 40.0, "weightMin": 3.0, "weightMax": 10.0, "baseValue": 12000.0, "difficulty": 7, "pattern": "Erratic", "pearlsMin": 12.0}, {"id": "CoralSeahorse", "name": "Coral Seahorse", "rarity": "Legendary", "tier": 5, "depthMin": 50.0, "depthMax": 150.0, "weightMin": 0.1, "weightMax": 0.3, "baseValue": 15000.0, "difficulty": 8, "pattern": "Erratic", "pearlsMin": 12.0}, {"id": "AncientCoelacanth", "name": "Ancient Coelacanth", "rarity": "Legendary", "tier": 5, "depthMin": 250.0, "depthMax": 600.0, "weightMin": 40.0, "weightMax": 90.0, "baseValue": 32000.0, "difficulty": 8, "pattern": "Sinker", "pearlsMin": 12.0}, {"id": "VoidKoi", "name": "Void Koi", "rarity": "Legendary", "tier": 5, "depthMin": 650.0, "depthMax": 1000.0, "weightMin": 5.0, "weightMax": 14.0, "baseValue": 65000.0, "difficulty": 8, "pattern": "Erratic", "pearlsMin": 12.0}, {"id": "NagaHatchling", "name": "Naga Hatchling", "rarity": "Mythic", "tier": 6, "depthMin": 200.0, "depthMax": 300.0, "weightMin": 5.0, "weightMax": 15.0, "baseValue": 120000.0, "difficulty": 9, "pattern": "Erratic", "pearlsMin": 40.0}, {"id": "AbyssLeviathan", "name": "Abyss Leviathan", "rarity": "Mythic", "tier": 6, "depthMin": 800.0, "depthMax": 1000.0, "weightMin": 200.0, "weightMax": 600.0, "baseValue": 320000.0, "difficulty": 10, "pattern": "Erratic", "pearlsMin": 40.0}], "items": [{"category": "Rod", "id": "DriftwoodRod", "name": "Driftwood Rod", "order": 1, "price": 0.0, "currency": "Coins", "reqLevel": 0, "capacity": null, "buyAmount": null, "stats": {}}, {"category": "Rod", "id": "BambooRod", "name": "Bamboo Rod", "order": 2, "price": 1500.0, "currency": "Coins", "reqLevel": 0, "capacity": null, "buyAmount": null, "stats": {"Luck": 0.05, "CastRange": 3.0, "CatchBarSize": 0.03, "ReelPower": 0.15}}, {"category": "Rod", "id": "CoralRod", "name": "Coral Rod", "order": 3, "price": 12000.0, "currency": "Coins", "reqLevel": 0, "capacity": null, "buyAmount": null, "stats": {"Luck": 0.15, "CastRange": 5.0, "CatchBarSize": 0.05, "ReelPower": 0.3, "Resilience": 0.15}}, {"category": "Rod", "id": "MoonsilverRod", "name": "Moonsilver Rod", "order": 4, "price": 120000.0, "currency": "Coins", "reqLevel": 10, "capacity": null, "buyAmount": null, "stats": {"Luck": 0.35, "CastRange": 8.0, "AutoSpeed": 0.1, "CatchBarSize": 0.08, "ReelPower": 0.5, "Resilience": 0.3, "FishStability": 0.1}}, {"category": "Rod", "id": "NagaScaleRod", "name": "Naga Scale Rod", "order": 5, "price": 900000.0, "currency": "Coins", "reqLevel": 25, "capacity": null, "buyAmount": null, "stats": {"Luck": 0.75, "CastRange": 11.0, "AutoSpeed": 0.2, "CatchBarSize": 0.12, "ReelPower": 0.8, "Resilience": 0.45, "FishStability": 0.2, "MutationChance": 0.02}}, {"category": "Rod", "id": "SweetheartRod", "name": "Sweetheart Rod", "order": 6, "price": 1500.0, "currency": "Coins", "reqLevel": 0, "capacity": null, "buyAmount": null, "stats": {"Luck": 0.03, "CastRange": 3.0, "CatchBarSize": 0.04, "ReelPower": 0.08}}, {"category": "Rod", "id": "AbyssRod", "name": "Abyss Rod", "order": 7, "price": 4500000.0, "currency": "Coins", "reqLevel": 35, "capacity": null, "buyAmount": null, "stats": {"Luck": 1.1, "CastRange": 14.0, "AutoSpeed": 0.25, "CatchBarSize": 0.14, "ReelPower": 1.1, "Resilience": 0.55, "FishStability": 0.25, "MutationChance": 0.03}}, {"category": "Rod", "id": "CelestialRod", "name": "Celestial Rod", "order": 8, "price": 20000000.0, "currency": "Coins", "reqLevel": 50, "capacity": null, "buyAmount": null, "stats": {"Luck": 1.6, "CastRange": 18.0, "AutoSpeed": 0.3, "CatchBarSize": 0.16, "ReelPower": 1.5, "Resilience": 0.65, "FishStability": 0.3, "MutationChance": 0.05}}, {"category": "Line", "id": "CottonLine", "name": "Cotton Line (30m)", "order": 1, "price": 0.0, "currency": "Coins", "reqLevel": 0, "capacity": null, "buyAmount": null, "stats": {"MaxDepth": 30.0}}, {"category": "Line", "id": "HempLine", "name": "Hemp Line (80m)", "order": 2, "price": 1000.0, "currency": "Coins", "reqLevel": 0, "capacity": null, "buyAmount": null, "stats": {"MaxDepth": 80.0}}, {"category": "Line", "id": "NylonLine", "name": "Nylon Line (150m)", "order": 3, "price": 15000.0, "currency": "Coins", "reqLevel": 0, "capacity": null, "buyAmount": null, "stats": {"Resilience": 0.05, "MaxDepth": 150.0}}, {"category": "Line", "id": "SilkLine", "name": "Spider-Silk Line (300m)", "order": 4, "price": 150000.0, "currency": "Coins", "reqLevel": 12, "capacity": null, "buyAmount": null, "stats": {"Resilience": 0.1, "MaxDepth": 300.0}}, {"category": "Line", "id": "AbyssLine", "name": "Abyss Line (600m)", "order": 5, "price": 1200000.0, "currency": "Coins", "reqLevel": 30, "capacity": null, "buyAmount": null, "stats": {"Resilience": 0.15, "MaxDepth": 600.0}}, {"category": "Line", "id": "StarLine", "name": "Star Line (1000m)", "order": 6, "price": 6000000.0, "currency": "Coins", "reqLevel": 45, "capacity": null, "buyAmount": null, "stats": {"Luck": 0.1, "Resilience": 0.2, "MaxDepth": 1000.0}}, {"category": "Bait", "id": "Worm", "name": "Worm", "order": 1, "price": 100.0, "currency": "Coins", "reqLevel": 0, "capacity": null, "buyAmount": 10, "stats": {"Luck": 0.1}}, {"category": "Bait", "id": "Shrimp", "name": "Shrimp", "order": 2, "price": 800.0, "currency": "Coins", "reqLevel": 0, "capacity": null, "buyAmount": 10, "stats": {"Luck": 0.3, "BiteSpeed": 0.1}}, {"category": "Bait", "id": "GlowGrub", "name": "Glow Grub", "order": 3, "price": 6000.0, "currency": "Coins", "reqLevel": 0, "capacity": null, "buyAmount": 10, "stats": {"Luck": 0.75, "AutoSpeed": 0.1, "MutationChance": 0.01}}, {"category": "Bait", "id": "SquidBait", "name": "Squid Bait", "order": 4, "price": 40000.0, "currency": "Coins", "reqLevel": 20, "capacity": null, "buyAmount": 10, "stats": {"Luck": 1.2, "BiteSpeed": 0.15}}, {"category": "Bait", "id": "PearlBait", "name": "Pearl Bait", "order": 5, "price": 250000.0, "currency": "Coins", "reqLevel": 30, "capacity": null, "buyAmount": 10, "stats": {"Luck": 1.8, "AutoSpeed": 0.15, "MutationChance": 0.02}}, {"category": "Bait", "id": "StormBait", "name": "Storm Bait", "order": 6, "price": 1200000.0, "currency": "Coins", "reqLevel": 40, "capacity": null, "buyAmount": 10, "stats": {"Luck": 2.6, "BiteSpeed": 0.3, "MutationChance": 0.03}}, {"category": "Bait", "id": "SummonBait", "name": "Summon Bait", "order": 7, "price": 60.0, "currency": "Gems", "reqLevel": 20, "capacity": null, "buyAmount": 3, "stats": {"Luck": 4.0, "FishStability": 0.1, "MutationChance": 0.05}}, {"category": "Bag", "id": "StarterPouch", "name": "Starter Pouch", "order": 1, "price": 0.0, "currency": "Coins", "reqLevel": 0, "capacity": 6, "buyAmount": null, "stats": {}}, {"category": "Bag", "id": "WovenBasket", "name": "Woven Basket", "order": 2, "price": 800.0, "currency": "Coins", "reqLevel": 0, "capacity": 10, "buyAmount": null, "stats": {}}, {"category": "Bag", "id": "Crate", "name": "Fish Crate", "order": 3, "price": 6000.0, "currency": "Coins", "reqLevel": 0, "capacity": 15, "buyAmount": null, "stats": {}}, {"category": "Bag", "id": "Coolbox", "name": "Ice Coolbox", "order": 4, "price": 40000.0, "currency": "Coins", "reqLevel": 0, "capacity": 20, "buyAmount": null, "stats": {}}, {"category": "Bag", "id": "Hold", "name": "Ship's Hold", "order": 5, "price": 250000.0, "currency": "Coins", "reqLevel": 0, "capacity": 30, "buyAmount": null, "stats": {}}, {"category": "Pass", "id": "VIP", "name": "VIP", "order": 1, "price": 149.0, "currency": "Robux", "reqLevel": 0, "capacity": null, "buyAmount": null, "stats": {"Luck": 0.15}}, {"category": "Pass", "id": "AutoFishPro", "name": "Auto-Fish Pro", "order": 2, "price": 249.0, "currency": "Robux", "reqLevel": 0, "capacity": null, "buyAmount": null, "stats": {"AutoSpeed": 0.25, "AutoMultiplier": 0.25}}, {"category": "Pass", "id": "InfiniteBag", "name": "Infinite Bag", "order": 3, "price": 349.0, "currency": "Robux", "reqLevel": 0, "capacity": null, "buyAmount": null, "stats": {}}, {"category": "Pass", "id": "ExtraCast", "name": "Extra Cast", "order": 4, "price": 199.0, "currency": "Robux", "reqLevel": 0, "capacity": null, "buyAmount": null, "stats": {}}, {"category": "Aura", "id": "SparklingDew", "name": "Sparkling Dew", "order": 1, "price": 0.0, "currency": "Gacha", "reqLevel": 0, "capacity": null, "buyAmount": null, "stats": {"Luck": 0.05}}, {"category": "Aura", "id": "TidalBloom", "name": "Tidal Bloom", "order": 2, "price": 0.0, "currency": "Gacha", "reqLevel": 0, "capacity": null, "buyAmount": null, "stats": {"Luck": 0.06, "BiteSpeed": 0.02}}, {"category": "Aura", "id": "KelpWhisper", "name": "Kelp Whisper", "order": 3, "price": 0.0, "currency": "Gacha", "reqLevel": 0, "capacity": null, "buyAmount": null, "stats": {"Luck": 0.1, "FishStability": 0.05}}, {"category": "Aura", "id": "CoralHeart", "name": "Coral Heart", "order": 4, "price": 0.0, "currency": "Gacha", "reqLevel": 0, "capacity": null, "buyAmount": null, "stats": {"Luck": 0.1}}, {"category": "Aura", "id": "NeonWave", "name": "Neon Wave", "order": 5, "price": 0.0, "currency": "Gacha", "reqLevel": 0, "capacity": null, "buyAmount": null, "stats": {"Luck": 0.15, "CatchBarSize": 0.022}}, {"category": "Aura", "id": "MoonlitRipple", "name": "Moonlit Ripple", "order": 6, "price": 0.0, "currency": "Gacha", "reqLevel": 0, "capacity": null, "buyAmount": null, "stats": {"Luck": 0.2, "AutoSpeed": 0.05}}, {"category": "Aura", "id": "StormCurrent", "name": "Storm Current", "order": 7, "price": 0.0, "currency": "Gacha", "reqLevel": 0, "capacity": null, "buyAmount": null, "stats": {"Luck": 0.25, "BiteSpeed": 0.08}}, {"category": "Aura", "id": "SolarFlare", "name": "Solar Flare", "order": 8, "price": 0.0, "currency": "Gacha", "reqLevel": 0, "capacity": null, "buyAmount": null, "stats": {"Luck": 0.35}}, {"category": "Aura", "id": "FrostPearl", "name": "Frost Pearl", "order": 9, "price": 0.0, "currency": "Gacha", "reqLevel": 0, "capacity": null, "buyAmount": null, "stats": {"Luck": 0.4, "Resilience": 0.1}}, {"category": "Aura", "id": "NebulaKoi", "name": "Nebula Koi", "order": 10, "price": 0.0, "currency": "Gacha", "reqLevel": 0, "capacity": null, "buyAmount": null, "stats": {"Luck": 0.45}}, {"category": "Aura", "id": "AbyssalShadow", "name": "Abyssal Shadow", "order": 11, "price": 0.0, "currency": "Gacha", "reqLevel": 0, "capacity": null, "buyAmount": null, "stats": {"Luck": 0.5, "AutoMultiplier": 0.2}}, {"category": "Aura", "id": "LotusNaga", "name": "Lotus Naga", "order": 12, "price": 0.0, "currency": "Gacha", "reqLevel": 0, "capacity": null, "buyAmount": null, "stats": {"Luck": 0.6, "AutoMultiplier": 0.1, "FishStability": 0.15}}, {"category": "Aura", "id": "SerpentOfTheVoid", "name": "Serpent of the Void", "order": 13, "price": 0.0, "currency": "Gacha", "reqLevel": 0, "capacity": null, "buyAmount": null, "stats": {"Luck": 0.75, "MutationChance": 0.03}}, {"category": "Aura", "id": "DragonEmperor", "name": "Dragon Emperor", "order": 14, "price": 0.0, "currency": "Gacha", "reqLevel": 0, "capacity": null, "buyAmount": null, "stats": {"Luck": 1.0, "FishStability": 0.3}}, {"category": "Aura", "id": "CelestialLeviathan", "name": "Celestial Leviathan", "order": 15, "price": 0.0, "currency": "Gacha", "reqLevel": 0, "capacity": null, "buyAmount": null, "stats": {"Luck": 1.4, "FishStability": 0.35, "MutationChance": 0.05}}], "rarities": [{"tier": 1, "name": "Common", "weight": 1000.0, "xp": 5.0, "manualGems": 0.0, "autoGems": 0.0, "pearlsMin": 0.2}, {"tier": 2, "name": "Uncommon", "weight": 400.0, "xp": 10.0, "manualGems": 0.0, "autoGems": 0.0, "pearlsMin": 0.5}, {"tier": 3, "name": "Rare", "weight": 120.0, "xp": 25.0, "manualGems": 1.0, "autoGems": 0.5, "pearlsMin": 1.5}, {"tier": 4, "name": "Epic", "weight": 30.0, "xp": 60.0, "manualGems": 3.0, "autoGems": 1.5, "pearlsMin": 4.0}, {"tier": 5, "name": "Legendary", "weight": 6.0, "xp": 150.0, "manualGems": 10.0, "autoGems": 5.0, "pearlsMin": 12.0}, {"tier": 6, "name": "Mythic", "weight": 1.0, "xp": 400.0, "manualGems": 30.0, "autoGems": 15.0, "pearlsMin": 40.0}]};
  
  // Clone seed into reactive state
  let state = JSON.parse(JSON.stringify(SEED_DATA));
  let baselineState = JSON.parse(JSON.stringify(SEED_DATA));
  
  let currentTab = 'overview';
  let fishFilterRarity = 'ALL';
  let fishFilterDepth = 'ALL';
  let fishSearchTerm = '';
  let itemCategory = 'Rods';
  let itemSearchTerm = '';
  let constGroupFilter = 'ALL';
  let constSearchTerm = '';
  let isModified = false;
  
  // DOM Elements
  const statusPill = document.getElementById('statusPill');
  const toast = document.getElementById('toast');

  function showToast(msg) {
    if (!toast) return;
    toast.textContent = msg;
    toast.classList.add('show');
    setTimeout(() => toast.classList.remove('show'), 2800);
  }

  function markModified() {
    isModified = true;
    if (statusPill) {
      statusPill.textContent = 'CHANGES UNSAVED';
      statusPill.classList.add('modified');
    }
    updateAll();
  }

  // Tab switching
  document.querySelectorAll('.nav-tab').forEach(tab => {
    tab.addEventListener('click', () => {
      document.querySelectorAll('.nav-tab').forEach(t => t.classList.remove('active'));
      document.querySelectorAll('.tab-content').forEach(c => c.classList.remove('active'));
      
      tab.classList.add('active');
      const target = tab.dataset.tab;
      currentTab = target;
      const content = document.getElementById('tab-' + target);
      if (content) content.classList.add('active');
      
      if (target === 'export') renderExport();
    });
  });

  // Theme toggle
  const themeToggle = document.getElementById('themeToggle');
  if (themeToggle) {
    themeToggle.addEventListener('click', () => {
      const current = document.documentElement.getAttribute('data-theme') || 'dark';
      const next = current === 'dark' ? 'light' : 'dark';
      document.documentElement.setAttribute('data-theme', next);
      themeToggle.textContent = next === 'dark' ? 'DARK' : 'LIGHT';
      renderChart();
    });
  }

  // Progression & Economy Simulation Math
  function computeProgression() {
    const rods = state.items.filter(i => i.category === 'Rods' || i.category === 'Rod').sort((a,b) => a.order - b.order);
    const commonFish = state.fish.filter(f => f.rarity === 'Common');
    const avgCommonValue = commonFish.length > 0 ? (commonFish.reduce((s,f) => s + f.baseValue, 0) / commonFish.length) : 50;

    // Estimate catch rate (sec/fish)
    const autoCycle = parseFloat(getConst('AutoCycleTime', 14));
    const manualMult = parseFloat(getConst('ManualMultiplier', 1.5));
    
    // Base player catch speed: ~10s per manual fish, 14s auto
    const coinsPerMinuteManual = (60 / 10) * avgCommonValue * manualMult;
    const coinsPerMinuteAuto = (60 / autoCycle) * avgCommonValue * 0.8;
    
    // Target rods
    const bamboo = rods.find(r => r.id === 'BambooRod') || { price: 1500 };
    const coral = rods.find(r => r.id === 'CoralRod') || { price: 12000 };
    const moonsilver = rods.find(r => r.id === 'MoonsilverRod') || { price: 120000 };
    const celestial = rods.find(r => r.id === 'CelestialRod') || { price: 20000000 };

    const timeToBambooMin = (bamboo.price / coinsPerMinuteManual).toFixed(1);
    const timeToCoralMin = (coral.price / (coinsPerMinuteManual * 1.5)).toFixed(1);
    const timeToMoonsilverHours = (moonsilver.price / (coinsPerMinuteManual * 4 * 60)).toFixed(1);
    const timeToCelestialHours = (celestial.price / (coinsPerMinuteManual * 25 * 60)).toFixed(1);

    // Top aquarium rate (top 6 fish pearls/min)
    const sortedFishPearls = [...state.fish].sort((a,b) => b.pearlsMin - a.pearlsMin);
    const top6PearlsMin = sortedFishPearls.slice(0, 6).reduce((s,f) => s + (f.pearlsMin || 0), 0);
    const pearlsPerSec = (top6PearlsMin / 60).toFixed(3);
    const pearlsPerHour = (top6PearlsMin * 60).toFixed(0);

    return {
      avgCommonValue: avgCommonValue.toFixed(0),
      timeToBambooMin,
      timeToCoralMin,
      timeToMoonsilverHours,
      timeToCelestialHours,
      pearlsPerSec,
      pearlsPerHour,
      rods
    };
  }

  function getConst(key, fallback) {
    const c = state.constants.find(item => item.key === key);
    return c ? c.value : fallback;
  }

  function setConst(key, val) {
    const c = state.constants.find(item => item.key === key);
    if (c) {
      c.value = val;
      markModified();
    }
  }

  // Render KPIs
  function renderKPIs() {
    const prog = computeProgression();
    const kpiWrap = document.getElementById('kpiGrid');
    if (!kpiWrap) return;

    kpiWrap.innerHTML = `
      <div class="kpi-box teal">
        <span class="kpi-label">Starter Pacing (Bamboo Rod)</span>
        <span class="kpi-value">${prog.timeToBambooMin} min</span>
        <span class="kpi-sub">Target early game goal (~3-6 min)</span>
      </div>
      <div class="kpi-box gold">
        <span class="kpi-label">Midgame Wall (Moonsilver Rod)</span>
        <span class="kpi-value">${prog.timeToMoonsilverHours} hrs</span>
        <span class="kpi-sub">Depth 200m barrier unlock</span>
      </div>
      <div class="kpi-box purple">
        <span class="kpi-label">Endgame Finish (Celestial Rod)</span>
        <span class="kpi-value">${prog.timeToCelestialHours} hrs</span>
        <span class="kpi-sub">Price: 20M Coins (Trench depth)</span>
      </div>
      <div class="kpi-box good">
        <span class="kpi-label">Aquarium Top Idle</span>
        <span class="kpi-value">+${prog.pearlsPerSec}/s</span>
        <span class="kpi-sub">≈ ${prog.pearlsPerHour} Pearls / hr</span>
      </div>
      <div class="kpi-box warn">
        <span class="kpi-label">Total Species / Gear</span>
        <span class="kpi-value">${state.fish.length} / ${state.items.length}</span>
        <span class="kpi-sub">Rods: ${state.items.filter(i=>i.category.startsWith('Rod')).length} | Lines: ${state.items.filter(i=>i.category==='Line').length}</span>
      </div>
    `;
  }

  // Render Progression SVG Chart
  function renderChart() {
    const chartBox = document.getElementById('progChartBox');
    if (!chartBox) return;

    const prog = computeProgression();
    const rods = prog.rods;
    if (rods.length === 0) return;

    const w = 900;
    const h = 240;
    const pad = { top: 25, right: 30, bottom: 40, left: 70 };
    const plotW = w - pad.left - pad.right;
    const plotH = h - pad.top - pad.bottom;

    const maxPrice = Math.max(...rods.map(r => r.price), 1000);
    const points = rods.map((r, idx) => {
      const x = pad.left + (idx / (rods.length - 1)) * plotW;
      const logVal = Math.log10(Math.max(r.price, 100));
      const logMax = Math.log10(maxPrice);
      const logMin = Math.log10(100);
      const yNorm = (logVal - logMin) / (logMax - logMin);
      const y = pad.top + plotH - yNorm * plotH;
      return { x, y, rod: r };
    });

    const linePath = points.map((p, i) => (i === 0 ? `M ${p.x} ${p.y}` : `L ${p.x} ${p.y}`)).join(' ');
    const areaPath = `${linePath} L ${points[points.length-1].x} ${pad.top + plotH} L ${points[0].x} ${pad.top + plotH} Z`;

    let pointsSvg = '';
    points.forEach(p => {
      pointsSvg += `
        <circle class="chart-point" cx="${p.x}" cy="${p.y}" r="5">
          <title>${p.rod.name}: ${Number(p.rod.price).toLocaleString()} Coins</title>
        </circle>
        <text x="${p.x}" y="${p.y - 10}" text-anchor="middle" fill="var(--text)" font-size="11" font-family="var(--font-mono)">${p.rod.name.replace(' Rod','')}</text>
        <text x="${p.x}" y="${pad.top + plotH + 20}" text-anchor="middle" fill="var(--text-muted)" font-size="11" font-family="var(--font-mono)">${p.rod.price >= 1000000 ? (p.rod.price/1000000)+'M' : (p.rod.price >= 1000 ? (p.rod.price/1000)+'K' : p.rod.price)}</text>
      `;
    });

    chartBox.innerHTML = `
      <svg class="prog-chart" viewBox="0 0 ${w} ${h}" preserveAspectRatio="none">
        <defs>
          <linearGradient id="tealGrad" x1="0%" y1="0%" x2="0%" y2="100%">
            <stop offset="0%" stop-color="var(--teal)" stop-opacity="0.4"/>
            <stop offset="100%" stop-color="var(--teal)" stop-opacity="0.0"/>
          </linearGradient>
        </defs>
        <!-- Horizontal Grid -->
        <line class="chart-grid" x1="${pad.left}" y1="${pad.top}" x2="${w - pad.right}" y2="${pad.top}"/>
        <line class="chart-grid" x1="${pad.left}" y1="${pad.top + plotH * 0.5}" x2="${w - pad.right}" y2="${pad.top + plotH * 0.5}"/>
        <line class="chart-grid" x1="${pad.left}" y1="${pad.top + plotH}" x2="${w - pad.right}" y2="${pad.top + plotH}"/>
        
        <path class="chart-area" d="${areaPath}"/>
        <path class="chart-line" d="${linePath}"/>
        ${pointsSvg}
      </svg>
    `;
  }

  // Render Fish Table
  function renderFishTable() {
    const tbody = document.getElementById('fishTableBody');
    if (!tbody) return;

    let filtered = state.fish.filter(f => {
      if (fishFilterRarity !== 'ALL' && f.rarity !== fishFilterRarity) return false;
      if (fishFilterDepth === 'SHALLOW' && (f.depthMin > 50 || f.depthMax < 0)) return false;
      if (fishFilterDepth === 'MID' && (f.depthMin > 200 || f.depthMax < 50)) return false;
      if (fishFilterDepth === 'DEEP' && (f.depthMax < 200)) return false;
      if (fishSearchTerm) {
        const term = fishSearchTerm.toLowerCase();
        return f.name.toLowerCase().includes(term) || f.pattern.toLowerCase().includes(term);
      }
      return true;
    });

    const countLabel = document.getElementById('fishCountLabel');
    if (countLabel) countLabel.textContent = `Showing ${filtered.length} of ${state.fish.length} species`;

    tbody.innerHTML = filtered.map(f => {
      const avgWeight = ((f.weightMin + f.weightMax) / 2).toFixed(2);
      const minVal = Math.round(f.baseValue * Math.pow(f.weightMin / avgWeight, 0.7));
      const maxVal = Math.round(f.baseValue * Math.pow(f.weightMax / avgWeight, 0.7));
      const pearlsMin = f.pearlsMin || 0.2;
      const pearlsHr = Math.round(pearlsMin * 60);

      return `
        <tr data-id="${f.id}">
          <td>
            <input type="text" class="text" value="${f.name}" data-field="name" style="font-weight:600">
          </td>
          <td>
            <select data-field="rarity">
              ${['Common','Uncommon','Rare','Epic','Legendary','Mythic'].map(r => 
                `<option value="${r}" ${f.rarity === r ? 'selected' : ''}>${r}</option>`
              ).join('')}
            </select>
          </td>
          <td class="num">
            <div style="display:flex; gap:4px; align-items:center;">
              <input type="number" class="num" value="${f.depthMin}" data-field="depthMin" style="width:55px">
              <span>-</span>
              <input type="number" class="num" value="${f.depthMax}" data-field="depthMax" style="width:55px">
              <span class="text-muted">m</span>
            </div>
          </td>
          <td class="num">
            <div style="display:flex; gap:4px; align-items:center;">
              <input type="number" class="num" step="0.1" value="${f.weightMin}" data-field="weightMin" style="width:55px">
              <span>-</span>
              <input type="number" class="num" step="0.1" value="${f.weightMax}" data-field="weightMax" style="width:55px">
              <span class="text-muted">kg</span>
            </div>
          </td>
          <td class="num">
            <input type="number" class="num" value="${f.baseValue}" data-field="baseValue" style="font-weight:700; color:var(--gold); width:85px">
          </td>
          <td class="num">
            <span class="text-muted">${minVal} - ${maxVal}</span>
          </td>
          <td class="num">
            <input type="number" class="num" min="1" max="10" value="${f.difficulty}" data-field="difficulty" style="width:50px">
          </td>
          <td>
            <select data-field="pattern">
              ${['Calm','Darting','Sinker','Erratic','Jumper'].map(p => 
                `<option value="${p}" ${f.pattern === p ? 'selected' : ''}>${p}</option>`
              ).join('')}
            </select>
          </td>
          <td class="num">
            <div style="display:flex; gap:4px; align-items:center; justify-content:flex-end;">
              <input type="number" step="0.1" class="num" value="${pearlsMin}" data-field="pearlsMin" style="width:60px">
              <span class="text-muted">/m (${pearlsHr}/h)</span>
            </div>
          </td>
          <td style="text-align:center;">
            <button class="btn btn-sm text-warn delete-fish-btn" data-id="${f.id}">Delete</button>
          </td>
        </tr>
      `;
    }).join('');

    // Attach listeners
    tbody.querySelectorAll('input, select').forEach(el => {
      el.addEventListener('change', (e) => {
        const tr = e.target.closest('tr');
        const id = tr.dataset.id;
        const field = e.target.dataset.field;
        const fishObj = state.fish.find(f => f.id === id);
        if (fishObj) {
          let val = e.target.value;
          if (['depthMin','depthMax','weightMin','weightMax','baseValue','difficulty','pearlsMin'].includes(field)) {
            val = parseFloat(val) || 0;
          }
          fishObj[field] = val;
          markModified();
        }
      });
    });

    tbody.querySelectorAll('.delete-fish-btn').forEach(btn => {
      btn.addEventListener('click', (e) => {
        const id = e.target.dataset.id;
        if (confirm(`Are you sure you want to delete fish ${id}?`)) {
          state.fish = state.fish.filter(f => f.id !== id);
          markModified();
          renderFishTable();
        }
      });
    });
  }

  // Render Equipment Table
  function renderEquipmentTable() {
    const tbody = document.getElementById('equipTableBody');
    if (!tbody) return;

    let filtered = state.items.filter(i => {
      const cat = i.category;
      if (itemCategory === 'Rods' && cat !== 'Rods' && cat !== 'Rod') return false;
      if (itemCategory === 'Lines' && cat !== 'Lines' && cat !== 'Line') return false;
      if (itemCategory === 'Baits' && cat !== 'Baits' && cat !== 'Bait') return false;
      if (itemCategory === 'Bags' && cat !== 'Bags' && cat !== 'Bag') return false;
      if (itemSearchTerm) {
        return i.name.toLowerCase().includes(itemSearchTerm.toLowerCase());
      }
      return true;
    }).sort((a,b) => a.order - b.order);

    tbody.innerHTML = filtered.map(item => {
      const statsStr = Object.entries(item.stats || {})
        .map(([k,v]) => `${k}: +${v}`)
        .join(', ');

      return `
        <tr data-id="${item.id}">
          <td class="num" style="width:40px">
            <input type="number" class="num" value="${item.order}" data-field="order" style="width:45px">
          </td>
          <td>
            <input type="text" class="text" value="${item.name}" data-field="name" style="font-weight:600">
          </td>
          <td class="num">
            <input type="number" class="num" value="${item.price}" data-field="price" style="font-weight:700; color:var(--gold); width:110px">
          </td>
          <td>
            <select data-field="currency" style="width:80px">
              <option value="Coins" ${item.currency==='Coins'?'selected':''}>Coins</option>
              <option value="Gems" ${item.currency==='Gems'?'selected':''}>Gems</option>
            </select>
          </td>
          <td class="num">
            <input type="number" class="num" value="${item.reqLevel || 0}" data-field="reqLevel" style="width:60px">
          </td>
          <td>
            <input type="text" class="text" value="${statsStr}" data-field="statsStr" placeholder="StatName: Value" style="min-width:280px">
          </td>
          <td style="text-align:center;">
            <button class="btn btn-sm text-warn delete-item-btn" data-id="${item.id}">Delete</button>
          </td>
        </tr>
      `;
    }).join('');

    tbody.querySelectorAll('input, select').forEach(el => {
      el.addEventListener('change', (e) => {
        const tr = e.target.closest('tr');
        const id = tr.dataset.id;
        const field = e.target.dataset.field;
        const itemObj = state.items.find(i => i.id === id);
        if (itemObj) {
          if (field === 'price' || field === 'order' || field === 'reqLevel') {
            itemObj[field] = parseFloat(e.target.value) || 0;
          } else if (field === 'statsStr') {
            const newStats = {};
            e.target.value.split(',').forEach(part => {
              const [k, v] = part.split(':');
              if (k && v) newStats[k.trim()] = parseFloat(v.replace('+','').trim()) || 0;
            });
            itemObj.stats = newStats;
          } else {
            itemObj[field] = e.target.value;
          }
          markModified();
        }
      });
    });

    tbody.querySelectorAll('.delete-item-btn').forEach(btn => {
      btn.addEventListener('click', (e) => {
        const id = e.target.dataset.id;
        if (confirm(`Delete item ${id}?`)) {
          state.items = state.items.filter(i => i.id !== id);
          markModified();
          renderEquipmentTable();
        }
      });
    });
  }

  // Render Constants Grid
  function renderConstants() {
    const wrap = document.getElementById('constantsGrid');
    if (!wrap) return;

    const groups = {};
    state.constants.forEach(c => {
      const g = c.group || 'Other';
      if (!groups[g]) groups[g] = [];
      groups[g].push(c);
    });

    wrap.innerHTML = Object.entries(groups).map(([groupName, items]) => {
      if (constGroupFilter !== 'ALL' && groupName !== constGroupFilter) return '';

      const filteredItems = items.filter(c => {
        if (!constSearchTerm) return true;
        return c.key.toLowerCase().includes(constSearchTerm.toLowerCase()) || 
               c.desc.toLowerCase().includes(constSearchTerm.toLowerCase());
      });

      if (filteredItems.length === 0) return '';

      return `
        <div class="const-group">
          <div class="const-group-title">${groupName}</div>
          ${filteredItems.map(c => `
            <div class="const-row" data-key="${c.key}">
              <div class="const-info">
                <span class="const-key">${c.key}</span>
                <span class="const-desc">${c.desc}</span>
              </div>
              <input type="text" class="const-input" value="${c.value}" data-key="${c.key}">
              <span class="const-unit">${c.unit || ''}</span>
            </div>
          `).join('')}
        </div>
      `;
    }).join('');

    wrap.querySelectorAll('.const-input').forEach(input => {
      input.addEventListener('change', (e) => {
        const key = e.target.dataset.key;
        setConst(key, e.target.value);
      });
    });
  }

  // Export Luau Code Generation
  function generateFishLuau() {
    let lines = [
      '--!strict',
      '-- Generated by Aura Fishing Game Balance & Project Manager',
      '-- Auto-validated by Registry at game startup',
      '',
      'export type FishDef = {',
      '\tName: string,',
      '\tRarity: string,',
      '\tDepthMin: number,',
      '\tDepthMax: number,',
      '\tBaseValue: number,',
      '\tWeight: { number },',
      '\tDifficulty: number,',
      '\tPattern: string,',
      '\tLocations: { string }?,',
      '\tRollWeight: number?,',
      '\tDescription: string?,',
      '}',
      '',
      'local Fish: { [string]: FishDef } = {'
    ];

    state.fish.forEach(f => {
      lines.push(`\t${f.id} = { Name = "${f.name}", Rarity = "${f.rarity}", DepthMin = ${f.depthMin}, DepthMax = ${f.depthMax}, BaseValue = ${f.baseValue}, Weight = { ${f.weightMin}, ${f.weightMax} }, Difficulty = ${f.difficulty}, Pattern = "${f.pattern}" },`);
    });

    lines.push('}');
    lines.push('');
    lines.push('return Fish');
    return lines.join('\n');
  }

  function generateEquipmentLuau() {
    const cats = ['Rods', 'Lines', 'Baits', 'Bags'];
    let lines = [
      '--!strict',
      '-- Generated by Aura Fishing Game Balance & Project Manager',
      '',
      'export type Item = {',
      '\tName: string,',
      '\tPrice: number,',
      '\tCurrency: string,',
      '\tOrder: number,',
      '\tStats: { [string]: number },',
      '\tDescription: string?,',
      '\tCapacity: number?,',
      '\tBuyAmount: number?,',
      '\tRequiredLevel: number?,',
      '\tExclusive: string?,',
      '}',
      '',
      'local Equipment = {'
    ];

    cats.forEach(cat => {
      const catItems = state.items.filter(i => i.category === cat || i.category === cat.slice(0,-1));
      lines.push(`\t${cat} = {`);
      lines.push(`\t\tDisplayName = "${cat}",`);
      lines.push(`\t\tKind = "${cat === 'Baits' ? 'Consumable' : 'Permanent'}",`);
      lines.push('\t\tItems = {');
      catItems.forEach(item => {
        const statsObjStr = Object.entries(item.stats || {}).map(([k,v]) => `${k} = ${v}`).join(', ');
        let extra = '';
        if (item.reqLevel) extra += `, RequiredLevel = ${item.reqLevel}`;
        if (item.capacity) extra += `, Capacity = ${item.capacity}`;
        if (item.buyAmount) extra += `, BuyAmount = ${item.buyAmount}`;
        lines.push(`\t\t\t${item.id} = { Name = "${item.name}", Price = ${item.price}, Currency = "${item.currency}", Order = ${item.order}, Stats = { ${statsObjStr} }${extra} },`);
      });
      lines.push('\t\t},');
      lines.push('\t},');
    });

    lines.push('}');
    lines.push('');
    lines.push('return Equipment');
    return lines.join('\n');
  }

  function generateDiffPatch() {
    const changes = [];
    state.fish.forEach(f => {
      const base = baselineState.fish.find(b => b.id === f.id);
      if (!base) changes.push(`[NEW FISH] ${f.name} (${f.rarity}, BaseValue: ${f.baseValue})`);
      else if (base.baseValue !== f.baseValue) changes.push(`[FISH VALUE] ${f.name}: ${base.baseValue} -> ${f.baseValue} Coins`);
      else if (base.depthMin !== f.depthMin || base.depthMax !== f.depthMax) changes.push(`[FISH DEPTH] ${f.name}: ${base.depthMin}-${base.depthMax}m -> ${f.depthMin}-${f.depthMax}m`);
    });
    state.items.forEach(i => {
      const base = baselineState.items.find(b => b.id === i.id);
      if (!base) changes.push(`[NEW ITEM] ${i.name} (${i.category}, Price: ${i.price})`);
      else if (base.price !== i.price) changes.push(`[ITEM PRICE] ${i.name}: ${base.price} -> ${i.price} ${i.currency}`);
    });
    state.constants.forEach(c => {
      const base = baselineState.constants.find(b => b.key === c.key);
      if (base && base.value !== c.value) changes.push(`[TUNING] ${c.key}: ${base.value} -> ${c.value} (${c.unit || ''})`);
    });
    return changes.length > 0 ? changes.join('\n') : 'No balance changes detected compared to baseline.';
  }

  function renderExport() {
    const exportSel = document.getElementById('exportSelect');
    const codeArea = document.getElementById('exportCodeArea');
    const diffArea = document.getElementById('diffArea');
    if (!codeArea) return;

    const sel = exportSel ? exportSel.value : 'fish';
    if (sel === 'fish') codeArea.textContent = generateFishLuau();
    else if (sel === 'equipment') codeArea.textContent = generateEquipmentLuau();
    else if (sel === 'json') codeArea.textContent = JSON.stringify(state, null, 2);

    if (diffArea) diffArea.textContent = generateDiffPatch();
  }

  // Update All Views
  function updateAll() {
    renderKPIs();
    renderChart();
    renderFishTable();
    renderEquipmentTable();
    renderConstants();
  }

  // Event Listeners for Filters & Controls
  const fishSearch = document.getElementById('fishSearch');
  if (fishSearch) {
    fishSearch.addEventListener('input', (e) => {
      fishSearchTerm = e.target.value;
      renderFishTable();
    });
  }

  document.querySelectorAll('.rarity-filter-btn').forEach(btn => {
    btn.addEventListener('click', (e) => {
      document.querySelectorAll('.rarity-filter-btn').forEach(b => b.classList.remove('active'));
      btn.classList.add('active');
      fishFilterRarity = btn.dataset.rarity;
      renderFishTable();
    });
  });

  document.querySelectorAll('.depth-filter-btn').forEach(btn => {
    btn.addEventListener('click', (e) => {
      document.querySelectorAll('.depth-filter-btn').forEach(b => b.classList.remove('active'));
      btn.classList.add('active');
      fishFilterDepth = btn.dataset.depth;
      renderFishTable();
    });
  });

  document.querySelectorAll('.item-cat-btn').forEach(btn => {
    btn.addEventListener('click', (e) => {
      document.querySelectorAll('.item-cat-btn').forEach(b => b.classList.remove('active'));
      btn.classList.add('active');
      itemCategory = btn.dataset.cat;
      renderEquipmentTable();
    });
  });

  const itemSearch = document.getElementById('itemSearch');
  if (itemSearch) {
    itemSearch.addEventListener('input', (e) => {
      itemSearchTerm = e.target.value;
      renderEquipmentTable();
    });
  }

  const addFishBtn = document.getElementById('addFishBtn');
  if (addFishBtn) {
    addFishBtn.addEventListener('click', () => {
      const name = prompt('Enter new Fish Name:');
      if (!name) return;
      const id = name.replace(/\s+/g, '');
      state.fish.unshift({
        id: id,
        name: name,
        rarity: 'Common',
        tier: 1,
        depthMin: 0,
        depthMax: 50,
        weightMin: 0.5,
        weightMax: 2.0,
        baseValue: 70,
        difficulty: 1,
        pattern: 'Calm',
        pearlsMin: 0.2
      });
      markModified();
      renderFishTable();
      showToast(`Added fish: ${name}`);
    });
  }

  const addItemBtn = document.getElementById('addItemBtn');
  if (addItemBtn) {
    addItemBtn.addEventListener('click', () => {
      const name = prompt(`Enter new ${itemCategory} Name:`);
      if (!name) return;
      const id = name.replace(/\s+/g, '');
      state.items.push({
        category: itemCategory,
        id: id,
        name: name,
        order: state.items.length + 1,
        price: 5000,
        currency: 'Coins',
        reqLevel: 1,
        stats: { Luck: 0.1 }
      });
      markModified();
      renderEquipmentTable();
      showToast(`Added ${itemCategory}: ${name}`);
    });
  }

  const fetchSheetBtn = document.getElementById('fetchSheetBtn');
  const sheetUrlInput = document.getElementById('sheetUrlInput');
  if (fetchSheetBtn && sheetUrlInput) {
    fetchSheetBtn.addEventListener('click', async () => {
      const url = sheetUrlInput.value.trim();
      if (!url) return;
      fetchSheetBtn.disabled = true;
      fetchSheetBtn.textContent = 'Fetching Sheet...';
      try {
        const idMatch = url.match(/\/d\/([a-zA-Z0-9-_]+)/);
        const gidMatch = url.match(/gid=([0-9]+)/);
        if (!idMatch) throw new Error('Invalid Google Sheet URL format');
        const sheetId = idMatch[1];
        const gid = gidMatch ? gidMatch[1] : '0';
        const exportUrl = `https://docs.google.com/spreadsheets/d/${sheetId}/export?format=csv&gid=${gid}`;

        const res = await fetch(exportUrl);
        if (!res.ok) throw new Error(`HTTP ${res.status}: Unable to fetch CSV directly (check sheet permissions)`);
        const csvText = await res.text();
        
        const lines = csvText.split('\n').map(l => l.trim()).filter(l => l.length > 0);
        let updatedCount = 0;
        lines.forEach(line => {
          const parts = line.split(',');
          if (parts.length >= 3) {
            const key = parts[1] ? parts[1].trim() : '';
            const val = parts[2] ? parts[2].trim() : '';
            const c = state.constants.find(item => item.key === key);
            if (c && val) {
              c.value = val;
              updatedCount++;
            }
          }
        });
        markModified();
        showToast(`Successfully synced ${updatedCount} constants from Google Sheet!`);
      } catch (err) {
        alert('Google Sheet Sync Note:\n' + err.message + '\n\nTip: If blocked by browser CORS, you can run the local sync tool `node tools/balance_sheet/build.mjs` or download CSV and import.');
      } finally {
        fetchSheetBtn.disabled = false;
        fetchSheetBtn.textContent = 'Sync from Sheet';
      }
    });
  }

  const exportSelect = document.getElementById('exportSelect');
  if (exportSelect) {
    exportSelect.addEventListener('change', renderExport);
  }

  const copyExportBtn = document.getElementById('copyExportBtn');
  if (copyExportBtn) {
    copyExportBtn.addEventListener('click', () => {
      const codeArea = document.getElementById('exportCodeArea');
      if (codeArea) {
        navigator.clipboard.writeText(codeArea.textContent);
        showToast('Copied Luau Code to Clipboard!');
      }
    });
  }

  const downloadExportBtn = document.getElementById('downloadExportBtn');
  if (downloadExportBtn) {
    downloadExportBtn.addEventListener('click', () => {
      const codeArea = document.getElementById('exportCodeArea');
      const sel = exportSelect ? exportSelect.value : 'config';
      const filename = sel === 'fish' ? 'Fish.luau' : (sel === 'equipment' ? 'Equipment.luau' : 'balance_patch.json');
      const blob = new Blob([codeArea.textContent], { type: 'text/plain;charset=utf-8' });
      const url = URL.createObjectURL(blob);
      const a = document.createElement('a');
      a.href = url;
      a.download = filename;
      a.click();
      URL.revokeObjectURL(url);
      showToast(`Downloaded ${filename}!`);
    });
  }

  const resetBtn = document.getElementById('resetBtn');
  if (resetBtn) {
    resetBtn.addEventListener('click', () => {
      if (confirm('Reset all changes back to base game configs?')) {
        state = JSON.parse(JSON.stringify(SEED_DATA));
        isModified = false;
        if (statusPill) {
          statusPill.textContent = 'IN SYNC (v1.0)';
          statusPill.classList.remove('modified');
        }
        updateAll();
        showToast('Reset back to base configs');
      }
    });
  }

  // Initial Load
  updateAll();
})();
