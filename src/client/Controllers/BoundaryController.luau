--!strict
-- Edge of the sea (Shared/PlayArea): past the area's Soft radius a current pushes the character
-- back toward the centre, growing until it beats swimming speed around Hard. Shows a one-line
-- warning (with cooldown). The server (BoundaryService) only steps in if someone gets past anyway.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local PlayArea = require(Shared.PlayArea)

local HUD = require(script.Parent.HUDController)

local BoundaryController = {}

local MAX_PUSH = 26 -- studs/s at Hard (swim/walk speed is 16)
local WARN_COOLDOWN = 10

local lastWarn = -math.huge

function BoundaryController.Init()
	local player = Players.LocalPlayer
	RunService.Heartbeat:Connect(function(dt)
		local char = player.Character
		local root = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
		if not root or root.Anchored then
			return
		end
		local area, d = PlayArea.At(root.Position)
		if not area then
			return
		end
		local s = PlayArea.Strength(area, d)
		if s <= 0 then
			return
		end
		local push = PlayArea.HomeDir(area, root.Position) * (s ^ 1.5) * MAX_PUSH * dt
		root.CFrame += push
		if os.clock() - lastWarn > WARN_COOLDOWN then
			lastWarn = os.clock()
			HUD.Notify("The current is too strong out here - head back to the boardwalk!", Color3.fromRGB(80, 160, 220))
		end
	end)
end

return BoundaryController
