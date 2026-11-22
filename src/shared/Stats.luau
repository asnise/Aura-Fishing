--!strict
-- Computes a player's final stats from their profile. Used by the server for gameplay and
-- by the client for UI display, so both always agree.
--
-- Stat sources (in order): StatDefs.Base, equipped items of each Equipment category (the worn rod/line
-- are bag items: scaled by their own Enhance level, rods add their Prefix/Suffix mods),
-- equipped bait (if any left), equipped aura, owned Game Passes (profile.Passes, Config/Products),
-- Mastery levels (profile.Mastery, Config/Mastery), Rebirth multiplier (profile.Rebirths, Features.Rebirth),
-- skills (profile.Skills, Config/Skills),
-- then any `extraSources` (buffs, skills, events... add them here as new systems arrive).

local Registry = require(script.Parent.Registry)
local Mastery = require(script.Parent.Mastery)
local Inventory = require(script.Parent.Items.ItemContainer)
local AuraStars = require(script.Parent.AuraStars)
local Rebirth = require(script.Parent.Rebirth)
local Skills = require(script.Parent.Skills)

export type ComputedStats = {
	Values: { [string]: number },
	MutationBonus: { [string]: number },
}

export type StatSource = {
	Stats: { [string]: number }?,
	Mutations: { [string]: number }?,
}

local Stats = {}

function Stats.Collect(profile: any): { StatSource }
	local sources: { StatSource } = {}
	for catId, cat in Registry.Equipment do
		if Inventory.IsGearCategory(catId) then
			local worn = Inventory.Worn(profile, catId)
			if worn then
				table.insert(sources, { Stats = Inventory.GearStats(worn) })
				table.insert(sources, { Stats = Inventory.ModStats(worn) })
			end
		else
			local equippedId = profile.Equipped[catId]
			local item = equippedId and cat.Items[equippedId]
			if item then
				if cat.Kind == "Consumable" then
					local left = profile.Consumables[catId] and profile.Consumables[catId][equippedId] or 0
					if left <= 0 then
						item = nil
					end
				end
				if item then
					table.insert(sources, item :: any)
				end
			end
		end
	end
	local auraId = profile.Auras.Equipped
	if auraId and Registry.Auras[auraId] then
		local aura = Registry.Auras[auraId]
		local stars = AuraStars.Stars(profile, auraId)
		if stars > 0 then
			-- Stars scale Stats (C17); mutation bonuses stay as they are
			table.insert(sources, { Stats = AuraStars.ScaledStats(aura.Stats, stars), Mutations = aura.Mutations })
		else
			table.insert(sources, aura :: any)
		end
	end
	if profile.Passes then
		for passId in profile.Passes do
			local pass = Registry.Products.Passes[passId]
			if pass then
				table.insert(sources, pass :: any)
			end
		end
	end
	if profile.Mastery then
		table.insert(sources, Mastery.Source(profile) :: any)
	end
	if (profile.Rebirths or 0) > 0 then
		table.insert(sources, Rebirth.Source(profile) :: any)
	end
	if profile.Skills then
		table.insert(sources, Skills.Source(profile) :: any)
	end
	return sources
end

function Stats.Compute(profile: any, extraSources: { StatSource }?): ComputedStats
	local values: { [string]: number } = {}
	for name, def in Registry.StatDefs do
		values[name] = def.Base
	end
	local mutationBonus: { [string]: number } = {}

	local sources = Stats.Collect(profile)
	if extraSources then
		for _, s in extraSources do
			table.insert(sources, s)
		end
	end

	for _, source in sources do
		if source.Stats then
			for stat, v in source.Stats do
				values[stat] = (values[stat] or 0) + v
			end
		end
		if source.Mutations then
			for m, v in source.Mutations do
				mutationBonus[m] = (mutationBonus[m] or 0) + v
			end
		end
	end

	for name, def in Registry.StatDefs do
		local v = values[name]
		if def.Min then
			v = math.max(def.Min, v)
		end
		if def.Max then
			v = math.min(def.Max, v)
		end
		values[name] = v
	end

	return { Values = values, MutationBonus = mutationBonus }
end

return Stats
