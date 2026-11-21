--!nonstrict
-- Runtime access to the component samples baked in StarterGui.Components (see Screens/Components.luau).
--   Components.Clone("NotifyPill") -> a fresh copy of the sample (your Studio edits included)
-- Falls back to building the component in code if the place has no baked copy.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")
local TweenService = game:GetService("TweenService")

local New = require(script.Parent.New)
local Make = (require(script.Parent.Screens:WaitForChild("Components")) :: any).Make

local Components = {}

local sheet: Instance? = nil
local function findSheet(): Instance?
	if sheet and sheet.Parent then
		return sheet
	end
	local gui: Instance? = nil
	if RunService:IsRunning() and Players.LocalPlayer then
		local pg = Players.LocalPlayer:FindFirstChild("PlayerGui")
		gui = pg and (pg:FindFirstChild("Components") or (StarterGui:FindFirstChild("Components") and pg:WaitForChild("Components", 10)))
	else
		gui = StarterGui:FindFirstChild("Components")
	end
	sheet = gui and gui:FindFirstChild("Sheet")
	return sheet
end

function Components.Clone(name: string): any
	local s = findSheet()
	local cell = s and s:FindFirstChild(name)
	local sample = cell and cell:FindFirstChild("Sample")
	local copy
	if sample then
		copy = sample:Clone()
	else
		copy = Make[name]()
	end
	copy.Name = name
	New.ApplyImages(copy)
	New.HookButtons(copy)
	if copy:IsA("TextButton") and copy:GetAttribute("CozyButton") then
		New.HookButton(copy)
	end
	return copy
end

-- Hover / press pop for a Make.MenuTile (baked tiles are plain instances; behaviour is added here).
function Components.HookTile(b: GuiButton)
	local pop = b:FindFirstChild("Pop") :: UIScale?
	if not pop then
		pop = Instance.new("UIScale")
		pop.Name = "Pop"
		pop.Parent = b
	end
	local function to(v: number)
		TweenService:Create(pop :: UIScale, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Scale = v }):Play()
	end
	b.MouseEnter:Connect(function()
		to(1.06)
	end)
	b.MouseLeave:Connect(function()
		to(1)
	end)
	b.MouseButton1Down:Connect(function()
		to(0.94)
	end)
	b.MouseButton1Up:Connect(function()
		to(1.06)
	end)
end

return Components
