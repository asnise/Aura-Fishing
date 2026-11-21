--!strict
-- Map edges ("endless sea" feel without letting players leave). A play area = a Part tagged
-- "PlayArea" (built by tools/map/boardwalk.luau). Its position is the centre; attributes:
--   Soft   (studs)   past this a current starts pushing you back (client, BoundaryController)
--   Hard   (studs)   the push is stronger than swimming here, so you can't really get further
--   Reach  (studs)   the area only applies within this distance (other maps far away are unaffected)
--   ReturnTo (Vector3) where the server puts you if you still end up past Hard (+ margin)
-- Distances are flat (X/Z). Several areas may exist; the nearest one in Reach applies.

local CollectionService = game:GetService("CollectionService")
local Workspace = game:GetService("Workspace")

export type Area = {
	Center: Vector3,
	Soft: number,
	Hard: number,
	Reach: number,
	ReturnTo: Vector3?,
}

local PlayArea = {}

PlayArea.Tag = "PlayArea"
PlayArea.ReturnMargin = 40 -- server only returns you this far past Hard (the current normally stops you first)

local function flat(v: Vector3): Vector3
	return Vector3.new(v.X, 0, v.Z)
end

-- The area at `pos` (nearest centre within its Reach) and the flat distance from its centre.
function PlayArea.At(pos: Vector3): (Area?, number)
	local best: Area? = nil
	local bestD = math.huge
	for _, inst in CollectionService:GetTagged(PlayArea.Tag) do
		-- Workspace only: a backup map in ServerStorage must not move the play area
		if inst:IsA("BasePart") and inst:IsDescendantOf(Workspace) then
			local d = (flat(pos) - flat(inst.Position)).Magnitude
			local reach = (inst:GetAttribute("Reach") :: number?) or 1000
			if d <= reach and d < bestD then
				bestD = d
				best = {
					Center = inst.Position,
					Soft = (inst:GetAttribute("Soft") :: number?) or 500,
					Hard = (inst:GetAttribute("Hard") :: number?) or 600,
					Reach = reach,
					ReturnTo = inst:GetAttribute("ReturnTo") :: Vector3?,
				}
			end
		end
	end
	return best, bestD
end

-- 0 inside Soft, rising to 1 at Hard (and a bit above past it).
function PlayArea.Strength(area: Area, d: number): number
	if d <= area.Soft then
		return 0
	end
	return math.min(1.5, (d - area.Soft) / math.max(1, area.Hard - area.Soft))
end

-- Flat unit vector from `pos` back toward the area centre.
function PlayArea.HomeDir(area: Area, pos: Vector3): Vector3
	local v = flat(area.Center) - flat(pos)
	return if v.Magnitude > 0.01 then v.Unit else Vector3.zero
end

return PlayArea
