local Motion = require("../../src/client/UI/AuraRevealMotion")

local epic = Motion.ForTier(4)
local legendary = Motion.ForTier(5)
local mythic = Motion.ForTier(6)

assert(Motion.Sample(legendary.Background, 0) == 0, "Backdrop must start transparent")
assert(Motion.Sample(legendary.Background, 0.36) == 1, "Backdrop must reach black in 0.36 seconds")
assert(Motion.Sample(legendary.SparkleScale, 0.55) == 10, "Sparkle must reach 10x")
assert(legendary.RimScale and mythic.RimScale and not epic.RimScale, "Eclipse applies to Legendary and Mythic")
assert(legendary.RevealAt == 1.96 and mythic.RevealAt == 2.36, "Match the selected Figma reveal timings")
assert(Motion.Sample(mythic.WaveScale, 3) > Motion.Sample(legendary.WaveScale, 3), "Mythic must expand farther")
assert(Motion.Sample(mythic.Overlay, 2.25) > Motion.Sample(legendary.Overlay, 1.85), "Mythic overlay must peak higher")
print("Aura reveal timings passed")
