--!strict
-- Skill maths (C4), shared by server and client. Config: Config/Skills.
--   profile.Skills = { Points = unspent, Levels = { [skillId] = level } }
-- Requires only Registry (Stats requires this module).

local Registry = require(script.Parent.Registry)

local CFG = Registry.Skills

export type SkillState = {
	Id: string,
	Name: string,
	Stat: string,
	Description: string,
	Level: number,
	MaxLevel: number,
	Current: number, -- stat bonus now
	Next: number?, -- after the next level, nil = MAX
	Cost: number?, -- points for the next level, nil = MAX
	Icon: string?,
}

local Skills = {}

function Skills.Points(profile: any): number
	return (profile.Skills and profile.Skills.Points) or 0
end

function Skills.Level(profile: any, id: string): number
	return (profile.Skills and profile.Skills.Levels[id]) or 0
end

-- Points for going from `level` to level + 1; nil at max.
function Skills.Cost(id: string, level: number): number?
	local s = CFG.List[id]
	if not s or level >= s.MaxLevel then
		return nil
	end
	if s.Costs then
		return s.Costs[level + 1]
	end
	return (s.CostBase or 1) + math.floor(level / (s.CostStep or math.huge))
end

function Skills.Bonus(id: string, level: number): number
	local s = CFG.List[id]
	return if s then s.PerLevel * math.max(0, level) else 0
end

function Skills.Source(profile: any): { Stats: { [string]: number } }
	local stats: { [string]: number } = {}
	for id, s in CFG.List do
		local b = Skills.Bonus(id, Skills.Level(profile, id))
		if b ~= 0 then
			stats[s.Stat] = (stats[s.Stat] or 0) + b
		end
	end
	return { Stats = stats }
end

function Skills.State(profile: any): { SkillState }
	local ids = {}
	for id in CFG.List do
		table.insert(ids, id)
	end
	table.sort(ids, function(a, b)
		return CFG.List[a].Order < CFG.List[b].Order
	end)
	local out = {}
	for _, id in ids do
		local s = CFG.List[id]
		local lv = Skills.Level(profile, id)
		local cost = Skills.Cost(id, lv)
		table.insert(out, {
			Id = id,
			Name = s.Name,
			Stat = s.Stat,
			Description = s.Description,
			Level = lv,
			MaxLevel = s.MaxLevel,
			Current = Skills.Bonus(id, lv),
			Next = if cost then Skills.Bonus(id, lv + 1) else nil,
			Cost = cost,
			Icon = s.Icon,
		})
	end
	return out
end

return Skills
