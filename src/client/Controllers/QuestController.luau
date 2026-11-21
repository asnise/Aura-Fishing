--!strict
-- Manages the Daily Quests window (C7, Figma Option 1 Classic Cozy Deck).
-- Opened from Main Menu hub (Quests tile) or HUD.QuestsRequested.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Remotes = require(Shared.Remotes)

local New = require(script.Parent.Parent.UI.New)
local QuestsScreen = require(script.Parent.Parent.UI.QuestsScreen)
local DataController = require(script.Parent.DataController)
local HUD = require(script.Parent.HUDController)

local T = New.Theme

local QuestController = {}

local screen: any = nil
local lastTick = 0

local function onClaim(index: number)
	local func = Remotes.Func("ClaimQuest")
	local ok, msg = func:InvokeServer(index)
	if ok then
		HUD.Notify(msg or "Reward claimed!", T.GoodLip)
	else
		HUD.Notify(msg or "Could not claim reward", T.Bad)
	end
end

function QuestController.Init()
	screen = QuestsScreen.Create({
		OnClaim = onClaim,
		OnClose = function()
			QuestController.Close()
		end,
	})

	DataController.Observe(function(profile)
		if screen and screen.IsOpen() then
			screen.Render(profile)
		end
	end)

	if (HUD :: any).QuestsRequested then
		(HUD :: any).QuestsRequested:Connect(QuestController.Open)
	end

	RunService.Heartbeat:Connect(function()
		local now = os.clock()
		if now - lastTick >= 1 then
			lastTick = now
			if screen and screen.IsOpen() then
				screen.Tick()
			end
		end
	end)
end

function QuestController.Open()
	if screen then
		screen.Open()
		screen.Render(DataController.Profile)
		screen.Tick()
	end
end

function QuestController.Close()
	if screen then
		screen.Close()
	end
end

function QuestController.Toggle()
	if screen and screen.IsOpen() then
		QuestController.Close()
	else
		QuestController.Open()
	end
end

function QuestController.IsOpen(): boolean
	return screen ~= nil and screen.IsOpen()
end

return QuestController
