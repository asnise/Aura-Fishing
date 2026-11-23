--!strict
-- Keep the total used by gameplay and track the bound portion of each stack.
local BaitBinding = {}

function BaitBinding.Free(profile: any, id: string): number
	return math.max(0, (profile.Consumables.Baits[id] or 0) - (profile.BoundBaits[id] or 0))
end

function BaitBinding.Bind(profile: any, id: string)
	profile.BoundBaits[id] = profile.Consumables.Baits[id] or 0
end

function BaitBinding.Add(profile: any, id: string, count: number, bound: boolean?)
	local total = math.max(0, (profile.Consumables.Baits[id] or 0) + count)
	profile.Consumables.Baits[id] = total
	if profile.Equipped.Baits == id then
		BaitBinding.Bind(profile, id)
	else
		local addedBound = if bound then math.max(0, count) else 0
		profile.BoundBaits[id] = math.min(total, (profile.BoundBaits[id] or 0) + addedBound)
	end
end

function BaitBinding.RemoveBound(profile: any, id: string, count: number)
	local bound = profile.BoundBaits[id] or 0
	local removed = math.min(count, bound)
	profile.Consumables.Baits[id] = math.max(0, (profile.Consumables.Baits[id] or 0) - removed)
	profile.BoundBaits[id] = bound - removed
end

function BaitBinding.Consume(profile: any, id: string)
	if (profile.Consumables.Baits[id] or 0) > 0 then
		BaitBinding.Bind(profile, id)
		BaitBinding.RemoveBound(profile, id, 1)
	end
end

function BaitBinding.Migrate(profile: any)
	-- Existing totals mix purchases and gifts, so their provenance cannot be recovered.
	profile.BoundBaits = table.clone(profile.Consumables.Baits)
end

return BaitBinding
