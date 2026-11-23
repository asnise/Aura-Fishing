--!nonstrict
-- Low FX mode (GDD 10.2): hides other players' aura particles/lights, keeps your own.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local AuraProjectRenderer = require(script.Parent.AuraProjectRenderer)
local DataController = require(script.Parent.DataController)

local player = Players.LocalPlayer
local AuraFXController = {}

local lowFX = false
local projects = {}
local UPDATE_INTERVAL = 1 / 30
local DRAW_DISTANCE = 160

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

local function track(inst: Instance)
	if not inst:IsA("StringValue") or inst.Name ~= "AuraVFX" or inst:GetAttribute("AuraParticleProject") ~= true then
		return
	end
	local root = inst.Parent
	if root and root:IsA("BasePart") and root.Name == "HumanoidRootPart" and not projects[inst] then
		projects[inst] = { root = root, started = os.clock() }
	end
end

local function removeProject(inst: Instance)
	local record = projects[inst]
	if record then
		projects[inst] = nil
		if record.handle then record.handle:Destroy() end
	end
end

local function updateProjects()
	local now = os.clock()
	local camera = Workspace.CurrentCamera
	for marker, record in projects do
		if record.failed then continue end
		local nearby = camera and (record.root.Position - camera.CFrame.Position).Magnitude <= DRAW_DISTANCE
		if nearby and (not lowFX or isOwn(marker)) then
			if not record.handle then
				local ok, handle = pcall(AuraProjectRenderer.mount, marker, record.root)
				if not ok then
					record.failed = true
					warn("Aura project failed to load:", handle)
					continue
				end
				record.handle = handle
			end
			record.handle:Update(now - record.started)
		elseif record.handle then
			record.handle:Destroy()
			record.handle = nil
		end
	end
end

function AuraFXController.Init()
	Workspace.DescendantAdded:Connect(function(inst)
		apply(inst)
		track(inst)
	end)
	Workspace.DescendantRemoving:Connect(removeProject)
	for _, inst in Workspace:GetDescendants() do track(inst) end
	local accumulator = 0
	RunService.Heartbeat:Connect(function(dt)
		if not next(projects) then return end
		for _, record in projects do
			if record.handle then record.handle:Follow() end
		end
		accumulator += dt
		if accumulator >= UPDATE_INTERVAL then
			accumulator %= UPDATE_INTERVAL
			updateProjects()
		end
	end)
	DataController.Observe(function(profile)
		local v = profile.Settings.LowFX == true
		if v ~= lowFX then
			lowFX = v
			applyAll()
		end
	end)
end

return AuraFXController
