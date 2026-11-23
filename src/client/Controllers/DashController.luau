--!nonstrict
-- Dash + front flip (Q on PC; no mobile button yet). The character leaps forward while its root joint spins one
-- full forward rotation. Client-side only (the player owns their character); blocked while any menu or dialogue is open.
local Players = game:GetService("Players")
local ContextActionService = game:GetService("ContextActionService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local MenuManager = require(script.Parent.Parent.UI.MenuManager)

local DashController = {}

local COOLDOWN = 1.5
local DURATION = 0.55 -- seconds of the flip
local SPEED = 50 -- studs/s forward during the dash
local LIFT = 32 -- upward kick

local busy = false
local lastDash = 0

local function dash()
	local player = Players.LocalPlayer
	local char = player.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	local root = char and char:FindFirstChild("HumanoidRootPart")
	if busy or not hum or not root or hum.Health <= 0 or hum.Sit then
		return
	end
	if os.clock() - lastDash < COOLDOWN or MenuManager.Top() ~= nil then
		return
	end
	busy = true
	lastDash = os.clock()

	local joint = char:FindFirstChild("RootJoint", true) -- R15: LowerTorso.Root is named "Root"; R6: HumanoidRootPart.RootJoint
	if not joint then
		joint = char:FindFirstChild("Root", true)
	end
	local baseC0 = if joint and joint:IsA("Motor6D") then joint.C0 else nil
	local look = root.CFrame.LookVector
	local forward = Vector3.new(look.X, 0, look.Z)
	forward = if forward.Magnitude > 0.01 then forward.Unit else Vector3.new(0, 0, -1)

	-- dash sound is muted for now (does not fit the game); re-enable: SoundController.Play("dash")
	hum:ChangeState(Enum.HumanoidStateType.Jumping)
	root.AssemblyLinearVelocity = forward * SPEED + Vector3.new(0, LIFT, 0)

	local started = os.clock()
	local connection
	connection = RunService.Heartbeat:Connect(function()
		local t = (os.clock() - started) / DURATION
		if t >= 1 or not root.Parent or hum.Health <= 0 then
			connection:Disconnect()
			if baseC0 and joint.Parent then
				joint.C0 = baseC0
			end
			busy = false
			return
		end
		-- keep the forward speed in the air (humanoid air control would bleed it off)
		local v = root.AssemblyLinearVelocity
		root.AssemblyLinearVelocity = Vector3.new(forward.X * SPEED, v.Y, forward.Z * SPEED)
		if baseC0 then
			local eased = TweenService:GetValue(t, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
			joint.C0 = baseC0 * CFrame.Angles(-math.rad(360) * eased, 0, 0) -- negative X = pitch forward
		end
	end)
end

function DashController.Init()
	ContextActionService:BindAction("Dash", function(_, state)
		if state == Enum.UserInputState.Begin then
			dash()
		end
		return Enum.ContextActionResult.Pass
	end, false, Enum.KeyCode.Q)
end

return DashController
