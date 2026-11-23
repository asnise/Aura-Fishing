--!strict
-- Aura rolling, equipping and VFX (GDD 5). Visuals are built from Config/Auras `Visual` data,
-- so new auras need no code. Swap in hand-made VFX later by putting a model named after the aura
-- id in ReplicatedStorage.AuraVFX (its Attachments/emitters get cloned onto the character).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Registry = require(Shared.Registry)
local Remotes = require(Shared.Remotes)
local Roll = require(Shared.Roll)
local Inventory = require(Shared.Inventory)
local BaitBinding = require(Shared.Items.BaitBinding)
local Format = require(Shared.Util.Format)
local AuraStars = require(Shared.AuraStars)
local Signal = require(Shared.Util.Signal)

local DataService = require(script.Parent.DataService)


local AuraService = {}
AuraService.Pulled = Signal.new() -- (player, bannerId, results { {Aura, New, Tokens} }) hook for quests/events

local rng = Random.new()
local VFX_NAME = "AuraVFX"

local function clearVFX(character: Model)
	for _, d in character:GetDescendants() do
		if d.Name == VFX_NAME then
			d:Destroy()
		end
	end
end

local function buildVFX(character: Model, auraId: string)
	clearVFX(character)
	local aura = Registry.Auras[auraId]
	local root = character:FindFirstChild("HumanoidRootPart")
	if not aura or not root then
		return
	end

	local custom = ReplicatedStorage:FindFirstChild("AuraVFX")
	local template = custom and custom:FindFirstChild(auraId)
	if template then
		for _, child in template:GetChildren() do
			local c = child:Clone()
			c.Name = VFX_NAME
			c.Parent = root
		end
		return
	end

	local v = aura.Visual
	local att = Instance.new("Attachment")
	att.Name = VFX_NAME
	att.Position = Vector3.new(0, -1.5, 0)
	att:SetAttribute("AuraId", auraId)
	att.Parent = root

	local pe = Instance.new("ParticleEmitter")
	pe.Name = "Particles"
	local c1 = v.Color[1]
	local c2 = v.Color[2] or c1
	pe.Color = ColorSequence.new(c1, c2)
	pe.Rate = v.Rate
	pe.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, v.Size),
		NumberSequenceKeypoint.new(1, 0),
	})
	pe.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.1),
		NumberSequenceKeypoint.new(1, 1),
	})
	pe.Lifetime = NumberRange.new(v.Lifetime * 0.7, v.Lifetime)
	pe.Speed = NumberRange.new(v.Speed * 0.5, v.Speed)
	pe.SpreadAngle = Vector2.new(180, 180)
	pe.Acceleration = Vector3.new(0, 2, 0)
	pe.LightEmission = v.LightEmission
	pe.Shape = Enum.ParticleEmitterShape.Cylinder
	pe.ShapeStyle = Enum.ParticleEmitterShapeStyle.Surface
	pe.ShapeInOut = Enum.ParticleEmitterShapeInOut.Outward
	if v.Spin then
		pe.RotSpeed = NumberRange.new(-180, 180)
		pe.Rotation = NumberRange.new(0, 360)
	end
	if v.Texture then
		pe.Texture = v.Texture
	end
	pe.Parent = att

	if v.Light then
		local light = Instance.new("PointLight")
		light.Color = c1
		light.Range = 10
		light.Brightness = 1.5
		light.Parent = att
	end
end

local function refresh(player: Player)
	local data = DataService.Get(player)
	local char = player.Character
	if not data or not char then
		return
	end
	if data.Auras.Equipped then
		buildVFX(char, data.Auras.Equipped)
	else
		clearVFX(char)
	end
end

local Banners = Registry.AuraBanners

local function tierOf(rarityId: string): number
	return Registry.Rarities[rarityId].Tier
end

function AuraService.BannerOpen(bannerId: string): boolean
	local b = Banners[bannerId]
	if not b then
		return false
	end
	local now = os.time()
	return (b.StartsUTC == nil or now >= b.StartsUTC) and (b.EndsUTC == nil or now < b.EndsUTC)
end

function AuraService.PullCost(bannerId: string, count: number): number
	local b = Banners[bannerId]
	return if count == 10 then math.floor(b.Cost * 10 * (1 - b.Ten.Discount) + 0.5) else b.Cost
end

local function announce(player: Player, auraId: string)
	local aura = Registry.Auras[auraId]
	local rarity = Registry.Rarities[aura.Rarity]
	if rarity.Tier >= 5 then
		task.delay(3.5, function()
			Remotes.Event("Notify"):FireAllClients(`{player.DisplayName} rolled {aura.Name} ({Format.Chance(aura.Chance)})!`, rarity.Color)
		end)
	end
end

-- Gives one aura. First copy = owned; a duplicate = Star Tokens (C17). Returns isNew, tokens.
function AuraService.GiveAura(data: any, auraId: string): (boolean, number)
	if (data.Auras.Owned[auraId] or 0) > 0 then
		local tokens = AuraStars.TokensFor(auraId)
		data.Auras.StarTokens += tokens
		return false, tokens
	end
	data.Auras.Owned[auraId] = 1
	return true, 0
end

-- Spend Star Tokens: owned aura Star +1. Returns ok, message, { Stars, StarTokens }
function AuraService.StarUp(player: Player, auraId: any): (boolean, string, any)
	local data = DataService.Get(player)
	if not data or type(auraId) ~= "string" or not Registry.Auras[auraId] then
		return false, "Invalid request", nil
	end
	if (data.Auras.Owned[auraId] or 0) <= 0 then
		return false, "Not owned", nil
	end
	local stars = AuraStars.Stars(data, auraId)
	local cost = AuraStars.Cost(auraId, stars)
	local function info()
		return { Stars = AuraStars.Stars(data, auraId), StarTokens = data.Auras.StarTokens }
	end
	if not cost then
		return false, `Already Star {stars} (MAX)`, info()
	end
	if data.Auras.StarTokens < cost then
		return false, `Need {cost} Star Tokens`, info()
	end
	data.Auras.StarTokens -= cost
	data.Auras.Stars[auraId] = stars + 1
	DataService.MarkDirty(player)
	return true, `{Registry.Auras[auraId].Name} Star {stars + 1}!`, info()
end

-- Pulls `count` (1 or 10) auras on a banner.
-- Pity: after PityPulls-1 pulls without PityRarity-or-better, the next pull is exactly PityRarity
-- (Legendary). HardPity: after HardPity.Pulls-1 pulls without HardPity.Rarity, the next is that (Mythic).
-- x10: if nothing Ten.MinRarity+ dropped, the last pull is re-rolled to at least that rarity.
-- Duplicates give Star Tokens instead of a second copy.
-- Returns ok, results { {Aura, New, Tokens} } | message, equippedId?
function AuraService.Pull(player: Player, bannerId: any, count: any): (boolean, any, string?)
	local data = DataService.Get(player)
	local b = if type(bannerId) == "string" then Banners[bannerId] else nil
	if not data or not b or (count ~= 1 and count ~= 10) then
		return false, "Invalid request"
	end
	if not AuraService.BannerOpen(bannerId) then
		return false, `{b.Name} has ended`
	end
	local cost = AuraService.PullCost(bannerId, count)
	if data[b.Currency] < cost then
		return false, `Need {cost} {b.Currency}`
	end
	data[b.Currency] -= cost
	local g = data.Gacha
	local pityTier = tierOf(b.PityRarity)
	local hardTier = if b.HardPity then tierOf(b.HardPity.Rarity) else nil
	local minTenTier = tierOf(b.Ten.MinRarity)
	local results = {}
	local bestTier = 0
	for i = 1, count do
		local pity = g.Pity[bannerId] or 0
		local hard = g.PityHard[bannerId] or 0
		local minTier, maxTier = nil, nil
		if hardTier and hard + 1 >= (b.HardPity :: any).Pulls then
			minTier, maxTier = hardTier, hardTier
		elseif pity + 1 >= b.PityPulls then
			minTier, maxTier = pityTier, pityTier
		elseif count == 10 and i == 10 and bestTier < minTenTier then
			minTier = minTenTier
		end
		local auraId = Roll.Aura(0, rng, b.RateUp, minTier, maxTier)
		local tier = tierOf(Registry.Auras[auraId].Rarity)
		bestTier = math.max(bestTier, tier)
		g.Pity[bannerId] = if tier >= pityTier then 0 else pity + 1
		if hardTier then
			g.PityHard[bannerId] = if tier >= hardTier then 0 else hard + 1
		end
		g.Pulls[bannerId] = (g.Pulls[bannerId] or 0) + 1
		data.Auras.TotalRolls += 1
		local isNew, tokens = AuraService.GiveAura(data, auraId)
		table.insert(results, { Aura = auraId, New = isNew, Tokens = tokens })
		-- auto-equip if rarer than current
		local current = data.Auras.Equipped and Registry.Auras[data.Auras.Equipped]
		if not current or Registry.Auras[auraId].Chance > current.Chance then
			data.Auras.Equipped = auraId
		end
		announce(player, auraId)
	end
	refresh(player)
	DataService.MarkDirty(player)
	AuraService.Pulled:Fire(player, bannerId, results)
	return true, results, data.Auras.Equipped
end

-- Legacy single roll on the Altar banner: ok, auraId | message, isNew, equippedNow
function AuraService.Roll(player: Player): (boolean, string, boolean?, boolean?)
	local ok, res, equipped = AuraService.Pull(player, "Altar", 1)
	if not ok then
		return false, res
	end
	local r = res[1]
	return true, r.Aura, r.New, equipped == r.Aura
end

-- Milestone reward on an event banner (Config/AuraBanners Milestones) once total pulls reach it.
function AuraService.ClaimMilestone(player: Player, bannerId: any, pulls: any): (boolean, string)
	local data = DataService.Get(player)
	local b = if type(bannerId) == "string" then Banners[bannerId] else nil
	if not data or not b or not b.Milestones then
		return false, "Invalid request"
	end
	local m
	for _, x in b.Milestones do
		if x.Pulls == pulls then
			m = x
		end
	end
	if not m then
		return false, "Invalid request"
	end
	local g = data.Gacha
	g.Claimed[bannerId] = g.Claimed[bannerId] or {}
	local key = tostring(m.Pulls)
	if g.Claimed[bannerId][key] then
		return false, "Already claimed"
	end
	if (g.Pulls[bannerId] or 0) < m.Pulls then
		return false, `Reach {m.Pulls} pulls first`
	end
	g.Claimed[bannerId][key] = true
	local msg
	if m.Kind == "Gems" or m.Kind == "Coins" then
		data[m.Kind] += m.Amount :: number
		msg = `+{m.Amount} {string.lower(m.Kind)}`
	elseif m.Kind == "Bait" then
		local id = m.Id :: string
		BaitBinding.Add(data, id, m.Amount or 1, true)
		msg = `+{m.Amount or 1} {Registry.Equipment.Baits.Items[id].Name}`
	elseif m.Kind == "Treasure" then
		local given = 0
		for _ = 1, m.Amount or 1 do
			if Inventory.AddTreasure(data, m.Id :: string, true) then
				given += 1
			end
		end
		if given < (m.Amount or 1) then
			g.Claimed[bannerId][key] = nil -- bag full: undo so it can be claimed later
			for _ = 1, given do
				for i, s in data.Bag do
					if s.Kind == "Treasure" and s.Id == m.Id then
						s.Count -= 1
						if s.Count <= 0 then
							table.remove(data.Bag, i)
						end
						break
					end
				end
			end
			return false, "Your bag is full - make room first"
		end
		msg = `+{m.Amount} {Registry.Treasures[m.Id :: string].Name}`
	else
		local id = m.Id :: string
		local isNew, tokens = AuraService.GiveAura(data, id)
		msg = if isNew then `{Registry.Auras[id].Name} aura!` else `{Registry.Auras[id].Name} (duplicate: +{tokens} Star Tokens)`
	end
	DataService.MarkDirty(player)
	return true, `Milestone {m.Pulls}: {msg}`
end

function AuraService.Equip(player: Player, auraId: any): (boolean, string)
	local data = DataService.Get(player)
	if not data then
		return false, "Invalid request"
	end
	if auraId == nil then
		data.Auras.Equipped = nil
	elseif type(auraId) == "string" and (data.Auras.Owned[auraId] or 0) > 0 then
		data.Auras.Equipped = auraId
	else
		return false, "Not owned"
	end
	refresh(player)
	DataService.MarkDirty(player)
	return true, "OK"
end

function AuraService.Init()
	local lastRoll: { [Player]: number } = {}
	local function canRoll(player: Player): boolean
		local now = os.clock()
		if lastRoll[player] and now - lastRoll[player] < 0.4 then
			return false
		end
		lastRoll[player] = now
		return true
	end

	Remotes.Func("RollAura").OnServerInvoke = function(player)
		if not canRoll(player) then
			return false, "Slow down"
		end
		return AuraService.Roll(player)
	end
	Remotes.Func("PullAura").OnServerInvoke = function(player, bannerId, count)
		if not canRoll(player) then
			return false, "Slow down"
		end
		return AuraService.Pull(player, bannerId, count)
	end
	Remotes.Func("ClaimMilestone").OnServerInvoke = function(player, bannerId, pulls)
		if not canRoll(player) then
			return false, "Slow down"
		end
		return AuraService.ClaimMilestone(player, bannerId, pulls)
	end
	Remotes.Func("EquipAura").OnServerInvoke = function(player, auraId)
		return AuraService.Equip(player, auraId)
	end
	Remotes.Func("StarUpAura").OnServerInvoke = function(player, auraId)
		if not canRoll(player) then
			return false, "Slow down", nil
		end
		return AuraService.StarUp(player, auraId)
	end

	local function onPlayer(player: Player)
		player.CharacterAdded:Connect(function(char)
			char:WaitForChild("HumanoidRootPart", 10)
			DataService.WaitFor(player)
			refresh(player)
		end)
		if player.Character then
			task.spawn(function()
				DataService.WaitFor(player)
				refresh(player)
			end)
		end
	end
	Players.PlayerAdded:Connect(onPlayer)
	for _, p in Players:GetPlayers() do
		onPlayer(p)
	end
	Players.PlayerRemoving:Connect(function(p)
		lastRoll[p] = nil
	end)

	-- World altar prompt
	task.spawn(function()
		local map = Workspace:WaitForChild("Map", 30)
		local altar = map and map:FindFirstChild("AuraAltar", true)
		local prompt = altar and altar:FindFirstChild("RollPrompt")
		if prompt and prompt:IsA("ProximityPrompt") then
			-- B7: talk to Sela (Config/Dialogues.Sela); "Open the Altar" opens the gacha page client-side
			local npc = Registry.Dialogues.Sela
			if npc then
				prompt.ActionText = "Talk"
				prompt.ObjectText = npc.Name
			end
			prompt.Triggered:Connect(function(player)
				if not canRoll(player) then
					return
				end
				if npc then
					Remotes.Event("OpenDialogue"):FireClient(player, "Sela")
				else
					-- the altar opens the Aura Altar gacha page (pity, x1/x10, rates); pulls go through PullAura
					Remotes.Event("OpenBanner"):FireClient(player, "Altar")
				end
			end)
		end
	end)
end

return AuraService
