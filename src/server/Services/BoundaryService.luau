--!strict
-- Safety net for the sea edge (Shared/PlayArea). The client current (BoundaryController) normally
-- stops players before Hard; if someone still ends up past Hard + ReturnMargin (lag, exploit, a
-- seat/boat), they are put back at the area's ReturnTo point with a short message.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local PlayArea = require(Shared.PlayArea)
local Remotes = require(Shared.Remotes)

local BoundaryService = {}

local CHECK_EVERY = 1

function BoundaryService.Check(player: Player): boolean
	local char = player.Character
	if not char then
		return false
	end
	local root = char:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not root then
		return false
	end
	local area, d = PlayArea.At(root.Position)
	if not area or not area.ReturnTo or d <= area.Hard + PlayArea.ReturnMargin then
		return false
	end
	local humanoid = char:FindFirstChildOfClass("Humanoid")
	if humanoid and humanoid.SeatPart then
		humanoid.Sit = false
	end
	char:PivotTo(CFrame.new(area.ReturnTo + Vector3.new(0, 3, 0)))
	Remotes.Event("Notify"):FireClient(player, "The waves carried you back to the boardwalk.", Color3.fromRGB(80, 160, 220))
	return true
end

function BoundaryService.Init()
	task.spawn(function()
		while true do
			task.wait(CHECK_EVERY)
			for _, p in Players:GetPlayers() do
				BoundaryService.Check(p)
			end
		end
	end)
end

return BoundaryService
