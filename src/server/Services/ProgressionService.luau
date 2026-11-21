--!strict
-- XP, levels and level-up rewards (+ skill points, C4). Skills: Config/Skills, Shared/Skills.
-- Rebirth: RebirthService.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Registry = require(Shared.Registry)
local Remotes = require(Shared.Remotes)
local Skills = require(Shared.Skills)
local DataService = require(script.Parent.DataService)

local GameConfig = Registry.GameConfig

local ProgressionService = {}

-- Returns number of levels gained.
function ProgressionService.AddXP(player: Player, amount: number): number
	local data = DataService.Get(player)
	if not data then
		return 0
	end
	data.XP += math.floor(amount)
	local gained = 0
	while data.XP >= GameConfig.XPForLevel(data.Level) do
		data.XP -= GameConfig.XPForLevel(data.Level)
		data.Level += 1
		data.Gems += GameConfig.GemsPerLevel
		data.Skills.Points += Registry.Skills.PointsPerLevel
		gained += 1
	end
	DataService.MarkDirty(player)
	return gained
end

-- Spend skill points: skill +1 level. Returns ok, message, { Points, Skills = Skills.State }
function ProgressionService.UpgradeSkill(player: Player, skillId: any): (boolean, string, any)
	local data = DataService.Get(player)
	if not data or type(skillId) ~= "string" or not Registry.Skills.List[skillId] then
		return false, "Unknown skill", nil
	end
	local function info()
		return { Points = Skills.Points(data), Skills = Skills.State(data) }
	end
	local level = Skills.Level(data, skillId)
	local cost = Skills.Cost(skillId, level)
	local name = Registry.Skills.List[skillId].Name
	if not cost then
		return false, `{name} is at max level`, info()
	end
	if data.Skills.Points < cost then
		return false, `Need {cost} skill points`, info()
	end
	data.Skills.Points -= cost
	data.Skills.Levels[skillId] = level + 1
	DataService.MarkDirty(player)
	return true, `{name} Lv.{level + 1}!`, info()
end

function ProgressionService.Init()
	Remotes.Func("UpgradeSkill").OnServerInvoke = function(player, skillId)
		return ProgressionService.UpgradeSkill(player, skillId)
	end
end

return ProgressionService
