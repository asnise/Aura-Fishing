--!strict
-- Rod Fusion (docs/ROD_FUSION_COST.md, rules in shared/Items/Fusion). The server rolls the 5% failure and
-- charges; the Fusion window only sends which rods, which mod type and which two slots.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Remotes = require(Shared.Remotes)
local Inventory = require(Shared.Inventory)
local Fusion = require(Shared.Items.Fusion)
local Format = require(Shared.Util.Format)
local Registry = require(Shared.Registry)

local DataService = require(script.Parent.DataService)
local AquariumService = require(script.Parent.AquariumService)

local FusionService = {}

local rng = Random.new()
local lastCall: { [Player]: number } = {}

-- The window opens from Old Marlin: when the map has his stall, the player must be near it.
local function nearMerchant(player: Player): boolean
	local map = Workspace:FindFirstChild("Map")
	local merchant = map and map:FindFirstChild("Merchant", true)
	local prompt = merchant and merchant:FindFirstChild("SellPrompt")
	local part = prompt and prompt.Parent
	if not part or not part:IsA("BasePart") then
		return true -- no stall in this place (Studio test map): nothing to check against
	end
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
	return root ~= nil and (root.Position - part.Position).Magnitude <= Registry.GameConfig.Fusion.NpcRange
end

function FusionService.Fuse(player: Player, baseUuid: any, materialUuid: any, kind: any, baseIndex: any, materialIndex: any, guard: any): (boolean, string, any)
	local data = DataService.Get(player)
	if not data then
		return false, "Invalid request", nil
	end
	if not nearMerchant(player) then
		return false, "Go back to Old Marlin to fuse rods", nil
	end
	local base = Inventory.Find(data, baseUuid)
	local material = Inventory.Find(data, materialUuid)
	if not base or not material then
		return false, "Rod not found", nil
	end
	local plan, reason = Fusion.Plan(data, base, material, kind, baseIndex, materialIndex)
	if not plan then
		return false, reason or "Cannot fuse", nil
	end
	AquariumService.Settle(player)
	if data.Coins < plan.Coins then
		return false, `Need {Format.Number(plan.Coins)} coins`, nil
	end
	if data.Pearls < plan.Pearls then
		return false, `Need {Format.Number(plan.Pearls)} Pearls`, nil
	end
	local guarded = guard == true
	if guarded then
		if plan.GuardGems <= 0 then
			return false, "Guard is not offered for this mod", nil
		end
		if data.Gems < plan.GuardGems then
			return false, `Need {Format.Number(plan.GuardGems)} Gems for Guard`, nil
		end
	end

	Inventory.Remove(data, material.UUID) -- the Material rod is gone either way
	if not guarded and rng:NextNumber() < Fusion.FailChance then
		DataService.MarkDirty(player)
		return true, "Fusion failed. The Material rod is lost.", { Success = false, Coins = 0, Pearls = 0, Gems = 0 }
	end

	data.Coins -= plan.Coins
	data.Pearls -= plan.Pearls
	local gems = if guarded then plan.GuardGems else 0
	data.Gems -= gems
	local list: { any } = {}
	if plan.Kind == "Prefixes" then
		list = base.Prefixes or {}
		base.Prefixes = list
	else
		list = base.Suffixes or {}
		base.Suffixes = list
	end
	list[plan.BaseIndex] = table.clone(plan.Mod) -- Enhance of the Material rod does not come along
	DataService.MarkDirty(player)
	return true, `Fused! {plan.Mod.Name} is now on your rod.`, { Success = true, Coins = plan.Coins, Pearls = plan.Pearls, Gems = gems }
end

function FusionService.Init()
	Remotes.Func("FuseRods").OnServerInvoke = function(player, baseUuid, materialUuid, kind, baseIndex, materialIndex, guard)
		local now = os.clock()
		if lastCall[player] and now - lastCall[player] < 0.4 then
			return false, "Slow down", nil
		end
		lastCall[player] = now
		return FusionService.Fuse(player, baseUuid, materialUuid, kind, baseIndex, materialIndex, guard)
	end
	game:GetService("Players").PlayerRemoving:Connect(function(p)
		lastCall[p] = nil
	end)
end

return FusionService
