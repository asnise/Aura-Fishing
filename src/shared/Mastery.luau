--!strict
-- Mastery maths (C15), shared by server and client. Content: Config/Mastery.
--   profile.Mastery = { [trackId] = level }   (missing = 0)
-- Stats.Collect adds Mastery.Source(profile) as one stat source.
-- Requires only Registry (Stats requires this module, so no Stats here).

local Registry = require(script.Parent.Registry)

local CFG = Registry.Mastery

-- What the UI shows (contract with the UI session, docs/HANDOFF_ECONOMY_UI.md).
export type TrackState = {
	Id: string,
	Name: string,
	Stat: string,
	Level: number,
	Current: number, -- bonus now (stat units, format with Format.Stat)
	Next: number?, -- bonus after the next level, nil = max
	Price: number?, -- Pearls for the next level, nil = max
	Icon: string?, -- UIAssets key (Config/Mastery)
	IconTile: string?, -- New.Theme colour name behind a white icon; nil = white tile
}

local Mastery = {}

function Mastery.Level(profile: any, trackId: string): number
	return (profile.Mastery and profile.Mastery[trackId]) or 0
end

function Mastery.Bonus(trackId: string, level: number): number
	local t = CFG.Tracks[trackId]
	if not t or level <= 0 then
		return 0
	end
	if t.Curve == "Diminishing" then
		return (t.MaxBonus :: number) * (1 - (t.Decay :: number) ^ level)
	end
	return (t.PerLevel :: number) * level
end

-- Pearls for going from `level` to level + 1; nil at MaxLevel.
function Mastery.Price(trackId: string, level: number): number?
	local t = CFG.Tracks[trackId]
	if not t or (t.MaxLevel and level >= t.MaxLevel) then
		return nil
	end
	return math.floor(t.BasePrice * CFG.PriceGrowth ^ level)
end

-- One stat source with every track's bonus.
function Mastery.Source(profile: any): { Stats: { [string]: number } }
	local stats: { [string]: number } = {}
	for id, t in CFG.Tracks do
		local b = Mastery.Bonus(id, Mastery.Level(profile, id))
		if b ~= 0 then
			stats[t.Stat] = (stats[t.Stat] or 0) + b
		end
	end
	return { Stats = stats }
end

function Mastery.SortedIds(): { string }
	local ids = {}
	for id in CFG.Tracks do
		table.insert(ids, id)
	end
	table.sort(ids, function(a, b)
		return CFG.Tracks[a].Order < CFG.Tracks[b].Order
	end)
	return ids
end

function Mastery.Tracks(profile: any): { TrackState }
	local out = {}
	for _, id in Mastery.SortedIds() do
		local t = CFG.Tracks[id]
		local lv = Mastery.Level(profile, id)
		local price = Mastery.Price(id, lv)
		table.insert(out, {
			Id = id,
			Name = t.Name,
			Stat = t.Stat,
			Level = lv,
			Current = Mastery.Bonus(id, lv),
			Next = if price then Mastery.Bonus(id, lv + 1) else nil,
			Price = price,
			Icon = t.Icon,
			IconTile = t.IconTile,
		})
	end
	return out
end

function Mastery.TotalLevel(profile: any): number
	local n = 0
	for id in CFG.Tracks do
		n += Mastery.Level(profile, id)
	end
	return n
end

return Mastery
