--!nonstrict
-- Low FX mode (GDD 10.2): hides other players' aura particles/lights, keeps your own.

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local DataController = require(script.Parent.DataController)

local player = Players.LocalPlayer
local AuraFXController = {}

local lowFX = false

local function isOwn(inst: Instance): boolean
	local char = player.Character
	return char ~= nil and inst:IsDescendantOf(char)
end

local function apply(inst: Instance)
	if inst:IsA("ParticleEmitter") or inst:IsA("PointLight") then
		local vfx = inst:FindFirstAncestor("AuraVFX")
		if vfx and not isOwn(inst) then
			(inst :: any).Enabled = not lowFX
		end
	end
end

local function applyAll()
	for _, d in Workspace:GetDescendants() do
		apply(d)
	end
end

function AuraFXController.Init()
	Workspace.DescendantAdded:Connect(apply)
	DataController.Observe(function(profile)
		local v = profile.Settings.LowFX == true
		if v ~= lowFX then
			lowFX = v
			applyAll()
		end
	end)
end

return AuraFXController
