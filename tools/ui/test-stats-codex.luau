local Codex = require("../../src/client/UI/StatsCodexEntries")
local StatDefs = require("../../src/shared/Config/StatDefs")
local ModifierDefs = require("../../src/shared/Config/ModifierDefs")

local entries = Codex.Build(StatDefs, ModifierDefs, {
	TestMutation = { Name = "Test Mutation", BaseChance = 0, ValueMultiplier = 2 },
})
local byId = {}
for _, entry in entries do
	assert(not byId[entry.Id], "Duplicate Codex entry " .. entry.Id)
	byId[entry.Id] = entry
end

for id, stat in StatDefs do
	assert(byId[id].Title == stat.Display and #byId[id].Effect > 30, id)
end
for _, definitions in { ModifierDefs.Prefixes, ModifierDefs.Suffixes } do
	for _, mod in definitions do
		local entry = byId[mod.Id]
		assert(entry.Title == mod.Name and entry.Category == "Rod Mods", mod.Id)
		assert(Codex.Matches(entry, "Rod Mods", mod.Stat), mod.Stat)
	end
end

assert(Codex.Matches(byId.AutoSpeed, "All", "  AUTO wait "))
assert(not Codex.Matches(byId.AutoSpeed, "Attributes", "Auto Wait"))
assert(not Codex.Matches(byId.AutoSpeed, "All", "%["))
assert(Codex.Matches(byId.MaxAutoSpeed, "All", "auto wait cap"))
assert(byId.TestMutation and byId.BagCapacity, "Item attributes must be available")
print("Stats Codex coverage and search passed")
