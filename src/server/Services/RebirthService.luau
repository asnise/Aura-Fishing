--!strict
-- Rebirth (C3, GDD 7.2). Config: Features.Rebirth. Maths: Shared/Rebirth.
-- Remote "Rebirth"() -> ok, message. What resets / stays: see Features.Rebirth.
-- Title + count are put on the Player as attributes ("Title", "Rebirths") so every client can draw
-- the title over the head (TitleController).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Registry = require(Shared.Registry)
local Remotes = require(Shared.Remotes)
local Rebirth = require(Shared.Rebirth)
local Signal = require(Shared.Util.Signal)

local DataService = require(script.Parent.DataService)

local GameConfig = Registry.GameConfig

local RebirthService = {}
RebirthService.Reborn = Signal.new() -- (player, newCount)

local function applyAttributes(player: Player, data: any)
	local n = Rebirth.Count(data)
	player:SetAttribute("Rebirths", if n > 0 then n else nil)
	player:SetAttribute("Title", Rebirth.Title(n))
end

function RebirthService.Rebirth(player: Player): (boolean, string)
	local data = DataService.Get(player)
	if not data then
		return false, "Profile not loaded"
	end
	if not Registry.Features.Rebirth.Enabled then
		return false, Registry.Features.Rebirth.Notice
	end
	local need = Rebirth.RequiredLevel(data)
	if data.Level < need then
		return false, `Reach Lv.{need} to rebirth (you are Lv.{data.Level})`
	end

	-- Reset
	data.Level = 1
	data.XP = 0
	data.Coins = GameConfig.StartingCoins
	local keep = {}
	for _, s in data.Bag do
		if s.Kind ~= "Fish" then
			table.insert(keep, s) -- treasure chests stay
		end
	end
	data.Bag = keep

	data.Rebirths = Rebirth.Count(data) + 1
	data.Lifetime.Rebirths = data.Rebirths
	applyAttributes(player, data)
	DataService.MarkDirty(player)
	RebirthService.Reborn:Fire(player, data.Rebirths)

	local title = Rebirth.Title(data.Rebirths)
	local mult = 1 + Rebirth.Bonus(data.Rebirths)
	Remotes.Event("Notify"):FireAllClients(
		`{player.DisplayName} was reborn! (Rebirth {data.Rebirths}{if title then ` · {title}` else ""})`,
		Color3.fromRGB(242, 181, 68)
	)
	return true, `Reborn! Coins and Pearls now x{mult}.`
end

-- Dev: set the rebirth count directly.
function RebirthService.SetCount(player: Player, n: number)
	local data = DataService.Get(player)
	if data then
		data.Rebirths = math.max(0, n)
		applyAttributes(player, data)
		DataService.MarkDirty(player)
	end
end

function RebirthService.Init()
	Remotes.Func("Rebirth").OnServerInvoke = function(player)
		return RebirthService.Rebirth(player)
	end
	DataService.ProfileLoaded:Connect(function(player, data)
		applyAttributes(player, data)
	end)
	for _, player in Players:GetPlayers() do
		local data = DataService.Get(player)
		if data then
			applyAttributes(player, data)
		end
	end
end

return RebirthService
