--!strict
-- Declares every network endpoint in one place. The server creates them; the client waits.
-- Add a remote = add its name below, then use Remotes.Event("Name") / Remotes.Func("Name").

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local EVENTS = {
	-- server -> client
	"TradeUpdate", -- (state?, notice?) private session snapshot for each participant
	"DataSync", -- (profileSnapshot)
	"PlaySound", -- (soundId, position?) server asks this client to play a Config/Sounds entry (SoundController)
	"Bite", -- (token, { Rarity })
	"FishingState", -- (state: "Idle" | "Waiting" | "Bite" | "Reeling", info)
	"StartMinigame", -- (token, params)
	"CatchResult", -- (result)
	"Notify", -- (text, color?)
	"AuraRolled", -- (auraId, isNew, equipped) altar roll -> play the reel reveal (legacy)
	"OpenBanner", -- (bannerId) server asks the client to open a gacha page (Aura Altar prompt)
	"TideEvent", -- (snapshot) tide event state, all clients (C5, TideEventService)
	"HotFish", -- ({ {FishId, Mult, EndsAt} }) hot fish list on join + whenever it changes (C18; also Shared/HotFish.Current())
	"OfflineReward", -- ({ Seconds, Credited, Pearls, Capped, CapHours }) Pearls earned while away (popup)
	"Streak", -- ({ Streak, Bonus, Lost }) Hot Streak changed (manual catch / snapped line / missed bite)
	-- client -> server
	"ClientReady", -- () client listeners are connected; resend snapshot
	"Cast", -- (depth)
	"Hook", -- (token)
	"ReelResult", -- (token, success, perfect)
	"CancelFishing", -- ()
	"SetAuto", -- (enabled)
	"BagSeen", -- ({newToken}) acknowledges the displayed or clicked bag items
	"PromptPass", -- (passKey) open the Roblox buy dialog for a Game Pass (Config/Products.Passes)
	"PromptProduct", -- (productKey) open the Roblox buy dialog for a Developer Product
	"OpenDialogue", -- (npcId) server -> client: a world NPC prompt was used (Config/Dialogues, B7)
}

local FUNCTIONS = {
	"TradeAction", -- (action, request) -> ok, message
	"Buy", -- (categoryId, itemId) -> ok, message
	"Equip", -- (categoryId, itemId | uuid for Rods/Lines) -> ok, message
	"SellAll", -- () -> ok, message   (fish only; chests, rods and lines stay)
	"SellItem", -- (uuid, confirmed?) -> ok, message   sell one fish or one spare Rod / Line (+N or modded gear needs confirmed = true)
	"OpenTreasure", -- (uuid) -> ok, message, reward { Kind, Amount?, Id? }   open one chest
	"OpenAllTreasure", -- (uuid) -> ok, message, rewardSummary   open entire chest stack
	"RollAura", -- () -> ok, auraId | message   (legacy x1 on the Altar banner)
	"PullAura", -- (bannerId, count 1|10) -> ok, results {auraId, isNew}[] | message, equippedId?
	"ClaimMilestone", -- (bannerId, pulls) -> ok, message
	"DevCommand", -- (line) -> ok, message   dev/admin only (Config/Dev); "ping" tells the client if it may open the Dev panel
	"EquipAura", -- (auraId?) -> ok, message
	"UpgradeSkill", -- (skillId) -> ok, message, { Points, Skills = Skills.State(profile) }   C4
	"Rebirth", -- () -> ok, message   (Features.Rebirth; level check on the server)
	"ClaimQuest", -- (index) -> ok, message, Quests.State(profile)   daily quest reward (Gems)
	"StarUpAura", -- (auraId) -> ok, message, { Stars, StarTokens }   spend Star Tokens: Star +1
	"SetSetting", -- (key, value) -> ok
	"PutInTank", -- ({ {Id, Mutation, Count} }) -> { ok, reason?, Aquarium = State }   all or nothing
	"TakeFromTank", -- (uid) -> { ok, reason?, Aquarium = State }   fish goes back to the bag
	"FuseRods", -- (baseUuid, materialUuid, "Prefixes"|"Suffixes", baseSlot, materialSlot, guard?) -> ok, message, { Success, Coins, Pearls, Gems }   Rod Fusion
	"Enhance", -- (uuid) -> ok, message, state = Enhance.State   one Rod/Line item +1
	"UpgradeMastery", -- (trackId) -> { ok, reason?, Tracks = Mastery.Tracks(profile), Pearls }
	"BuyTankSlot", -- () -> { ok, reason?, Aquarium = State }   Coins, price = Aquarium.NextSlotPrice
	"ClaimDailyLogin", -- () -> ok, message, state = DailyLoginState   claim today's daily reward
}

local FOLDER_NAME = "Remotes"

local Remotes = {}

local folder: Folder
if RunService:IsServer() or not RunService:IsRunning() then -- Edit mode (bake / preview) also builds the folder; IsEdit() is not callable from client scripts
	local existing = ReplicatedStorage:FindFirstChild(FOLDER_NAME)
	if existing then
		folder = existing :: Folder
	else
		folder = Instance.new("Folder")
		folder.Name = FOLDER_NAME
		folder.Parent = ReplicatedStorage
	end
	for _, name in EVENTS do
		if not folder:FindFirstChild(name) then
			local e = Instance.new("RemoteEvent")
			e.Name = name
			e.Parent = folder
		end
	end
	for _, name in FUNCTIONS do
		if not folder:FindFirstChild(name) then
			local f = Instance.new("RemoteFunction")
			f.Name = name
			f.Parent = folder
		end
	end
else
	folder = ReplicatedStorage:WaitForChild(FOLDER_NAME) :: Folder
end

function Remotes.Event(name: string): RemoteEvent
	assert(table.find(EVENTS, name), `Unknown RemoteEvent '{name}' (declare it in Remotes.luau)`)
	return folder:WaitForChild(name) :: RemoteEvent
end

function Remotes.Func(name: string): RemoteFunction
	assert(table.find(FUNCTIONS, name), `Unknown RemoteFunction '{name}' (declare it in Remotes.luau)`)
	return folder:WaitForChild(name) :: RemoteFunction
end

return Remotes
