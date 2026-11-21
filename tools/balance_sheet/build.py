import json
import sys
from xl import *

D = json.load(open("dump.json", encoding="utf-8"))
G = D["GameConfig"]
book = Book()

STAT_ORDER = ["Luck", "CastRange", "BiteSpeed", "AutoSpeed", "AutoMultiplier", "CatchBarSize", "ReelPower", "Resilience", "FishStability",
              "MutationChance", "SellMultiplier", "XPMultiplier", "PearlRate", "OfflineCapHours", "MaxDepth", "ExtraLines"]
assert set(STAT_ORDER) == set(D["StatDefs"].keys())
RARITIES = sorted(D["Rarities"].values(), key=lambda r: r["Tier"])
RN = len(RARITIES)


def q(name):  # sheet name for use inside formulas
    return f"'{name}'" if " " in name else name


def title(sh, text, note=None):
    sh.put(1, 1, text, S_TITLE)
    if note:
        sh.put(2, 1, note, S_NOTE)


def header(sh, r, labels, c0=1):
    for i, t in enumerate(labels):
        sh.put(r, c0 + i, t, S_HEADER)


# ============================================================ Constants
CONST = {}  # key -> absolute address
cs = book.sheet("Constants")
title(cs, "Constants - every tuning number in one place", "Yellow cells are inputs: change a value and every sheet that references it recalculates. Values come from GameConfig / Config files (source column).")
header(cs, 4, ["Group", "Key", "Value", "Unit", "What it does", "Source (src/shared/...)"])
rows = []


def const(group, key, value, unit, what, src):
    rows.append((group, key, value, unit, what, src))


GC = G
const("Start", "StartingCoins", GC["StartingCoins"], "coins", "Coins a new player starts with", "Config/GameConfig")
const("Start", "StartingGems", GC["StartingGems"], "gems", "Gems a new player starts with", "Config/GameConfig")
const("Casting", "CastTapPower", GC["Cast"]["TapPower"], "0-1", "Cast power of a tap / Auto cast (distance = MinDistance + (CastRange-MinDistance) x power)", "Config/GameConfig.Cast")
const("Casting", "CastMinDistance", GC["Cast"]["MinDistance"], "studs", "Cast distance at power 0", "Config/GameConfig.Cast")
const("Casting", "PerfectBiteBonus", GC["Cast"]["PerfectBiteBonus"], "fraction", "Perfect cast: bite wait x (1 - this)", "Config/GameConfig.Cast")
const("Casting", "PerfectMin", GC["Cast"]["PerfectMin"], "0-1", "Gold zone start on the power bar", "Config/GameConfig.Cast")
const("Casting", "PerfectMax", GC["Cast"]["PerfectMax"], "0-1", "Gold zone end on the power bar", "Config/GameConfig.Cast")
const("Casting", "BiteWaitMin", GC["BiteWait"][0], "sec", "Shortest random bite wait (before BiteSpeed)", "Config/GameConfig")
const("Casting", "BiteWaitMax", GC["BiteWait"][1], "sec", "Longest random bite wait (before BiteSpeed)", "Config/GameConfig")
const("Casting", "BiteWindow", GC["BiteWindow"], "sec", "Seconds to click the '!' before the fish escapes", "Config/GameConfig")
const("Casting", "CastCooldown", GC["CastCooldown"], "sec", "Cooldown between casts", "Config/GameConfig")
const("Casting", "FlightTime", GC["Cast"]["FlightTime"], "sec", "Bobber flight time", "Config/GameConfig.Cast")
const("Manual vs Auto", "ManualMultiplier", GC["ManualMultiplier"], "x", "Coin value and XP multiplier of a manual catch", "Config/GameConfig")
const("Manual vs Auto", "PerfectCatchBonus", GC["PerfectCatchBonus"], "x added", "Added to the manual multiplier when the fish never left the catch bar", "Config/GameConfig")
const("Manual vs Auto", "AutoCycleTime", GC["AutoCycleTime"], "sec", "Seconds per Auto catch (before AutoSpeed / BiteSpeed)", "Config/GameConfig")
const("Manual vs Auto", "AutoGemMultiplier", GC["AutoGemMultiplier"], "share", "Auto catches give this share of rarity Gems (the fraction is the chance of +1)", "Config/GameConfig")
const("Manual vs Auto", "AutoTreasureMultiplier", GC["AutoTreasureMultiplier"], "share", "Auto catches roll chests at this share of the chance", "Config/GameConfig")
const("Hot Streak", "HotStreakPerCatch", GC["HotStreak"]["PerCatch"], "x per catch", "Each manual catch in a row adds this to the coin value", "Config/GameConfig.HotStreak")
const("Hot Streak", "HotStreakMax", GC["HotStreak"]["Max"], "x max", "Streak bonus cap (reached at x10)", "Config/GameConfig.HotStreak")
const("Reel minigame", "ReelStartProgress", GC["Minigame"]["StartProgress"], "0-1", "Catch progress at the start", "Config/GameConfig.Minigame")
const("Reel minigame", "ReelGainPerSecond", GC["Minigame"]["GainPerSecond"], "per sec", "Progress gain while on the fish (x ReelPower)", "Config/GameConfig.Minigame")
const("Reel minigame", "ReelLossPerSecond", GC["Minigame"]["LossPerSecond"], "per sec", "Progress loss while off the fish (x (1 - Resilience))", "Config/GameConfig.Minigame")
const("Reel minigame", "DifficultySpeedScale", GC["Minigame"]["DifficultySpeedScale"], "x per level", "Fish speed = pattern speed x (1 + (Difficulty-1) x this)", "Config/GameConfig.Minigame")
const("Reel minigame", "ReelMaxDuration", GC["Minigame"]["MaxDuration"], "sec", "Max reel time", "Config/GameConfig.Minigame")
const("Reel minigame", "ValidationSlack", GC["Minigame"]["ValidationSlack"], "fraction", "Server accepts a finish at this share of the theoretical minimum time", "Config/GameConfig.Minigame")
const("Inventory", "FishStackMax", GC["Inventory"]["FishStackMax"], "fish", "Same species + mutation stack up to this", "Config/GameConfig.Inventory")
const("Inventory", "TreasureStackMax", GC["Inventory"]["TreasureStackMax"], "chests", "Chest stack size", "Config/GameConfig.Inventory")
const("Inventory", "TreasureLuckScale", GC["Inventory"]["TreasureLuckScale"], "x per Luck", "Chest drop chance x (1 + Luck x this)", "Config/GameConfig.Inventory")
const("Inventory", "InfiniteBagSlots", GC["Inventory"]["InfiniteBagSlots"], "slots", "Capacity with the Infinite Bag pass", "Config/GameConfig.Inventory")
const("Boosts", "BoostCoinsMult", GC["Boosts"]["Coins"]["Multiplier"], "x", "2x Coins boost (fish sale price)", "Config/GameConfig.Boosts")
const("Boosts", "BoostPearlsMult", GC["Boosts"]["Pearls"]["Multiplier"], "x", "2x Pearls boost (Aquarium)", "Config/GameConfig.Boosts")
const("Rolling", "LuckTierExponent", GC["LuckTierExponent"], "exponent", "Fish weight x (1 + Luck) ^ ((Tier - 1) x this)", "Config/GameConfig")
const("Progression", "XPBase", GC["XPBase"], "xp", "XP to next level = floor(XPBase x Level ^ XPExponent)", "Config/GameConfig")
const("Progression", "XPExponent", GC["XPExponent"], "exponent", "XP curve steepness", "Config/GameConfig")
const("Progression", "GemsPerLevel", GC["GemsPerLevel"], "gems", "Gems for each level-up", "Config/GameConfig")
const("Progression", "NewSpeciesGems", GC["NewSpeciesGems"], "gems", "Gems for the first catch of a species", "Config/GameConfig")
const("Progression", "SkillPointsPerLevel", D["Skills"]["PointsPerLevel"], "points", "Skill points per level-up", "Config/Skills")
const("Mastery", "MasteryPriceGrowth", D["Mastery"]["PriceGrowth"], "x per level", "Mastery price = floor(BasePrice x PriceGrowth ^ level) Pearls", "Config/Mastery")
const("Enhance", "EnhanceMaxLevel", GC["Enhance"]["MaxLevel"], "level", "Max Enhance level", "Config/GameConfig.Enhance")
const("Enhance", "EnhanceStatPerLevel", GC["Enhance"]["StatPerLevel"], "x per level", "Stats x (1 + this x level); MaxDepth is excluded", "Config/GameConfig.Enhance")
const("Enhance", "EnhanceCostFraction", GC["Enhance"]["CostFraction"], "of price", "Coins for level L->L+1 = floor(price x this x growth ^ L)", "Config/GameConfig.Enhance")
const("Enhance", "EnhanceCostGrowth", GC["Enhance"]["CostGrowth"], "x per level", "Enhance cost growth", "Config/GameConfig.Enhance")
const("Aquarium", "AquariumStartSlots", GC["Aquarium"]["StartSlots"], "slots", "Tank slots at start", "Config/GameConfig.Aquarium")
const("Aquarium", "AquariumMinOfflineSeconds", GC["Aquarium"]["MinOfflineSeconds"], "sec", "Shorter absences give nothing", "Config/GameConfig.Aquarium")
const("Auras", "AuraRollCost", GC["AuraRollCost"], "gems", "Default cost of one aura roll", "Config/GameConfig")
const("Auras", "AuraStarsMax", D["AuraStars"]["MaxStars"], "stars", "Max aura stars", "Config/AuraStars")
const("Auras", "AuraStatPerStar", D["AuraStars"]["StatPerStar"], "x per star", "Aura stats x (1 + this x stars)", "Config/AuraStars")
const("Rebirth", "RebirthRequiredLevel", D["Features"]["Rebirth"]["RequiredLevel"], "level", "Level needed for the first rebirth", "Config/Features.Rebirth")
const("Rebirth", "RebirthLevelStep", D["Features"]["Rebirth"]["LevelStep"], "levels", "Added to the required level per rebirth", "Config/Features.Rebirth")
const("Rebirth", "RebirthMaxLevel", D["Features"]["Rebirth"]["MaxRequiredLevel"], "level", "Required level cap", "Config/Features.Rebirth")
const("Rebirth", "RebirthBonus", D["Features"]["Rebirth"]["MultiplierPerRebirth"], "x per rebirth", "Added to SellMultiplier and PearlRate per rebirth", "Config/Features.Rebirth")
const("Skills", "MultiCastChance", D["Skills"]["MultiCast"]["ExtraLineChance"], "chance", "Each extra line: chance of a bonus fish per catch", "Config/Skills")
const("Hot fish", "HotFishIntervalMin", GC["HotFish"]["IntervalMinutes"], "min", "Merchant hot list rotates this often", "Config/GameConfig.HotFish")
const("Hot fish", "HotFishCountMin", GC["HotFish"]["Count"][0], "species", "Fewest hot species", "Config/GameConfig.HotFish")
const("Hot fish", "HotFishCountMax", GC["HotFish"]["Count"][1], "species", "Most hot species", "Config/GameConfig.HotFish")
const("Hot fish", "HotFishMults", " / ".join(str(x) for x in GC["HotFish"]["Mults"]), "x", "Possible sell multipliers (random)", "Config/GameConfig.HotFish")
const("Hotspot", "HotspotLuckBonus", GC["Hotspot"]["LuckBonus"], "Luck", "Luck added when a manual cast lands in a hotspot", "Config/GameConfig.Hotspot")
const("Hotspot", "HotspotUses", GC["Hotspot"]["Uses"], "casts", "Casts a hotspot allows", "Config/GameConfig.Hotspot")
const("Hotspot", "HotspotMax", GC["Hotspot"]["Max"], "spots", "Hotspots per server", "Config/GameConfig.Hotspot")
const("Quests", "QuestsPerDay", D["Features"]["Quests"]["PerDay"], "quests", "Daily quests", "Config/Features.Quests")
const("Quests", "QuestRewardGems", D["Features"]["Quests"]["RewardGems"], "gems", "Gems per finished quest", "Config/Features.Quests")

for i, (grp, key, val, unit, what, src) in enumerate(rows):
    r = 5 + i
    cs.row(r, 1, [grp, key])
    is_text = isinstance(val, str)
    cs.put(r, 3, val, S_DEFAULT if is_text else S_INPUT)
    cs.row(r, 4, [unit, what, src])
    CONST[key] = f"Constants!$C${r}"
for c, w in zip(range(1, 7), [16, 26, 14, 14, 78, 30]):
    cs.width(c, w)
cs.freeze = (5, 1)


def K(name):
    return CONST[name]


# ============================================================ Rarities
rs = book.sheet("Rarities")
title(rs, "Rarities - weights, XP, Gems, Aquarium rate", "Tier 1-6. Roll weight is the base chance weight when picking a fish; Luck shifts weight toward higher tiers (see Fish Odds).")
header(rs, 4, ["Tier", "Rarity", "Roll weight", "XP per catch", "Gems per catch (manual)", "Gems per catch (auto, expected)", "Aquarium Pearls/min (base)",
               "Aura star cost mult", "Tokens per duplicate aura", "Hot-fish eligible", "Share of base weight"])
GEMS_TIER = {int(k): v for k, v in GC["GemsByRarityTier"].items()}
for i, rr in enumerate(RARITIES):
    r = 5 + i
    n = rr["Name"]
    rs.row(r, 1, [rr["Tier"], n], [S_DEFAULT, S_DEFAULT])
    rs.put(r, 3, rr["Weight"], S_INPUT)
    rs.put(r, 4, rr["XP"], S_INPUT)
    rs.put(r, 5, GEMS_TIER.get(rr["Tier"], 0), S_INPUT)
    rs.put(r, 6, f"=E{r}*{K('AutoGemMultiplier')}", S_DEC2)
    rs.put(r, 7, GC["Aquarium"]["RatePerMinute"][n], S_INPUT)
    rs.put(r, 8, D["AuraStars"]["RarityCostMult"][n], S_INPUT)
    rs.put(r, 9, D["AuraStars"]["TokensPerDuplicate"][n], S_INPUT)
    rs.put(r, 10, "Yes" if n in GC["HotFish"]["Rarities"] else "No")
    rs.put(r, 11, f"=C{r}/SUM($C$5:$C${4+RN})", S_PCT)
RA = f"Rarities!$A$5:$A${4+RN}"
RB = f"Rarities!$B$5:$B${4+RN}"
RC = f"Rarities!$C$5:$C${4+RN}"
RD = f"Rarities!$D$5:$D${4+RN}"
RE = f"Rarities!$E$5:$E${4+RN}"
RG = f"Rarities!$G$5:$G${4+RN}"
for c, w in zip(range(1, 12), [6, 12, 12, 12, 16, 18, 18, 14, 16, 12, 14]):
    rs.width(c, w)
rs.freeze = (5, 1)

# ============================================================ Fish
fs = book.sheet("Fish")
title(fs, "Fish - 30 species", "Sell value = BaseValue x size factor x mutation x catch multiplier x Sell Multiplier. Size factor = clamp((weight / avg weight)^0.7, 0.4, 3). Edit yellow cells to rebalance.")
header(fs, 4, ["Id", "Name", "Rarity", "Tier", "Depth min (m)", "Depth max (m)", "Weight min (kg)", "Weight max (kg)", "Avg weight (kg)", "Base value (coins)",
               "Roll weight override", "Effective roll weight", "Difficulty", "Pattern", "Aquarium Pearls/min", "Value at min weight", "Value at max weight",
               "Gems / catch (manual)", "XP / catch", "Pearls / hour", "Manual value at avg weight (x1.5)"])
fish_ids = sorted(D["Fish"], key=lambda k: (next(r["Tier"] for r in RARITIES if r["Name"] == D["Fish"][k]["Rarity"]), D["Fish"][k]["BaseValue"]))
NF = len(fish_ids)
F0, F1 = 5, 4 + NF
for i, fid in enumerate(fish_ids):
    f = D["Fish"][fid]
    r = 5 + i
    fs.put(r, 1, fid)
    fs.put(r, 2, f["Name"])
    fs.put(r, 3, f["Rarity"], S_INPUT)
    fs.put(r, 4, f"=INDEX({RA},MATCH(C{r},{RB},0))")
    fs.put(r, 5, f["DepthMin"], S_INPUT)
    fs.put(r, 6, f["DepthMax"], S_INPUT)
    fs.put(r, 7, f["Weight"][0], S_INPUT)
    fs.put(r, 8, f["Weight"][1], S_INPUT)
    fs.put(r, 9, f"=(G{r}+H{r})/2", S_DEC2)
    fs.put(r, 10, f["BaseValue"], S_INPUT_INT)
    if "RollWeight" in f:
        fs.put(r, 11, f["RollWeight"], S_INPUT)
    else:
        fs.put(r, 11, None, S_INPUT)
    fs.put(r, 12, f'=IF(K{r}="",INDEX({RC},D{r}),K{r})', S_DEC2)
    fs.put(r, 13, f["Difficulty"], S_INPUT)
    fs.put(r, 14, f["Pattern"], S_INPUT)
    fs.put(r, 15, f"=INDEX({RG},D{r})", S_DEC2)
    fs.put(r, 16, f"=MAX(1,INT(J{r}*MIN(3,MAX(0.4,(G{r}/I{r})^0.7))+0.5))", S_INT)
    fs.put(r, 17, f"=MAX(1,INT(J{r}*MIN(3,MAX(0.4,(H{r}/I{r})^0.7))+0.5))", S_INT)
    fs.put(r, 18, f"=INDEX({RE},D{r})", S_INT)
    fs.put(r, 19, f"=INDEX(Rarities!$D$5:$D${4+RN},D{r})", S_INT)
    fs.put(r, 20, f"=O{r}*60", S_DEC2)
    fs.put(r, 21, f"=J{r}*{K('ManualMultiplier')}", S_INT)
for c, w in zip(range(1, 22), [20, 22, 11, 6, 9, 9, 9, 9, 9, 12, 11, 11, 9, 10, 11, 11, 11, 10, 8, 9, 14]):
    fs.width(c, w)
fs.freeze = (5, 3)
FISH = lambda col: f"Fish!${col}${F0}:${col}${F1}"

# ============================================================ Fish Odds
fo = book.sheet("Fish Odds")
title(fo, "Fish Odds - what bites at a depth with a given Luck", "Weight = base weight x (1 + Luck)^((Tier-1) x LuckTierExponent). Only fish whose depth range contains the depth can bite. Change the yellow inputs.")
fo.put(3, 1, "Depth (m)", S_BOLD)
fo.put(3, 2, 80, S_INPUT_INT)
fo.put(4, 1, "Luck (1 = +100%)", S_BOLD)
fo.put(4, 2, 0.5, S_INPUT)
fo.put(5, 1, "Expected base value per catch", S_BOLD)
header(fo, 7, ["Id", "Name", "Rarity", "Tier", "Can bite (1/0)", "Base weight", "Luck factor", "Weight", "Probability", "1 in N", "Base value"])
O0, O1 = 8, 7 + NF
for i in range(NF):
    r, fr = 8 + i, 5 + i
    fo.put(r, 1, f"=Fish!A{fr}")
    fo.put(r, 2, f"=Fish!B{fr}")
    fo.put(r, 3, f"=Fish!C{fr}")
    fo.put(r, 4, f"=Fish!D{fr}")
    fo.put(r, 5, f"=IF(AND($B$3>=Fish!E{fr},$B$3<=Fish!F{fr}),1,0)", S_INT)
    fo.put(r, 6, f"=Fish!L{fr}", S_DEC2)
    fo.put(r, 7, f"=(1+$B$4)^((D{r}-1)*{K('LuckTierExponent')})", S_DEC3)
    fo.put(r, 8, f"=E{r}*F{r}*G{r}", S_DEC2)
    fo.put(r, 9, f"=IF(SUM($H${O0}:$H${O1})=0,0,H{r}/SUM($H${O0}:$H${O1}))", S_PCT)
    fo.put(r, 10, f'=IF(I{r}=0,"",1/I{r})', S_DEC2)
    fo.put(r, 11, f"=Fish!J{fr}", S_INT)
fo.put(5, 2, f"=SUMPRODUCT($I${O0}:$I${O1},$K${O0}:$K${O1})", S_OUT_INT)
fo.put(6, 1, "Expected Gems per catch (manual)", S_BOLD)
fo.put(6, 2, f"=SUMPRODUCT($I${O0}:$I${O1},{FISH('R')})", S_OUT)
header(fo, 7, ["Rarity", "Chance per catch"], 13)
for i, rr in enumerate(RARITIES):
    r = 8 + i
    fo.put(r, 13, rr["Name"])
    fo.put(r, 14, f"=SUMIF($C${O0}:$C${O1},M{r},$I${O0}:$I${O1})", S_PCT)
fo.put(15, 13, "Luck sweep: chance of each rarity at this depth", S_SECTION)
fo.put(16, 13, "Luck", S_HEADER)
for i, rr in enumerate(RARITIES):
    fo.put(16, 14 + i, rr["Name"], S_HEADER)
for j, lk in enumerate([0, 0.25, 0.5, 1, 1.5, 2, 3, 5]):
    r = 17 + j
    fo.put(r, 13, lk, S_INPUT)
    for i, rr in enumerate(RARITIES):
        colL = col_letter(14 + i)
        den = f"SUMPRODUCT($E${O0}:$E${O1}*$F${O0}:$F${O1}*(1+$M{r})^(($D${O0}:$D${O1}-1)*{K('LuckTierExponent')}))"
        num_ = f"SUMPRODUCT($E${O0}:$E${O1}*($C${O0}:$C${O1}={colL}$16)*$F${O0}:$F${O1}*(1+$M{r})^(($D${O0}:$D${O1}-1)*{K('LuckTierExponent')}))"
        fo.put(r, 14 + i, f"=IF({den}=0,0,{num_}/{den})", S_PCT)
for c, w in zip(range(1, 21), [30, 22, 11, 6, 10, 10, 10, 10, 11, 10, 11, 3, 12, 12, 11, 11, 11, 11, 11, 11]):
    fo.width(c, w)
fo.freeze = (8, 1)

# ============================================================ Mutations
ms = book.sheet("Mutations")
title(ms, "Mutations - priority roll", "Mutations are rolled highest priority first; the first success wins. Chance = BaseChance + aura bonus; if above 0, the global MutationChance stat is added. Edit yellow inputs.")
header(ms, 4, ["Id", "Name", "Priority", "Base chance", "Value multiplier", "Aura bonus (input)", "Effective chance", "Chance nothing rolled before", "Chance this mutation is picked"])
mut_ids = sorted(D["Mutations"], key=lambda k: -D["Mutations"][k]["Priority"])
NM = len(mut_ids)
ms.put(12, 1, "MutationChance stat (input)", S_BOLD)
ms.put(12, 2, 0.0, S_INPUT_PCT)
for i, mid in enumerate(mut_ids):
    m = D["Mutations"][mid]
    r = 5 + i
    ms.put(r, 1, mid)
    ms.put(r, 2, m["Name"])
    ms.put(r, 3, m["Priority"], S_INPUT)
    ms.put(r, 4, m["BaseChance"], S_INPUT_PCT)
    ms.put(r, 5, m["ValueMultiplier"], S_INPUT)
    ms.put(r, 6, 0.0, S_INPUT_PCT)
    ms.put(r, 7, f"=MIN(1,IF(D{r}+F{r}>0,D{r}+F{r}+$B$12,0))", S_PCT)
    ms.put(r, 8, 1 if i == 0 else f"=H{r-1}*(1-G{r-1})", S_PCT)
    ms.put(r, 9, f"=G{r}*H{r}", S_PCT)
last = 4 + NM
ms.put(last + 1, 2, "No mutation")
ms.put(last + 1, 5, 1, S_DEFAULT)
ms.put(last + 1, 9, f"=H{last}*(1-G{last})", S_PCT)
ms.put(last + 2, 2, "Expected value multiplier", S_BOLD)
ms.put(last + 2, 5, f"=SUMPRODUCT(E5:E{last+1},I5:I{last+1})", S_OUT)
for c, w in zip(range(1, 10), [16, 16, 9, 12, 14, 16, 14, 22, 22]):
    ms.width(c, w)
MUT_ID = f"Mutations!$A$5:$A${last}"
MUT_VAL = f"Mutations!$E$5:$E${last}"

# ============================================================ Sell Value
sv = book.sheet("Sell Value")
title(sv, "Sell Value - one fish, step by step", "Mirrors Roll.Value + Inventory.SellValue. The game stores each catch's value at catch time, then multiplies by the Sell Multiplier x Coin boost x Hot-fish multiplier when sold.")
labels = [("Fish Id", "AbyssLeviathan"), ("Weight (kg)", 400), ("Mutation (None or Id)", "None"), ("Catch mode (Manual / Auto)", "Manual"),
          ("Perfect catch (1 = yes)", 1), ("Hot Streak count", 5), ("AutoMultiplier stat", 1), ("SellMultiplier stat", 1),
          ("2x Coins boost on (1 = yes)", 0), ("Hot-fish multiplier at merchant (1 = none)", 1)]
sv.put(3, 1, "Inputs", S_SECTION)
for i, (lab, v) in enumerate(labels):
    r = 4 + i
    sv.put(r, 1, lab, S_BOLD)
    sv.put(r, 2, v, S_INPUT if not isinstance(v, str) else S_INPUT)
sv.validations.append(("B4", f"Fish!$A${F0}:$A${F1}"))
sv.validations.append(("B6", '"None,Glowing,SunForged,Golden,VoidTouched"'))
sv.validations.append(("B7", '"Manual,Auto"'))
sv.put(15, 1, "Steps", S_SECTION)
steps = [
    ("Base value", f"=INDEX({FISH('J')},MATCH(B4,{FISH('A')},0))", S_INT),
    ("Average weight (kg)", f"=INDEX({FISH('I')},MATCH(B4,{FISH('A')},0))", S_DEC2),
    ("Size factor = clamp((weight/avg)^0.7, 0.4, 3)", "=MIN(3,MAX(0.4,(B5/B17)^0.7))", S_DEC3),
    ("Mutation multiplier", f'=IF(B6="None",1,INDEX({MUT_VAL},MATCH(B6,{MUT_ID},0)))', S_DEC2),
    ("Catch multiplier (manual 1.5 + perfect 0.25, or Auto stat)", f'=IF(B7="Manual",{K("ManualMultiplier")}+B8*{K("PerfectCatchBonus")},B10)', S_DEC2),
    ("Hot Streak bonus (manual only)", f'=IF(B7="Manual",MIN({K("HotStreakMax")},B9*{K("HotStreakPerCatch")}),0)', S_DEC2),
    ("Value stored in the bag at catch time", "=MAX(1,INT(B16*B18*B19*B20*(1+B21)+0.5))", S_OUT_INT),
    ("Sale multiplier = Sell Multiplier x Coin boost", f"=B11*IF(B12=1,{K('BoostCoinsMult')},1)", S_DEC2),
    ("Coins when sold = stored x sale multiplier x hot-fish", "=INT(B22*B23*B13+0.5)", S_OUT_INT),
]
for i, (lab, fm, st) in enumerate(steps):
    r = 16 + i
    sv.put(r, 1, lab, S_DEFAULT)
    sv.put(r, 2, fm, st)
sv.put(26, 1, "Note: the shop sums stored values per stack then multiplies, so per-fish rounding can differ by a few coins in big stacks.", S_NOTE)
sv.width(1, 58)
sv.width(2, 20)

# ============================================================ Progression
pg = book.sheet("Progression")
title(pg, "Progression - XP, levels, Gems, skill points", "XP to next level = floor(XPBase x Level^XPExponent). Each level-up gives Gems and skill points. Set the average XP per catch to see catches per level.")
pg.put(3, 1, "Average XP per catch (input)", S_BOLD)
pg.put(3, 2, 25, S_INPUT)
header(pg, 5, ["Level", "XP to next level", "Total XP to reach this level", "Gems earned by level-ups (total)", "Skill points earned (total)", "Catches to next level", "Total catches to reach this level"])
for L in range(1, 101):
    r = 5 + L
    pg.put(r, 1, L)
    pg.put(r, 2, f"=INT({K('XPBase')}*A{r}^{K('XPExponent')})", S_INT)
    pg.put(r, 3, 0 if L == 1 else f"=C{r-1}+B{r-1}", S_INT)
    pg.put(r, 4, f"=(A{r}-1)*{K('GemsPerLevel')}", S_INT)
    pg.put(r, 5, f"=(A{r}-1)*{K('SkillPointsPerLevel')}", S_INT)
    pg.put(r, 6, f"=B{r}/$B$3", S_DEC2)
    pg.put(r, 7, f"=C{r}/$B$3", S_DEC2)
for c, w in zip(range(1, 8), [8, 16, 20, 24, 20, 18, 22]):
    pg.width(c, w)
pg.freeze = (6, 1)
PG_LEVEL = "Progression!$A$6:$A$105"
PG_CUM = "Progression!$C$6:$C$105"

# ============================================================ Items (equipment, passes, auras)
it = book.sheet("Items")
title(it, "Items - rods, lines, baits, bags, passes, auras", "Every stat source in one table. Rods/Lines are scaled by Enhance level, auras by stars. Stat columns are additive (see Stats Calculator).")
header(it, 4, ["Category", "Id", "Name", "Order", "Price", "Currency", "Required level", "Capacity (bags)", "Buy amount (baits)"] + STAT_ORDER + ["Rarity (aura)", "Aura chance: 1 in N"])
STAT_COL = {s: 10 + i for i, s in enumerate(STAT_ORDER)}
NS = len(STAT_ORDER)
items = []
for cat_id, cat in (("Rod", "Rods"), ("Line", "Lines"), ("Bait", "Baits"), ("Bag", "Bags")):
    for iid, v in sorted(D["Equipment"][cat]["Items"].items(), key=lambda kv: kv[1]["Order"]):
        items.append((cat_id, iid, v["Name"], v["Order"], v.get("Price", 0), v.get("Currency", "Coins"), v.get("RequiredLevel", 0), v.get("Capacity"), v.get("BuyAmount"), v.get("Stats", {}), None, None))
for pid, v in sorted(D["Products"]["Passes"].items(), key=lambda kv: kv[1]["Order"]):
    items.append(("Pass", pid, v["Name"], v["Order"], v["Price"], "Robux", 0, None, None, v.get("Stats", {}), None, None))
for aid, v in sorted(D["Auras"].items(), key=lambda kv: kv[1]["Order"]):
    items.append(("Aura", aid, v["Name"], v["Order"], 0, "Gacha", 0, None, None, v.get("Stats", {}), v["Rarity"], v["Chance"]))
I0, I1 = 5, 4 + len(items)
for i, (cat, iid, name, order, price, cur, lvl, cap, buy, stats, rar, chance) in enumerate(items):
    r = 5 + i
    it.row(r, 1, [cat, iid, name, order])
    it.put(r, 5, price, S_INPUT_INT)
    it.put(r, 6, cur)
    it.put(r, 7, lvl, S_INPUT)
    it.put(r, 8, cap, S_INPUT if cap is not None else S_DEFAULT)
    it.put(r, 9, buy, S_INPUT if buy is not None else S_DEFAULT)
    for s in STAT_ORDER:
        v = stats.get(s)
        it.put(r, STAT_COL[s], v if v is not None else None, S_INPUT if v is not None else S_DEFAULT)
    it.put(r, 10 + NS, rar)
    it.put(r, 11 + NS, chance, S_INPUT if chance else S_DEFAULT)
for c in range(1, 12 + NS):
    it.width(c, 14)
it.width(3, 24)
it.width(2, 20)
it.freeze = (5, 4)
IT_ID = f"Items!$B${I0}:$B${I1}"
IT_NAME = f"Items!$C${I0}:$C${I1}"
IT_PRICE = f"Items!$E${I0}:$E${I1}"
IT_CAT = f"Items!$A${I0}:$A${I1}"


def item_stat(stat, id_cell):
    col = col_letter(STAT_COL[stat])
    return f"IFERROR(INDEX(Items!${col}${I0}:${col}${I1},MATCH({id_cell},{IT_ID},0)),0)"


# ============================================================ Enhance
en = book.sheet("Enhance")
title(en, "Enhance - rod upgrade costs", "Coins for level L -> L+1 = max(1, floor(price x CostFraction x CostGrowth^L)). Stats x (1 + StatPerLevel x level); MaxDepth never scales. Only items with a scaling stat can be enhanced (rods).")
rods = [r for r in items if r[0] == "Rod" and any(k != "MaxDepth" for k in r[9])]
header(en, 4, ["Rod", "Price"] + [f"{L}->{L+1}" for L in range(10)] + ["Total to +10"])
for i, (cat, iid, name, order, price, cur, lvl, cap, buy, stats, rar, ch) in enumerate(rods):
    r = 5 + i
    en.put(r, 1, name)
    en.put(r, 2, f"=INDEX({IT_PRICE},MATCH(\"{iid}\",{IT_ID},0))", S_INT)
    for L in range(10):
        en.put(r, 3 + L, f"=MAX(1,INT($B{r}*{K('EnhanceCostFraction')}*{K('EnhanceCostGrowth')}^{L}))", S_INT)
    en.put(r, 13, f"=SUM(C{r}:L{r})", S_OUT_INT)
base = 6 + len(rods) + 1
en.put(base, 1, "Selected rod (Id)", S_BOLD)
en.put(base, 2, rods[-1][1], S_INPUT)
en.validations.append((f"B{base}", f"Items!$B${I0}:$B${I1}"))
header(en, base + 2, ["Enhance level", "Stat multiplier", "Coins for this level", "Coins spent so far", "Luck", "Cast range", "Reel power", "Catch bar size", "Resilience", "Auto wait", "Mutation chance"])
sel = f"$B${base}"
for L in range(0, 11):
    r = base + 3 + L
    en.put(r, 1, L)
    en.put(r, 2, f"=1+{K('EnhanceStatPerLevel')}*A{r}", S_DEC3)
    if L < 10:
        en.put(r, 3, f"=MAX(1,INT(INDEX({IT_PRICE},MATCH({sel},{IT_ID},0))*{K('EnhanceCostFraction')}*{K('EnhanceCostGrowth')}^A{r}))", S_INT)
    else:
        en.put(r, 3, "MAX", S_DEFAULT)
    en.put(r, 4, 0 if L == 0 else f"=D{r-1}+C{r-1}", S_INT)
    for j, st in enumerate(["Luck", "CastRange", "ReelPower", "CatchBarSize", "Resilience", "AutoSpeed", "MutationChance"]):
        en.put(r, 5 + j, f"={item_stat(st, sel)}*B{r}", S_DEC3)
for c in range(1, 14):
    en.width(c, 13)
en.width(1, 22)

# ============================================================ Mastery
ma = book.sheet("Mastery")
title(ma, "Mastery - permanent upgrades paid in Pearls", "Price to go from level L to L+1 = floor(BasePrice x PriceGrowth^L). Bonus is linear (PerLevel x level) or diminishing (MaxBonus x (1 - Decay^level)). Levels shown to 100.")
header(ma, 4, ["Track", "Stat", "Curve", "Max level", "Base price (Pearls)", "Per level", "Max bonus", "Decay", "Order"])
tracks = sorted(D["Mastery"]["Tracks"].items(), key=lambda kv: kv[1]["Order"])
for i, (tid, t) in enumerate(tracks):
    r = 5 + i
    ma.put(r, 1, tid)
    ma.put(r, 2, t["Stat"])
    ma.put(r, 3, t["Curve"])
    ma.put(r, 4, t.get("MaxLevel", 999), S_INPUT)
    ma.put(r, 5, t["BasePrice"], S_INPUT)
    ma.put(r, 6, t.get("PerLevel"), S_INPUT)
    ma.put(r, 7, t.get("MaxBonus"), S_INPUT)
    ma.put(r, 8, t.get("Decay"), S_INPUT)
    ma.put(r, 9, t["Order"])
ma.put(13, 1, "999 = no level cap. Tables below stop at the cap.", S_NOTE)
TR0 = 17
ma.put(TR0 - 2, 1, "Level tables", S_SECTION)
ma.put(TR0 - 1, 1, "Level", S_HEADER)
for i, (tid, t) in enumerate(tracks):
    c0 = 2 + i * 3
    ma.put(TR0 - 1, c0, f"{tid}: bonus", S_HEADER)
    ma.put(TR0 - 1, c0 + 1, f"{tid}: price to next", S_HEADER)
    ma.put(TR0 - 1, c0 + 2, f"{tid}: Pearls spent so far", S_HEADER)
for L in range(0, 101):
    r = TR0 + L
    ma.put(r, 1, L)
    for i, (tid, t) in enumerate(tracks):
        tr = 5 + i
        cb, cp, cc = col_letter(2 + i * 3), col_letter(3 + i * 3), col_letter(4 + i * 3)
        ma.put(r, 2 + i * 3, f'=IF($A{r}>$D${tr},"",IF($C${tr}="Linear",$F${tr}*$A{r},$G${tr}*(1-$H${tr}^$A{r})))', S_DEC3)
        ma.put(r, 3 + i * 3, f'=IF($A{r}>=$D${tr},"",INT($E${tr}*{K("MasteryPriceGrowth")}^$A{r}))', S_INT)
        if L == 0:
            ma.put(r, 4 + i * 3, 0, S_INT)
        else:
            ma.put(r, 4 + i * 3, f'=IF({cp}{r-1}="","",{cc}{r-1}+{cp}{r-1})', S_INT)
for c in range(1, 23):
    ma.width(c, 15)
ma.freeze = (TR0, 2)
MASTERY_ROW = {tid: 5 + i for i, (tid, t) in enumerate(tracks)}

# ============================================================ Skills
sk = book.sheet("Skills")
title(sk, "Skills - spend skill points", "Skill points come from level-ups. Cost of a level = CostBase + floor(level / CostStep), or an explicit list (Multi-Cast).")
header(sk, 4, ["Skill", "Stat", "Per level", "Max level", "Cost base", "Cost step", "Description"])
skills = sorted(D["Skills"]["List"].items(), key=lambda kv: kv[1]["Order"])
for i, (sid, s) in enumerate(skills):
    r = 5 + i
    sk.put(r, 1, sid)
    sk.put(r, 2, s["Stat"])
    sk.put(r, 3, s["PerLevel"], S_INPUT)
    sk.put(r, 4, s["MaxLevel"], S_INPUT)
    sk.put(r, 5, s.get("CostBase"), S_INPUT)
    sk.put(r, 6, s.get("CostStep"), S_INPUT)
    sk.put(r, 7, s["Description"])
SK_ROW = {sid: 5 + i for i, (sid, s) in enumerate(skills)}
mc = D["Skills"]["List"]["MultiCast"]["Costs"]
sk.put(9, 1, "Multi-Cast explicit costs (points per level)", S_BOLD)
for i, c in enumerate(mc):
    sk.put(9, 2 + i, c, S_INPUT)
SK0 = 13
sk.put(SK0 - 2, 1, "Level tables", S_SECTION)
sk.put(SK0 - 1, 1, "Level", S_HEADER)
for i, (sid, s) in enumerate(skills):
    c0 = 2 + i * 3
    sk.put(SK0 - 1, c0, f"{sid}: bonus", S_HEADER)
    sk.put(SK0 - 1, c0 + 1, f"{sid}: points to next", S_HEADER)
    sk.put(SK0 - 1, c0 + 2, f"{sid}: points so far", S_HEADER)
for L in range(0, 51):
    r = SK0 + L
    sk.put(r, 1, L)
    for i, (sid, s) in enumerate(skills):
        sr = 5 + i
        cp, cc = col_letter(3 + i * 3), col_letter(4 + i * 3)
        sk.put(r, 2 + i * 3, f'=IF($A{r}>$D${sr},"",$C${sr}*$A{r})', S_DEC3)
        if sid == "MultiCast":
            sk.put(r, 3 + i * 3, f'=IF($A{r}>=$D${sr},"",INDEX($B$9:$J$9,$A{r}+1))', S_INT)
        else:
            sk.put(r, 3 + i * 3, f'=IF($A{r}>=$D${sr},"",$E${sr}+INT($A{r}/$F${sr}))', S_INT)
        sk.put(r, 4 + i * 3, 0 if L == 0 else f'=IF({cp}{r-1}="","",{cc}{r-1}+{cp}{r-1})', S_INT)
for c in range(1, 13):
    sk.width(c, 17)
sk.width(7, 40)

# ============================================================ Rebirth
rb = book.sheet("Rebirth")
title(rb, "Rebirth - prestige", "Required level = min(Max, RequiredLevel + LevelStep x rebirths). Each rebirth adds a flat bonus to SellMultiplier and PearlRate. Rebirth resets level and coins.")
header(rb, 4, ["Rebirths", "Required level", "Sell Multiplier bonus", "Pearl Rate bonus", "Total XP from level 1 to required level", "Title"])
titles = D["Features"]["Rebirth"]["Titles"]
for n in range(0, 21):
    r = 5 + n
    rb.put(r, 1, n)
    rb.put(r, 2, f"=MIN({K('RebirthMaxLevel')},{K('RebirthRequiredLevel')}+{K('RebirthLevelStep')}*A{r})", S_INT)
    rb.put(r, 3, f"={K('RebirthBonus')}*A{r}", S_DEC2)
    rb.put(r, 4, f"={K('RebirthBonus')}*A{r}", S_DEC2)
    rb.put(r, 5, f"=INDEX({PG_CUM},B{r})", S_INT)
    tf = '""'
    for t in titles:
        tf = f'IF(A{{r}}>={t["Rebirths"]},"{t["Title"]}",{tf})'
    tf = tf.replace("{r}", str(r))
    rb.put(r, 6, "=" + tf)
for c, w in zip(range(1, 7), [10, 16, 20, 18, 34, 22]):
    rb.width(c, w)

# ============================================================ Stats Calculator
sc = book.sheet("Stats Calculator")
title(sc, "Stats Calculator - final stats for any build", "Mirrors Stats.Compute: base + rod/line/bait + aura + passes + mastery + rebirth + skills, then clamped by Min/Max. Yellow cells are the build; the table shows each source.")
inputs = [
    ("Rod Id", "CelestialRod"), ("Rod Enhance level (0-10)", 0), ("Line Id", "StarLine"), ("Bait Id (blank = none)", "PearlBait"), ("Bait left (1 = yes)", 1),
    ("Aura Id (blank = none)", "AbyssalShadow"), ("Aura stars (0-5)", 0), ("VIP pass (1 = owned)", 0), ("Auto-Fish Pro pass (1 = owned)", 0), ("Rebirths", 0),
]
sc.put(3, 1, "Build", S_SECTION)
for i, (lab, v) in enumerate(inputs):
    sc.put(4 + i, 1, lab, S_BOLD)
    sc.put(4 + i, 2, v, S_INPUT)
sc.validations.append(("B4", f"Items!$B${I0}:$B${I1}"))
sc.put(3, 4, "Mastery levels", S_SECTION)
for i, (tid, t) in enumerate(tracks):
    sc.put(4 + i, 4, tid, S_BOLD)
    sc.put(4 + i, 5, 0, S_INPUT)
sc.put(3, 7, "Skill levels", S_SECTION)
for i, (sid, s) in enumerate(skills):
    sc.put(4 + i, 7, sid, S_BOLD)
    sc.put(4 + i, 8, 0, S_INPUT)
MAST_IN = {tid: f"$E${4+i}" for i, (tid, t) in enumerate(tracks)}
SKILL_IN = {sid: f"$H${4+i}" for i, (sid, s) in enumerate(skills)}
TR = 17
header(sc, TR, ["Stat", "Base", "Rod", "Line", "Bait", "Aura", "Passes", "Mastery", "Rebirth", "Skills", "Raw total", "Min", "Max", "FINAL"])
SD = D["StatDefs"]
enh = f"(1+{K('EnhanceStatPerLevel')}*$B$5)"
star = f"(1+{K('AuraStatPerStar')}*$B$10)"
for i, st in enumerate(STAT_ORDER):
    r = TR + 1 + i
    d = SD[st]
    sc.put(r, 1, st, S_BOLD)
    sc.put(r, 2, d["Base"], S_INPUT)
    sc.put(r, 3, f"={item_stat(st, '$B$4')}" + ("" if st == "MaxDepth" else f"*{enh}"), S_DEC3)
    sc.put(r, 4, f"={item_stat(st, '$B$6')}", S_DEC3)
    sc.put(r, 5, f'=IF($B$8=1,{item_stat(st, "$B$7")},0)', S_DEC3)
    sc.put(r, 6, f'=IF($B$9="",0,{item_stat(st, "$B$9")}*{star})', S_DEC3)
    sc.put(r, 7, f'=$B$11*{item_stat(st, chr(34) + "VIP" + chr(34))}+$B$12*{item_stat(st, chr(34) + "AutoFishPro" + chr(34))}', S_DEC3)
    parts = []
    for tid, t in tracks:
        if t["Stat"] == st:
            tr = MASTERY_ROW[tid]
            lv = f"MIN({MAST_IN[tid]},Mastery!$D${tr})"
            parts.append(f'IF(Mastery!$C${tr}="Linear",Mastery!$F${tr}*{lv},Mastery!$G${tr}*(1-Mastery!$H${tr}^{lv}))')
    sc.put(r, 8, "=" + ("+".join(parts) if parts else "0"), S_DEC3)
    sc.put(r, 9, f"={K('RebirthBonus')}*$B$13" if st in D["Features"]["Rebirth"]["MultiplierStats"] else 0, S_DEC3)
    parts = []
    for sid, s in skills:
        if s["Stat"] == st:
            parts.append(f"Skills!$C${SK_ROW[sid]}*MIN({SKILL_IN[sid]},Skills!$D${SK_ROW[sid]})")
    sc.put(r, 10, "=" + ("+".join(parts) if parts else "0"), S_DEC3)
    sc.put(r, 11, f"=SUM(B{r}:J{r})", S_DEC3)
    sc.put(r, 12, d.get("Min"), S_DEC3)
    sc.put(r, 13, d.get("Max"), S_DEC3)
    lo = f"IF(L{r}=\"\",K{r},MAX(L{r},K{r}))"
    sc.put(r, 14, f'=IF(M{r}="",{lo},MIN(M{r},{lo}))', S_OUT)
for c in range(1, 15):
    sc.width(c, 13)
sc.width(1, 26)
SC_FINAL = {st: f"'Stats Calculator'!$N${TR+1+i}" for i, st in enumerate(STAT_ORDER)}
sc.put(TR + NS + 2, 1, "Percent stats (Luck, BiteSpeed, ...) are fractions: 0.5 = +50%. Bag capacity is not a stat; see Items.", S_NOTE)

# ============================================================ Fishing Loop (timing + income)
fl = book.sheet("Fishing Loop")
title(fl, "Fishing Loop - catches and income per hour", "Estimates, not a simulation. Links to the Stats Calculator (Luck, speeds, multipliers) and Fish Odds (depth, expected value). Change the yellow assumptions.")
fl.put(3, 1, "Stats (linked to Stats Calculator)", S_SECTION)
links = [("Luck", "Luck"), ("BiteSpeed", "BiteSpeed"), ("AutoSpeed", "AutoSpeed"), ("AutoMultiplier", "AutoMultiplier"), ("SellMultiplier", "SellMultiplier"), ("XPMultiplier", "XPMultiplier")]
for i, (lab, st) in enumerate(links):
    fl.put(4 + i, 1, lab, S_BOLD)
    fl.put(4 + i, 2, f"={SC_FINAL[st]}", S_DEC3)
fl.put(3, 4, "Assumptions (inputs)", S_SECTION)
assum = [("Perfect cast share (0-1)", 0.5), ("Reaction time to '!' (sec)", 1.0), ("Reel minigame time (sec)", 8.0), ("Share of manual catches that are 'perfect' (never left the bar)", 0.4),
         ("Average Hot Streak count while fishing", 5), ("2x Coins boost active (1 = yes)", 0), ("Average XP per catch before multipliers (see Rarities)", 25)]
for i, (lab, v) in enumerate(assum):
    fl.put(4 + i, 4, lab, S_BOLD)
    fl.put(4 + i, 8, v, S_INPUT)
fl.put(12, 1, "Manual fishing", S_SECTION)
rowsM = [
    ("Bite wait (avg, sec)", f"=({K('BiteWaitMin')}+{K('BiteWaitMax')})/2*(1-B5)*(1-H4*{K('PerfectBiteBonus')})", S_DEC2),
    ("Seconds per catch", f"=B13+H5+H6+{K('CastCooldown')}+{K('FlightTime')}", S_DEC2),
    ("Catches per hour", "=3600/B14", S_DEC2),
    ("Coin multiplier per catch (avg)", f"=({K('ManualMultiplier')}+H7*{K('PerfectCatchBonus')})*(1+MIN({K('HotStreakMax')},H8*{K('HotStreakPerCatch')}))", S_DEC3),
    ("Coins per hour (before hot fish)", f"=B15*'Fish Odds'!B5*B16*B8*IF(H9=1,{K('BoostCoinsMult')},1)", S_OUT_INT),
    ("Gems per hour (catch rewards only)", "=B15*'Fish Odds'!B6", S_OUT),
]
for i, (lab, fm, st) in enumerate(rowsM):
    fl.put(13 + i, 1, lab)
    fl.put(13 + i, 2, fm, st)
fl.put(20, 1, "Auto fishing", S_SECTION)
rowsA = [
    ("Seconds per catch = AutoCycleTime x (1-AutoSpeed) x (1-BiteSpeed x 0.5)", f"={K('AutoCycleTime')}*(1-B6)*(1-B5*0.5)", S_DEC2),
    ("Catches per hour", "=3600/B21", S_DEC2),
    ("Coins per hour (before hot fish)", f"=B22*'Fish Odds'!B5*B7*B8*IF(H9=1,{K('BoostCoinsMult')},1)", S_OUT_INT),
    ("Gems per hour (Auto gives 50%)", f"=B22*'Fish Odds'!B6*{K('AutoGemMultiplier')}", S_OUT),
    ("Auto coins as % of Manual", "=IF(B17=0,0,B23/B17)", S_PCT),
]
for i, (lab, fm, st) in enumerate(rowsA):
    fl.put(21 + i, 1, lab)
    fl.put(21 + i, 2, fm, st)
fl.put(27, 1, "Chests (Treasure Chest)", S_SECTION)
tre = D["Treasures"]["TreasureChest"]
tw = sum(x["Weight"] for x in tre["Rewards"])
coins_r = next(x for x in tre["Rewards"] if x["Kind"] == "Coins")
gems_r = next(x for x in tre["Rewards"] if x["Kind"] == "Gems")
bait_r = next(x for x in tre["Rewards"] if x["Kind"] == "Bait")
fl.put(28, 1, "Chest drop chance per manual catch = DropChance x (1 + Luck x TreasureLuckScale)")
fl.put(28, 2, f"={tre['DropChance']}*(1+B4*{K('TreasureLuckScale')})", S_PCT)
fl.put(29, 1, "Chests per hour (manual)")
fl.put(29, 2, "=B15*B28", S_DEC2)
fl.put(30, 1, "Chest reward weights: Coins / Gems / Bait")
fl.put(30, 2, f"{coins_r['Weight']} / {gems_r['Weight']} / {bait_r['Weight']}")
fl.put(31, 1, "Expected coins per chest")
fl.put(31, 2, f"={coins_r['Weight']}/{tw}*({coins_r['Min']}+{coins_r['Max']})/2", S_DEC2)
fl.put(32, 1, "Expected Gems per chest")
fl.put(32, 2, f"={gems_r['Weight']}/{tw}*({gems_r['Min']}+{gems_r['Max']})/2", S_DEC2)
fl.put(33, 1, "Chest coins per hour (manual)")
fl.put(33, 2, "=B29*B31", S_OUT_INT)
fl.put(35, 1, "XP", S_SECTION)
fl.put(36, 1, "XP per hour (manual) = catches x XP x XPMultiplier x Manual multiplier")
fl.put(36, 2, f"=B15*H10*B9*{K('ManualMultiplier')}", S_OUT_INT)
fl.put(37, 1, "XP per hour (auto)")
fl.put(37, 2, "=B22*H10*B9", S_OUT_INT)
fl.put(38, 1, "Hours of manual fishing to gain one level at level 30")
fl.put(38, 2, "=INDEX(Progression!$B$6:$B$105,30)/B36", S_DEC2)
fl.width(1, 62)
fl.width(2, 16)
fl.width(4, 52)
fl.width(8, 12)

# ============================================================ Reel minigame
rm = book.sheet("Reel Minigame")
title(rm, "Reel Minigame - difficulty and time to land", "Progress rises while the catch bar is on the fish and falls when off. Use this to tune Difficulty, ReelPower and Resilience.")
rm.put(3, 1, "ReelPower stat", S_BOLD)
rm.put(3, 2, 1.0, S_INPUT)
rm.put(4, 1, "Resilience stat (0-0.9)", S_BOLD)
rm.put(4, 2, 0.0, S_INPUT)
rm.put(5, 1, "Minimum time to land (perfect tracking), sec", S_BOLD)
rm.put(5, 2, f"=(1-{K('ReelStartProgress')})/({K('ReelGainPerSecond')}*B3)", S_OUT)
rm.put(6, 1, "Fastest finish the server accepts, sec", S_BOLD)
rm.put(6, 2, f"=B5*{K('ValidationSlack')}", S_OUT)
header(rm, 8, ["Pattern", "Speed", "Jitter", "Burst chance", "Bias"])
pats = sorted(D["MinigamePatterns"].items())
for i, (pid, p) in enumerate(pats):
    r = 9 + i
    rm.put(r, 1, pid)
    rm.put(r, 2, p["Speed"], S_INPUT)
    rm.put(r, 3, p["Jitter"], S_INPUT)
    rm.put(r, 4, p["BurstChance"], S_INPUT)
    rm.put(r, 5, p.get("Bias"), S_INPUT)
rm.put(14, 1, "Fish speed by pattern and difficulty = Speed x (1 + (Difficulty-1) x DifficultySpeedScale)", S_SECTION)
rm.put(15, 1, "Difficulty", S_HEADER)
for i, (pid, p) in enumerate(pats):
    rm.put(15, 2 + i, pid, S_HEADER)
for dlv in range(1, 11):
    r = 15 + dlv
    rm.put(r, 1, dlv)
    for i in range(len(pats)):
        rm.put(r, 2 + i, f"=$B${9+i}*(1+($A{r}-1)*{K('DifficultySpeedScale')})", S_DEC3)
rm.put(28, 1, "Time to land (sec) if the bar is on the fish X% of the time", S_SECTION)
rm.put(29, 1, "On-fish %", S_HEADER)
for j, rp in enumerate([1, 1.5, 2, 3]):
    rm.put(29, 2 + j, rp, S_INPUT)
rm.put(28, 7, "<- ReelPower values (inputs)", S_NOTE)
for k, pct in enumerate([0.5, 0.6, 0.7, 0.8, 0.9, 1.0]):
    r = 30 + k
    rm.put(r, 1, pct, S_INPUT_PCT)
    for j in range(4):
        colL = col_letter(2 + j)
        rate = f"({K('ReelGainPerSecond')}*{colL}$29*$A{r}-{K('ReelLossPerSecond')}*(1-$B$4)*(1-$A{r}))"
        rm.put(r, 2 + j, f'=IF({rate}<=0,"never",(1-{K("ReelStartProgress")})/{rate})', S_DEC2)
for c, w in zip(range(1, 8), [44, 14, 14, 14, 14, 14, 24]):
    rm.width(c, w)

# ============================================================ Aquarium
aq = book.sheet("Aquarium")
title(aq, "Aquarium - idle Pearls", "Each fish in the tank makes Pearls/min = rarity rate x mutation multiplier x PearlRate. Offline credit is capped by OfflineCapHours. Slot prices are in Coins.")
aq.put(3, 1, "PearlRate stat (linked)", S_BOLD)
aq.put(3, 2, f"={SC_FINAL['PearlRate']}", S_DEC3)
aq.put(4, 1, "2x Pearls boost on (1 = yes)", S_BOLD)
aq.put(4, 2, 0, S_INPUT)
aq.put(5, 1, "Offline cap (hours, linked)", S_BOLD)
aq.put(5, 2, f"={SC_FINAL['OfflineCapHours']}", S_DEC2)
header(aq, 7, ["Rarity", "Fish in tank (input)", "Pearls/min per fish", "Pearls/min total", "Pearls / hour", "Pearls / day"])
counts = [0, 0, 1, 1, 1, 0]
for i, rr in enumerate(RARITIES):
    r = 8 + i
    aq.put(r, 1, rr["Name"])
    aq.put(r, 2, counts[i], S_INPUT)
    aq.put(r, 3, f"=INDEX({RG},{i+1})*$B$3*IF($B$4=1,{K('BoostPearlsMult')},1)", S_DEC3)
    aq.put(r, 4, f"=B{r}*C{r}", S_DEC3)
    aq.put(r, 5, f"=D{r}*60", S_DEC2)
    aq.put(r, 6, f"=E{r}*24", S_INT)
tr = 8 + RN
aq.put(tr, 1, "Total", S_BOLD)
aq.put(tr, 2, f"=SUM(B8:B{tr-1})", S_INT)
aq.put(tr, 4, f"=SUM(D8:D{tr-1})", S_OUT)
aq.put(tr, 5, f"=SUM(E8:E{tr-1})", S_OUT)
aq.put(tr, 6, f"=SUM(F8:F{tr-1})", S_OUT_INT)
aq.put(tr + 1, 1, "Pearls per second")
aq.put(tr + 1, 4, f"=D{tr}/60", S_DEC3)
aq.put(tr + 2, 1, "Offline Pearls if away 8 hours (capped)")
aq.put(tr + 2, 4, f"=D{tr}*MIN(8,B5)*60", S_OUT_INT)
sp = GC["Aquarium"]["SlotPrices"]
aq.put(tr + 4, 1, "Tank slots", S_SECTION)
header(aq, tr + 5, ["Slot #", "Price (Coins)", "Total spent"])
for i, p in enumerate(sp):
    r = tr + 6 + i
    aq.put(r, 1, f"={K('AquariumStartSlots')}+{i+1}", S_INT)
    aq.put(r, 2, p, S_INPUT_INT)
    aq.put(r, 3, f"=SUM($B${tr+6}:B{r})", S_INT)
aq.put(tr + 6 + len(sp), 1, "Max slots", S_BOLD)
aq.put(tr + 6 + len(sp), 2, f"={K('AquariumStartSlots')}+{len(sp)}", S_INT)
SLOT_TOTAL = f"Aquarium!$C${tr+5+len(sp)}"
for c, w in zip(range(1, 7), [34, 18, 18, 16, 14, 14]):
    aq.width(c, w)

# ============================================================ Auras
au = book.sheet("Auras")
title(au, "Auras - gacha pool and real rates", "Auras are tried rarest first, each with chance (1+Luck) x rateUp / Chance; the most common takes what is left (Roll.AuraRates). Stats are in Items.")
au.put(3, 1, "Luck (linked)", S_BOLD)
au.put(3, 2, f"={SC_FINAL['Luck']}", S_DEC3)
au.put(4, 1, "Rate-up (input per aura, column G)", S_NOTE)
header(au, 6, ["Id", "Name", "Rarity", "Tier", "1 in N (Chance)", "Order", "Rate-up multiplier", "Per-step chance", "Left before", "Real rate per pull", "1 in N (real)", "Glowing", "SunForged", "Golden", "VoidTouched"])
auras_sorted = sorted(D["Auras"].items(), key=lambda kv: -kv[1]["Chance"])
NA = len(auras_sorted)
A0, A1 = 7, 6 + NA
for i, (aid, a) in enumerate(auras_sorted):
    r = 7 + i
    au.put(r, 1, aid)
    au.put(r, 2, a["Name"])
    au.put(r, 3, a["Rarity"])
    au.put(r, 4, f"=INDEX({RA},MATCH(C{r},{RB},0))")
    au.put(r, 5, a["Chance"], S_INPUT_INT)
    au.put(r, 6, a["Order"])
    au.put(r, 7, 1, S_INPUT)
    au.put(r, 8, f"=MIN(1,(1+$B$3)*G{r}/E{r})", S_PCT)
    au.put(r, 9, 1 if i == 0 else f"=I{r-1}*(1-H{r-1})", S_PCT)
    au.put(r, 10, f"=I{r}" if i == NA - 1 else f"=I{r}*H{r}", S_PCT)
    au.put(r, 11, f'=IF(J{r}=0,"",1/J{r})', S_DEC2)
    for j, mid in enumerate(["Glowing", "SunForged", "Golden", "VoidTouched"]):
        au.put(r, 12 + j, a.get("Mutations", {}).get(mid), S_INPUT)
au.put(A1 + 1, 9, "Check (should be 100%)", S_BOLD)
au.put(A1 + 1, 10, f"=SUM(J{A0}:J{A1})", S_PCT)
au.put(A1 + 3, 1, "Rates by rarity", S_SECTION)
for i, rr in enumerate(RARITIES):
    r = A1 + 4 + i
    au.put(r, 1, rr["Name"])
    au.put(r, 2, f"=SUMIF($C${A0}:$C${A1},A{r},$J${A0}:$J${A1})", S_PCT)
AU_RATE_TIER = f"Auras!$D${A0}:$D${A1}"
AU_RATE = f"Auras!$J${A0}:$J${A1}"
for c, w in zip(range(1, 16), [20, 22, 11, 6, 14, 7, 12, 12, 12, 14, 12, 9, 10, 9, 11]):
    au.width(c, w)

# ============================================================ Gacha
gc = book.sheet("Gacha")
title(gc, "Gacha - banners, pity, expected cost", "Pity: after PityPulls-1 pulls without Legendary-or-better the next pull is Legendary; hard pity guarantees Mythic. x10: cost x10 x (1 - discount); at least one Rare+. Expected pulls use the capped-geometric formula.")
banners = [(k, v) for k, v in D["AuraBanners"].items()]
header(gc, 4, ["Banner", "Kind", "Cost per pull", "Currency", "x10 discount", "x10 min rarity", "Pity pulls", "Pity rarity", "Hard pity pulls", "Hard pity rarity", "Featured", "Rate-up"])
for i, (bid, b) in enumerate(banners):
    r = 5 + i
    gc.put(r, 1, b["Name"])
    gc.put(r, 2, b["Kind"])
    gc.put(r, 3, b["Cost"], S_INPUT)
    gc.put(r, 4, b["Currency"])
    gc.put(r, 5, b["Ten"]["Discount"], S_INPUT_PCT)
    gc.put(r, 6, b["Ten"]["MinRarity"])
    gc.put(r, 7, b["PityPulls"], S_INPUT)
    gc.put(r, 8, b["PityRarity"])
    gc.put(r, 9, b["HardPity"]["Pulls"], S_INPUT)
    gc.put(r, 10, b["HardPity"]["Rarity"])
    gc.put(r, 11, b.get("Featured", ""))
    gc.put(r, 12, ", ".join(f"{k} x{v}" for k, v in b.get("RateUp", {}).items()))
gc.put(8, 1, "Expected cost (uses the Real rates on the Auras sheet at the Luck shown there)", S_SECTION)
header(gc, 9, ["Banner", "x10 price", "Price per pull in x10", "P(Legendary+) per pull", "P(Mythic) per pull", "Expected pulls to Legendary+ (cap = pity)", "Expected pulls to Mythic (cap = hard pity)", "Expected gems to Legendary+", "Expected gems to Mythic", "Worst-case gems to Legendary+", "Worst-case gems to Mythic"])
for i, (bid, b) in enumerate(banners):
    r = 10 + i
    br = 5 + i
    gc.put(r, 1, b["Name"])
    gc.put(r, 2, f"=INT(C{br}*10*(1-E{br})+0.5)", S_INT)
    gc.put(r, 3, f"=B{r}/10", S_DEC2)
    gc.put(r, 4, f"=SUMPRODUCT(({AU_RATE_TIER}>=5)*{AU_RATE})", S_PCT)
    gc.put(r, 5, f"=SUMPRODUCT(({AU_RATE_TIER}>=6)*{AU_RATE})", S_PCT)
    gc.put(r, 6, f"=IF(D{r}=0,G{br},(1-(1-D{r})^G{br})/D{r})", S_DEC2)
    gc.put(r, 7, f"=IF(E{r}=0,I{br},(1-(1-E{r})^I{br})/E{r})", S_DEC2)
    gc.put(r, 8, f"=F{r}*C{br}", S_INT)
    gc.put(r, 9, f"=G{r}*C{br}", S_INT)
    gc.put(r, 10, f"=G{br}*C{br}", S_INT)
    gc.put(r, 11, f"=I{br}*C{br}", S_INT)
gc.put(13, 1, "Rate-up banners also change the rates; set Rate-up multipliers on the Auras sheet to model them.", S_NOTE)
mi = [b for k, b in banners if b.get("Milestones")]
gc.put(15, 1, "Event banner milestones (Neon Tide)", S_SECTION)
header(gc, 16, ["Pulls", "Reward", "Amount", "Gems value"])
for i, m in enumerate(mi[0]["Milestones"]):
    r = 17 + i
    gc.put(r, 1, m["Pulls"], S_INPUT)
    gc.put(r, 2, m["Kind"] + (f" ({m['Id']})" if "Id" in m else ""))
    gc.put(r, 3, m.get("Amount", 1), S_INPUT)
    gc.put(r, 4, m["Amount"] if m["Kind"] == "Gems" else 0, S_INT)
mr_end = 16 + len(mi[0]["Milestones"])
gc.put(mr_end + 1, 1, "Total Gems from milestones", S_BOLD)
gc.put(mr_end + 1, 4, f"=SUM(D17:D{mr_end})", S_OUT_INT)
gc.put(mr_end + 3, 1, "Aura stars", S_SECTION)
header(gc, mr_end + 4, ["Rarity", "Tokens per duplicate", "Cost 0->1", "1->2", "2->3", "3->4", "4->5", "Total tokens to 5 stars", "Duplicates needed"])
sc_costs = D["AuraStars"]["StarCost"]
for i, rr in enumerate(RARITIES):
    r = mr_end + 5 + i
    gc.put(r, 1, rr["Name"])
    gc.put(r, 2, f"=INDEX(Rarities!$I$5:$I${4+RN},{i+1})", S_INT)
    for j, c in enumerate(sc_costs):
        gc.put(r, 3 + j, f"={c}*INDEX(Rarities!$H$5:$H${4+RN},{i+1})", S_INT)
    gc.put(r, 8, f"=SUM(C{r}:G{r})", S_INT)
    gc.put(r, 9, f"=H{r}/B{r}", S_DEC2)
gc.put(mr_end + 5 + RN, 1, "Star costs (base list per star, before the rarity multiplier): " + ", ".join(str(c) for c in sc_costs), S_NOTE)
for c, w in zip(range(1, 13), [22, 12, 14, 16, 14, 18, 18, 16, 16, 18, 18, 24]):
    gc.width(c, w)

# ============================================================ Monetization
mo = book.sheet("Monetization")
title(mo, "Monetization - Robux value", "Robux prices are display values from Products.luau (set them on the Creator Hub). Gem value uses AuraRollCost. Rewards come from the product config.")
header(mo, 4, ["Product", "Type", "Robux", "Gems", "Aura pulls", "Gems per Robux", "Robux per pull", "Robux per expected Legendary+ (Altar)", "Other rewards"])
prods = sorted(D["Products"]["Products"].items(), key=lambda kv: kv[1]["Order"])
for i, (pid, p) in enumerate(prods):
    r = 5 + i
    gems = sum(x.get("Amount", 0) for x in p["Rewards"] if x["Kind"] == "Gems")
    other = []
    for x in p["Rewards"]:
        if x["Kind"] == "Boost":
            other.append(f"{x['Id']} boost {x['Amount']//3600}h")
        if x["Kind"] == "Bait":
            other.append(f"{x['Amount']} {x['Id']}")
        if x["Kind"] == "Item":
            other.append(f"{x['Id']} ({x['Category']})")
    mo.put(r, 1, p["Name"])
    mo.put(r, 2, "Developer product")
    mo.put(r, 3, p["Price"], S_INPUT)
    mo.put(r, 4, gems, S_INPUT)
    mo.put(r, 5, f"=D{r}/{K('AuraRollCost')}", S_DEC2)
    mo.put(r, 6, f'=IF(D{r}=0,"",D{r}/C{r})', S_DEC2)
    mo.put(r, 7, f'=IF(D{r}=0,"",C{r}/E{r})', S_DEC2)
    mo.put(r, 8, f'=IF(D{r}=0,"",G{r}*Gacha!F10)', S_DEC2)
    mo.put(r, 9, ", ".join(other))
pr0 = 5 + len(prods) + 1
mo.put(pr0, 1, "Game passes", S_SECTION)
header(mo, pr0 + 1, ["Pass", "Robux", "What it gives"])
for i, (pid, p) in enumerate(sorted(D["Products"]["Passes"].items(), key=lambda kv: kv[1]["Order"])):
    r = pr0 + 2 + i
    mo.put(r, 1, p["Name"])
    mo.put(r, 2, p["Price"], S_INPUT)
    mo.put(r, 3, p["Description"])
vr = pr0 + 2 + 4 + 1
mo.put(vr, 1, "Starter Pack content value (Coins)", S_SECTION)
mo.put(vr + 1, 1, "50 Shrimp")
mo.put(vr + 1, 2, f"=50*INDEX({IT_PRICE},MATCH(\"Shrimp\",{IT_ID},0))/INDEX(Items!$I${I0}:$I${I1},MATCH(\"Shrimp\",{IT_ID},0))", S_INT)
mo.put(vr + 2, 1, "Sweetheart Rod (shop price)")
mo.put(vr + 2, 2, f"=INDEX({IT_PRICE},MATCH(\"SweetheartRod\",{IT_ID},0))", S_INT)
mo.put(vr + 3, 1, "100 Gems = pulls")
mo.put(vr + 3, 2, f"=100/{K('AuraRollCost')}", S_DEC2)
mo.put(vr + 4, 1, "Note: Gems per Robux is the effective rate (25 Robux buys 25 Gems, 99 buys 110, 249 buys 300).", S_NOTE)
for c, w in zip(range(1, 10), [34, 18, 10, 10, 12, 14, 14, 26, 36]):
    mo.width(c, w)

# ============================================================ Economy Totals
et = book.sheet("Economy Totals")
title(et, "Economy Totals - sinks and sources", "Everything players can spend or earn, summed from the other sheets. Use it to spot where content is too cheap or too slow.")
header(et, 4, ["Sink", "Currency", "Total", "Notes"])
sinks = [
    ("All rods (shop price)", "Coins", f'=SUMIF({IT_CAT},"Rod",{IT_PRICE})', "One of each rod"),
    ("All lines", "Coins", f'=SUMIF({IT_CAT},"Line",{IT_PRICE})', "Max depth tiers"),
    ("All bags", "Coins", f'=SUMIF({IT_CAT},"Bag",{IT_PRICE})', "Capacity tiers"),
    ("Enhance every rod to +10", "Coins", f"=SUM(Enhance!M5:M{4+len(rods)})", "Rods with scaling stats"),
    ("All Aquarium slots", "Coins", f"={SLOT_TOTAL}", "9 extra slots"),
    ("One bait batch of each bait type (BuyAmount each)", "Coins", f'=SUMIF({IT_CAT},"Bait",{IT_PRICE})', "Baits are consumed per catch"),
    ("Aura Altar: guaranteed Legendary (worst case)", "Gems", "=Gacha!J10", "Soft pity"),
    ("Aura Altar: guaranteed Mythic (worst case)", "Gems", "=Gacha!K10", "Hard pity"),
]
tm_cols = {tid: (col_letter(4 + i * 3), t) for i, (tid, t) in enumerate(tracks)}
for tid, t in tracks:
    if t.get("MaxLevel"):
        cc = col_letter(4 + [x[0] for x in tracks].index(tid) * 3)
        sinks.append((f"Mastery: {tid} to max level ({t['MaxLevel']})", "Pearls", f"=INDEX(Mastery!${cc}${TR0}:${cc}${TR0+100},{t['MaxLevel']}+1)", "Linear, capped"))
for i, (a, cur, fm, note) in enumerate(sinks):
    r = 5 + i
    et.row(r, 1, [a, cur])
    et.put(r, 3, fm, S_INT)
    et.put(r, 4, note)
sr = 5 + len(sinks) + 2
et.put(sr, 1, "Sources", S_SECTION)
header(et, sr + 1, ["Source", "Currency", "Amount", "Notes"])
dl = D["DailyLogin"]["Days"]
sources = [
    ("Daily login, 7-day cycle: Coins", "Coins", sum(d["Reward"]["Amount"] for d in dl if d["Reward"]["Kind"] == "Coins"), "Per 7 days"),
    ("Daily login, 7-day cycle: Gems", "Gems", sum(d["Reward"]["Amount"] for d in dl if d["Reward"]["Kind"] == "Gems"), "Per 7 days"),
    ("Daily login, 7-day cycle: Pearls", "Pearls", sum(d["Reward"]["Amount"] for d in dl if d["Reward"]["Kind"] == "Pearls"), "Per 7 days"),
    ("Daily quests: Gems per day (all done)", "Gems", f"={K('QuestsPerDay')}*{K('QuestRewardGems')}", "3 quests x 5 gems"),
    ("Level-ups: Gems by level 50", "Gems", f"=INDEX(Progression!$D$6:$D$105,50)", "5 Gems per level"),
    ("New species: Gems for all 30 fish", "Gems", f"={NF}*{K('NewSpeciesGems')}", "First catch of each species"),
    ("Event banner milestones (Neon Tide)", "Gems", f"=Gacha!D{mr_end+1}", "Total over 400 pulls"),
]
for i, (a, cur, fm, note) in enumerate(sources):
    r = sr + 2 + i
    et.row(r, 1, [a, cur])
    et.put(r, 3, fm, S_INT)
    et.put(r, 4, note)
for c, w in zip(range(1, 5), [56, 12, 18, 40]):
    et.width(c, w)

# ============================================================ Live Content
lc = book.sheet("Live Content")
title(lc, "Live Content - daily login, quests, hot fish, events", "Time-based content tables. Rewards and weights are inputs; expected values are formulas.")
lc.put(3, 1, "Daily Login (7 days)", S_SECTION)
header(lc, 4, ["Day", "Reward kind", "Item id", "Amount"])
for i, d in enumerate(dl):
    r = 5 + i
    lc.put(r, 1, d["Day"])
    lc.put(r, 2, d["Reward"]["Kind"])
    lc.put(r, 3, d["Reward"].get("Id", ""))
    lc.put(r, 4, d["Reward"]["Amount"], S_INPUT)
lc.put(12, 1, "Weekly totals by kind", S_BOLD)
for i, kd in enumerate(["Coins", "Gems", "Pearls", "Bait"]):
    lc.put(13 + i, 1, kd)
    lc.put(13 + i, 2, f"=SUMIF($B$5:$B$11,A{13+i},$D$5:$D$11)", S_INT)
lc.put(19, 1, "Quests (3 random per day, weighted)", S_SECTION)
header(lc, 20, ["Quest", "Kind", "Target", "Min level", "Weight", "Pick chance (all levels)"])
qs = sorted(D["Quests"].items())
for i, (qid, qv) in enumerate(qs):
    r = 21 + i
    lc.put(r, 1, qid)
    lc.put(r, 2, qv["Kind"])
    lc.put(r, 3, qv["Target"], S_INPUT)
    lc.put(r, 4, qv.get("MinLevel", 1), S_INPUT)
    lc.put(r, 5, qv["Weight"], S_INPUT)
    lc.put(r, 6, f"=E{r}/SUM($E$21:$E${20+len(qs)})", S_PCT)
qe = 21 + len(qs) + 1
lc.put(qe, 1, "Hot fish (Merchant)", S_SECTION)
lc.put(qe + 1, 1, "Rotation every (min)")
lc.put(qe + 1, 2, f"={K('HotFishIntervalMin')}", S_INT)
lc.put(qe + 2, 1, "Species per rotation")
lc.put(qe + 2, 2, f'={K("HotFishCountMin")}&"-"&{K("HotFishCountMax")}')
lc.put(qe + 3, 1, "Multipliers")
lc.put(qe + 3, 2, f"={K('HotFishMults')}")
lc.put(qe + 4, 1, "Eligible rarities")
lc.put(qe + 4, 2, ", ".join(GC["HotFish"]["Rarities"]))
lc.put(qe + 6, 1, "Naga Tide event", S_SECTION)
te = D["TideEvents"]["Events"]["NagaTide"]
lc.put(qe + 7, 1, "Duration (sec) / Luck bonus / crowd bonus per extra angler / crowd cap")
lc.put(qe + 7, 2, te["Duration"], S_INPUT)
lc.put(qe + 7, 3, te["LuckBonus"], S_INPUT)
lc.put(qe + 7, 4, te["CrowdBonusPerPlayer"], S_INPUT)
lc.put(qe + 7, 5, te["CrowdBonusMax"], S_INPUT)
header(lc, qe + 9, ["Other anglers", "Crowd factor", "NagaHatchling chance", "CoralSeahorse chance"])
for n in range(0, 8):
    r = qe + 10 + n
    lc.put(r, 1, n, S_INPUT)
    lc.put(r, 2, f"=1+MIN($E${qe+7},A{r}*$D${qe+7})", S_DEC2)
    for j, c in enumerate(te["Catches"]):
        lc.put(r, 3 + j, f"={c['Chance']}*B{r}", S_PCT)
lc.put(qe + 19, 1, "Hotspot: Luck bonus " + str(GC["Hotspot"]["LuckBonus"]) + " for a manual cast inside; each spot allows " + str(GC["Hotspot"]["Uses"]) + " casts; up to " + str(GC["Hotspot"]["Max"]) + " per server (see Constants).", S_NOTE)
for c, w in zip(range(1, 7), [56, 20, 22, 20, 12, 24]):
    lc.width(c, w)

# ============================================================ README
rd = Sheet("README")
book.sheets.insert(0, rd)
book.by_name["README"] = rd
title(rd, "Aura Fishing - Game Design Math workbook", "Generated from the game's config and formula code. Every number is read from src/shared/Config; every formula mirrors the Luau code named in the Source column.")
readme = [
    ("How to use", ""),
    ("1", "Yellow cells are inputs/tuning numbers. Change one and the formulas recalculate. Green cells are key results. Blue-grey bars are section titles."),
    ("2", "Import into Google Sheets: File > Import > Upload > choose this .xlsx > 'Insert new sheet(s)' (or 'Replace spreadsheet'). Formulas and dropdowns are kept."),
    ("2b", "Defaults: Stats Calculator is pre-filled with an endgame build (Celestial Rod, Star Line, Pearl Bait, Abyssal Shadow). Fishing Loop, Aquarium and Auras read their stats from it, so set the build first. Fish Odds defaults to depth 80 m, Luck 0.5."),
    ("3", "Changing a value here does NOT change the game. To apply a balance change, edit the value in the config file named in the Source column."),
    ("", ""),
    ("Sheets", ""),
    ("Constants", "All global tuning numbers (GameConfig, Rebirth, Skills, Mastery growth...). Other sheets read from here."),
    ("Rarities", "Tier, roll weight, XP, Gems, Aquarium rate and aura-star multipliers per rarity."),
    ("Fish", "All 30 species: depth, weight, base value, roll weight, Pearls/min, value range."),
    ("Fish Odds", "Simulator: what bites at a depth and Luck, probabilities, a Luck sweep per rarity, expected value per catch."),
    ("Mutations", "Mutation priority roll and expected value multiplier."),
    ("Sell Value", "One fish step by step: size factor, mutation, manual/auto/streak, sell multiplier, coin boost, hot fish."),
    ("Progression", "XP curve, cumulative XP, Gems and skill points by level, catches per level."),
    ("Items", "Rods, lines, baits, bags, passes and auras with every stat in one table."),
    ("Enhance", "Rod upgrade costs and stat scaling +0 to +10."),
    ("Mastery", "7 permanent Pearl upgrades: price and bonus per level to level 100."),
    ("Skills", "Skill point costs and bonuses (Keen Eye, Quick Hands, Multi-Cast)."),
    ("Rebirth", "Required level, bonus and title per rebirth, with total XP to get there."),
    ("Stats Calculator", "Final stats for any build (rod, line, bait, aura, passes, mastery, skills, rebirths) with every source shown."),
    ("Fishing Loop", "Catches and coins/Gems per hour for manual vs auto, chest income."),
    ("Reel Minigame", "Fish speed by pattern and difficulty, time to land by ReelPower and tracking accuracy."),
    ("Aquarium", "Idle Pearls from a tank, offline credit, slot prices."),
    ("Auras", "Gacha pool with the real per-pull rates at your Luck, rate-up inputs, mutation bonuses."),
    ("Gacha", "Banners, pity, expected pulls and Gems to Legendary/Mythic, event milestones, aura star costs."),
    ("Monetization", "Robux products and passes: Gems per Robux, Robux per pull and per Legendary."),
    ("Economy Totals", "Total sinks (what players can spend) and sources (what they earn)."),
    ("Live Content", "Daily login, quests, hot fish, Naga Tide crowd bonus."),
    ("", ""),
    ("Known simplifications", ""),
    ("-", "Fishing Loop and Fish Odds are expected-value estimates, not a simulation. Player behaviour (reel time, perfect rate) is an input."),
    ("-", "Hot fish and the Tide event are random/time-based in the game; here they are parameters."),
    ("-", "Server rounding: the game stores each catch's value rounded, then sells the stack total x multipliers; very large stacks can differ by a few coins."),
    ("-", "Prices of Robux products are display values; the real price is set on the Creator Hub."),
    ("-", "Dev-only content (Dev config) and UI/Figma values are not included."),
]
for i, (a, b) in enumerate(readme):
    r = 4 + i
    st = S_SECTION if b == "" and a else S_DEFAULT
    rd.put(r, 1, a, S_SECTION if (b == "" and a) else S_BOLD)
    rd.put(r, 2, b, S_WRAP)
rd.width(1, 22)
rd.width(2, 130)

# reorder sheets for readability
order = ["README", "Constants", "Rarities", "Fish", "Fish Odds", "Mutations", "Sell Value", "Progression", "Items", "Enhance", "Mastery", "Skills", "Rebirth",
         "Stats Calculator", "Fishing Loop", "Reel Minigame", "Aquarium", "Auras", "Gacha", "Monetization", "Economy Totals", "Live Content"]
book.sheets = [book.by_name[n] for n in order]

ev = evaluate(book)
print("sheets:", len(book.sheets), "cells:", sum(len(s.cells) for s in book.sheets))
print("formula errors:", len(ev.errors))
for e in ev.errors[:40]:
    print("  ", e)
out = sys.argv[1] if len(sys.argv) > 1 else "workbook.xlsx"
write_xlsx(book, out, ev)
print("written", out)
if len(sys.argv) > 2:  # values-only csv copies (one per sheet) for tools that cannot open the xlsx
    import csv
    import os
    os.makedirs(sys.argv[2], exist_ok=True)
    for n, sh in enumerate(book.sheets):
        maxr = max(r for r, c in sh.cells)
        maxc = max(c for r, c in sh.cells)
        with open(os.path.join(sys.argv[2], f"{n:02d}_{sh.name.replace(' ', '_')}.csv"), "w", newline="", encoding="utf-8-sig") as fh:
            w = csv.writer(fh)
            for r in range(1, maxr + 1):
                row = []
                for c in range(1, maxc + 1):
                    v = sh.cells.get((r, c), [None])[0]
                    if isinstance(v, str) and v.startswith("="):
                        v = ev.memo.get((sh.name, r, c))
                    if isinstance(v, float):
                        v = int(v) if v == int(v) and abs(v) < 1e15 else round(v, 6)
                    row.append("" if v is None else v)
                w.writerow(row)
    print("csv written", sys.argv[2])
