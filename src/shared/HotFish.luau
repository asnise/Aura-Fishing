--!strict
-- Hot fish at the Merchant (C18), shared by server and client. Config: GameConfig.HotFish.
-- The list is worked out from the current UTC period + Seed, so every server and every client gets
-- the same answer without any network sync. A Dev override (ReplicatedStorage attribute
-- "HotFishOverride", JSON list, set by the server) wins while it has not ended.
--
--   HotFish.Current() -> { {FishId, Mult, EndsAt} }   (EndsAt = os.time() of the next change)
--   HotFish.Mult(fishId) -> 1 or the hot multiplier

local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Registry = require(script.Parent.Registry)

local CFG = Registry.GameConfig.HotFish

export type Entry = { FishId: string, Mult: number, EndsAt: number }

local HotFish = {}

HotFish.OVERRIDE_ATTRIBUTE = "HotFishOverride"

local pool: { string } = {}
do
	local allowed: { [string]: boolean } = {}
	for _, r in CFG.Rarities do
		allowed[r] = true
	end
	for id, f in Registry.Fish do
		if allowed[f.Rarity] then
			table.insert(pool, id)
		end
	end
	table.sort(pool) -- same order everywhere
end

function HotFish.Period(now: number?): number
	return math.floor((now or os.time()) / (CFG.IntervalMinutes * 60))
end

-- Scheduled list for a period (no override).
function HotFish.ForPeriod(period: number): { Entry }
	local rng = Random.new(CFG.Seed * 100003 + period)
	local ends = (period + 1) * CFG.IntervalMinutes * 60
	local left = table.clone(pool)
	local list: { Entry } = {}
	local n = rng:NextInteger(CFG.Count[1], CFG.Count[2])
	for _ = 1, math.min(n, #left) do
		local id = table.remove(left, rng:NextInteger(1, #left)) :: string
		table.insert(list, { FishId = id, Mult = CFG.Mults[rng:NextInteger(1, #CFG.Mults)], EndsAt = ends })
	end
	return list
end

local function override(now: number): { Entry }?
	local raw = ReplicatedStorage:GetAttribute(HotFish.OVERRIDE_ATTRIBUTE)
	if type(raw) ~= "string" or raw == "" then
		return nil
	end
	local ok, list = pcall(function()
		return HttpService:JSONDecode(raw)
	end)
	if not ok or type(list) ~= "table" or #list == 0 or (list[1].EndsAt or 0) <= now then
		return nil
	end
	return list
end

function HotFish.Current(now: number?): { Entry }
	local t = now or os.time()
	return override(t) or HotFish.ForPeriod(HotFish.Period(t))
end

function HotFish.Mult(fishId: string, now: number?): number
	for _, e in HotFish.Current(now) do
		if e.FishId == fishId then
			return e.Mult
		end
	end
	return 1
end

-- Short key that changes whenever the list changes (server broadcasts on change).
function HotFish.Key(now: number?): string
	local parts = {}
	for _, e in HotFish.Current(now) do
		table.insert(parts, `{e.FishId}x{e.Mult}@{e.EndsAt}`)
	end
	return table.concat(parts, ",")
end

return HotFish
