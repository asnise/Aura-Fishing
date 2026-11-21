--!nonstrict
-- Screens are stored in the place (StarterGui), not created when the game starts.
--   * Each screen has a builder in UI/Screens/<Name>.luau: { Name = "Modal", Build = function(): ScreenGui }.
--   * `node tools/ui/bake.mjs [Name ...]` runs the builders inside Studio (StudioBridge) and puts the
--     ScreenGuis into StarterGui. Save the place afterwards. Hand-edit them in Studio freely; set the
--     ScreenGui attribute Locked = true so a later bake skips it.
--   * At runtime controllers call Baked.Get(name) to find their ScreenGui in PlayerGui and bind data.
--     Only if the place has no baked copy (e.g. a fresh `rojo build`) is the screen built here, with a warning.

local Players = game:GetService("Players")
local StarterGui = game:GetService("StarterGui")

local New = require(script.Parent.New)
local Screens = script.Parent.Screens

local Baked = {}

function Baked.Get(name: string): ScreenGui
	local player = Players.LocalPlayer
	local playerGui = player and player:FindFirstChild("PlayerGui")
	if not playerGui then
		local sg = StarterGui:FindFirstChild(name)
		if sg and sg:IsA("ScreenGui") then
			return sg
		end
		playerGui = if player then player:WaitForChild("PlayerGui", 5) else nil
		if not playerGui then
			playerGui = StarterGui :: any
		end
	end
	local gui = playerGui:FindFirstChild(name)
	local baked = StarterGui:FindFirstChild(name) ~= nil
	if not gui and baked then
		-- baked: Roblox copies StarterGui into PlayerGui when the character spawns. The first spawn can
		-- take a while in Studio (avatar loading), so wait long; 15 s was sometimes too short for the HUD.
		gui = playerGui:WaitForChild(name, 60)
	end
	if not gui then
		warn(
			if baked
				then `[UI] ScreenGui "{name}" is baked but did not reach PlayerGui in 60 s (no character?); building it at runtime.`
				else `[UI] ScreenGui "{name}" is not baked into StarterGui; building it at runtime. Run: node tools/ui/bake.mjs {name}`
		)
		local screen = require(Screens:WaitForChild(name)) :: any
		local built = screen.Build()
		built.Parent = playerGui
		gui = built
		-- if the baked copy still arrives later (first spawn), drop it: the runtime one is already bound
		playerGui.ChildAdded:Connect(function(child)
			if child.Name == name and child ~= built and child:IsA("ScreenGui") then
				child:Destroy()
			end
		end)
	end
	New.ApplyImages(gui)
	New.HookButtons(gui)
	return gui :: ScreenGui
end

-- Find a descendant by slash path ("Window/Footer/Confirm"); errors with the exact missing part.
function Baked.Find(root: Instance, path: string): any
	local cur = root
	for part in string.gmatch(path, "[^/]+") do
		local nxt = cur:FindFirstChild(part)
		if not nxt then
			error(`[UI] {root.Name}: missing "{part}" in "{path}" (re-bake the screen or fix the name in Studio)`, 2)
		end
		cur = nxt
	end
	return cur
end

return Baked
